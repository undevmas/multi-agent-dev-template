# SKILL — Auditoría Pre-Productiva (Agente Analista)

## Cuándo usar esta skill

Al recibir una instrucción del tipo:
- "Actúa como agente analista pre-productivo, inicia el análisis completo"
- "Corre el checklist pre-prod"
- "Necesito una auditoría de seguridad antes de liberar este proyecto"
- "Genera el análisis pre-productivo para [proyecto]"

Esta es la skill orquestadora — no reemplaza a `SKILL-dependency-vulnerability-triage.md`,
`SKILL-secrets-scanning.md`, `SKILL-legacy-stack-security-baseline.md`,
`SKILL-security-{angular,dotnet,nestjs,python}.md`, `SKILL-accessibility-a11y.md`
ni `SKILL-risk-zone-policy.md` — las invoca a todas, en orden, y consolida
el resultado en 2 entregables.

**Prompt recomendado para arrancar** (mejora sobre el original: fija de
entrada el proyecto y evita una vuelta de clarificación):

```
Actúa como agente analista pre-productivo. Proyecto: [nombre/ruta en Codigo/].
Corre el análisis pre-prod completo siguiendo SKILL-preprod-security-audit.md
y genera los 2 entregables en Entregables/.
```

Si no se especifica el proyecto y hay más de uno en `Codigo/`, preguntar
cuál antes de arrancar — es la única pausa permitida en todo el flujo.

---

## Regla de finalización — qué significa "completo"

El análisis **no se da por terminado** hasta pasar por las 10 categorías
de la tabla de abajo, una por una, en orden. Para cada categoría el
resultado debe ser exactamente uno de estos 3 estados — nunca un silencio:

- **Evaluado, sin hallazgos** — se corrió el análisis, no hay nada que reportar
- **Evaluado, con hallazgos** — van al entregable, clasificados por zona
- **NO EVALUADO — sin skill de referencia** — para las 4 categorías que
  hoy no tienen skill (rendimiento, observabilidad, CI/CD, compliance PII).
  No se improvisa criterio genérico para estas — se listan tal cual, para
  que quede explícito que el agente no las cubrió, no que las revisó y
  no encontró nada.

Un entregable que omite una categoría sin decirlo es peor que uno que
dice "no evaluado" — la ambigüedad ahí es el error que este skill existe
para prevenir.

---

## Principio v2 — el output de la herramienta es la fuente, no la lectura de código

El output crudo de SonarQube/Semgrep/Trivy/Dependency-Check/Gitleaks/ZAP/pa11y
**es la fuente primaria** de cada hallazgo. Leer código a mano para "buscar"
hallazgos ya no es el método por default — es la excepción, permitida
únicamente en dos casos:

1. **Confirmar o descartar un falso positivo** que ya señaló una herramienta
   (ej. revisar si una variable interpolada sin escapar viene de input de
   usuario o de una env var, como ya se hacía en el piloto).
2. **La clase residual de hallazgos que ningún scanner genérico puede
   expresar** — típicamente autorización a nivel de dato de negocio (A01):
   "¿puede el capturista A editar un amparo asignado al capturista B?" no es
   algo que SonarQube/Semgrep puedan inferir sin conocer la regla de negocio.
   Ver `SKILL-security-owasp-checklist.md` para el criterio de A01.

Todo hallazgo que venga de lectura manual (caso 2) debe decirlo explícito en
el entregable — "detectado por revisión manual dirigida, no por herramienta"
— con el mismo rigor con el que hoy se distingue "no evaluado" de "sin
hallazgos". Un entregable que mezcla hallazgos de herramienta con hallazgos
de lectura manual sin decir cuál es cuál le hace creer al equipo que todo
pasó por el mismo nivel de cobertura automatizada, y no es cierto.

---

## Las 10 categorías, en orden, con su skill

| # | Categoría | Skill / acción |
|---|---|---|
| 1 | Dependencias (SCA) | Trivy + OWASP Dependency-Check (`Tools/`, confirmación cruzada — un CVE reportado por cualquiera de los dos entra al triage; pasa `--nvdApiKey` si `DEPCHECK_NVD_API_KEY` está definido en `Tools/.env`) + scanner nativo del stack (`npm audit`/`dotnet list package --vulnerable`/`pip-audit`) como respaldo si Docker no está disponible, luego `SKILL-dependency-vulnerability-triage.md` (prioridad CISA KEV incluida). **Trivy solo ve dependencias con archivo de bloqueo** (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `packages.lock.json`): sin él reporta 0 (falso limpio). Los manifiestos sin lockfile se listan; en .NET se cubren con `dotnet list package --vulnerable --include-transitive` y en Node quedan "no evaluado" + hallazgo 🟡 (builds no reproducibles). Además: licencias (`--scanners vuln,license`, política en `SKILL-stack-policy.md`) y SBOM CycloneDX como anexo del entregable |
| 2 | SAST / código propio | Semgrep (reglas `p/security-audit` + `p/owasp-top-ten` con `--metrics=off`; nunca `--config=auto`, que exige enviar telemetría a semgrep.dev) + SonarQube (`Tools/`, correr `sonar-scanner` de verdad — no asumir que "revisar el código" reemplaza el análisis) para el hallazgo bruto, leído vía `/api/issues/search`. Interpretación: si el stack está en la tabla aprobada, `SKILL-security-{angular,dotnet,nestjs,python}.md`; si no, `SKILL-legacy-stack-security-baseline.md` |
| 3 | Secretos | Gitleaks (`Tools/`, escaneando el repo del proyecto `--source /src/Codigo/<proyecto>` con `--log-opts="--all"` y `--redact`) + verificación de archivos sensibles trackeados (`git ls-files`), triage con `SKILL-secrets-scanning.md` (contención local inmediata 🟢 vs. rotación externa `S1`) |
| 4 | OWASP (revisión general) | SonarQube (reglas de seguridad) + ZAP (`Tools/`, modo `spider` + `passive scan` únicamente — **sin Active Scan por decisión del proyecto**, previa verificación de que el puerto objetivo sirve al proyecto bajo auditoría) + `trivy config` sobre los Dockerfile (imagen `latest`, usuario root, sin healthcheck; no analiza `docker-compose.yml` ni `azure-pipelines.yml`) + `SKILL-security-owasp-checklist.md` para interpretar |
| 5 | Testing / cobertura | Correr el comando de cobertura del stack (`npm test -- --coverage`, `dotnet test --collect:"XPlat Code Coverage"`, `pytest --cov`) — importable a SonarQube si se desea, pero el número real es lo que se reporta, nunca se asume (si no hay framework de pruebas configurado, reportar `0%` como hallazgo 🟡 ámbar) |
| 6 | Accesibilidad (solo frontend) | pa11y (`Tools/`, contenedor sobre imagen oficial de Playwright, requiere la app objetivo corriendo) para el hallazgo real, `SKILL-accessibility-a11y.md` para interpretar/priorizar. Si el proyecto no tiene frontend: estado "No aplica" (distinto de "no evaluado") |
| 7 | Rendimiento | **NO EVALUADO — sin skill de referencia** (fuera del alcance de medición dinámica pre-prod; para optimización estática de Core Web Vitals durante desarrollo usar `IA_Skill/web-official/modern-web-guidance/guides/performance/performance.md`) |
| 8 | Observabilidad | **NO EVALUADO — sin skill de referencia** |
| 9 | CI/CD (Azure DevOps) | **NO EVALUADO — sin skill de referencia** |
| 10 | Compliance PII/salud | **NO EVALUADO — sin skill de referencia** |

**Nota sobre el modo de ZAP (categoría 4):** por default, ZAP corre solo
`spider` (mapea rutas) + `passive scan` (analiza el tráfico observado sin
enviar payloads propios) — nunca Active Scan. Active Scan envía payloads
reales (SQLi, XSS, etc.) contra la app objetivo; en un sistema con datos
legales/PII reales y que dispara correos/SMS reales, eso puede generar
tráfico de negocio real (altas, notificaciones) contra la instancia
escaneada. Los hallazgos que solo un Active Scan puede confirmar (inyección
verificada, no solo sospechada) quedan fuera de alcance de esta auditoría
salvo que el equipo pida explícitamente correrlo contra un entorno aislado
con datos de prueba — eso se decide caso por caso, nunca por default.

Todo hallazgo de las categorías 1-6, sin excepción, se clasifica con
`SKILL-risk-zone-policy.md` (verde/ámbar/roja) antes de entrar al
entregable — esto determina qué tan urgente/riesgoso es atenderlo, no
reemplaza la severidad propia de cada herramienta (CVSS, etc.), la
complementa.

---

## Paso 1 — Verificar las herramientas de `Tools/` antes de analizar

Leer `IA_Memoria/arquitectura.md` primero para saber el stack real del
proyecto (no asumir Angular/.NET solo porque es el default del template).

**Nunca correr un scanner sin antes verificar que su servicio está
arriba.** Si algo no responde, no se improvisa un análisis manual como
sustituto silencioso — se imprime la instrucción de arranque exacta y se
continúa con lo que sí esté disponible, marcando el resto como "no
evaluado — herramienta no disponible" en el entregable final.

### 1a — ¿Existe `Tools/` en este proyecto?

```bash
if [[ ! -f "Tools/docker-compose.yml" ]]; then
  echo "Tools/ no existe en este proyecto — copiarla del template antes de continuar."
  exit 0
fi
if [[ ! -f "Tools/.env" ]]; then
  cp Tools/.env.example Tools/.env
  echo "Tools/.env creado desde el ejemplo. Revisar SONAR_TOKEN antes de usar Sonar."
fi
source Tools/.env 2>/dev/null || true
SONARQUBE_HOST_PORT="${SONARQUBE_HOST_PORT:-19000}"
TRIVY_HOST_PORT="${TRIVY_HOST_PORT:-14954}"
ZAP_HOST_PORT="${ZAP_HOST_PORT:-18080}"
```

### 1b — Chequeo de cada servicio persistente

```bash
check_sonarqube() {
  curl -sf "http://localhost:${SONARQUBE_HOST_PORT}/api/system/status" 2>/dev/null | grep -q '"status":"UP"'
}
check_trivy() {
  [[ "$(curl -sf http://localhost:${TRIVY_HOST_PORT}/healthz 2>/dev/null)" == "ok" ]]
}
check_zap() {
  # ZAP valida el Host header contra su puerto interno (8080) y rechaza peticiones
  # desde el host a localhost:${ZAP_HOST_PORT}; verificar siempre desde el contenedor:
  docker compose -f Tools/docker-compose.yml exec -T zap \
    curl -sf "http://localhost:8080/JSON/core/view/version/" 2>/dev/null | grep -q '"version"'
}

if ! check_sonarqube; then
  echo "SonarQube no responde. Arrancar con:"
  echo "  cd Tools && docker compose up -d sonarqube-db sonarqube"
  echo "  (tarda 30-60s la primera vez, reintentar el chequeo después)"
fi

if ! check_trivy; then
  echo "Trivy server no responde. Arrancar con: cd Tools && docker compose up -d trivy"
fi

if ! check_zap; then
  echo "ZAP no responde. Arrancar con: cd Tools && docker compose up -d zap"
  echo "  (recordar: la app objetivo debe ser alcanzable en host.docker.internal:<puerto>)"
fi
```

Si alguno no responde tras darle la instrucción, esa categoría se marca
"no evaluado — herramienta no disponible" y el análisis **continúa** con
las demás — nunca se detiene todo el flujo por un servicio caído.

### 1c — ¿El proyecto ya fue analizado en SonarQube alguna vez?

Esto es distinto de "¿el contenedor está arriba?" — un Sonar recién
levantado responde `UP` pero no tiene ningún análisis todavía.

```bash
check_sonar_project_analizado() {
  local project_key="$1"
  [[ -z "$SONAR_TOKEN" ]] && { echo "Sin SONAR_TOKEN en Tools/.env — ver Tools/README.md"; return 1; }
  local result
  result=$(curl -sf -u "${SONAR_TOKEN}:" \
    "http://localhost:${SONARQUBE_HOST_PORT}/api/project_analyses/search?project=${project_key}&ps=1" 2>/dev/null)
  [[ -z "$result" ]] && return 1
  echo "$result" | grep -q '"analyses":\[\]' && return 1  # existe el proyecto pero sin análisis
  return 0
}

# La clave del proyecto en Sonar es la carpeta de Codigo/ (una por proyecto, sin mezclar historiales)
if check_sonarqube && ! check_sonar_project_analizado "<carpeta-del-proyecto>"; then
  echo "Proyecto sin análisis previo en Sonar: el Paso 1d lo crea con el primer sonar-scanner."
fi
```

### 1d — Ejecutar los scanners, vía `Tools/` si Docker está disponible

> **Verificación obligatoria antes de ZAP y pa11y (evitar colisión de puertos):**
> Antes de escanear `TARGET_URL="http://host.docker.internal:<puerto>"`, comprobar que el proceso que escucha en `<puerto>` pertenece realmente al proyecto auditado en `Codigo/` (p. ej. verificando el título/rutas devueltas o levantando la app en un puerto libre dedicado como `3005`/`4205` si el puerto por defecto `3000`/`4200`/`5000` está ocupado por otro servicio en la máquina del dev). Documentar en la nota metodológica del entregable el puerto exacto escaneado.

```bash
# Carpeta del proyecto auditado dentro de Codigo/ (cada proyecto es su propio repo git)
PROYECTO="<carpeta-del-proyecto>"
PROYECTO="${PROYECTO%/}"   # sin "/" final: la búsqueda de lockfiles se detiene en la raíz del proyecto

cd Tools

# En Windows con Git Bash (MSYS): sin esto, argumentos como /src o /report
# se reinterpretan como rutas de Windows (ej. "C:/Program Files/Git/src")
# ANTES de llegar al contenedor, y todo comando de abajo con una ruta Unix
# falla con "path does not exist" -- confirmado corriendo dependency-check
# real en este entorno. No-op en Linux/Mac, seguro dejarlo siempre.
export MSYS_NO_PATHCONV=1

# Todos los escáneres apuntan a Codigo/${PROYECTO}, nunca a Codigo/ completo (mezclaría proyectos).

# --- SCA 0: archivos de bloqueo. Sin ellos Trivy no resuelve dependencias y reporta 0 (falso limpio) ---
RAIZ="../Codigo/${PROYECTO}"
find "$RAIZ" \( -name node_modules -o -name bin -o -name obj -o -name .git \) -prune -o \( -name '*.csproj' -o -name package.json \) -print |
while read -r m; do
  d=$(dirname "$m")
  case "$m" in
    *.csproj) [ -f "$d/packages.lock.json" ] || echo "$m" ;;
    *) until [ -f "$d/package-lock.json" ] || [ -f "$d/yarn.lock" ] || [ -f "$d/pnpm-lock.yaml" ] || [ "$d" = "$RAIZ" ] || [ "$d" = "." ]; do d=$(dirname "$d"); done
       [ -f "$d/package-lock.json" ] || [ -f "$d/yarn.lock" ] || [ -f "$d/pnpm-lock.yaml" ] || echo "$m" ;;
  esac
done > ../Insumos/sca-sin-lockfile-report.txt

# .NET sin packages.lock.json: respaldo con el SDK (restore genera obj/, ya ignorado por .NET).
# Node sin lockfile: no hay respaldo confiable -> "no evaluado" + hallazgo 🟡 (builds no reproducibles).
grep '\.csproj$' ../Insumos/sca-sin-lockfile-report.txt | while read -r p; do
  echo "=== $p"; dotnet restore "$p" >/dev/null 2>&1 || echo "restore falló (no evaluado): $p"
  dotnet list "$p" package --vulnerable --include-transitive 2>&1
done > ../Insumos/dotnet-vulnerable-report.txt

# --- SCA 1: dos motores, confirmación cruzada. Supresiones aprobadas del proyecto si existen ---
TRIVY_IGN=(); [ -f "$RAIZ/.trivyignore.yaml" ] && TRIVY_IGN=(--ignorefile "/src/${PROYECTO}/.trivyignore.yaml")
docker compose run --rm -v "$(pwd)/../Codigo:/src" -v "$(pwd)/../Insumos:/report" \
  trivy fs --server http://trivy:4954 --scanners vuln,license "${TRIVY_IGN[@]}" \
  --format json --output /report/trivy-report.json "/src/${PROYECTO}" \
  || echo "Trivy (Tools/) falló — verificar Docker, o correr localmente si está instalado"

# SBOM CycloneDX (anexo del entregable; misma limitación de lockfiles que el escaneo)
docker compose run --rm -v "$(pwd)/../Codigo:/src" -v "$(pwd)/../Insumos:/report" \
  trivy fs --server http://trivy:4954 --format cyclonedx --output /report/sbom-cyclonedx-report.json "/src/${PROYECTO}" \
  || echo "SBOM (Trivy) falló"

# Dockerfile del proyecto (no analiza docker-compose.yml ni azure-pipelines.yml)
docker compose run --rm -v "$(pwd)/../Codigo:/src" -v "$(pwd)/../Insumos:/report" \
  trivy config --format json --output /report/trivy-config-report.json "/src/${PROYECTO}" \
  || echo "trivy config falló"

# Si DEPCHECK_NVD_API_KEY está en Tools/.env, se pasa como --nvdApiKey para evitar
# rate-limiting de NIST NVD (reduce la descarga inicial de ~40 min a pocos minutos):
DC_SUP=(); [ -f "$RAIZ/dependency-check-suppression.xml" ] && DC_SUP=(--suppression "/src/${PROYECTO}/dependency-check-suppression.xml")
docker compose --profile tools run --rm dependency-check \
  --scan "/src/${PROYECTO}" --format JSON --out /report --project "${PROYECTO}" "${DC_SUP[@]}" \
  ${DEPCHECK_NVD_API_KEY:+--nvdApiKey "$DEPCHECK_NVD_API_KEY"} \
  || echo "Dependency-Check (Tools/) falló — ver Tools/README.md (primera corrida puede tardar por la descarga NVD)"

# Catálogo CISA KEV (CVE explotadas activamente). Público: solo se descarga, no se envía nada del proyecto
curl -sf https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json \
  -o ../Insumos/cisa-kev-report.json || echo "No se pudo descargar CISA KEV — prioridad por explotación sin evaluar"

# --- SAST: correr el análisis real, no asumir que "leer el código" lo reemplaza ---
# Clave Sonar = carpeta del proyecto. qualitygate.wait espera el cálculo del quality gate;
# si el gate no pasa, el scanner termina con error: leer el estado real antes de concluir.
docker compose --profile tools run --rm sonar-scanner \
  -Dsonar.projectKey="${PROYECTO}" -Dsonar.projectBaseDir="/usr/src/${PROYECTO}" -Dsonar.sources=. \
  -Dsonar.qualitygate.wait=true \
  || echo "sonar-scanner terminó con error o el quality gate no pasó — revisar SONAR_TOKEN y el estado del gate"

curl -sf -u "${SONAR_TOKEN}:" \
  "http://localhost:${SONARQUBE_HOST_PORT}/api/issues/search?componentKeys=${PROYECTO}&resolved=false&ps=500" \
  > ../Insumos/sonar-issues.json || echo "No se pudo leer /api/issues/search — revisar SONAR_TOKEN"
curl -sf -u "${SONAR_TOKEN}:" \
  "http://localhost:${SONARQUBE_HOST_PORT}/api/qualitygates/project_status?projectKey=${PROYECTO}" \
  > ../Insumos/sonar-qualitygate-report.json || echo "No se pudo leer el quality gate — criterio 'Indeterminado'"

# Semgrep con reglas explícitas y sin telemetría (--config=auto exige enviar métricas a semgrep.dev).
# Corre desde la raíz del proyecto para respetar su .semgrepignore y su .gitignore.
docker compose --profile tools run --rm -w "/src/${PROYECTO}" semgrep \
  --config p/security-audit --config p/owasp-top-ten --metrics=off \
  --json --output=/report/semgrep-report.json . \
  || echo "semgrep (Tools/) falló — verificar Docker, o correr localmente si está instalado"

# --- Secretos ---
# Escanea el repo del proyecto, no Codigo/: Codigo/ no es repo git y gitleaks leería el
# historial de la plantilla (falso negativo comprobado). Si el proyecto no tiene .git,
# cambiar --log-opts="--all" por --no-git. --redact: el reporte no guarda secretos en claro.
# JSON en /report/gitleaks-report.json (../Insumos/gitleaks-report.json)
docker compose --profile tools run --rm gitleaks detect \
  --source "/src/Codigo/${PROYECTO}" --log-opts="--all" --redact \
  --report-format json --report-path /report/gitleaks-report.json \
  || echo "gitleaks (Tools/) revisó historial (exit != 0 indica leaks encontrados o error de ejecución)"

# Verificación complementaria de archivos sensibles trackeados en git (SKILL-secrets-scanning.md)
git -C "../Codigo/${PROYECTO}" ls-files | grep -E '\.env$|\.env\.|\.pem$|\.key$|\.pfx$|id_rsa|credentials\.json|secrets\.json' \
  > ../Insumos/tracked-secret-files.txt || true

# --- OWASP dinámico: ZAP en modo spider + passive únicamente (sin Active Scan,
# ver nota en la tabla de categorías). Se consulta SIEMPRE desde dentro del
# contenedor (puerto interno 8080) -- ZAP rechaza el Host header del puerto
# remapeado del host y responde "Connection Refused" contra sí mismo si se le
# pega por localhost:$ZAP_HOST_PORT (confirmado, no es un bug de esta skill).
TARGET_URL="http://host.docker.internal:4200"  # ajustar al puerto real verificado del proyecto

docker compose exec -T zap curl -s \
  "http://localhost:8080/JSON/spider/action/scan/?url=${TARGET_URL}" > /dev/null

# Poll hasta que el spider termine (status llega a 100) antes de leer alerts —
# el passive scan corre en paralelo sobre lo que el spider va encontrando.
# Con tope: si ZAP se cae o no avanza, se reporta como escaneo parcial y se sigue.
intentos=0
until [[ "$(docker compose exec -T zap curl -s 'http://localhost:8080/JSON/spider/view/status/' | grep -o '"status":"[0-9]*"' | grep -o '[0-9]*')" == "100" ]]; do
  (( ++intentos > 360 )) && { echo "ZAP: spider sin terminar tras 30 min — reportar escaneo parcial"; break; }
  sleep 5
done

# Esperar a que la cola del passive scanner llegue a 0 registros pendientes (tope: 10 min)
intentos=0
until [[ "$(docker compose exec -T zap curl -s 'http://localhost:8080/JSON/pscan/view/recordsToScan/' | grep -o '[0-9]*')" == "0" ]]; do
  (( ++intentos > 300 )) && { echo "ZAP: passive scan con registros pendientes tras 10 min — reportar escaneo parcial"; break; }
  sleep 2
done

docker compose exec -T zap curl -s "http://localhost:8080/JSON/core/view/alerts/?baseurl=${TARGET_URL}" \
  > ../Insumos/zap-alerts.json || echo "No se pudieron leer las alertas de ZAP"

# --- Accesibilidad real (requiere la app corriendo en el host) ---
# Corre sobre imagen oficial de Playwright configurada en Tools/docker-compose.yml.
# Distinguir el código de salida: solo 2 significa hallazgos; cualquier otro distinto de 0
# es una falla de la herramienta y la categoría queda "no evaluado", nunca "con hallazgos".
docker compose --profile tools run --rm pa11y "${TARGET_URL}" > ../Insumos/pa11y-report.txt 2>&1
case $? in
  0) echo "pa11y: sin hallazgos en ${TARGET_URL}" ;;
  2) echo "pa11y: hallazgos de accesibilidad (ver Insumos/pa11y-report.txt)" ;;
  *) echo "pa11y FALLÓ (no evaluado): revisar Insumos/pa11y-report.txt y que la app responda en ${TARGET_URL}" ;;
esac

cd ..

# Cobertura — local, dentro del proyecto en Codigo/ (no requiere Tools/). La raíz de la
# plantilla no tiene script "test": correrlo ahí falla y el reporte queda sin cobertura.
# Node / Angular / React / NestJS:
npm --prefix "Codigo/${PROYECTO}" test -- --coverage 2>&1 | tee Insumos/coverage-output.txt || true
# .NET:
# dotnet test "Codigo/${PROYECTO}" --collect:"XPlat Code Coverage" 2>&1 | tee Insumos/coverage-output.txt || true
# Python:
# (cd "Codigo/${PROYECTO}" && pytest --cov) 2>&1 | tee Insumos/coverage-output.txt || true
```

Si Docker no está disponible en el entorno en absoluto, caer a las
versiones locales de cada herramienta (`npm audit`, `pip-audit`,
`dotnet list package --vulnerable`) tal como en la versión anterior de
este skill — degradado, pero no bloqueante. En ese caso, SonarQube/ZAP/
Dependency-Check/pa11y quedan como "no evaluado — herramienta no disponible"
(no hay equivalente local razonable para esos cuatro).

---

## Paso 2 — Triage de cada hallazgo

Para cada reporte generado en el Paso 1:

1. Parsear el output según el formato de la herramienta
2. Aplicar `SKILL-dependency-vulnerability-triage.md` a los hallazgos de SCA
3. Aplicar `SKILL-secrets-scanning.md` a los hallazgos de Gitleaks
4. Aplicar `SKILL-security-{framework}.md` o `SKILL-legacy-stack-security-baseline.md`
   a los hallazgos de Semgrep, según el stack detectado en el Paso 1
5. Clasificar cada uno con `SKILL-risk-zone-policy.md`
6. Licencias: comparar las de `trivy-report.json` (`Class: license`) con la política de
   licencias de `SKILL-stack-policy.md`
7. Emitir el veredicto (abajo)

### Veredicto de salida a producción

El agente no concluye "se ve bien": aplica estos criterios y emite uno de tres estados.

| Criterio bloqueante | Fuente | Se cumple si |
|---|---|---|
| Secretos | Gitleaks | 0 hallazgos vigentes |
| Dependencias | Trivy + Dependency-Check + respaldo .NET + CISA KEV | 0 críticas/altas con corrección disponible y 0 CVE del catálogo KEV sin mitigación documentada |
| Licencias | Trivy | 0 licencias restringidas sin aprobación |
| Código (SAST) | SonarQube + Semgrep | Quality gate `OK` (`sonar-qualitygate-report.json`) y 0 hallazgos `ERROR` de Semgrep confirmados |
| Cobertura | Comando del stack | ≥ mínimo de `IA_Memoria/arquitectura.md`; sin mínimo definido no bloquea y se reporta "umbral sin definir" |

- **Apto:** todos los criterios se cumplen.
- **No apto:** al menos uno falla; nombrar el criterio y el hallazgo que lo causa.
- **Indeterminado:** una fuente bloqueante no corrió o tuvo cobertura parcial (herramienta caída,
  manifiestos sin lockfile ni respaldo, sin token de Sonar). "No evaluado" nunca se convierte en "Apto".

ZAP, pa11y y las categorías 7–10 se reportan pero no bloquean, salvo que `arquitectura.md` del
proyecto diga lo contrario. Solo el dev puede aceptar una excepción a un criterio bloqueante; se
registra en el entregable con nombre, fecha y motivo. El agente nunca la acepta por su cuenta.

### Supresiones (falsos positivos y riesgos aceptados)

Viven versionadas en el repo del proyecto (`Codigo/<proyecto>/`) para no volver a triar lo ya
decidido. Usar el ID exacto que reporta cada herramienta (Dependency-Check identifica npm por GHSA,
no por CVE).

| Herramienta | Archivo (raíz del proyecto) | Justificación y caducidad |
|---|---|---|
| Gitleaks | `.gitleaksignore` (un fingerprint por línea) | Línea `#` previa: motivo, quién aprobó, fecha de revisión |
| Trivy | `.trivyignore.yaml` (`vulnerabilities: - id:`) | `statement:` con motivo y aprobador · `expired_at:` obligatoria |
| Dependency-Check | `dependency-check-suppression.xml` | `<notes>` con motivo y aprobador · atributo `until` obligatorio · `<cve>` para CVE, `<vulnerabilityName>` para GHSA |
| Semgrep | `.semgrepignore` (rutas) o `// nosemgrep: <regla>` en la línea | Comentario con el motivo junto a la supresión |
| SonarQube | Marcar el issue como "False positive" o "Accepted" | Comentario en el issue |

Reglas: caducidad máxima de 6 meses (al vencer, el hallazgo reaparece y se vuelve a triar). El
agente propone la supresión; una crítica o alta solo la suprime el dev. El entregable informa
cuántos hallazgos se suprimieron y en qué archivo: suprimir no es ocultar.

---

## Paso 3 — Generar los 2 entregables

Crear la carpeta con timestamp exacto `YYYYMMDD_HHmm`, dentro del proyecto (estructura de
`Entregables/README.md`; no se versiona):

```bash
PROYECTO="<carpeta-del-proyecto>"   # el mismo del Paso 1d
TS=$(date +"%Y%m%d_%H%M")
mkdir -p "Entregables/${PROYECTO}/auditoria-preprod/${TS}"
# Anexo: inventario de componentes (SBOM) de esta versión
cp Insumos/sbom-cyclonedx-report.json "Entregables/${PROYECTO}/auditoria-preprod/${TS}/sbom.cdx.json"
```

### Entregable 1 — `Entregables/<Proyecto>/auditoria-preprod/{TS}/hallazgos-preprod.md`

Markdown puro, autocontenido — un dev usando otra IA sin este template
debe poder leerlo y actuar sin contexto adicional. Estructura obligatoria:

**Regla dura, sin excepción: cero referencias al template dentro del
cuerpo de cada hallazgo.** Nunca escribir `IA_Memoria/`, `IA_Skill/`,
`SKILL-*.md`, `deuda-tecnica.md`, ni la palabra "template" dentro de
"Qué es", "Por qué importa", "Acción sugerida" o "Cómo refutar si no
aplica" — el dev que reciba esto probablemente no tiene ese folder ni
sabe qué es. Si la acción sugerida internamente implica registrar algo en
`IA_Memoria/deuda-tecnica.md`, eso se hace aparte, en el workflow interno
del agente — no se le pide al dev externo que lo haga.

Segunda regla dura: cada campo debe ser específico al hallazgo real, no
una descripción genérica de la categoría. "Cada dependencia declarada
entra en el árbol de auditoría de SCA" es una frase que aplica a
cualquier paquete de cualquier proyecto — no dice nada sobre el
hallazgo concreto. Si un campo se puede copiar-pegar a un hallazgo
distinto sin cambiar una palabra, está mal escrito.

```markdown
# Auditoría Pre-Productiva — [Proyecto] — [fecha legible]

## Resumen ejecutivo
- **Veredicto: [Apto | No apto | Indeterminado]** — [criterio(s) que fallan o fuentes que no corrieron]
- Total hallazgos: [N] (🟢 [N] verde · 🟡 [N] ámbar · 🔴 [N] roja) · Suprimidos: [N] (ver archivos de supresión)
- Categorías evaluadas: [N]/10 · No evaluadas: [N] (ver sección al final)
- Leyenda de zonas:
  - 🟢 **Verde:** acción inmediata sin riesgo de regresión funcional (p. ej. contención local de archivos en `.gitignore`), o falso positivo confirmado tras inspección puntual (no requiere cambio de código).
  - 🟡 **Ámbar:** cambio acotado en líneas o paquetes específicos con validación focalizada.
  - 🔴 **Roja:** requiere diseño, coordinación de despliegue, rotación de secretos activos o cambio con impacto en consumidores.
- Nota metodológica: [indicar URL/puerto exacto escaneado en análisis dinámico y motores ejecutados].

## 1. Dependencias (SCA)
*Motores usados: Trivy [versión] + OWASP Dependency-Check [versión] (+ scanner nativo si aplica).*
### [🔴|🟡|🟢] [Paquete] — [severidad CVSS] — [ID del advisory/CVE]
**Dónde:** `package.json` (o equivalente, con ruta exacta)
**Qué es:** [descripción concreta y específica del hallazgo — nombre del paquete, versión instalada, versión con fix, qué vulnerabilidad es exactamente. Nunca una frase genérica que aplicaría a cualquier dependencia]
**Por qué importa:** [impacto real y específico de ESTA vulnerabilidad en ESTE contexto — no una explicación de qué es SCA en general]
**Acción sugerida:** [acción concreta y ejecutable: "bump a versión X.Y.Z", "eliminar del package.json si no se usa (confirmar con `grep -r` en el código)", "sin fix disponible, monitorear el advisory"]
**Cómo refutar si no aplica:** [una condición verificable por el propio dev, sin depender de ningún documento externo — ej. "si al buscar el import de este paquete en el código no aparece ningún uso real, es seguro eliminarlo del package.json en vez de solo actualizarlo"]

[... un bloque por hallazgo ...]

## 2. Código / SAST
*Motores usados: SonarQube [versión] + Semgrep [versión].*
[mismo formato, con archivo:línea exacto]

### Autorización a nivel de dato de negocio (revisión manual dirigida, no herramienta)
*Ningún scanner genérico de SAST puede evaluar reglas de negocio como
"¿solo el capturista asignado puede editar este registro?" — esta
subsección es la única de todo el documento que sale de lectura manual en
vez de output de herramienta, ver principio v2 de esta skill.*
[mismo formato, o "Evaluado, sin hallazgos" si no se detectó nada]

## 3. Secretos
*Motor usado: Gitleaks [versión] (historial completo de git) + inspección de archivos trackeados (`git ls-files`).*
[mismo formato — distinguir siempre en "Acción sugerida" la contención local inmediata (`git rm --cached`, `.gitignore`) de la revocación/rotación en el proveedor externo, que debe ejecutar el responsable humano de infraestructura/seguridad como prioridad #1]

## 4. OWASP
*Motor dinámico: ZAP [versión] en modo spider + passive scan contra `[TARGET_URL]` — sin Active
Scan (ver nota de alcance). Hallazgos que solo un Active Scan confirmaría
(inyección verificada) no están cubiertos.*
[mismo formato]

## 5. Testing / Cobertura
**Cobertura actual:** [N]% ([herramienta usada])
[hallazgos si cobertura < umbral esperado o si no existe suite de pruebas automatizadas (`0%`), o "Evaluado, sin hallazgos" si es aceptable]

## 6. Accesibilidad
*Motor usado: pa11y (WCAG2AA) / Playwright.*
[mismo formato, o "No aplica — proyecto sin frontend"]

## Categorías no evaluadas en esta auditoría
- **7. Rendimiento** — **NO EVALUADO — sin skill de referencia** (fuera del alcance de las herramientas dinámicas usadas en esta auditoría)
- **8. Observabilidad** — **NO EVALUADO — sin skill de referencia** (fuera del alcance de las herramientas usadas en esta auditoría)
- **9. CI/CD (Azure DevOps)** — **NO EVALUADO — sin skill de referencia** (fuera del alcance de las herramientas usadas en esta auditoría)
- **10. Compliance PII/salud** — **NO EVALUADO — sin skill de referencia** (fuera del alcance de las herramientas usadas en esta auditoría)

*Auditoría generada el [fecha]. La comparación con auditorías futuras
(¿bajó el conteo de hallazgos?, ¿aparecieron nuevos?) es manual — este
documento es una fotografía de un momento, no un tracker.*
```

### Entregable 2 — `Entregables/<Proyecto>/auditoria-preprod/{TS}/hallazgos-preprod.html`

HTML autocontenido (un solo archivo, sin build step — sigue
`SKILL-frontend-design.md`), agrupado por categoría igual que el .md,
pensado para que un QA copie una tarjeta y pegue su contenido directo en
un ticket de Azure DevOps/Jira. Cada hallazgo es una tarjeta con botón de
copiar que incluye ubicación (`Dónde`), descripción, impacto, acción y criterio de refutación. Usar exactamente esta estructura base:

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Auditoría Pre-Productiva — [Proyecto] — [fecha]</title>
<style>
:root {
  color-scheme: light;
  --color-surface-app: #f8fafc; --color-surface-card: #ffffff;
  --color-text-primary: #0f172a; --color-text-secondary: #475569;
  --color-border-default: #e2e8f0;
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  --zone-verde: #16a34a; --zone-ambar: #d97706; --zone-roja: #dc2626;
  --zone-verde-bg: #f0fdf4; --zone-ambar-bg: #fffbeb; --zone-roja-bg: #fef2f2;
  --no-evaluado-bg: #f1f5f9;
}
* { box-sizing: border-box; }
body { margin:0; background:var(--color-surface-app); color:var(--color-text-primary); font-family:var(--font-sans); padding:32px 20px 64px; max-width:960px; margin:0 auto; line-height:1.55; }
h1 { font-size:24px; margin:0 0 8px; }
h2 { font-size:17px; border-bottom:2px solid var(--color-border-default); padding-bottom:8px; margin-top:36px; }
h3.motor { font-size:13px; font-weight:500; color:var(--color-text-secondary); margin:4px 0 14px; font-style:italic; }
.summary-bar { display:flex; flex-wrap:wrap; gap:10px; margin:12px 0 16px; }
.pill { display:inline-flex; align-items:center; gap:6px; padding:6px 12px; border-radius:999px; font-size:13px; font-weight:600; border:1px solid var(--color-border-default); background:#fff; }
.note { background:#fff; border:1px solid var(--color-border-default); border-radius:10px; padding:12px 16px; font-size:13px; color:var(--color-text-secondary); margin-bottom:20px; }
.card { background:var(--color-surface-card); border:1px solid var(--color-border-default); border-radius:10px; padding:16px 18px; margin-bottom:14px; border-left-width:5px; }
.card.verde { border-left-color:var(--zone-verde); background:var(--zone-verde-bg); }
.card.ambar { border-left-color:var(--zone-ambar); background:var(--zone-ambar-bg); }
.card.roja  { border-left-color:var(--zone-roja); background:var(--zone-roja-bg); }
.card-title { font-weight:700; margin:0 0 6px; font-size:15px; }
.card-where { font-family:var(--font-mono); font-size:12px; color:var(--color-text-secondary); margin:0 0 10px; word-break:break-all; }
.card-body p { margin:6px 0; font-size:14px; }
code { font-family:var(--font-mono); font-size:12.5px; background:rgba(15,23,42,0.06); padding:1px 5px; border-radius:4px; }
.copy-btn { background:#2563eb; color:#fff; border:none; border-radius:6px; padding:6px 14px; font-size:13px; font-weight:600; cursor:pointer; margin-top:10px; }
.copy-btn:hover { background:#1d4ed8; }
.no-evaluado { background:var(--no-evaluado-bg); border:1px dashed var(--color-border-default); border-radius:10px; padding:16px; color:var(--color-text-secondary); font-size:14px; }
.no-evaluado ul { margin:6px 0 0; padding-left:20px; }
</style>
</head>
<body>
<h1>Auditoría Pre-Productiva — [Proyecto]</h1>
<p><strong>Veredicto: [Apto | No apto | Indeterminado]</strong> — [criterio(s) que fallan o fuentes que no corrieron]</p>
<p>[fecha] · [N] hallazgos totales · [N] suprimidos · Categorías evaluadas: [N]/10</p>

<div class="summary-bar">
  <span class="pill">🔴 [N] Zona Roja</span>
  <span class="pill">🟡 [N] Zona Ámbar</span>
  <span class="pill">🟢 [N] Zona Verde</span>
</div>

<div class="note">
  <strong>Leyenda de zonas:</strong> 🟢 <strong>Verde</strong> = acción inmediata sin riesgo de regresión o falso positivo confirmado (sin cambio de código); 🟡 <strong>Ámbar</strong> = cambio acotado en líneas o paquetes específicos; 🔴 <strong>Roja</strong> = requiere diseño, rotación de credenciales o validación de consumidores.<br>
  <strong>Nota metodológica:</strong> [puerto e instancia exacta escaneada en análisis dinámico y motores utilizados].
</div>

<h2>1. Dependencias (SCA)</h2>
<h3 class="motor">Motores: Trivy [versión] + OWASP Dependency-Check [versión]</h3>
<div class="card roja" id="finding-1">
  <p class="card-title">🔴 [Paquete] — [severidad] — [CVE/Advisory]</p>
  <p class="card-where">Dónde: [archivo/ruta]</p>
  <div class="card-body">
    <p><strong>Qué es:</strong> [descripción]</p>
    <p><strong>Por qué importa:</strong> [impacto]</p>
    <p><strong>Acción sugerida:</strong> [acción]</p>
    <p><strong>Cómo refutar si no aplica:</strong> [condición verificable]</p>
  </div>
  <button class="copy-btn" onclick="copyFinding('finding-1', this)">Copiar para ticket</button>
</div>
<!-- repetir .card por cada hallazgo, agrupado por categoría con su <h2> y <h3 class="motor"> -->

<h2>Categorías no evaluadas (7 a 10)</h2>
<div class="no-evaluado">
  No evaluadas en esta auditoría — fuera del alcance de las herramientas automatizadas ejecutadas:
  <ul>
    <li><strong>7. Rendimiento</strong> — NO EVALUADO — sin skill de referencia</li>
    <li><strong>8. Observabilidad</strong> — NO EVALUADO — sin skill de referencia</li>
    <li><strong>9. CI/CD (Azure DevOps)</strong> — NO EVALUADO — sin skill de referencia</li>
    <li><strong>10. Compliance PII/salud</strong> — NO EVALUADO — sin skill de referencia</li>
  </ul>
</div>

<script>
function copyFinding(id, btn) {
  const card = document.getElementById(id);
  const text = card.innerText.replace(/Copiar para ticket|¡Copiado!/g, '').trim();
  navigator.clipboard.writeText(text).then(() => {
    if (!btn) return;
    const orig = btn.innerText;
    btn.innerText = '¡Copiado!';
    setTimeout(() => { btn.innerText = orig; }, 1600);
  });
}
</script>
</body>
</html>
```

---

## Paso 4 — Reporte final al usuario (en el chat, no en el entregable)

```
Auditoría completa. Veredicto: [Apto | No apto | Indeterminado] — [motivo].
[N] hallazgos (🟢[N] 🟡[N] 🔴[N]) · [N] suprimidos.
Categorías evaluadas: 6/10. No evaluadas: rendimiento, observabilidad, CI/CD, compliance PII.
Entregables en: Entregables/[Proyecto]/auditoria-preprod/[TS]/ (incluye sbom.cdx.json)
```

---

## ❌ Qué NO hacer

- No detenerse tras la categoría 1-2 sin recorrer las 10
- No inventar criterio genérico para las 4 categorías sin skill —
  marcarlas "no evaluado" explícitamente
- No comparar esta auditoría con una anterior ni calcular tendencia — eso
  es trabajo manual del equipo, fuera del alcance de este skill
- No bloquear todo el análisis si un scanner falla — marcar esa
  herramienta como no disponible y seguir con el resto
- No mezclar "no evaluado" (sin skill/herramienta) con "sin hallazgos"
  (se evaluó y no hay nada que reportar) — son estados distintos y el
  entregable debe distinguirlos con claridad
- No correr un scanner de `Tools/` sin el chequeo del Paso 1 primero —
  un contenedor caído da error confuso, no "sin hallazgos"
- No dejar el puerto de ZAP expuesto más allá de `localhost` — corre sin
  autenticación (`api.disablekey=true`) a propósito para simplificar el
  uso local, nunca lo publiques en un servidor accesible desde internet
- No commitear `Tools/.env` (tiene `SONAR_TOKEN`) — ver `SKILL-secrets-scanning.md`
- No leer código a mano para buscar hallazgos de las categorías 1-4 y 6
  (SCA, SAST, secretos, OWASP, accesibilidad) cuando la herramienta
  correspondiente está disponible — eso es exactamente el análisis manual
  que este skill v2 existe para reemplazar. Lectura manual solo para
  confirmar falsos positivos o para autorización a nivel de dato de negocio
  (ver "Principio v2" arriba)
- No correr Active Scan de ZAP por default — solo `spider` + `passive
  scan`. Active Scan envía payloads reales contra la app y solo se activa
  si el equipo lo pide explícitamente para un entorno aislado
- No dejar ninguna referencia a `IA_Memoria/`, `IA_Skill/`, `SKILL-*.md` ni
  a la palabra "template" dentro del cuerpo de un hallazgo en los 2
  entregables — quien los recibe (dev o su propia IA) no tiene ese
  contexto y no debería necesitarlo para actuar
- No escribir campos genéricos que apliquen a cualquier hallazgo de la
  misma categoría — cada "Qué es"/"Por qué importa"/"Acción sugerida" debe
  ser específico al paquete/archivo/línea real encontrado
