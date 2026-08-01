#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./repomix-lib.sh
source "$ROOT_DIR/repomix-lib.sh"

FULL=false
NO_COMPRESS=false
STACK=""
# Nota: el contexto git (diffs y logs) se controla en repomix.config.json
# mediante git.includeDiffs y git.includeLogs — no hay flags CLI equivalentes en repomix.

for arg in "$@"; do
  case "$arg" in
    --full) FULL=true ;;
    --no-compress) NO_COMPRESS=true ;;
    --stack=*) STACK="${arg#--stack=}" ;;
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

has_code="$(find "$CODIGO_DIR" -mindepth 1 -not -name ".gitignore" | head -n 1 || true)"
if [[ -z "$has_code" ]]; then
  warn "Codigo/ esta vacio. Agrega codigo y vuelve a ejecutar."
  exit 0
fi

is_full_scan=false
if [[ "$TARGET" == "all" || "$TARGET" == "--all" || "$TARGET" == "" ]]; then
  is_full_scan=true
  invoke_scan "." "$SNAPSHOTS_DIR/snapshot-latest.md" "codigo-completo"
  snapshot_rel_path="IA_Memoria/snapshots/snapshot-latest.md"
else
  TARGET="${TARGET#--}"

  # Alias de conveniencia para layouts planos (Codigo/<tech>/ directo).
  # Si $TARGET no matchea ningun alias, se trata como ruta arbitraria
  # relativa a Codigo/, usando --stack=<nombre> para el ignore correcto
  # si se especifico.
  relative_path="$TARGET"
  effective_stack="$STACK"
  case "$TARGET" in
    backend-net)    relative_path="backend-net";      [[ -z "$effective_stack" ]] && effective_stack="dotnet" ;;
    backend-nestjs) relative_path="backend-nestjs";   [[ -z "$effective_stack" ]] && effective_stack="nestjs" ;;
    frontend)       relative_path="frontend-angular"; [[ -z "$effective_stack" ]] && effective_stack="angular" ;;
  esac

  if [[ ! -d "$CODIGO_DIR/$relative_path" ]]; then
    warn "No existe Codigo/$relative_path/."
    exit 0
  fi

  ignore_all="$(get_stack_ignore "$effective_stack")"
  safe_name="$(get_safe_name "$TARGET")"
  invoke_scan "$relative_path" "$SNAPSHOTS_DIR/snapshot-${safe_name}.md" "$TARGET" "$ignore_all"
  snapshot_rel_path="IA_Memoria/snapshots/snapshot-${safe_name}.md"
fi

echo ""
echo "================================================================"
echo "  PROMPT DE INSPECCION — copiar y pegar en tu agente IA"
echo "================================================================"
echo ""

if [[ "$is_full_scan" == true ]]; then
cat <<PROMPT
Lee $snapshot_rel_path usando lectura estrategica por secciones:

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

5. IA_Memoria/modulos.json (crear si no existe, o sobreescribir con lo detectado)
   - Un objeto { "generatedAt": "...", "modules": [...] } con un entry por cada modulo/microservicio real
     detectado en el arbol (name, path relativo a Codigo/, stack: dotnet | nestjs | angular | react | python-fastapi)
   - Este archivo es el que usa repomix-scan-modules.ps1/.sh para escanear un modulo a la vez —
     mantenlo sincronizado con lo que declares en arquitectura.md

Al terminar, reporta: cuantos modulos encontraste implementados,
que tecnologias detectaste, si hay alguna inconsistencia con
lo que ya estaba declarado en los archivos de memoria,
y si registraste deuda tecnica (si/no y cuantas entradas).
PROMPT
else
cat <<PROMPT
Lee $snapshot_rel_path usando lectura estrategica por secciones (arbol + resumen de tokens
al inicio, luego solo las secciones utiles: .csproj/package.json, controllers/endpoints,
middleware/manejo de errores, migraciones).

Este es un scan de un modulo especifico ($TARGET), no del proyecto completo. Al actualizar memoria:
- IA_Memoria/arquitectura.md: actualiza SOLO la seccion de este modulo (ruta, tecnologia, estado),
  sin tocar ni asumir el estado de otros modulos que no fueron escaneados.
- IA_Memoria/progreso.md: marca [x] los features de este modulo que ya existan en el codigo.
- IA_Memoria/convenciones.md: si este modulo revela un patron nuevo o inconsistente con lo ya
  documentado, agregalo o senala la inconsistencia — no lo generalices a otros modulos sin evidencia.
- IA_Memoria/deuda-tecnica.md: registra antipatrones reales encontrados en este modulo.
- IA_Memoria/modulos.json: si no existe todavia, no lo generes a partir de este scan parcial
  (necesita ver el proyecto completo) — sugiere correr \`./repomix-scan.sh all\` primero.

Reporta: que encontraste en este modulo especificamente y si hay
inconsistencias con lo que ya estaba declarado en los archivos de memoria.
PROMPT
fi

echo ""
echo "================================================================"
echo ""
