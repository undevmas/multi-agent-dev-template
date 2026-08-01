#!/usr/bin/env bash
# repomix-lib.sh — funciones compartidas entre repomix-scan.sh y
# repomix-scan-modules.sh. Este archivo NO ejecuta nada por si solo:
# solo define funciones y variables. Se carga con:
#   source "$(dirname "${BASH_SOURCE[0]}")/repomix-lib.sh"
#
# Se centraliza aca la logica de scan/ignore/naming para evitar que los
# scripts que la consumen (el scan individual y el orquestador por modulos)
# diverjan entre si con el tiempo.

info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
ok() { echo "[OK]   $1"; }

# Presets de ignore por stack tecnologico — cubren la tabla de stacks
# aprobados en CLAUDE.md (.NET, NestJS, Angular, React, Python FastAPI).
# Independientes del nombre de carpeta: aplican a cualquier proyecto que
# use el template, no solo a la instancia actual.
get_stack_ignore() {
  local stack="$1"
  case "$stack" in
    dotnet)         echo "**/bin/**,**/obj/**,**/*.user,**/.vs/**,**/TestResults/**" ;;
    nestjs)         echo "**/node_modules/**,**/dist/**,**/build/**,**/coverage/**" ;;
    angular)        echo "**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**" ;;
    react)          echo "**/node_modules/**,**/dist/**,**/build/**,**/coverage/**" ;;
    python-fastapi) echo "**/__pycache__/**,**/.venv/**,**/venv/**,**/*.egg-info/**,**/.pytest_cache/**" ;;
    *)              echo "**/bin/**,**/obj/**,**/*.user,**/.vs/**,**/TestResults/**,**/node_modules/**,**/dist/**,**/build/**,**/.angular/**,**/coverage/**,**/__pycache__/**,**/.venv/**" ;;
  esac
}

get_safe_name() {
  local target="$1"
  echo "${target//[^a-zA-Z0-9_-]/-}"
}

# Setea las variables globales de contexto (CODIGO_DIR, SNAPSHOTS_DIR,
# CONFIG_PATH, COMPRESS_ENABLED, TIMESTAMP) a partir de ROOT_DIR. Requiere
# que el caller ya haya definido FULL y NO_COMPRESS (o los toma en false).
init_repomix_context() {
  local root_dir="$1"
  CODIGO_DIR="$root_dir/Codigo"
  SNAPSHOTS_DIR="$root_dir/IA_Memoria/snapshots"
  CONFIG_PATH="$CODIGO_DIR/repomix.config.json"

  COMPRESS_ENABLED=true
  if [[ "${NO_COMPRESS:-false}" == true || "${FULL:-false}" == true ]]; then
    COMPRESS_ENABLED=false
  fi

  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  mkdir -p "$SNAPSHOTS_DIR"
}

# Corre un scan de repomix para un source_path (relativo a Codigo/) y
# escribe el snapshot + su .meta.json. Requiere que init_repomix_context ya
# se haya llamado.
invoke_scan() {
  local source_path="$1"
  local output_path="$2"
  local label="$3"
  local ignore_patterns="${4:-}"

  local args=("repomix@latest" "$source_path" "--output" "$output_path")
  local local_config_path=""

  if [[ -f "$CONFIG_PATH" ]]; then
    # NOTA: Repomix no tiene un flag CLI --no-compress (verificado contra
    # cliRun.ts del repo oficial) — --compress es opt-in y no es negable.
    if [[ "$COMPRESS_ENABLED" == false ]]; then
      local_config_path="$(mktemp -t repomix-config-XXXXXX.json)"
      node -e "
        const fs = require('fs');
        const cfg = JSON.parse(fs.readFileSync('$CONFIG_PATH', 'utf8'));
        cfg.output = cfg.output || {};
        cfg.output.compress = false;
        fs.writeFileSync('$local_config_path', JSON.stringify(cfg, null, 2));
      "
      args+=("--config" "$local_config_path")
    else
      args+=("--config" "$CONFIG_PATH")
    fi
  else
    args+=("--style" "markdown")
    if [[ "$COMPRESS_ENABLED" == true ]]; then
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

  if [[ -n "$local_config_path" && -f "$local_config_path" ]]; then
    rm -f "$local_config_path"
  fi

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
  "generatedAt": "$TIMESTAMP",
  "source": "$source_path",
  "output": "$output_path",
  "compress": $COMPRESS_ENABLED,
  "sizeBytes": $size_bytes
}
EOF

  ok "Snapshot: $output_path"
  ok "Meta: $meta_path"
}
