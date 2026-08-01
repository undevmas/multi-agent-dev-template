#!/usr/bin/env bash
set -euo pipefail

# Orquestador de scans dirigidos por modulo. A diferencia de
# repomix-scan.sh all (que empaqueta TODO Codigo/ en un solo snapshot),
# este script lee IA_Memoria/modulos.json — el manifest que la IA
# genera/actualiza como parte del PASO 3 de un scan completo — y corre un
# scan independiente por cada modulo, con el preset de ignore correcto
# segun su stack. Al final imprime un solo prompt consolidado que le dice
# a la IA exactamente que snapshots leer y como actualizar la memoria.
#
# Uso:
#   ./repomix-scan-modules.sh                       # todos los modulos del manifest
#   ./repomix-scan-modules.sh --modules=Gateway,Identity

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./repomix-lib.sh
source "$ROOT_DIR/repomix-lib.sh"

MODULES_ARG=""
FULL=false
NO_COMPRESS=false

for arg in "$@"; do
  case "$arg" in
    --full) FULL=true ;;
    --no-compress) NO_COMPRESS=true ;;
    --modules=*) MODULES_ARG="${arg#--modules=}" ;;
  esac
done

init_repomix_context "$ROOT_DIR"

if [[ ! -d "$CODIGO_DIR" ]]; then
  warn "No se encontro la carpeta Codigo/."
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "[ERROR] npx no encontrado. Instala Node.js para usar repomix."
  exit 1
fi

MANIFEST_PATH="$ROOT_DIR/IA_Memoria/modulos.json"
if [[ ! -f "$MANIFEST_PATH" ]]; then
  warn "No existe IA_Memoria/modulos.json todavia."
  warn "Corre primero un scan completo para que la IA lo genere:"
  echo "    ./repomix-scan.sh all"
  exit 0
fi

modules_tsv="$(MODULES_FILTER="$MODULES_ARG" MANIFEST_PATH="$MANIFEST_PATH" node -e "
  const fs = require('fs');
  const manifest = JSON.parse(fs.readFileSync(process.env.MANIFEST_PATH, 'utf8'));
  const filter = (process.env.MODULES_FILTER || '').split(',').map(s => s.trim()).filter(Boolean);
  const mods = (manifest.modules || []).filter(m => filter.length === 0 || filter.includes(m.name));
  for (const m of mods) {
    console.log([m.name, m.path, m.stack].join('\t'));
  }
")"

if [[ -z "$modules_tsv" ]]; then
  warn "Ningun modulo seleccionado para escanear (revisa nombres en modulos.json)."
  exit 0
fi

mkdir -p "$SNAPSHOTS_DIR"

result_names=()
result_stacks=()
result_snapshots=()

while IFS=$'\t' read -r name path stack; do
  [[ -z "$name" ]] && continue
  if [[ ! -d "$CODIGO_DIR/$path" ]]; then
    warn "Modulo '$name': no existe Codigo/$path/ — se omite (modulos.json desactualizado?)."
    continue
  fi

  ignore_patterns="$(get_stack_ignore "$stack")"
  safe_name="$(get_safe_name "$path")"
  out="$SNAPSHOTS_DIR/snapshot-${safe_name}.md"

  invoke_scan "$path" "$out" "$name" "$ignore_patterns"

  result_names+=("$name")
  result_stacks+=("$stack")
  result_snapshots+=("IA_Memoria/snapshots/snapshot-${safe_name}.md")
done <<< "$modules_tsv"

if [[ ${#result_names[@]} -eq 0 ]]; then
  warn "Ningun modulo pudo escanearse."
  exit 0
fi

declare -A STACK_HINTS=(
  [dotnet]="  - *.csproj / *.sln / appsettings*.json -> tecnologias, versiones, puertos y variables
  - Controllers, Program.cs, middleware -> formato de response, manejo de errores
  - Migraciones EF Core -> tipo de IDs, soft delete"
  [nestjs]="  - package.json -> tecnologias y versiones
  - *.module.ts, *.controller.ts, guards/interceptors -> formato de response, manejo de errores
  - Migraciones TypeORM/Prisma -> tipo de IDs, soft delete"
  [angular]="  - package.json, angular.json -> version de Angular y librerias
  - Componentes, servicios, guards -> patron de estado y llamadas a API"
  [react]="  - package.json -> version de React y librerias
  - Componentes, hooks, llamadas a API -> patron de estado y manejo de errores"
  [python-fastapi]="  - requirements.txt / pyproject.toml -> version de FastAPI y dependencias
  - routers, Dockerfile, docker-compose.yml -> endpoints, puertos y deploy"
)

declare -A seen_stack=()
hints_block=""
for s in "${result_stacks[@]}"; do
  if [[ -z "${seen_stack[$s]:-}" ]]; then
    seen_stack[$s]=1
    if [[ -n "${STACK_HINTS[$s]:-}" ]]; then
      hints_block+="[$s]"$'\n'"${STACK_HINTS[$s]}"$'\n\n'
    fi
  fi
done

module_table=""
for i in "${!result_names[@]}"; do
  module_table+="  - ${result_names[$i]} (${result_stacks[$i]}) -> ${result_snapshots[$i]}"$'\n'
done

module_names_csv="$(printf ", %s" "${result_names[@]}")"
module_names_csv="${module_names_csv:2}"

module_count="${#result_names[@]}"

echo ""
echo "================================================================"
echo "  PROMPT DE INSPECCION — copiar y pegar en tu agente IA"
echo "================================================================"
echo ""
cat <<PROMPT
Se escanearon $module_count modulo(s) de forma dirigida (no el proyecto completo):

$module_table
PASO 1 — Para cada snapshot de la lista: leer primero el arbol de archivos y el
  resumen de tokens al inicio (las primeras ~200-300 lineas). No leas mas hasta
  completar este paso para todos los snapshots.

PASO 2 — Leer selectivamente por snapshot, segun su stack:

$hints_block
  Si un snapshot supera 400 lineas: NO leerlo completo de corrido.
  Saltar directamente a los bloques de cada archivo usando su arbol del PASO 1.

PASO 3 — Actualizar memoria SOLO para los modulos escaneados ($module_names_csv):
  - IA_Memoria/arquitectura.md: actualiza unicamente las secciones de estos modulos
    (ruta, tecnologia, estado). No toques ni asumas el estado de otros modulos.
  - IA_Memoria/progreso.md: marca [x] los features de estos modulos que ya existan en el codigo.
  - IA_Memoria/convenciones.md: si algun modulo revela un patron nuevo o inconsistente con lo
    ya documentado, agregalo o senala la inconsistencia — no lo generalices sin evidencia.
  - IA_Memoria/deuda-tecnica.md: registra antipatrones reales encontrados en estos modulos.
  - IA_Memoria/modulos.json: si alguno de estos modulos cambio de ruta o stack, actualiza SOLO
    esa entrada — no regeneres el archivo completo a partir de un scan parcial.

Al terminar, reporta: que encontraste en cada modulo escaneado y si hay
inconsistencias con lo que ya estaba declarado en los archivos de memoria.
PROMPT
echo ""
echo "================================================================"
echo ""
