#!/usr/bin/env bash
# Sincroniza la skill archify (github.com/tt-a1i/archify) hacia IA_Skill/archify-official/archify.
# Copia la carpeta archify/ del repo sin los HTML de ejemplo ya renderizados (~12 MB que el motor
# no usa) y las licencias. No toca README.md ni los scripts de esta carpeta.
#
# Uso:
#   ./sync-archify.sh                 # clona tt-a1i/archify (solo archify/) en una carpeta temporal
#   ./sync-archify.sh /ruta/al/clon   # usa un clon existente (sin red)
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/tt-a1i/archify.git"
SRC="${1:-}"
TMP=""

cleanup() { if [[ -n "$TMP" ]]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

if [[ -z "$SRC" ]]; then
  TMP="$(mktemp -d)"
  echo "Clonando $REPO_URL (solo archify/)..."
  git -c core.longpaths=true -c core.hooksPath=/dev/null \
    clone --quiet --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TMP/repo"
  git -C "$TMP/repo" -c core.longpaths=true sparse-checkout set archify
  SRC="$TMP/repo"
fi

if [[ ! -f "$SRC/archify/SKILL.md" || ! -f "$SRC/archify/bin/archify.mjs" ]]; then
  echo "ERROR: $SRC no contiene archify/SKILL.md y archify/bin/archify.mjs. No se modificó nada." >&2
  exit 1
fi

rm -rf "$DEST/archify"
cp -R "$SRC/archify" "$DEST/archify"
rm -f "$DEST"/archify/examples/*.html
for f in LICENSE LICENSE-MIT NOTICE; do cp "$SRC/$f" "$DEST/$f"; done

{
  echo "repo: https://github.com/tt-a1i/archify"
  echo "commit: $(git -C "$SRC" rev-parse HEAD)"
  echo "fecha_commit: $(git -C "$SRC" log -1 --format=%cI)"
  echo "version: $(node -e "console.log(require(process.argv[1]).version)" "$DEST/archify/package.json")"
  echo "sincronizado: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "excluido: archify/examples/*.html (renderizados de ejemplo)"
} > "$DEST/SOURCE.txt"

echo "OK: archify sincronizado en $DEST/archify ($(find "$DEST/archify" -type f | wc -l | xargs) archivos)"
cat "$DEST/SOURCE.txt"
echo "Verificar: node Tools/entregables/archify.mjs doctor · revisar el diff (git diff IA_Skill/archify-official): es contenido de terceros."
