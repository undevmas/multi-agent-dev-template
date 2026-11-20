# Validador local y simulador de escenarios para el workflow operativo de Antigravity (Template Multiagente)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " VALIDACION OPERATIVA DEL WORKFLOW DE ANTIGRAVITY (TEMPLATE)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Record-TestResult {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Passed,
        [string]$Evidence
    )
    $obj = [PSCustomObject]@{
        Category = $Category
        TestName = $TestName
        Passed   = $Passed
        Evidence = $Evidence
    }
    $script:results.Add($obj)
    $statusColor = if ($Passed) { 'Green' } else { 'Red' }
    $statusText  = if ($Passed) { '[PASS]' } else { '[FAIL]' }
    $catPad = $Category.PadRight(12)
    Write-Host "$statusText | $catPad | $TestName" -ForegroundColor $statusColor
    if (-not $Passed) {
        Write-Host "         Detalle: $Evidence" -ForegroundColor Yellow
    }
}

Write-Host "`n--- Ejecutando 6.1: Validaciones Estaticas ---" -ForegroundColor Yellow

$requiredFiles = @(
    'CLAUDE.md',
    'AGENTS.md',
    '.gemini/GEMINI.md',
    'GUIDE.md',
    '.cursor/rules/project.mdc',
    '.github/copilot-instructions.md',
    'IA_Skill/SKILL-instruction-router.md',
    'IA_Skill/SKILL-autonomy-policy.md',
    'IA_Skill/SKILL-stack-policy.md',
    'IA_Skill/README.md',
    'IA_Skill/web-official/README.md',
    'IA_Skill/web-official/modern-web-guidance/SKILL.md',
    'IA_Skill/SKILL-implementation.md',
    'IA_Skill/SKILL-risk-zone-policy.md',
    'IA_Skill/SKILL-spec-generator.md'
)

$missingFiles = @()
foreach ($rf in $requiredFiles) {
    $p = Join-Path $workspaceRoot $rf
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        $missingFiles += $rf
    }
}
Record-TestResult "Estatica" "Existencia de archivos base y router" ($missingFiles.Count -eq 0) ("Archivos faltantes: " + ($missingFiles -join ', '))

$expectedMarker = 'AUTONOMY_POLICY_VERSION: 1'
$policyFiles = @(
    'CLAUDE.md',
    'AGENTS.md',
    '.gemini/GEMINI.md',
    '.github/copilot-instructions.md',
    '.cursor/rules/project.mdc',
    'IA_Skill/SKILL-autonomy-policy.md',
    'IA_Skill/SKILL-implementation.md',
    'IA_Skill/SKILL-risk-zone-policy.md',
    'IA_Skill/SKILL-spec-generator.md'
)

$invalidMarkers = @()
foreach ($pf in $policyFiles) {
    $p = Join-Path $workspaceRoot $pf
    if (Test-Path -LiteralPath $p -PathType Leaf) {
        $cnt = @(Select-String -LiteralPath $p -SimpleMatch $expectedMarker).Count
        if ($cnt -ne 1) {
            $invalidMarkers += "$pf (conteo: $cnt)"
        }
    }
}
Record-TestResult "Estatica" "Sincronizacion AUTONOMY_POLICY_VERSION: 1" ($invalidMarkers.Count -eq 0) ("Desincronizados: " + ($invalidMarkers -join ', '))

$bridgeFiles = @('CLAUDE.md', 'AGENTS.md', '.gemini/GEMINI.md', '.github/copilot-instructions.md', '.cursor/rules/project.mdc')
$duplications = @()
foreach ($bf in $bridgeFiles) {
    $p = Join-Path $workspaceRoot $bf
    $text = Get-Content -LiteralPath $p -Raw -Encoding UTF8
    if ($text -match '(?m)^### 1\. Investigar antes de preguntar$') {
        $duplications += $bf
    }
}
Record-TestResult "Estatica" "Fuente canonica unica (sin duplicacion en bridges)" ($duplications.Count -eq 0) ("Duplican politica: " + ($duplications -join ', '))

$routerMentionFiles = @('CLAUDE.md', 'AGENTS.md', '.gemini/GEMINI.md', 'GUIDE.md', '.cursor/rules/project.mdc', '.github/copilot-instructions.md')
$missingRouterRef = @()
foreach ($rmf in $routerMentionFiles) {
    $p = Join-Path $workspaceRoot $rmf
    $text = Get-Content -LiteralPath $p -Raw -Encoding UTF8
    if ($text -notmatch 'SKILL-instruction-router\.md') {
        $missingRouterRef += $rmf
    }
}
Record-TestResult "Estatica" "Referencias activas a SKILL-instruction-router.md" ($missingRouterRef.Count -eq 0) ("Sin referencia al router: " + ($missingRouterRef -join ', '))

$forbiddenRules = @(
    'Si la spec no lo dice, no existe',
    'No modificar el contrato durante',
    'todas las features listadas deben estar en estado `done`',
    'alguien ya est. trabajando esto, confirmar con el dev',
    'nunca requiere ticket, se hace de inmediato',
    'resolverlas con defaults razonables',
    'sin una spec aprobada y evidencia expl.cita'
)

$forbiddenFound = @()
foreach ($fr in $forbiddenRules) {
    foreach ($pf in $policyFiles) {
        $p = Join-Path $workspaceRoot $pf
        # Patron regex ASCII + lectura UTF-8: evita falsos negativos con acentos en PS 5.1
        if (Select-String -LiteralPath $p -Pattern $fr -Encoding UTF8 -Quiet) {
            $forbiddenFound += "$pf contiene '$fr'"
        }
    }
}
Record-TestResult "Estatica" "Ausencia de contradicciones o reglas prohibidas" ($forbiddenFound.Count -eq 0) ("Hallazgos: " + ($forbiddenFound -join '; '))

Write-Host "`n--- Ejecutando 6.2: Pruebas de Ruteo (9 Escenarios) ---" -ForegroundColor Yellow

$routerPath = Join-Path $workspaceRoot 'IA_Skill/SKILL-instruction-router.md'
$routerContent = Get-Content -LiteralPath $routerPath -Raw -Encoding UTF8

$scenarios = @(
    @{ Id = 'R1'; Desc = 'Implementar SPEC'; ExpectedPrimary = 'SKILL-implementation.md'; ExpectedAux = 'Stack de la capa actual'; ForbiddenLoad = 'SKILL-spec-generator.md'; MustBlock = $false },
    @{ Id = 'R2'; Desc = 'Reanudar SPEC'; ExpectedPrimary = 'SKILL-implementation.md'; ExpectedAux = 'Stack segun capa pendiente'; ForbiddenLoad = 'snapshots globales'; MustBlock = $false },
    @{ Id = 'R3'; Desc = 'Generar SPEC'; ExpectedPrimary = 'SKILL-spec-generator.md'; ExpectedAux = 'Ninguna (solo especificacion)'; ForbiddenLoad = 'Skills de codificacion'; MustBlock = $false },
    @{ Id = 'R4'; Desc = 'Corregir bug localizado'; ExpectedPrimary = 'Skill del stack'; ExpectedAux = 'Testing del stack'; ForbiddenLoad = 'progreso.md'; MustBlock = $false },
    @{ Id = 'R5'; Desc = 'Modificar contrato interno'; ExpectedPrimary = 'SKILL-implementation.md'; ExpectedAux = 'Tests de contrato del stack'; ForbiddenLoad = 'Skills de UI'; MustBlock = $false },
    @{ Id = 'R6'; Desc = 'Realizar migrac'; ExpectedPrimary = 'SKILL-database-migrations.md'; ExpectedAux = 'SKILL-risk-zone-policy.md'; ForbiddenLoad = 'Skills de frontend'; MustBlock = $true },
    @{ Id = 'R7'; Desc = 'Worker sin UI'; ExpectedPrimary = 'Skill del stack'; ExpectedAux = 'Tests de integracion / contratos'; ForbiddenLoad = 'SKILL-e2e-playwright.md'; MustBlock = $false },
    @{ Id = 'R8'; Desc = 'Cambio frontend visible'; ExpectedPrimary = 'SKILL-e2e-playwright.md'; ExpectedAux = 'Skill de framework UI'; ForbiddenLoad = 'Skills de backend'; MustBlock = $false },
    @{ Id = 'R9'; Desc = 'Dependencia SOFT ausente'; ExpectedPrimary = 'SKILL-implementation.md'; ExpectedAux = 'Degradacion / Fallback seguro'; ForbiddenLoad = 'NEEDS CLARIFICATION'; MustBlock = $false }
)

foreach ($sc in $scenarios) {
    $matchPrimary = $routerContent.Contains($sc.ExpectedPrimary)
    $matchDoc = $routerContent.Contains($sc.Desc)
    $passed = $matchPrimary -and $matchDoc
    $evidence = "Primaria: $($sc.ExpectedPrimary) | Prohibido: $($sc.ForbiddenLoad) | Bloquea: $($sc.MustBlock)"
    Record-TestResult "Ruteo" "$($sc.Id): $($sc.Desc)" $passed $evidence
}

Write-Host "`n--- Ejecutando 6.3: Pruebas de Decision (Casos A - G) ---" -ForegroundColor Yellow

$decisionCases = @(
    @{ Case = 'Caso A - T1'; Classification = 'T1'; Behavior = 'Decidir autonomamente sin preguntar'; Blocks = $false; Keyword = 'T1 .* Decisi.n t.cnica reversible' },
    @{ Case = 'Caso B - T2'; Classification = 'T2'; Behavior = 'Evolucion aditiva compatible y contract tests'; Blocks = $false; Keyword = 'T2 .* Decisi.n arquitect.nica acotada' },
    @{ Case = 'Caso C - B1'; Classification = 'B1'; Behavior = 'Configuracion nullable, regla deshabilitada y estado explicito'; Blocks = $false; Keyword = 'B1 .* Regla de negocio faltante pero aislable' },
    @{ Case = 'Caso D - B2 aislable'; Classification = 'B2'; Behavior = 'Contrato provisional y PENDING_CONFIGURATION'; Blocks = $false; Keyword = 'B2 .* Decisi.n de negocio material no aislable' },
    @{ Case = 'Caso E - S1'; Classification = 'S1'; Behavior = 'Detencion obligatoria y confirmacion previa'; Blocks = $true; Keyword = 'S1 .* Seguridad, datos o acci.n irreversible' },
    @{ Case = 'Caso F - X1'; Classification = 'X1'; Behavior = 'Completar mocks y trabajo independiente; reportar bloqueo externo'; Blocks = $true; Keyword = 'X1 .* Bloqueo externo real' },
    @{ Case = 'Caso G - Presupuesto'; Classification = 'Tokens'; Behavior = '1 primaria, auxiliares bajo demanda, validacion antes de 75%'; Blocks = $false; Keyword = '14 Reglas de Eficiencia de Tokens' }
)

foreach ($dc in $decisionCases) {
    $hasKeyword = $routerContent -match $dc.Keyword
    $hasClasif = $routerContent.Contains($dc.Classification)
    $passed = $hasKeyword -and $hasClasif
    $ev = "Clasificacion: $($dc.Classification) | Conducta: $($dc.Behavior) | Bloquea: $($dc.Blocks)"
    Record-TestResult "Decision" $dc.Case $passed $ev
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host " RESUMEN DE EJECUCION DE PRUEBAS" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$total = $results.Count
$passedCount = @($results | Where-Object { $_.Passed }).Count
$failedCount = $total - $passedCount

Write-Host "Total pruebas ejecutadas: $total"
Write-Host "Aprobadas:                $passedCount" -ForegroundColor Green
Write-Host "Fallidas:                 $failedCount" -ForegroundColor $(if ($failedCount -eq 0) { 'Green' } else { 'Red' })

if ($failedCount -gt 0) {
    throw "Fallaron $failedCount pruebas de validacion operativa."
} else {
    Write-Host "`nTodas las validaciones estaticas, de ruteo y de decision resultaron SATISFACTORIAS." -ForegroundColor Green
}

