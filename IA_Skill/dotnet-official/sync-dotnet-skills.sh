#!/usr/bin/env bash
# Sincroniza las skills oficiales de Microsoft (github.com/dotnet/skills) listadas en
# skills.manifest hacia esta carpeta. Reemplaza las carpetas dotnet*/ por la versión
# actual del repo; no toca README.md, skills.manifest ni los scripts.
#
# Uso:
#   ./sync-dotnet-skills.sh                 # clona dotnet/skills (solo plugins/) en una carpeta temporal
#   ./sync-dotnet-skills.sh /ruta/al/clon   # usa un clon existente (sin red)
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DEST/skills.manifest"
REPO_URL="https://github.com/dotnet/skills.git"
SRC="${1:-}"
TMP=""

cleanup() { if [[ -n "$TMP" ]]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

if [[ -z "$SRC" ]]; then
  TMP="$(mktemp -d)"
  echo "Clonando $REPO_URL (solo plugins/)..."
  git -c core.longpaths=true -c core.hooksPath=/dev/null \
    clone --quiet --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TMP/repo"
  git -C "$TMP/repo" -c core.longpaths=true sparse-checkout set plugins
  SRC="$TMP/repo"
fi

if [[ ! -d "$SRC/plugins" ]]; then
  echo "ERROR: no se encontró $SRC/plugins" >&2
  exit 1
fi

# Leer manifest (sin comentarios, líneas vacías ni CR de Windows)
entries=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | tr -d '\r' | xargs)"
  [[ -n "$line" ]] && entries+=("$line")
done < "$MANIFEST"

# Validar TODO el manifest antes de borrar nada
missing=()
for entry in "${entries[@]}"; do
  plugin="${entry%%/*}"; skill="${entry#*/}"
  [[ -d "$SRC/plugins/$plugin/skills/$skill" ]] || missing+=("$entry")
done
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: skills del manifest que ya no existen en el repo: ${missing[*]}" >&2
  echo "Revisar el repo (pudieron renombrarse) y corregir skills.manifest. No se modificó nada." >&2
  exit 1
fi

# Reemplazar solo las carpetas de plugins (dotnet*/)
for dir in "$DEST"/dotnet*/; do
  [[ -d "$dir" ]] && rm -rf "$dir"
done

for entry in "${entries[@]}"; do
  plugin="${entry%%/*}"; skill="${entry#*/}"
  mkdir -p "$DEST/$plugin"
  cp -R "$SRC/plugins/$plugin/skills/$skill" "$DEST/$plugin/"
done

cp "$SRC/LICENSE" "$DEST/LICENSE"

{
  echo "repo: https://github.com/dotnet/skills"
  echo "commit: $(git -C "$SRC" rev-parse HEAD)"
  echo "fecha_commit: $(git -C "$SRC" log -1 --format=%cI)"
  echo "sincronizado: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "skills: ${#entries[@]}"
} > "$DEST/SOURCE.txt"

echo "OK: ${#entries[@]} skills sincronizadas en $DEST"
cat "$DEST/SOURCE.txt"
echo "Revisar el diff (git diff IA_Skill/dotnet-official) antes de commitear: es contenido de terceros."
