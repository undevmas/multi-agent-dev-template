# Tools/ — Herramientas de Análisis Pre-Productivo

Docker Compose con las herramientas que usa `SKILL-preprod-security-audit.md`.
El agente puede levantarlas él mismo si tiene acceso a Docker en el
entorno, o las levantas tú manualmente una vez y el agente solo las usa.

## Arranque manual

```bash
cd Tools
cp .env.example .env
# ajustar puertos en .env si alguno choca con algo que ya tengas corriendo

docker compose up -d sonarqube-db sonarqube trivy zap
```

Sonar tarda 30-60 segundos en arrancar la primera vez (crea el esquema en
Postgres). Los demás (Trivy, ZAP) arrancan casi de inmediato.

### Aislamiento entre copias del template

Por default, Docker Compose deriva el nombre de proyecto del nombre de esta
carpeta (`Tools`) — igual en cualquier clon de este template. Sin
`COMPOSE_PROJECT_NAME` en `.env`, dos proyectos distintos en la misma
máquina terminarían compartiendo el mismo SonarQube/Trivy/ZAP (misma red,
mismos volúmenes de datos) sin ningún error visible.
`setup-tools.ps1`/`setup-tools.sh` lo autocompletan en `.env` con un valor
derivado del nombre de la carpeta raíz del proyecto la primera vez que
corren — no hace falta tocarlo a mano. Si levantas los servicios sin pasar
por el script, corre el script al menos una vez primero (o define
`COMPOSE_PROJECT_NAME` tú mismo en `.env`) para no pisar otra instancia.

## Verificar que están arriba

```bash
curl -s http://localhost:${SONARQUBE_HOST_PORT:-19000}/api/system/status
curl -s http://localhost:${TRIVY_HOST_PORT:-14954}/healthz
# ZAP valida el Host header contra su puerto interno (8080); consultarlo siempre desde dentro del contenedor:
docker compose exec -T zap curl -s http://localhost:8080/JSON/core/view/version/
```

`SKILL-preprod-security-audit.md` hace este mismo chequeo antes de correr
el análisis — si algo no responde, imprime la instrucción de arranque en
vez de fallar en silencio.

## Primer arranque de SonarQube — paso manual obligatorio, no automatizable

SonarQube exige cambiar el password del admin en el primer login antes de
emitir tokens — esto no se puede saltar vía API, es una medida de
seguridad del propio SonarQube. Una sola vez:

1. Abrir `http://localhost:${SONARQUBE_HOST_PORT:-19000}` en el navegador
2. Login con `admin` / `admin`
3. Cambiar el password cuando lo pida
4. Ir a **Administration → Security → Users → Tokens** (o el ícono de tu
   usuario → **My Account → Security**)
5. Generar un token, copiarlo
6. Pegarlo en `Tools/.env` como `SONAR_TOKEN=...`

Después de esto, el agente puede correr `sonar-scanner` sin más
intervención tuya.

## Correr un análisis con Sonar Scanner

```bash
cd Tools
docker compose --profile tools run --rm sonar-scanner \
  -Dsonar.projectKey=mi-proyecto \
  -Dsonar.sources=.
```

## Herramientas on-demand (no quedan corriendo, un solo uso)

**Windows con Git Bash:** anteponer `export MSYS_NO_PATHCONV=1` antes de
correr cualquiera de estos comandos. Sin eso, Git Bash reinterpreta
argumentos como `/src` o `/report` como rutas de Windows (ej.
`C:/Program Files/Git/src`) antes de que lleguen al contenedor, y el
comando falla con `path does not exist` — confirmado corriendo
Dependency-Check real en este entorno. No-op en Linux/Mac/PowerShell.

```bash
# Semgrep — SAST (escribe reporte en Insumos/semgrep-report.json)
docker compose --profile tools run --rm semgrep --config=auto --json --output=/report/semgrep-report.json /src

# Gitleaks — secretos en todo el historial del repo del proyecto (Codigo/ no es repo git; si el
# proyecto no tiene .git, usar --no-git). Reporte sin secretos en claro en Insumos/gitleaks-report.json
docker compose --profile tools run --rm gitleaks detect --source /src/Codigo/<proyecto> --log-opts="--all" --redact \
  --report-format json --report-path /report/gitleaks-report.json

# pa11y — accesibilidad real sobre contenedor Playwright (la app objetivo debe estar corriendo en tu host)
docker compose --profile tools run --rm pa11y http://host.docker.internal:4200

# OWASP Dependency-Check — SCA, segundo motor como confirmación cruzada de
# Trivy (ver SKILL-dependency-vulnerability-triage.md). El reporte queda en
# Insumos/dependency-check-report.json. Si definiste DEPCHECK_NVD_API_KEY en .env, pásala con --nvdApiKey:
docker compose --profile tools run --rm dependency-check \
  --scan /src --format JSON --out /report --project "nombre-del-proyecto" \
  ${DEPCHECK_NVD_API_KEY:+--nvdApiKey "$DEPCHECK_NVD_API_KEY"}
```

**Primer arranque de Dependency-Check — lento, no es una falla:** la primera
corrida descarga la base de vulnerabilidades NVD completa, lo que sin API key
puede tardar 10-40 minutos (NIST limita la tasa de descarga sin autenticación).
Con una key gratuita (`DEPCHECK_NVD_API_KEY` en `.env`, ver `.env.example`) baja
a unos minutos. El dato queda cacheado en un volumen persistente
(`dependency_check_data`), así que corridas posteriores no vuelven a descargar
la base completa — solo la actualización incremental.

## Escanear con Trivy (ya corriendo como servidor)

```bash
docker compose run --rm -v "$(pwd)/../Codigo:/src" trivy fs --server http://trivy:4954 /src
```

Usa `docker compose run` (no `docker run --network ...`) para que se
conecte automáticamente a la red del proyecto correcto — el nombre de esa
red varía según `COMPOSE_PROJECT_NAME` (ver sección de aislamiento arriba).

## Escanear con ZAP (la app objetivo debe estar corriendo y ser alcanzable)

Por política de seguridad del template (`SKILL-preprod-security-audit.md`), ZAP se ejecuta por defecto **únicamente en modo `spider` + `passive scan`** y consultando su puerto interno `8080` vía `docker compose exec -T zap`:

```bash
# 1. Iniciar spider (el passive scan analiza en paralelo todo lo que el spider descubre)
docker compose exec -T zap curl -s "http://localhost:8080/JSON/spider/action/scan/?url=http://host.docker.internal:4200"

# 2. Consultar progreso del spider (esperar a {"status":"100"})
docker compose exec -T zap curl -s "http://localhost:8080/JSON/spider/view/status/"

# 3. Exportar alertas pasivas a Insumos/zap-alerts.json
docker compose exec -T zap curl -s "http://localhost:8080/JSON/core/view/alerts/" > ../Insumos/zap-alerts.json
```

> **Advertencia sobre Active Scan (`ascan`):** nunca ejecutar `/JSON/ascan/action/scan/` por defecto. Active Scan inyecta payloads reales (SQLi, XSS, fuzzing) que pueden mutar datos o disparar notificaciones reales; requiere autorización explícita sobre un entorno 100% aislado.

## Apagar todo

```bash
docker compose down
# agregar -v si además quieres borrar los datos de Sonar/Trivy (empezar de cero)
```

## Notas de seguridad

- El puerto de ZAP (`api.disablekey=true`) no lleva autenticación — está
  pensado para uso local, nunca expongas ese puerto fuera de tu máquina/red
  de confianza (no lo publiques en un servidor accesible desde internet).
- `SONAR_TOKEN` no debe commitearse — `Tools/.env` ya debería estar en
  `.gitignore` del proyecto raíz (ver `SKILL-secrets-scanning.md`).
