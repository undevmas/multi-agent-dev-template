param(
    # "all" escanea Codigo/ completo; cualquier otro valor escanea Codigo/<Target>/
    [string]$Target = "all",
    [switch]$Full,
    [switch]$NoCompress
)
# Nota: el contexto git (diffs y logs) se controla en repomix.config.json
# mediante git.includeDiffs y git.includeLogs - no hay flags CLI equivalentes en repomix.

$ErrorActionPreference = "Stop"

# Fix de encoding — PowerShell (sobre todo 5.1, el que trae Windows por
# default) no usa UTF-8 para la salida de consola salvo que se fuerce.
# Sin esto, los acentos/ñ de los mensajes [INFO]/[WARN] y del prompt final
# se ven mal (mojibake) aunque el contenido generado sea correcto — es
# puramente visual en la terminal, no afecta el snapshot ni el prompt copiado.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CodigoDir = Join-Path $RootDir "Codigo"
$SnapshotsDir = Join-Path $RootDir "IA_Memoria\snapshots"
$ConfigPath = Join-Path $CodigoDir "repomix.config.json"

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Ok([string]$Message) {
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

if (-not (Test-Path $CodigoDir)) {
    Write-Warn "No se encontro la carpeta Codigo/."
    exit 0
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] npx no encontrado. Instala Node.js para usar repomix." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $SnapshotsDir | Out-Null

$repomixArgsBase = @("repomix@latest")

$style = "markdown"
$compressEnabled = -not $NoCompress
if ($Full) {
    $compressEnabled = $false
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

function Invoke-RepomixScan {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [string]$Label,
        [string]$IgnorePatterns = ""
    )

    # Siempre pasar directorio y output explícito para todos los targets
    $npxArgs = @($repomixArgsBase) + @($SourcePath, "--output", $OutputPath)
    $tempConfigPath = $null

    if (Test-Path $ConfigPath) {
        # Heredar style, ignore patterns y security-check del config.
        # NOTA: Repomix no tiene un flag CLI --no-compress (verificado contra
        # cliRun.ts del repo oficial) — --compress es opt-in y no es negable.
        # Si se pide --Full/--NoCompress y el config trae compress:true, se
        # genera un config temporal con compress:false en vez de un flag
        # que no existe.
        if (-not $compressEnabled) {
            $tempConfigPath = Join-Path ([System.IO.Path]::GetTempPath()) "repomix-config-$([guid]::NewGuid().ToString('N')).json"
            $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            if (-not $cfg.output) { $cfg | Add-Member -MemberType NoteProperty -Name output -Value ([pscustomobject]@{}) }
            $cfg.output.compress = $false
            $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $tempConfigPath -Encoding UTF8
            $npxArgs += @("--config", $tempConfigPath)
        }
        else {
            $npxArgs += @("--config", $ConfigPath)
        }
    }
    else {
        $npxArgs += @("--style", $style)
        if ($compressEnabled) { $npxArgs += "--compress" }
    }

    if ($IgnorePatterns -ne "") {
        $npxArgs += @("--ignore", $IgnorePatterns)
    }

    Write-Info "Escaneando $Label ..."

    Push-Location $CodigoDir
    try {
        & npx @npxArgs
    }
    finally {
        Pop-Location
        if ($tempConfigPath -and (Test-Path $tempConfigPath)) {
            Remove-Item $tempConfigPath -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not (Test-Path $OutputPath)) {
        Write-Host "[ERROR] No se genero el snapshot esperado: $OutputPath" -ForegroundColor Red
        exit 1
    }

    $file = Get-Item $OutputPath
    $meta = [ordered]@{
        label = $Label
        generatedAt = $timestamp
        source = $SourcePath
        output = $OutputPath
        compress = $compressEnabled
        sizeBytes = $file.Length
    }

    $metaPath = [System.IO.Path]::ChangeExtension($OutputPath, ".meta.json")
    $meta | ConvertTo-Json -Depth 5 | Set-Content -Path $metaPath -Encoding UTF8

    Write-Ok "Snapshot: $OutputPath"
    Write-Ok "Meta: $metaPath"
}

$hasCode = (Get-ChildItem -Path $CodigoDir -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".gitignore" } | Measure-Object).Count -gt 0
if (-not $hasCode) {
    Write-Warn "Codigo/ esta vacio. Agrega codigo y vuelve a ejecutar."
    exit 0
}

switch ($Target) {
    "backend-net" {
        $path = Join-Path $CodigoDir "backend-net"
        if (-not (Test-Path $path)) { Write-Warn "No existe backend-net/."; exit 0 }
        Invoke-RepomixScan -SourcePath "backend-net" -OutputPath (Join-Path $SnapshotsDir "snapshot-backend-net.md") -Label "backend-net" -IgnorePatterns "**/bin/**,**/obj/**,**/*.user,**/.vs/**"
    }
    "backend-nestjs" {
        $path = Join-Path $CodigoDir "backend-nestjs"
        if (-not (Test-Path $path)) { Write-Warn "No existe backend-nestjs/."; exit 0 }
        Invoke-RepomixScan -SourcePath "backend-nestjs" -OutputPath (Join-Path $SnapshotsDir "snapshot-backend-nestjs.md") -Label "backend-nestjs" -IgnorePatterns "**/node_modules/**,**/dist/**,**/build/**,**/coverage/**"
    }
    "frontend" {
        $path = Join-Path $CodigoDir "frontend-angular"
        if (-not (Test-Path $path)) { Write-Warn "No existe frontend-angular/."; exit 0 }
        Invoke-RepomixScan -SourcePath "frontend-angular" -OutputPath (Join-Path $SnapshotsDir "snapshot-frontend.md") -Label "frontend-angular" -IgnorePatterns "**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**"
    }
    default {
        $out = Join-Path $SnapshotsDir "snapshot-latest.md"
        Invoke-RepomixScan -SourcePath "." -OutputPath $out -Label "codigo-completo"
    }
}

$prompt = @"
Lee IA_Memoria/snapshots/snapshot-latest.md usando lectura estrategica por secciones:

PASO 1 — Leer las primeras 300 lineas del snapshot.
  Repomix siempre coloca el arbol de archivos y el resumen de tokens al inicio.
  Con eso sabes que modulos existen y cuales son los archivos mas pesados.
  No leas mas hasta completar este paso.

PASO 2 — Con el arbol como mapa, leer selectivamente solo las secciones utiles:
  - Archivos .csproj / package.json / *.sln  → tecnologias y versiones
  - docker-compose.yml / appsettings*.json / .env.example → puertos y variables
  - Controllers o endpoints (buscar "Controller", "router", "@Controller")
    → formato real de respuesta API (campos, estructura de error, traceId, etc.)
  - Archivos base / middleware / filtros de excepciones → patron de errores
  - Carpetas de modulos → cuales estan implementados vs scaffolding vacio
  - Migraciones o esquemas de BD → tipo de IDs, soft delete

  Si el snapshot supera 400 lineas: NO leerlo completo de corrido.
  Saltar directamente a los bloques de cada archivo usando el arbol del PASO 1.

PASO 3 — Con la informacion recopilada, actualizar los archivos de memoria:

1. IA_Memoria/arquitectura.md
   - Ruta raiz del proyecto: el nombre exacto de la carpeta dentro de Codigo/ donde vive el proyecto
     (ej: si el arbol muestra "Codigo/MiApp/src/...", la raiz es "Codigo/MiApp/" y el src es "Codigo/MiApp/src/")
   - Mapa de rutas por capa: para cada capa (Domain, Application, Infrastructure, API, etc.)
     documentar su ruta completa desde Codigo/ para que cualquier agente pueda acceder sin explorar
   - Estructura de Codigo/: subcarpetas de primer nivel con contenido y tecnologia detectada
   - Tecnologias y versiones reales detectadas
   - Modulos y servicios existentes con su estado actual
   - Puertos en docker-compose o archivos de configuracion
   - Variables de entorno en .env.example o en el codigo

2. IA_Memoria/progreso.md
   - Marca [x] solo los modulos/features que realmente existan en el codigo
   - Deja [ ] los que no esten implementados
   - Si el proyecto esta vacio: escribe "Proyecto nuevo, sin modulos implementados"
   - Reemplaza los pendientes de ejemplo con los reales del proyecto

3. IA_Memoria/convenciones.md
   - Detectar y documentar el formato real de respuesta API usado en los controllers
     (campos exactos, estructura del objeto error, traceId, paginacion — lo que este en el codigo)
   - Detectar la arquitectura de capas usada (Clean Architecture, N-capas, Vertical Slice, etc.)
   - Detectar el patron de acceso a datos (Repository, DbContext directo, CQRS + MediatR, etc.)
   - Detectar el patron de manejo de excepciones y validaciones
   - Detectar la estructura de carpetas dentro de cada capa
   - Confirmar o corregir los patrones de naming ya declarados en el archivo
   - Deja [COMPLETAR] solo donde no puedas inferirlo del snapshot

4. IA_Memoria/deuda-tecnica.md (solo si el proyecto tiene codigo existente)
   - Registrar antipatrones reales: IDs enteros secuenciales, DELETE directo en tablas de negocio,
     credenciales hardcodeadas, endpoints que mezclan formatos de response distintos entre si
   - NO registrar como deuda: que el formato de response sea distinto al ejemplo del template
     (el formato real ya queda documentado en convenciones.md y es la fuente de verdad)
   - Agregar una entrada por cada antipatron siguiendo el formato del archivo
   - Si el proyecto esta vacio o el codigo sigue las convenciones: no agregar nada

Al terminar, reporta: cuantos modulos encontraste implementados,
que tecnologias detectaste, si hay alguna inconsistencia con
lo que ya estaba declarado en los archivos de memoria,
y si registraste deuda tecnica (si/no y cuantas entradas).
"@

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PROMPT DE INSPECCION - copiar y pegar en tu agente IA" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host $prompt -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
