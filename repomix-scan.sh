#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODIGO_DIR="$ROOT_DIR/Codigo"
SNAPSHOTS_DIR="$ROOT_DIR/IA_Memoria/snapshots"
CONFIG_PATH="$CODIGO_DIR/repomix.config.json"

FULL=false
NO_COMPRESS=false
# Nota: el contexto git (diffs y logs) se controla en repomix.config.json
# mediante git.includeDiffs y git.includeLogs — no hay flags CLI equivalentes en repomix.

for arg in "$@"; do
  case "$arg" in
    --full) FULL=true ;;
    --no-compress) NO_COMPRESS=true ;;
  esac
done

info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
ok() { echo "[OK]   $1"; }

if [[ ! -d "$CODIGO_DIR" ]]; then
  warn "No se encontro la carpeta Codigo/."
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "[ERROR] npx no encontrado. Instala Node.js para usar repomix."
  exit 1
fi

mkdir -p "$SNAPSHOTS_DIR"

compress_enabled=true
if [[ "$NO_COMPRESS" == true || "$FULL" == true ]]; then
  compress_enabled=false
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

invoke_scan() {
  local source_path="$1"
  local output_path="$2"
  local label="$3"
  local ignore_patterns="${4:-}"

  # Siempre pasar directorio y output explícito para todos los targets
  local args=("repomix@latest" "$source_path" "--output" "$output_path")

  if [[ -f "$CONFIG_PATH" ]]; then
    # Heredar style, compress, ignore patterns y security-check del config
    args+=("--config" "$CONFIG_PATH")
    # Respetar --full / --no-compress del usuario sobre lo que define el config
    if [[ "$compress_enabled" == false ]]; then
      args+=("--no-compress")
    fi
  else
    args+=("--style" "markdown")
    if [[ "$compress_enabled" == true ]]; then
      args+=("--compress")
    fi
  fi

  if [[ -n "$ignore_patterns" ]]; then
    args+=("--ignore" "$ignore_patterns")
  fi

  info "Escaneando $label ..."
  (
    cd "$CODIGO_DIR"
    npx "${args[@]}"
  )

  if [[ ! -f "$output_path" ]]; then
    echo "[ERROR] No se genero el snapshot esperado: $output_path"
    exit 1
  fi

  local size_bytes
  size_bytes="$(wc -c < "$output_path" | xargs)"
  local meta_path="${output_path%.md}.meta.json"

  cat > "$meta_path" <<EOF
{
  "label": "$label",
  "generatedAt": "$timestamp",
  "source": "$source_path",
  "output": "$output_path",
  "compress": $compress_enabled,
  "sizeBytes": $size_bytes
}
EOF

  ok "Snapshot: $output_path"
  ok "Meta: $meta_path"
}

has_code="$(find "$CODIGO_DIR" -mindepth 1 -not -name ".gitignore" | head -n 1 || true)"
if [[ -z "$has_code" ]]; then
  warn "Codigo/ esta vacio. Agrega codigo y vuelve a ejecutar."
  exit 0
fi

if [[ "$TARGET" == "all" || "$TARGET" == "--all" || "$TARGET" == "" ]]; then
  invoke_scan "." "$SNAPSHOTS_DIR/snapshot-latest.md" "codigo-completo"
else
  TARGET="${TARGET#--}"
  if [[ ! -d "$CODIGO_DIR/$TARGET" ]]; then
    warn "No existe Codigo/$TARGET/."
    exit 0
  fi
  safe_name="${TARGET//[^a-zA-Z0-9_-]/-}"
  ignore_all="**/bin/**,**/obj/**,**/*.user,**/.vs/**,**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**"
  invoke_scan "$TARGET" "$SNAPSHOTS_DIR/snapshot-${safe_name}.md" "$TARGET" "$ignore_all"
fi

echo ""
echo "================================================================"
echo "  PROMPT DE INSPECCION — copiar y pegar en tu agente IA"
echo "================================================================"
echo ""
cat <<'PROMPT'
Lee IA_Memoria/snapshots/snapshot-latest.md usando lectura estrategica por secciones:

PASO 1 — Leer las primeras 300 lineas del snapshot.
  Repomix siempre coloca el arbol de archivos y el resumen de tokens al inicio.
  Con eso sabes que modulos existen y cuales son los archivos mas pesados.
  No leas mas hasta completar este paso.

PASO 2 — Con el arbol como mapa, leer selectivamente solo las secciones utiles:
  - Archivos .csproj / package.json / *.sln  → tecnologias y versiones
  - docker-compose.yml / appsettings*.json / .env.example → puertos y variables
  - Controllers o endpoints (buscar "Controller", "router", "@Controller")
    → formato real de respuesta API (campos, estructura de error, traceId, etc.)
  - Archivos base / middleware / filtros de excepciones → patron de errores
  - Carpetas de modulos → cuales estan implementados vs scaffolding vacio
  - Migraciones o esquemas de BD → tipo de IDs, soft delete

  Si el snapshot supera 400 lineas: NO leerlo completo de corrido.
  Saltar directamente a los bloques de cada archivo usando el arbol del PASO 1.

PASO 3 — Con la informacion recopilada, actualizar los archivos de memoria:

1. IA_Memoria/arquitectura.md
   - Ruta raiz del proyecto: el nombre exacto de la carpeta dentro de Codigo/ donde vive el proyecto
     (ej: si el arbol muestra "Codigo/MiApp/src/...", la raiz es "Codigo/MiApp/" y el src es "Codigo/MiApp/src/")
   - Mapa de rutas por capa: para cada capa (Domain, Application, Infrastructure, API, etc.)
     documentar su ruta completa desde Codigo/ para que cualquier agente pueda acceder sin explorar
   - Estructura de Codigo/: subcarpetas de primer nivel con contenido y tecnologia detectada
   - Tecnologias y versiones reales detectadas
   - Modulos y servicios existentes con su estado actual
   - Puertos en docker-compose o archivos de configuracion
   - Variables de entorno en .env.example o en el codigo

2. IA_Memoria/progreso.md
   - Marca [x] solo los modulos/features que realmente existan en el codigo
   - Deja [ ] los que no esten implementados
   - Si el proyecto esta vacio: escribe "Proyecto nuevo, sin modulos implementados"
   - Reemplaza los pendientes de ejemplo con los reales del proyecto

3. IA_Memoria/convenciones.md
   - Detectar y documentar el formato real de respuesta API usado en los controllers
     (campos exactos, estructura del objeto error, traceId, paginacion — lo que este en el codigo)
   - Detectar la arquitectura de capas usada (Clean Architecture, N-capas, Vertical Slice, etc.)
   - Detectar el patron de acceso a datos (Repository, DbContext directo, CQRS + MediatR, etc.)
   - Detectar el patron de manejo de excepciones y validaciones
   - Detectar la estructura de carpetas dentro de cada capa
   - Confirmar o corregir los patrones de naming ya declarados en el archivo
   - Deja [COMPLETAR] solo donde no puedas inferirlo del snapshot

4. IA_Memoria/deuda-tecnica.md (solo si el proyecto tiene codigo existente)
   - Registrar antipatrones reales: IDs enteros secuenciales, DELETE directo en tablas de negocio,
     credenciales hardcodeadas, endpoints que mezclan formatos de response distintos entre si
   - NO registrar como deuda: que el formato de response sea distinto al ejemplo del template
     (el formato real ya queda documentado en convenciones.md y es la fuente de verdad)
   - Agregar una entrada por cada antipatron siguiendo el formato del archivo
   - Si el proyecto esta vacio o el codigo sigue las convenciones: no agregar nada

Al terminar, reporta: cuantos modulos encontraste implementados,
que tecnologias detectaste y si hay alguna inconsistencia con
lo que ya estaba declarado en los archivos de memoria.
PROMPT
echo ""
echo "================================================================"
echo ""
