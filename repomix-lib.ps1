# repomix-lib.ps1 - funciones compartidas entre repomix-scan.ps1 y
# repomix-scan-modules.ps1. Este archivo NO ejecuta nada por si solo:
# solo define funciones. Se carga con dot-sourcing:
#   . "$PSScriptRoot\repomix-lib.ps1"
#
# Se centraliza aca la logica de scan/ignore/naming para evitar que los
# scripts que la consumen (el scan individual y el orquestador por modulos)
# diverjan entre si con el tiempo - ya paso una vez entre la version .ps1
# y .sh de repomix-scan.

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Ok([string]$Message) {
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

# Presets de ignore por stack tecnologico - cubren la tabla de stacks
# aprobados en CLAUDE.md (.NET, NestJS, Angular, React, Python FastAPI).
# Independientes del nombre de carpeta: aplican a cualquier proyecto que
# use el template, no solo a la instancia actual.
$script:StackIgnorePresets = @{
    "dotnet"         = "**/bin/**,**/obj/**,**/*.user,**/.vs/**,**/TestResults/**"
    "nestjs"         = "**/node_modules/**,**/dist/**,**/build/**,**/coverage/**"
    "angular"        = "**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**"
    "react"          = "**/node_modules/**,**/dist/**,**/build/**,**/coverage/**"
    "python-fastapi" = "**/__pycache__/**,**/.venv/**,**/venv/**,**/*.egg-info/**,**/.pytest_cache/**"
}

# Ignore generico usado cuando no se conoce el stack de un target arbitrario
# (cubre los casos mas comunes de todos los presets combinados).
$script:GenericIgnorePattern = "**/bin/**,**/obj/**,**/*.user,**/.vs/**,**/TestResults/**,**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**,**/__pycache__/**,**/.venv/**"

function Get-StackIgnorePatterns([string]$Stack) {
    if ($Stack -and $script:StackIgnorePresets.ContainsKey($Stack)) {
        return $script:StackIgnorePresets[$Stack]
    }
    return $script:GenericIgnorePattern
}

function Get-SnapshotSafeName([string]$Target) {
    return (($Target -replace '[\\/]', '-') -replace '[^a-zA-Z0-9_-]', '-')
}

# Arma el contexto compartido (rutas, config, timestamp) que necesita
# Invoke-RepomixScan. $RootDir es la raiz del workspace (donde vive este
# archivo y Codigo/).
function New-RepomixContext {
    param(
        [Parameter(Mandatory = $true)][string]$RootDir,
        [switch]$Full,
        [switch]$NoCompress
    )

    $codigoDir = Join-Path $RootDir "Codigo"
    $compressEnabled = -not $NoCompress
    if ($Full) { $compressEnabled = $false }

    return [pscustomobject]@{
        RootDir         = $RootDir
        CodigoDir       = $codigoDir
        SnapshotsDir    = Join-Path $RootDir "IA_Memoria\snapshots"
        ConfigPath      = Join-Path $codigoDir "repomix.config.json"
        CompressEnabled = $compressEnabled
        Style           = "markdown"
        Timestamp       = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
        RepomixArgsBase = @("repomix@latest")
    }
}

# Corre un scan de repomix para un SourcePath (relativo a Codigo/) y escribe
# el snapshot + su .meta.json. Requiere el $Context devuelto por
# New-RepomixContext.
function Invoke-RepomixScan {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$IgnorePatterns = ""
    )

    $npxArgs = @($Context.RepomixArgsBase) + @($SourcePath, "--output", $OutputPath)
    $tempConfigPath = $null

    if (Test-Path $Context.ConfigPath) {
        # Heredar style, ignore patterns y security-check del config.
        # NOTA: Repomix no tiene un flag CLI --no-compress (verificado contra
        # cliRun.ts del repo oficial) - --compress es opt-in y no es negable.
        # Si se pide --Full/--NoCompress y el config trae compress:true, se
        # genera un config temporal con compress:false en vez de un flag
        # que no existe.
        if (-not $Context.CompressEnabled) {
            $tempConfigPath = Join-Path ([System.IO.Path]::GetTempPath()) "repomix-config-$([guid]::NewGuid().ToString('N')).json"
            $cfg = Get-Content $Context.ConfigPath -Raw | ConvertFrom-Json
            if (-not $cfg.output) { $cfg | Add-Member -MemberType NoteProperty -Name output -Value ([pscustomobject]@{}) }
            $cfg.output.compress = $false
            $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $tempConfigPath -Encoding UTF8
            $npxArgs += @("--config", $tempConfigPath)
        }
        else {
            $npxArgs += @("--config", $Context.ConfigPath)
        }
    }
    else {
        $npxArgs += @("--style", $Context.Style)
        if ($Context.CompressEnabled) { $npxArgs += "--compress" }
    }

    if ($IgnorePatterns -ne "") {
        $npxArgs += @("--ignore", $IgnorePatterns)
    }

    Write-Info "Escaneando $Label ..."

    Push-Location $Context.CodigoDir
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
        label       = $Label
        generatedAt = $Context.Timestamp
        source      = $SourcePath
        output      = $OutputPath
        compress    = $Context.CompressEnabled
        sizeBytes   = $file.Length
    }

    $metaPath = [System.IO.Path]::ChangeExtension($OutputPath, ".meta.json")
    $meta | ConvertTo-Json -Depth 5 | Set-Content -Path $metaPath -Encoding UTF8

    Write-Ok "Snapshot: $OutputPath"
    Write-Ok "Meta: $metaPath"

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        MetaPath   = $metaPath
        SizeBytes  = $file.Length
        Label      = $Label
    }
}
