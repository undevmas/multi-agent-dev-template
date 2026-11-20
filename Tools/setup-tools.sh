#!/usr/bin/env bash
# Tools/setup-tools.sh — v1
# Prepara y levanta SonarQube, Trivy y ZAP (Linux/Mac).
# No corre el análisis — solo deja la infraestructura lista y te da los
# prompts para validar el flujo (ver Capa 2 de Guia-Validacion-Template.md).

# Si el sistema da "Permission denied" al correr ./setup-tools.sh, falta el
# bit de ejecución (equivalente en Linux/Mac al bloqueo de Execution Policy
# en Windows). Corre una vez: chmod +x setup-tools.sh

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "=== Paso 1/4 — Verificando requisitos ==="

if ! command -v docker &>/dev/null; then
  fail "Docker no está instalado o no está en el PATH."
  echo "   Instálalo desde https://docs.docker.com/get-docker/ y vuelve a correr este script."
  exit 1
fi
ok "Docker encontrado: $(docker --version)"

if ! docker info &>/dev/null; then
  fail "Docker está instalado pero el daemon no responde (¿Docker Desktop está corriendo?)"
  exit 1
fi
ok "Docker daemon activo"

if ! docker compose version &>/dev/null; then
  fail "docker compose (v2) no disponible. Actualiza Docker Desktop o instala el plugin compose."
  exit 1
fi
ok "docker compose disponible: $(docker compose version --short 2>/dev/null || echo 'v2')"

echo ""
echo "=== Paso 2/4 — Preparando configuración ==="

if [[ ! -f .env ]]; then
  cp .env.example .env
  ok ".env creado desde .env.example"
else
  ok ".env ya existe, no se sobreescribe"
fi

# shellcheck disable=SC1091
source .env 2>/dev/null || true
SONARQUBE_HOST_PORT="${SONARQUBE_HOST_PORT:-19000}"
TRIVY_HOST_PORT="${TRIVY_HOST_PORT:-14954}"
ZAP_HOST_PORT="${ZAP_HOST_PORT:-18080}"

echo ""
echo "=== Paso 3/4 — Levantando servicios ==="

if ! docker compose up -d sonarqube-db sonarqube trivy zap; then
  fail "docker compose up falló. Revisa el output de arriba (puertos ocupados, imagen no descargable, etc.)."
  exit 1
fi
ok "Contenedores solicitados (sonarqube-db, sonarqube, trivy, zap)"

echo ""
echo "=== Paso 4/4 — Esperando a que respondan (hasta 3 minutos cada uno) ==="

wait_for() {
  local name="$1" check_cmd="$2" max_tries="${3:-18}" tries=0
  echo -n "   ${name}: "
  while (( tries < max_tries )); do
    if eval "$check_cmd" &>/dev/null; then
      echo -e "${GREEN}listo${NC}"
      return 0
    fi
    tries=$((tries + 1))
    sleep 10
    echo -n "."
  done
  local minutos=$(( max_tries * 10 / 60 ))
  echo -e "${RED}sin respuesta tras ${minutos} min${NC}"
  return 1
}

wait_for "Trivy    " "[[ \"\$(curl -sf http://localhost:${TRIVY_HOST_PORT}/healthz 2>/dev/null)\" == \"ok\" ]]"
# ZAP carga decenas de extensiones al iniciar en modo daemon -- tarda más
# que Trivy/Sonar en la práctica. Se le da el doble de margen (6 min).
# No verificar contra el puerto mapeado en el host (ZAP_HOST_PORT). ZAP
# valida el header Host contra su puerto interno real (8080); como el
# externo (18080) no coincide, cualquier ruta que llegue por ahí -- la raíz
# "/" y también /JSON/core/view/version/ -- la trata como una petición a
# proxear hacia afuera y responde "Connection Refused" contra sí mismo. El
# mismo curl ejecutado dentro del contenedor, contra el puerto real 8080,
# responde 200 sin problema -- es la misma técnica que usa el healthcheck
# nativo de esta imagen (ver `docker inspect` del contenedor zap).
wait_for "ZAP      " "docker compose exec -T zap curl -sf http://localhost:8080/JSON/core/view/version/ | grep -q version" 36
wait_for "SonarQube" "curl -sf http://localhost:${SONARQUBE_HOST_PORT}/api/system/status 2>/dev/null | grep -q '\"status\":\"UP\"'"

echo ""
echo "=== Resumen ==="
echo "SonarQube:  http://localhost:${SONARQUBE_HOST_PORT}  (admin/admin la primera vez)"
echo "Trivy:      http://localhost:${TRIVY_HOST_PORT}"
echo "ZAP:        http://localhost:${ZAP_HOST_PORT}  (el daemon ya está listo, pero NINGUNA ruta responde bien desde fuera por el remapeo de puerto -- ver nota arriba. Para confirmar: 'docker compose ps' (STATUS healthy) o 'docker compose logs zap'. Para que otro contenedor de este compose llame su API, usa http://zap:8080, no localhost:${ZAP_HOST_PORT})"
echo ""
echo "Herramientas on-demand (no quedan corriendo, se invocan cuando se usan):"
echo "  docker compose --profile tools run --rm semgrep --config=auto /src"
echo "  docker compose --profile tools run --rm gitleaks detect --source /src --log-opts=\"--all\""
echo "  docker compose --profile tools run --rm pa11y http://host.docker.internal:<puerto>"

if [[ -z "${SONAR_TOKEN:-}" ]]; then
  echo ""
  warn "SONAR_TOKEN no está configurado en Tools/.env"
  echo "   Paso manual único (no automatizable): entra a http://localhost:${SONARQUBE_HOST_PORT},"
  echo "   cambia el password de admin, genera un token en My Account > Security, y pégalo en Tools/.env"
fi

echo ""
echo "=== Prompts sugeridos para validar (Capa 2 de Guia-Validacion-Template.md) ==="
cat <<'PROMPTS'

1) Probar routing sin ejecutar nada:
   "¿Qué skill de IA_Skill/ deberías leer si te pido 'actúa como agente
   analista pre-productivo, inicia el análisis completo'? Nómbrala, no la
   ejecutes todavía."

2) Arrancar un análisis real:
   "Actúa como agente analista pre-productivo. Proyecto: [ruta].
   Corre el análisis pre-prod completo siguiendo
   SKILL-preprod-security-audit.md y genera los 2 entregables en
   Entregables/."

PROMPTS

echo "Listo. Revisa arriba si algún servicio quedó marcado sin respuesta antes de continuar."
