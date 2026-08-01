param(
    # Nombres de modulos a escanear (deben existir en IA_Memoria/modulos.json).
    # Vacio = escanea todos los modulos del manifest, uno por uno.
    [string[]]$Modules = @(),
    [switch]$Full,
    [switch]$NoCompress
)
# Orquestador de scans dirigidos por modulo. A diferencia de
# repomix-scan.ps1 -Target all (que empaqueta TODO Codigo/ en un solo
# snapshot), este script lee IA_Memoria/modulos.json - el manifest que la
# IA genera/actualiza como parte del PASO 3 de un scan completo - y corre
# un scan independiente por cada modulo, con el preset de ignore correcto
# segun su stack. Al final imprime un solo prompt consolidado que le dice
# a la IA exactamente que snapshots leer y como actualizar la memoria.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $RootDir "repomix-lib.ps1")

$Context = New-RepomixContext -RootDir $RootDir -Full:$Full -NoCompress:$NoCompress
$ManifestPath = Join-Path $RootDir "IA_Memoria\modulos.json"

if (-not (Test-Path $Context.CodigoDir)) {
    Write-Warn "No se encontro la carpeta Codigo/."
    exit 0
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] npx no encontrado. Instala Node.js para usar repomix." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ManifestPath)) {
    Write-Warn "No existe IA_Memoria/modulos.json todavia."
    Write-Warn "Corre primero un scan completo para que la IA lo genere:"
    Write-Host "    .\repomix-scan.ps1 -Target all" -ForegroundColor Yellow
    exit 0
}

$manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$allModules = @($manifest.modules)

if ($allModules.Count -eq 0) {
    Write-Warn "IA_Memoria/modulos.json no tiene modulos declarados."
    exit 0
}

$selected = $allModules
if ($Modules.Count -gt 0) {
    $selected = $allModules | Where-Object { $Modules -contains $_.name }
    $missing = $Modules | Where-Object { $_ -notin ($allModules | ForEach-Object { $_.name }) }
    foreach ($m in $missing) {
        Write-Warn "Modulo '$m' no existe en modulos.json - se omite."
    }
}

if (@($selected).Count -eq 0) {
    Write-Warn "Ningun modulo seleccionado para escanear."
    exit 0
}

New-Item -ItemType Directory -Force -Path $Context.SnapshotsDir | Out-Null

$results = @()
foreach ($mod in $selected) {
    $sourcePath = Join-Path $Context.CodigoDir $mod.path
    if (-not (Test-Path $sourcePath)) {
        Write-Warn "Modulo '$($mod.name)': no existe Codigo/$($mod.path)/ - se omite (modulos.json desactualizado?)."
        continue
    }

    $ignorePatterns = Get-StackIgnorePatterns $mod.stack
    $safeName = Get-SnapshotSafeName $mod.path
    $out = Join-Path $Context.SnapshotsDir "snapshot-$safeName.md"
    $snapshotRelPath = "IA_Memoria/snapshots/snapshot-$safeName.md"

    $scanResult = Invoke-RepomixScan -Context $Context -SourcePath $mod.path -OutputPath $out -Label $mod.name -IgnorePatterns $ignorePatterns

    $results += [pscustomobject]@{
        Name          = $mod.name
        Path          = $mod.path
        Stack         = $mod.stack
        SnapshotPath  = $snapshotRelPath
        SizeBytes     = $scanResult.SizeBytes
    }
}

if ($results.Count -eq 0) {
    Write-Warn "Ningun modulo pudo escanearse."
    exit 0
}

# Guia de lectura especifica por stack (PASO 2), solo se incluyen los
# stacks realmente presentes en esta corrida.
$stackHints = @{
    "dotnet"         = "  - *.csproj / *.sln / appsettings*.json -> tecnologias, versiones, puertos y variables`n  - Controllers, Program.cs, middleware -> formato de response, manejo de errores`n  - Migraciones EF Core -> tipo de IDs, soft delete"
    "nestjs"         = "  - package.json -> tecnologias y versiones`n  - *.module.ts, *.controller.ts, guards/interceptors -> formato de response, manejo de errores`n  - Migraciones TypeORM/Prisma -> tipo de IDs, soft delete"
    "angular"        = "  - package.json, angular.json -> version de Angular y librerias`n  - Componentes, servicios, guards -> patron de estado y llamadas a API"
    "react"          = "  - package.json -> version de React y librerias`n  - Componentes, hooks, llamadas a API -> patron de estado y manejo de errores"
    "python-fastapi" = "  - requirements.txt / pyproject.toml -> version de FastAPI y dependencias`n  - routers, Dockerfile, docker-compose.yml -> endpoints, puertos y deploy"
}

$distinctStacks = $results | Select-Object -ExpandProperty Stack -Unique
$hintsBlock = ($distinctStacks | ForEach-Object {
    if ($stackHints.ContainsKey($_)) { "[$_]`n$($stackHints[$_])" } else { $null }
}) -join "`n`n"

$moduleTable = ($results | ForEach-Object { "  - $($_.Name) ($($_.Stack)) -> $($_.SnapshotPath)" }) -join "`n"
$moduleNames = ($results | ForEach-Object { $_.Name }) -join ", "

$prompt = @"
Se escanearon $($results.Count) modulo(s) de forma dirigida (no el proyecto completo):

$moduleTable

PASO 1 - Para cada snapshot de la lista: leer primero el arbol de archivos y el
  resumen de tokens al inicio (las primeras ~200-300 lineas). No leas mas hasta
  completar este paso para todos los snapshots.

PASO 2 - Leer selectivamente por snapshot, segun su stack:

$hintsBlock

  Si un snapshot supera 400 lineas: NO leerlo completo de corrido.
  Saltar directamente a los bloques de cada archivo usando su arbol del PASO 1.

PASO 3 - Actualizar memoria SOLO para los modulos escaneados ($moduleNames):
  - IA_Memoria/arquitectura.md: actualiza unicamente las secciones de estos modulos
    (ruta, tecnologia, estado). No toques ni asumas el estado de otros modulos.
  - IA_Memoria/progreso.md: marca [x] los features de estos modulos que ya existan en el codigo.
  - IA_Memoria/convenciones.md: si algun modulo revela un patron nuevo o inconsistente con lo
    ya documentado, agregalo o senala la inconsistencia - no lo generalices sin evidencia.
  - IA_Memoria/deuda-tecnica.md: registra antipatrones reales encontrados en estos modulos.
  - IA_Memoria/modulos.json: si alguno de estos modulos cambio de ruta o stack, actualiza SOLO
    esa entrada - no regeneres el archivo completo a partir de un scan parcial.

Al terminar, reporta: que encontraste en cada modulo escaneado y si hay
inconsistencias con lo que ya estaba declarado en los archivos de memoria.
"@

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PROMPT DE INSPECCION - copiar y pegar en tu agente IA" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host $prompt -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
