param()

# Tools/setup-tools.ps1 — v1
# Prepara y levanta SonarQube, Trivy y ZAP (Windows).
# No corre el analisis -- solo deja la infraestructura lista y da los
# prompts para validar el flujo (ver Capa 2 de Guia-Validacion-Template.md).

$ErrorActionPreference = "Stop"

# Si Windows bloquea este script con "no esta firmado digitalmente" (Execution
# Policy Restricted por defecto), corre una vez:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# o, sin cambiar nada de forma permanente, solo para esta corrida:
#   powershell -ExecutionPolicy Bypass -File .\setup-tools.ps1

# Fix de encoding -- ver nota en repomix-scan.ps1, mismo motivo (acentos
# se ven mal en Windows PowerShell 5.1 si no se fuerza UTF-8).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Set-Location -Path $PSScriptRoot

function Write-Ok   { param($msg) Write-Host "OK  $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "ERR $msg" -ForegroundColor Red }
function Write-Warn2 { param($msg) Write-Host "!!  $msg" -ForegroundColor Yellow }

Write-Host "=== Paso 1/4 -- Verificando requisitos ==="

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Fail "Docker no esta instalado o no esta en el PATH."
    Write-Host "   Instalalo desde https://docs.docker.com/get-docker/ y vuelve a correr este script."
    exit 1
}
Write-Ok "Docker encontrado: $(docker --version)"

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Docker esta instalado pero el daemon no responde (¿Docker Desktop esta corriendo?)"
    exit 1
}
Write-Ok "Docker daemon activo"

docker compose version *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "docker compose (v2) no disponible. Actualiza Docker Desktop."
    exit 1
}
Write-Ok "docker compose disponible"

Write-Host ""
Write-Host "=== Paso 2/4 -- Preparando configuracion ==="

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Ok ".env creado desde .env.example"
} else {
    Write-Ok ".env ya existe, no se sobreescribe"
}

$workspaceRootName = (Split-Path -Parent $PSScriptRoot | Split-Path -Leaf).ToLowerInvariant() -replace '[^a-z0-9_-]', '-'
$defaultComposeName = "$workspaceRootName-tools"
$envContent = Get-Content ".env" -Raw -Encoding UTF8
if ($envContent -match '(?m)^\s*COMPOSE_PROJECT_NAME\s*=\s*$') {
    $envContent = $envContent -replace '(?m)^\s*COMPOSE_PROJECT_NAME\s*=\s*$', "COMPOSE_PROJECT_NAME=$defaultComposeName"
    Set-Content -Path ".env" -Value $envContent -Encoding UTF8 -NoNewline
    Write-Ok "COMPOSE_PROJECT_NAME autocompletado en .env: $defaultComposeName"
} elseif ($envContent -notmatch '(?m)^\s*COMPOSE_PROJECT_NAME\s*=') {
    Add-Content -Path ".env" -Value "`nCOMPOSE_PROJECT_NAME=$defaultComposeName" -Encoding UTF8
    Write-Ok "COMPOSE_PROJECT_NAME agregado en .env: $defaultComposeName"
}

$envVars = @{}
Get-Content ".env" -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') {
        $envVars[$matches[1]] = $matches[2]
    }
}
$sonarPort  = if ($envVars.ContainsKey("SONARQUBE_HOST_PORT") -and $envVars["SONARQUBE_HOST_PORT"]) { $envVars["SONARQUBE_HOST_PORT"] } else { "19000" }
$trivyPort  = if ($envVars.ContainsKey("TRIVY_HOST_PORT") -and $envVars["TRIVY_HOST_PORT"]) { $envVars["TRIVY_HOST_PORT"] } else { "14954" }
$zapPort    = if ($envVars.ContainsKey("ZAP_HOST_PORT") -and $envVars["ZAP_HOST_PORT"]) { $envVars["ZAP_HOST_PORT"] } else { "18080" }
$sonarToken = if ($envVars.ContainsKey("SONAR_TOKEN")) { $envVars["SONAR_TOKEN"] } else { "" }
$nvdApiKey  = if ($envVars.ContainsKey("DEPCHECK_NVD_API_KEY")) { $envVars["DEPCHECK_NVD_API_KEY"] } else { "" }

Write-Host ""
Write-Host "=== Paso 3/4 -- Levantando servicios ==="

docker compose up -d sonarqube-db sonarqube trivy zap
if ($LASTEXITCODE -ne 0) {
    Write-Fail "docker compose up fallo. Revisa el output de arriba (puertos ocupados, imagen no descargable, etc.)."
    exit 1
}
Write-Ok "Contenedores solicitados (sonarqube-db, sonarqube, trivy, zap)"

Write-Host ""
Write-Host "=== Paso 4/4 -- Esperando a que respondan (hasta 3 minutos cada uno) ==="

function Wait-ForService {
    param([string]$Name, [scriptblock]$Check, [int]$MaxTries = 18)
    Write-Host -NoNewline "   $Name`: "
    for ($i = 0; $i -lt $MaxTries; $i++) {
        $result = $false
        try { $result = & $Check } catch { $result = $false }
        if ($result) {
            Write-Host "listo" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 10
        Write-Host -NoNewline "."
    }
    $minutos = [math]::Round($MaxTries * 10 / 60, 1)
    Write-Host "sin respuesta tras $minutos min" -ForegroundColor Red
    return $false
}

# [void] delante de cada llamada: sin esto, PowerShell imprime "True"/"False"
# al final de cada barra de progreso porque Wait-ForService retorna un bool
# y el valor no capturado se vuelca al host automáticamente.
[void] (Wait-ForService -Name "Trivy    " -Check {
    $r = Invoke-WebRequest -Uri "http://localhost:$trivyPort/healthz" -UseBasicParsing -TimeoutSec 5
    $r.Content.Trim() -eq "ok"
})

# ZAP carga decenas de extensiones al iniciar en modo daemon (spider, active
# scan rules, WebSockets, etc.) -- tarda más que Trivy/Sonar en la práctica,
# sobre todo en Docker Desktop con WSL2. Se le da el doble de margen (6 min).
[void] (Wait-ForService -Name "ZAP      " -MaxTries 36 -Check {
    # No verificar contra el puerto mapeado en el host (localhost:$zapPort).
    # ZAP valida el header Host contra su puerto interno real (8080); como
    # el externo (18080) no coincide, CUALQUIER ruta que llegue por ahi --
    # la raiz "/" y tambien /JSON/core/view/version/, no solo la raiz -- la
    # trata como una peticion a proxear hacia afuera y responde "Connection
    # Refused" contra si mismo. Confirmado: el mismo curl ejecutado dentro
    # del contenedor, contra el puerto real 8080, responde 200 sin problema
    # -- es la misma tecnica que usa el healthcheck nativo de esta imagen
    # (ver `docker inspect` del contenedor zap).
    $r = docker compose exec -T zap curl -s -m 5 "http://localhost:8080/JSON/core/view/version/" 2>$null
    $LASTEXITCODE -eq 0 -and $r -match "version"
})

[void] (Wait-ForService -Name "SonarQube" -Check {
    $r = Invoke-WebRequest -Uri "http://localhost:$sonarPort/api/system/status" -UseBasicParsing -TimeoutSec 5
    $r.Content -match '"status":"UP"'
})

Write-Host ""
Write-Host "=== Resumen ==="
Write-Host "SonarQube:  http://localhost:$sonarPort  (admin/admin la primera vez)"
Write-Host "Trivy:      http://localhost:$trivyPort"
Write-Host "ZAP:        http://localhost:$zapPort  (el daemon ya esta listo, pero NINGUNA ruta responde bien desde fuera por el remapeo de puerto -- ver nota arriba. Para confirmar: 'docker compose ps' (STATUS healthy) o 'docker compose logs zap'. Para que otro contenedor de este compose llame su API, usa http://zap:8080, no localhost:$zapPort)"
Write-Host ""
Write-Host "Herramientas on-demand (no quedan corriendo, se invocan cuando se usan):"
Write-Host "  docker compose --profile tools run --rm semgrep --config=auto --json --output=/report/semgrep-report.json /src"
Write-Host "  docker compose --profile tools run --rm gitleaks detect --source /src/Codigo/<proyecto> --log-opts=`"--all`" --redact --report-format json --report-path /report/gitleaks-report.json"
Write-Host "  docker compose --profile tools run --rm dependency-check --scan /src --format JSON --out /report --project `"preprod-audit`""
Write-Host "  docker compose --profile tools run --rm pa11y http://host.docker.internal:<puerto>"

if ([string]::IsNullOrWhiteSpace($sonarToken)) {
    Write-Host ""
    Write-Warn2 "SONAR_TOKEN no esta configurado en Tools\.env"
    Write-Host "   Paso manual unico (no automatizable): entra a http://localhost:$sonarPort,"
    Write-Host "   cambia el password de admin, genera un token en My Account > Security, y pegalo en Tools\.env"
}

if ([string]::IsNullOrWhiteSpace($nvdApiKey)) {
    Write-Host ""
    Write-Warn2 "DEPCHECK_NVD_API_KEY no esta configurado en Tools\.env (opcional)"
    Write-Host "   Sin API key de NVD, la primera corrida de Dependency-Check puede tardar 10-40 min."
}

Write-Host ""
Write-Host "=== Prompts sugeridos para validar (Capa 2 de Guia-Validacion-Template.md) ==="
Write-Host @"

1) Probar routing sin ejecutar nada:
   "¿Qué skill de IA_Skill/ deberías leer si te pido 'actúa como agente
   analista pre-productivo, inicia el análisis completo'? Nómbrala, no la
   ejecutes todavía."

2) Arrancar un análisis real:
   "Actúa como agente analista pre-productivo. Proyecto: [ruta].
   Corre el análisis pre-prod completo siguiendo
   SKILL-preprod-security-audit.md y genera los 2 entregables en
   Entregables/."

"@

Write-Host "Listo. Revisa arriba si algun servicio quedo marcado sin respuesta antes de continuar."
