$ErrorActionPreference = 'Stop'

$expectedMarker = 'AUTONOMY_POLICY_VERSION: 1'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$policyFiles = @(
    'CLAUDE.md',
    'AGENTS.md',
    '.gemini/GEMINI.md',
    '.github/copilot-instructions.md',
    '.cursor/rules/project.mdc',
    'IA_Skill/SKILL-implementation.md',
    'IA_Skill/SKILL-risk-zone-policy.md',
    'IA_Skill/SKILL-spec-generator.md'
)

$invalidMarker = foreach ($instructionFile in $policyFiles) {
    $instructionPath = Join-Path $workspaceRoot $instructionFile
    if (-not (Test-Path -LiteralPath $instructionPath -PathType Leaf)) {
        "$instructionFile (missing file)"
        continue
    }

    $markerCount = @(Select-String -LiteralPath $instructionPath -SimpleMatch $expectedMarker).Count
    if ($markerCount -ne 1) {
        "$instructionFile (marker count: $markerCount)"
    }
}

if ($invalidMarker) {
    throw "Instruction autonomy policy is out of sync: $($invalidMarker -join ', ')"
}

$canonicalPath = Join-Path $workspaceRoot 'CLAUDE.md'
$canonicalText = Get-Content -LiteralPath $canonicalPath -Raw
if ($canonicalText -notmatch '(?m)^## Política de autonomía y ambigüedades$' -or
    $canonicalText -notmatch 'La falta de una regla de negocio puede impedir activar esa regla') {
    throw 'CLAUDE.md does not contain the canonical autonomy policy.'
}

$bridgeFiles = @('AGENTS.md', '.gemini/GEMINI.md', '.github/copilot-instructions.md', '.cursor/rules/project.mdc')
foreach ($bridgeFile in $bridgeFiles) {
    $bridgePath = Join-Path $workspaceRoot $bridgeFile
    $bridgeText = Get-Content -LiteralPath $bridgePath -Raw
    if ($bridgeText -match '(?m)^### 1\. Investigar antes de preguntar$') {
        throw "Bridge duplicates the canonical policy: $bridgeFile"
    }
}

$requiredRules = @(
    @('CLAUDE.md', 'operativa sobre credenciales o'),
    @('CLAUDE.md', 'Retomar en: SPEC-[propietaria]'),
    @('IA_Skill/SKILL-implementation.md', 'Gap T1/T2 propiedad de la Spec actual'),
    @('IA_Skill/SKILL-risk-zone-policy.md', 'Revocarla o rotarla en un proveedor externo es `S1`'),
    @('IA_Skill/SKILL-spec-generator.md', 'Nunca aplicar defaults a B2/S1/X1'),
    @('IA_Skill/SKILL-spec-generator.md', 'Spec propietaria')
)

foreach ($requiredRule in $requiredRules) {
    $requiredPath = Join-Path $workspaceRoot $requiredRule[0]
    if (-not (Select-String -LiteralPath $requiredPath -SimpleMatch $requiredRule[1] -Quiet)) {
        throw "Required autonomy or safety rule is missing: $($requiredRule[0])"
    }
}

$forbiddenRules = @(
    'Si la spec no lo dice, no existe',
    'No modificar el contrato durante',
    'todas las features listadas deben estar en estado `done`',
    'alguien ya está trabajando esto, confirmar con el dev',
    'nunca requiere ticket, se hace de inmediato',
    'resolverlas con defaults razonables',
    'sin una spec aprobada y evidencia explícita'
)

foreach ($forbiddenRule in $forbiddenRules) {
    foreach ($policyFile in $policyFiles) {
        $policyPath = Join-Path $workspaceRoot $policyFile
        if (Select-String -LiteralPath $policyPath -SimpleMatch $forbiddenRule -Quiet) {
            throw "Critical contradiction found in ${policyFile}: $forbiddenRule"
        }
    }
}

Write-Output 'Instruction autonomy policy is synchronized.'

