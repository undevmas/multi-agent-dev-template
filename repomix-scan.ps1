param(
    [ValidateSet("all", "backend-net", "backend-nestjs", "frontend")]
    [string]$Target = "all",
    [switch]$Full,
    [switch]$NoCompress
)
# Nota: el contexto git (diffs y logs) se controla en repomix.config.json
# mediante git.includeDiffs y git.includeLogs — no hay flags CLI equivalentes en repomix.

$ErrorActionPreference = "Stop"

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
    $args = @($repomixArgsBase) + @($SourcePath, "--output", $OutputPath)

    if (Test-Path $ConfigPath) {
        # Heredar style, compress, ignore patterns y security-check del config
        $args += @("--config", $ConfigPath)
        # Respetar --full / --no-compress del usuario sobre lo que define el config
        if (-not $compressEnabled) {
            $args += "--no-compress"
        }
    }
    else {
        $args += @("--style", $style)
        if ($compressEnabled) { $args += "--compress" }
    }

    if ($IgnorePatterns -ne "") {
        $args += @("--ignore", $IgnorePatterns)
    }

    Write-Info "Escaneando $Label ..."

    Push-Location $CodigoDir
    try {
        & npx @args
    }
    finally {
        Pop-Location
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
Lee IA_Memoria/snapshots/snapshot-latest.md e inspecciona el codigo en Codigo/.
Actualiza estos tres archivos con lo que encuentres en el codigo real.
No inventes ni asumas nada que no este en el codigo:

1. IA_Memoria/arquitectura.md
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
   - Confirma o corrige los patrones de naming detectados en el codigo real
   - Deja [COMPLETAR] donde no puedas inferirlo del codigo

4. IA_Memoria/deuda-tecnica.md (solo si el proyecto tiene codigo existente)
   - Si detectas antipatrones en el codigo (int secuenciales como IDs, DELETE directo
     en tablas de negocio, response sin estructura estandar, credenciales hardcodeadas)
   - Agregar una entrada por cada antipatron siguiendo el formato del archivo
   - Si el proyecto esta vacio o el codigo sigue las convenciones: no agregar nada

Al terminar, reporta: cuantos modulos encontraste implementados,
que tecnologias detectaste, si hay alguna inconsistencia con
lo que ya estaba declarado en los archivos de memoria,
y si registraste deuda tecnica (si/no y cuantas entradas).
"@

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PROMPT DE INSPECCION — copiar y pegar en tu agente IA" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host $prompt -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
