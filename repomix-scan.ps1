param(
    # "all" escanea Codigo/ completo; cualquier otro valor escanea Codigo/<Target>/
    [string]$Target = "all",
    # Stack del target (dotnet, nestjs, angular, react, python-fastapi).
    # Determina el preset de ignore cuando $Target no es un alias conocido.
    # La usa principalmente repomix-scan-modules.ps1; en uso manual es opcional.
    [string]$Stack = "",
    [switch]$Full,
    [switch]$NoCompress
)
# Nota: el contexto git (diffs y logs) se controla en repomix.config.json
# mediante git.includeDiffs y git.includeLogs - no hay flags CLI equivalentes en repomix.

$ErrorActionPreference = "Stop"

# Fix de encoding - PowerShell (sobre todo 5.1, el que trae Windows por
# default) no usa UTF-8 para la salida de consola salvo que se fuerce.
# Sin esto, los acentos/ñ de los mensajes [INFO]/[WARN] y del prompt final
# se ven mal (mojibake) aunque el contenido generado sea correcto - es
# puramente visual en la terminal, no afecta el snapshot ni el prompt copiado.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $RootDir "repomix-lib.ps1")

$Context = New-RepomixContext -RootDir $RootDir -Full:$Full -NoCompress:$NoCompress

if (-not (Test-Path $Context.CodigoDir)) {
    Write-Warn "No se encontro la carpeta Codigo/."
    exit 0
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] npx no encontrado. Instala Node.js para usar repomix." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $Context.SnapshotsDir | Out-Null

$hasCode = (Get-ChildItem -Path $Context.CodigoDir -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".gitignore" } | Measure-Object).Count -gt 0
if (-not $hasCode) {
    Write-Warn "Codigo/ esta vacio. Agrega codigo y vuelve a ejecutar."
    exit 0
}

$isFullScan = ($Target -eq "all")

if ($isFullScan) {
    $out = Join-Path $Context.SnapshotsDir "snapshot-latest.md"
    $snapshotRelPath = "IA_Memoria/snapshots/snapshot-latest.md"
    Invoke-RepomixScan -Context $Context -SourcePath "." -OutputPath $out -Label "codigo-completo" | Out-Null
}
else {
    # Alias de conveniencia para layouts planos (Codigo/<tech>/ directo).
    # Si $Target no matchea ningun alias, se trata como ruta arbitraria
    # relativa a Codigo/ (ej: "MiApp/src/Gateway" en un monorepo con
    # multiples microservicios bajo src/), usando -Stack para el ignore
    # correcto si se especifico.
    $aliasMap = @{
        "backend-net"    = @{ Path = "backend-net"; Stack = "dotnet" }
        "backend-nestjs" = @{ Path = "backend-nestjs"; Stack = "nestjs" }
        "frontend"       = @{ Path = "frontend-angular"; Stack = "angular" }
    }

    $relativePath = $Target
    $effectiveStack = $Stack

    if ($aliasMap.ContainsKey($Target)) {
        $relativePath = $aliasMap[$Target].Path
        if (-not $effectiveStack) { $effectiveStack = $aliasMap[$Target].Stack }
    }

    $ignorePatterns = Get-StackIgnorePatterns $effectiveStack

    $sourcePath = Join-Path $Context.CodigoDir $relativePath
    if (-not (Test-Path $sourcePath)) {
        Write-Warn "No existe Codigo/$relativePath/."
        exit 0
    }

    $safeName = Get-SnapshotSafeName $Target
    $out = Join-Path $Context.SnapshotsDir "snapshot-$safeName.md"
    $snapshotRelPath = "IA_Memoria/snapshots/snapshot-$safeName.md"
    Invoke-RepomixScan -Context $Context -SourcePath $relativePath -OutputPath $out -Label $Target -IgnorePatterns $ignorePatterns | Out-Null
}

if ($isFullScan) {
    $prompt = @"
Lee $snapshotRelPath usando lectura estrategica por secciones:

PASO 1 - Leer las primeras 300 lineas del snapshot.
  Repomix siempre coloca el arbol de archivos y el resumen de tokens al inicio.
  Con eso sabes que modulos existen y cuales son los archivos mas pesados.
  No leas mas hasta completar este paso.

PASO 2 - Con el arbol como mapa, leer selectivamente solo las secciones utiles:
  - Archivos .csproj / package.json / *.sln  -> tecnologias y versiones
  - docker-compose.yml / appsettings*.json / .env.example -> puertos y variables
  - Controllers o endpoints (buscar "Controller", "router", "@Controller")
    -> formato real de respuesta API (campos, estructura de error, traceId, etc.)
  - Archivos base / middleware / filtros de excepciones -> patron de errores
  - Carpetas de modulos -> cuales estan implementados vs scaffolding vacio
  - Migraciones o esquemas de BD -> tipo de IDs, soft delete

  Si el snapshot supera 400 lineas: NO leerlo completo de corrido.
  Saltar directamente a los bloques de cada archivo usando el arbol del PASO 1.

PASO 3 - Con la informacion recopilada, actualizar los archivos de memoria:

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
     (campos exactos, estructura del objeto error, traceId, paginacion - lo que este en el codigo)
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

5. IA_Memoria/modulos.json (crear si no existe, o sobreescribir con lo detectado)
   - Un objeto { "generatedAt": "...", "modules": [...] } con un entry por cada modulo/microservicio real
     detectado en el arbol (name, path relativo a Codigo/, stack: dotnet | nestjs | angular | react | python-fastapi)
   - Este archivo es el que usa repomix-scan-modules.ps1/.sh para escanear un modulo a la vez -
     mantenlo sincronizado con lo que declares en arquitectura.md

Al terminar, reporta: cuantos modulos encontraste implementados,
que tecnologias detectaste, si hay alguna inconsistencia con
lo que ya estaba declarado en los archivos de memoria,
y si registraste deuda tecnica (si/no y cuantas entradas).
"@
}
else {
    $prompt = @"
Lee $snapshotRelPath usando lectura estrategica por secciones (arbol + resumen de tokens
al inicio, luego solo las secciones utiles: .csproj/package.json, controllers/endpoints,
middleware/manejo de errores, migraciones).

Este es un scan de un modulo especifico ($Target), no del proyecto completo. Al actualizar memoria:
- IA_Memoria/arquitectura.md: actualiza SOLO la seccion de este modulo (ruta, tecnologia, estado),
  sin tocar ni asumir el estado de otros modulos que no fueron escaneados.
- IA_Memoria/progreso.md: marca [x] los features de este modulo que ya existan en el codigo.
- IA_Memoria/convenciones.md: si este modulo revela un patron nuevo o inconsistente con lo ya
  documentado, agregalo o senala la inconsistencia - no lo generalices a otros modulos sin evidencia.
- IA_Memoria/deuda-tecnica.md: registra antipatrones reales encontrados en este modulo.
- IA_Memoria/modulos.json: si no existe todavia, no lo generes a partir de este scan parcial
  (necesita ver el proyecto completo) - sugiere correr ``.\repomix-scan.ps1 -Target all`` primero.

Reporta: que encontraste en este modulo especificamente y si hay
inconsistencias con lo que ya estaba declarado en los archivos de memoria.
"@
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PROMPT DE INSPECCION - copiar y pegar en tu agente IA" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host $prompt -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
