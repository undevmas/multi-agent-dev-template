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

## Verificar que están arriba

```bash
curl -s http://localhost:${SONARQUBE_HOST_PORT:-19000}/api/system/status
curl -s http://localhost:${TRIVY_HOST_PORT:-14954}/healthz
curl -s http://localhost:${ZAP_HOST_PORT:-18080}/
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

```bash
# Semgrep — SAST
docker compose --profile tools run --rm semgrep --config=auto /src

# Gitleaks — secretos, todo el historial
docker compose --profile tools run --rm gitleaks detect --source /src --log-opts="--all"

# pa11y — accesibilidad real (la app objetivo debe estar corriendo en tu host)
docker compose --profile tools run --rm pa11y http://host.docker.internal:4200
```

## Escanear con Trivy (ya corriendo como servidor)

```bash
docker run --rm --network tools_preprod-tools -v "$(pwd)/../Codigo:/src" \
  aquasec/trivy fs --server http://preprod-trivy:4954 /src
```

## Atacar con ZAP (la app objetivo debe estar corriendo y ser alcanzable)

```bash
curl "http://localhost:${ZAP_HOST_PORT:-18080}/JSON/spider/action/scan/?url=http://host.docker.internal:4200"
# luego, tras esperar a que termine el spider:
curl "http://localhost:${ZAP_HOST_PORT:-18080}/JSON/ascan/action/scan/?url=http://host.docker.internal:4200"
```

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
