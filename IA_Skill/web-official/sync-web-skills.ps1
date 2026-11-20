<#
.SYNOPSIS
  Sincroniza las skills oficiales de la plataforma web (github.com/GoogleChrome/modern-web-guidance)
  listadas en skills.manifest hacia esta carpeta.

.DESCRIPTION
  Reemplaza las carpetas listadas en skills.manifest por la versión actual del repo (solo SKILL.md
  y guides/, omitiendo binarios/CLI ejecutables). No toca README.md, skills.manifest ni los scripts.
  Valida todo el manifest antes de borrar nada.

.PARAMETER Source
  Ruta a un clon existente de GoogleChrome/modern-web-guidance (sin red). Si se omite, clona solo
  skills/ en una carpeta temporal.

.EXAMPLE
  .\sync-web-skills.ps1
  .\sync-web-skills.ps1 -Source C:\temp\modern-web-guidance
#>
param([string]$Source = '')

$ErrorActionPreference = 'Stop'
$Dest = $PSScriptRoot
$Manifest = Join-Path $Dest 'skills.manifest'
$RepoUrl = 'https://github.com/GoogleChrome/modern-web-guidance.git'
$Tmp = $null

try {
    if (-not $Source) {
        $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('webskills-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        Write-Host "Clonando $RepoUrl (solo skills/)..."
        git -c core.longpaths=true -c core.hooksPath=NUL clone --quiet --depth 1 --filter=blob:none --sparse $RepoUrl "$Tmp\repo"
        if ($LASTEXITCODE -ne 0) { throw 'git clone falló' }
        git -C "$Tmp\repo" -c core.longpaths=true sparse-checkout set skills
        if ($LASTEXITCODE -ne 0) { throw 'git sparse-checkout falló' }
        $Source = "$Tmp\repo"
    }

    $skillsRoot = Join-Path $Source 'skills'
    if (-not (Test-Path $skillsRoot)) { throw "No se encontró $skillsRoot" }

    # Leer manifest (sin comentarios ni líneas vacías)
    $entries = @(Get-Content $Manifest -Encoding UTF8 |
        ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
        Where-Object { $_ })

    # Validar TODO el manifest antes de borrar nada
    $missing = @($entries | Where-Object {
        -not (Test-Path (Join-Path $skillsRoot "$_\SKILL.md"))
    })
    if ($missing.Count -gt 0) {
        throw "Skills del manifest que ya no existen en el repo: $($missing -join ', '). Corregir skills.manifest. No se modificó nada."
    }

    $totalGuides = 0
    foreach ($entry in $entries) {
        $target = Join-Path $Dest $entry
        if (Test-Path $target) {
            Remove-Item -Path $target -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $target | Out-Null

        $srcSkill = Join-Path $skillsRoot $entry
        Copy-Item -Path (Join-Path $srcSkill 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force

        foreach ($subDir in @('guides', 'references')) {
            $srcSub = Join-Path $srcSkill $subDir
            if (Test-Path $srcSub) {
                Copy-Item -Recurse -Path $srcSub -Destination (Join-Path $target $subDir) -Force
                $totalGuides += @(Get-ChildItem -Path (Join-Path $target $subDir) -Recurse -File -Filter '*.md').Count
            }
        }
    }

    Copy-Item -Path (Join-Path $Source 'LICENSE') -Destination (Join-Path $Dest 'LICENSE') -Force

    $sha = git -C $Source rev-parse HEAD
    $commitDate = git -C $Source log -1 --format=%cI
    @(
        'repo: https://github.com/GoogleChrome/modern-web-guidance'
        "commit: $sha"
        "fecha_commit: $commitDate"
        "sincronizado: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "skills: $($entries.Count)"
        "guias: $totalGuides"
    ) | Out-File -FilePath (Join-Path $Dest 'SOURCE.txt') -Encoding utf8

    Write-Host "OK: $($entries.Count) skill(s) y $totalGuides guías sincronizadas en $Dest"
    Get-Content (Join-Path $Dest 'SOURCE.txt')
    Write-Host 'Revisar el diff (git diff IA_Skill/web-official) antes de commitear: es contenido de terceros.'
}
finally {
    if ($Tmp -and (Test-Path $Tmp)) { Remove-Item -Path $Tmp -Recurse -Force }
}
