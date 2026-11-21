<#
.SYNOPSIS
  Sincroniza la skill archify (github.com/tt-a1i/archify) hacia IA_Skill/archify-official/archify.

.DESCRIPTION
  Copia la carpeta archify/ del repo sin los HTML de ejemplo ya renderizados (~12 MB que el motor
  no usa) y las licencias. No toca README.md ni los scripts de esta carpeta.

.PARAMETER Source
  Ruta a un clon existente de tt-a1i/archify (sin red). Si se omite, clona solo archify/ en una
  carpeta temporal.
#>
param([string]$Source = '')

$ErrorActionPreference = 'Stop'
$Dest = $PSScriptRoot
$RepoUrl = 'https://github.com/tt-a1i/archify.git'
$Tmp = $null

try {
    if (-not $Source) {
        $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('archify-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        Write-Host "Clonando $RepoUrl (solo archify/)..."
        git -c core.longpaths=true -c core.hooksPath=NUL clone --quiet --depth 1 --filter=blob:none --sparse $RepoUrl "$Tmp\repo"
        if ($LASTEXITCODE -ne 0) { throw 'git clone fallo' }
        git -C "$Tmp\repo" -c core.longpaths=true sparse-checkout set archify
        if ($LASTEXITCODE -ne 0) { throw 'git sparse-checkout fallo' }
        $Source = "$Tmp\repo"
    }

    if (-not (Test-Path (Join-Path $Source 'archify\SKILL.md')) -or -not (Test-Path (Join-Path $Source 'archify\bin\archify.mjs'))) {
        throw "$Source no contiene archify\SKILL.md y archify\bin\archify.mjs. No se modifico nada."
    }

    $target = Join-Path $Dest 'archify'
    if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
    Copy-Item -Recurse -Path (Join-Path $Source 'archify') -Destination $target
    Get-ChildItem -Path (Join-Path $target 'examples') -Filter '*.html' -File | Remove-Item -Force
    foreach ($f in 'LICENSE', 'LICENSE-MIT', 'NOTICE') { Copy-Item -Path (Join-Path $Source $f) -Destination (Join-Path $Dest $f) -Force }

    $sha = git -C $Source rev-parse HEAD
    $commitDate = git -C $Source log -1 --format=%cI
    $version = (Get-Content (Join-Path $target 'package.json') -Raw | ConvertFrom-Json).version
    @(
        'repo: https://github.com/tt-a1i/archify'
        "commit: $sha"
        "fecha_commit: $commitDate"
        "version: $version"
        "sincronizado: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        'excluido: archify/examples/*.html (renderizados de ejemplo)'
    ) | Out-File -FilePath (Join-Path $Dest 'SOURCE.txt') -Encoding utf8

    Write-Host "OK: archify sincronizado en $target ($((Get-ChildItem $target -Recurse -File).Count) archivos)"
    Get-Content (Join-Path $Dest 'SOURCE.txt')
    Write-Host 'Verificar: node Tools/entregables/archify.mjs doctor - revisar el diff: es contenido de terceros.'
}
finally {
    if ($Tmp -and (Test-Path $Tmp)) { Remove-Item -Path $Tmp -Recurse -Force }
}
