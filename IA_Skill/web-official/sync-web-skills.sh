#!/usr/bin/env bash
# Sincroniza las skills oficiales de la plataforma web (github.com/GoogleChrome/modern-web-guidance)
# listadas en skills.manifest hacia esta carpeta. Reemplaza las carpetas del manifest por la versión
# actual del repo (solo SKILL.md y guides/ o references/); no toca README.md, skills.manifest ni los scripts.
#
# Uso:
#   ./sync-web-skills.sh                 # clona GoogleChrome/modern-web-guidance (solo skills/) en carpeta temporal
#   ./sync-web-skills.sh /ruta/al/clon   # usa un clon existente (sin red)
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DEST/skills.manifest"
REPO_URL="https://github.com/GoogleChrome/modern-web-guidance.git"
SRC="${1:-}"
TMP=""

cleanup() { if [[ -n "$TMP" ]]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

if [[ -z "$SRC" ]]; then
  TMP="$(mktemp -d)"
  echo "Clonando $REPO_URL (solo skills/)..."
  git -c core.longpaths=true -c core.hooksPath=/dev/null \
    clone --quiet --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TMP/repo"
  git -C "$TMP/repo" -c core.longpaths=true sparse-checkout set skills
  SRC="$TMP/repo"
fi

if [[ ! -d "$SRC/skills" ]]; then
  echo "ERROR: no se encontró $SRC/skills" >&2
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
  [[ -f "$SRC/skills/$entry/SKILL.md" ]] || missing+=("$entry")
done
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: skills del manifest que ya no existen en el repo: ${missing[*]}" >&2
  echo "Revisar el repo y corregir skills.manifest. No se modificó nada." >&2
  exit 1
fi

total_guides=0
for entry in "${entries[@]}"; do
  target="$DEST/$entry"
  [[ -d "$target" ]] && rm -rf "$target"
  mkdir -p "$target"
  cp "$SRC/skills/$entry/SKILL.md" "$target/SKILL.md"
  for subdir in guides references; do
    if [[ -d "$SRC/skills/$entry/$subdir" ]]; then
      cp -R "$SRC/skills/$entry/$subdir" "$target/$subdir"
      count="$(find "$target/$subdir" -type f -name '*.md' | wc -l | xargs)"
      total_guides=$((total_guides + count))
    fi
  done
done

cp "$SRC/LICENSE" "$DEST/LICENSE"

{
  echo "repo: https://github.com/GoogleChrome/modern-web-guidance"
  echo "commit: $(git -C "$SRC" rev-parse HEAD)"
  echo "fecha_commit: $(git -C "$SRC" log -1 --format=%cI)"
  echo "sincronizado: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "skills: ${#entries[@]}"
  echo "guias: $total_guides"
} > "$DEST/SOURCE.txt"

echo "OK: ${#entries[@]} skill(s) y $total_guides guías sincronizadas en $DEST"
cat "$DEST/SOURCE.txt"
echo "Revisar el diff (git diff IA_Skill/web-official) antes de commitear: es contenido de terceros."
