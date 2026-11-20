<#
.SYNOPSIS
  Sincroniza las skills oficiales de Microsoft (github.com/dotnet/skills) listadas en
  skills.manifest hacia esta carpeta.

.DESCRIPTION
  Reemplaza las carpetas dotnet*\ por la versión actual del repo. No toca README.md,
  skills.manifest ni los scripts. Valida todo el manifest antes de borrar nada.

.PARAMETER Source
  Ruta a un clon existente de dotnet/skills (sin red). Si se omite, clona solo plugins/
  en una carpeta temporal.

.EXAMPLE
  .\sync-dotnet-skills.ps1
  .\sync-dotnet-skills.ps1 -Source C:\temp\dotnet-skills
#>
param([string]$Source = '')

$ErrorActionPreference = 'Stop'
$Dest = $PSScriptRoot
$Manifest = Join-Path $Dest 'skills.manifest'
$RepoUrl = 'https://github.com/dotnet/skills.git'
$Tmp = $null

try {
    if (-not $Source) {
        $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('dnskills-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        Write-Host "Clonando $RepoUrl (solo plugins/)..."
        git -c core.longpaths=true -c core.hooksPath=NUL clone --quiet --depth 1 --filter=blob:none --sparse $RepoUrl "$Tmp\repo"
        if ($LASTEXITCODE -ne 0) { throw 'git clone falló' }
        git -C "$Tmp\repo" -c core.longpaths=true sparse-checkout set plugins
        if ($LASTEXITCODE -ne 0) { throw 'git sparse-checkout falló' }
        $Source = "$Tmp\repo"
    }

    $plugins = Join-Path $Source 'plugins'
    if (-not (Test-Path $plugins)) { throw "No se encontró $plugins" }

    # Leer manifest (sin comentarios ni líneas vacías)
    $entries = @(Get-Content $Manifest -Encoding UTF8 |
        ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
        Where-Object { $_ })

    # Validar TODO el manifest antes de borrar nada
    $missing = @($entries | Where-Object {
        $parts = $_.Split('/')
        -not (Test-Path (Join-Path $plugins "$($parts[0])\skills\$($parts[1])"))
    })
    if ($missing.Count -gt 0) {
        throw "Skills del manifest que ya no existen en el repo: $($missing -join ', '). Corregir skills.manifest. No se modificó nada."
    }

    # Reemplazar solo las carpetas de plugins (dotnet*\)
    Get-ChildItem -Path $Dest -Directory -Filter 'dotnet*' | Remove-Item -Recurse -Force

    foreach ($entry in $entries) {
        $plugin, $skill = $entry.Split('/')
        $target = Join-Path $Dest $plugin
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Copy-Item -Recurse -Path (Join-Path $plugins "$plugin\skills\$skill") -Destination $target
    }

    Copy-Item -Path (Join-Path $Source 'LICENSE') -Destination (Join-Path $Dest 'LICENSE') -Force

    $sha = git -C $Source rev-parse HEAD
    $commitDate = git -C $Source log -1 --format=%cI
    @(
        'repo: https://github.com/dotnet/skills'
        "commit: $sha"
        "fecha_commit: $commitDate"
        "sincronizado: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "skills: $($entries.Count)"
    ) | Out-File -FilePath (Join-Path $Dest 'SOURCE.txt') -Encoding utf8

    Write-Host "OK: $($entries.Count) skills sincronizadas en $Dest"
    Get-Content (Join-Path $Dest 'SOURCE.txt')
    Write-Host 'Revisar el diff (git diff IA_Skill/dotnet-official) antes de commitear: es contenido de terceros.'
}
finally {
    if ($Tmp -and (Test-Path $Tmp)) { Remove-Item -Path $Tmp -Recurse -Force }
}
