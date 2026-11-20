# Verificacion de integridad de las instrucciones del workspace.
# AGENTS.md es la fuente unica; CLAUDE.md y .gemini/GEMINI.md la importan (@);
# copilot-instructions.md y .cursor/rules/project.mdc son punteros cortos.
# Literales en ASCII a proposito (Windows PowerShell 5.1 + archivos UTF-8 sin BOM).
$ErrorActionPreference = 'Stop'

$expectedMarker = 'AUTONOMY_POLICY_VERSION: 1'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$autonomyPolicy = 'IA_Skill/SKILL-autonomy-policy.md'
$instructionFiles = @('AGENTS.md', 'CLAUDE.md', '.gemini/GEMINI.md', '.github/copilot-instructions.md', '.cursor/rules/project.mdc')
$policyFiles = $instructionFiles + @(
    $autonomyPolicy,
    'IA_Skill/SKILL-implementation.md',
    'IA_Skill/SKILL-risk-zone-policy.md',
    'IA_Skill/SKILL-spec-generator.md',
    'IA_Skill/SKILL-execution-principles.md'
)

function Get-WorkspacePath([string]$relative) { Join-Path $workspaceRoot $relative }

# --- 1. Marcador de version de la politica: exactamente una vez por archivo ---
$invalidMarker = foreach ($policyFile in $policyFiles) {
    $policyPath = Get-WorkspacePath $policyFile
    if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) {
        "$policyFile (missing file)"
        continue
    }
    $markerCount = @(Select-String -LiteralPath $policyPath -SimpleMatch $expectedMarker).Count
    if ($markerCount -ne 1) {
        "$policyFile (marker count: $markerCount)"
    }
}
if ($invalidMarker) {
    throw "Instruction autonomy policy is out of sync: $($invalidMarker -join ', ')"
}

# --- 2. Politica canonica en su skill y sin duplicados en las instrucciones ---
$canonicalText = Get-Content -LiteralPath (Get-WorkspacePath $autonomyPolicy) -Raw -Encoding UTF8
if ($canonicalText -notmatch '(?m)^## Pol.tica de autonom.a y ambig.edades\r?$' -or
    $canonicalText -notmatch 'La falta de una regla de negocio puede impedir activar esa regla') {
    throw "$autonomyPolicy does not contain the canonical autonomy policy."
}
foreach ($instructionFile in $instructionFiles) {
    $instructionText = Get-Content -LiteralPath (Get-WorkspacePath $instructionFile) -Raw -Encoding UTF8
    if ($instructionText -match '(?m)^### 1\. Investigar antes de preguntar\r?$') {
        throw "Instruction file duplicates the canonical policy: $instructionFile"
    }
}

$requiredRules = @(
    @($autonomyPolicy, 'operativa sobre credenciales o'),
    @($autonomyPolicy, 'Retomar en: SPEC-[propietaria]'),
    @('IA_Skill/SKILL-implementation.md', 'Gap T1/T2 propiedad de la Spec actual'),
    @('IA_Skill/SKILL-risk-zone-policy.md', 'Revocarla o rotarla en un proveedor externo es `S1`'),
    @('IA_Skill/SKILL-spec-generator.md', 'Nunca aplicar defaults a B2/S1/X1'),
    @('IA_Skill/SKILL-spec-generator.md', 'Spec propietaria')
)
foreach ($requiredRule in $requiredRules) {
    if (-not (Select-String -LiteralPath (Get-WorkspacePath $requiredRule[0]) -SimpleMatch $requiredRule[1] -Quiet)) {
        throw "Required autonomy or safety rule is missing: $($requiredRule[0])"
    }
}

$forbiddenRules = @(
    'Si la spec no lo dice, no existe',
    'No modificar el contrato durante',
    'todas las features listadas deben estar en estado `done`',
    'alguien ya est. trabajando esto, confirmar con el dev',
    'nunca requiere ticket, se hace de inmediato',
    'resolverlas con defaults razonables',
    'sin una spec aprobada y evidencia expl.cita'
)
foreach ($forbiddenRule in $forbiddenRules) {
    foreach ($policyFile in $policyFiles) {
        # Patron regex ASCII ('.' en lugar de vocales con acento) + lectura UTF-8: evita falsos negativos en PS 5.1
        if (Select-String -LiteralPath (Get-WorkspacePath $policyFile) -Pattern $forbiddenRule -Encoding UTF8 -Quiet) {
            throw "Critical contradiction found in ${policyFile}: $forbiddenRule"
        }
    }
}

# --- 3. Fuente unica: imports y candado de comprobacion ("Claro team") ---
if (@(Select-String -LiteralPath (Get-WorkspacePath 'AGENTS.md') -Pattern '^## Candado de comprobaci').Count -ne 1 -or
    -not (Select-String -LiteralPath (Get-WorkspacePath 'AGENTS.md') -SimpleMatch '`Claro team`' -Quiet)) {
    throw "Canary 'Claro team' missing or duplicated in AGENTS.md"
}
if (@(Select-String -LiteralPath (Get-WorkspacePath 'AGENTS.md') -Pattern '^## Principios de ejecuci').Count -ne 1) {
    throw 'AGENTS.md must contain exactly one "Principios de ejecucion" section (always-on execution principles).'
}
$importChecks = @(
    @('CLAUDE.md', '^@AGENTS\.md\s*$'),
    @('.gemini/GEMINI.md', '^@\.\./AGENTS\.md\s*$')
)
foreach ($importCheck in $importChecks) {
    if (-not (Select-String -LiteralPath (Get-WorkspacePath $importCheck[0]) -Pattern $importCheck[1] -Quiet)) {
        throw "$($importCheck[0]) must import AGENTS.md (pattern $($importCheck[1]))"
    }
}
foreach ($pointerFile in @('.github/copilot-instructions.md', '.cursor/rules/project.mdc')) {
    if (-not (Select-String -LiteralPath (Get-WorkspacePath $pointerFile) -SimpleMatch '`Claro team`' -Quiet)) {
        throw "Canary 'Claro team' missing in $pointerFile"
    }
}

# --- 4. Presupuesto de lineas (estandar AGENTS.md: archivo raiz corto, punteros minimos) ---
$lineBudget = @{ 'AGENTS.md' = 150; 'CLAUDE.md' = 30; '.gemini/GEMINI.md' = 30; '.github/copilot-instructions.md' = 40; '.cursor/rules/project.mdc' = 40 }
foreach ($budgetFile in $lineBudget.Keys) {
    $lineCount = @(Get-Content -LiteralPath (Get-WorkspacePath $budgetFile)).Count
    if ($lineCount -gt $lineBudget[$budgetFile]) {
        throw "$budgetFile has $lineCount lines (budget: $($lineBudget[$budgetFile])). Move detail to IA_Skill/ instead of growing it."
    }
}

# --- 5. Marcadores de conflicto de merge ---
$referenceFiles = @('IA_Skill/README.md', 'IA_Skill/SKILL-instruction-router.md', 'IA_Skill/SKILL-stack-policy.md', 'IA_Skill/SKILL-execution-principles.md')
$markerFiles = $policyFiles + $referenceFiles | Select-Object -Unique
$missingReferences = @($referenceFiles | Where-Object { -not (Test-Path -LiteralPath (Get-WorkspacePath $_) -PathType Leaf) })
if ($missingReferences.Count -gt 0) {
    throw "Missing reference files cited by AGENTS.md: $($missingReferences -join ', ')"
}
foreach ($markerFile in $markerFiles) {
    if (Select-String -LiteralPath (Get-WorkspacePath $markerFile) -Pattern '^(<<<<<<<|>>>>>>>)( |$)' -Quiet) {
        throw "Merge conflict markers found in $markerFile"
    }
}

# --- 6. Rutas de skills citadas (rutas rotas) ---
$skillNames = @{}
Get-ChildItem -LiteralPath (Get-WorkspacePath 'IA_Skill') -Recurse -File -Filter 'SKILL*.md' |
    ForEach-Object { $skillNames[$_.Name] = $true }
$routeFiles = $instructionFiles + $referenceFiles + @($autonomyPolicy) | Select-Object -Unique
$brokenRoutes = foreach ($routeFile in $routeFiles) {
    $text = Get-Content -LiteralPath (Get-WorkspacePath $routeFile) -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($text, 'IA_Skill/[A-Za-z0-9_./-]+\.md')) {
        if (-not (Test-Path -LiteralPath (Get-WorkspacePath $match.Value) -PathType Leaf)) { "${routeFile}: $($match.Value)" }
    }
    foreach ($match in [regex]::Matches($text, 'SKILL-[a-z0-9-]+\.md')) {
        if (-not $skillNames.ContainsKey($match.Value)) { "${routeFile}: $($match.Value)" }
    }
    foreach ($match in [regex]::Matches($text, '`(?:dotnet-official/)?(dotnet[a-z0-9-]*/[a-z0-9-]+/SKILL\.md)`')) {
        if (-not (Test-Path -LiteralPath (Get-WorkspacePath ('IA_Skill/dotnet-official/' + $match.Groups[1].Value)) -PathType Leaf)) {
            "${routeFile}: dotnet-official/$($match.Groups[1].Value)"
        }
    }
}
if ($brokenRoutes) {
    throw "Broken skill routes: $(@($brokenRoutes | Select-Object -Unique) -join ', ')"
}

Write-Output 'Single source (AGENTS.md), imports, canary, line budget, merge markers and skill routes are OK.'
Write-Output 'Instruction autonomy policy is synchronized.'
