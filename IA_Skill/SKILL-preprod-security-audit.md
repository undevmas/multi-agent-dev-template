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

## Las 10 categorías, en orden, con su skill

| # | Categoría | Skill / acción |
|---|---|---|
| 1 | Dependencias (SCA) | Trivy (`Tools/`) + scanner nativo del stack (`npm audit`/`dotnet list package --vulnerable`/`pip-audit`), luego `SKILL-dependency-vulnerability-triage.md` |
| 2 | SAST / código propio | Semgrep + SonarQube (`Tools/`) para el hallazgo bruto. Interpretación: si el stack está en la tabla aprobada, `SKILL-security-{angular,dotnet,nestjs,python}.md`; si no, `SKILL-legacy-stack-security-baseline.md` |
| 3 | Secretos | Gitleaks (`Tools/`), triage con `SKILL-secrets-scanning.md` |
| 4 | OWASP (revisión general) | SonarQube (reglas de seguridad) + ZAP (`Tools/`, ataque real si la app está corriendo) + `SKILL-security-owasp-checklist.md` para interpretar |
| 5 | Testing / cobertura | Correr el comando de cobertura del stack (`npm test -- --coverage`, `dotnet test /p:CollectCoverage=true`, `pytest --cov`) — importable a SonarQube si se desea, pero el número real es lo que se reporta, nunca se asume |
| 6 | Accesibilidad (solo frontend) | pa11y (`Tools/`, requiere la app corriendo) para el hallazgo real, `SKILL-accessibility-a11y.md` para interpretar/priorizar. Si el proyecto no tiene frontend: estado "No aplica" (distinto de "no evaluado") |
| 7 | Rendimiento | **NO EVALUADO — sin skill de referencia** |
| 8 | Observabilidad | **NO EVALUADO — sin skill de referencia** |
| 9 | CI/CD (Azure DevOps) | **NO EVALUADO — sin skill de referencia** |
| 10 | Compliance PII/salud | **NO EVALUADO — sin skill de referencia** |

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
  curl -sf "http://localhost:${ZAP_HOST_PORT}/" >/dev/null 2>&1
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

if check_sonarqube && ! check_sonar_project_analizado "mi-proyecto"; then
  echo "Proyecto sin análisis previo en Sonar. Correr:"
  echo "  cd Tools && docker compose --profile tools run --rm sonar-scanner -Dsonar.projectKey=mi-proyecto -Dsonar.sources=."
fi
```

### 1d — Ejecutar los scanners, vía `Tools/` si Docker está disponible

```bash
cd Tools

# SCA (complementa/reemplaza npm audit según lo que ya cubra Trivy)
docker compose --profile tools run --rm gitleaks detect --source /src --log-opts="--all" \
  --report-path /src/Insumos/gitleaks-report.json \
  || echo "gitleaks (Tools/) falló — verificar Docker, o correr localmente si está instalado"

docker compose --profile tools run --rm semgrep --config=auto --json --output=/src/Insumos/semgrep-report.json /src \
  || echo "semgrep (Tools/) falló — verificar Docker, o correr localmente si está instalado"

# Accesibilidad real (requiere la app corriendo en el host)
docker compose --profile tools run --rm pa11y http://host.docker.internal:4200 \
  > ../Insumos/pa11y-report.txt 2>&1 || echo "pa11y no corrió — ¿la app está levantada en el puerto indicado?"

cd ..

# Cobertura — local, no requiere Tools/ (no hay ganancia en dockerizarlo)
npm test -- --coverage 2>&1 | tee Insumos/coverage-output.txt || true
```

Si Docker no está disponible en el entorno en absoluto, caer a las
versiones locales de cada herramienta (`npm audit`, `pip-audit`,
`dotnet list package --vulnerable`) tal como en la versión anterior de
este skill — degradado, pero no bloqueante.

---

## Paso 2 — Triage de cada hallazgo

Para cada reporte generado en el Paso 1:

1. Parsear el output según el formato de la herramienta
2. Aplicar `SKILL-dependency-vulnerability-triage.md` a los hallazgos de SCA
3. Aplicar `SKILL-secrets-scanning.md` a los hallazgos de Gitleaks
4. Aplicar `SKILL-security-{framework}.md` o `SKILL-legacy-stack-security-baseline.md`
   a los hallazgos de Semgrep, según el stack detectado en el Paso 1
5. Clasificar cada uno con `SKILL-risk-zone-policy.md`

---

## Paso 3 — Generar los 2 entregables

Crear la carpeta con timestamp exacto `YYYYMMDD_HHmm`:

```bash
TS=$(date +"%Y%m%d_%H%M")
mkdir -p "Entregables/${TS}"
```

### Entregable 1 — `Entregables/{TS}/hallazgos-preprod.md`

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
- Total hallazgos: [N] (🟢 [N] verde · 🟡 [N] ámbar · 🔴 [N] roja)
- Categorías evaluadas: [N]/10 · No evaluadas: [N] (ver sección al final)

## 1. Dependencias (SCA)
### [🔴|🟡|🟢] [Paquete] — [severidad CVSS] — [ID del advisory/CVE]
**Dónde:** `package.json` (o equivalente)
**Qué es:** [descripción concreta y específica del hallazgo — nombre del paquete, versión instalada, versión con fix, qué vulnerabilidad es exactamente. Nunca una frase genérica que aplicaría a cualquier dependencia]
**Por qué importa:** [impacto real y específico de ESTA vulnerabilidad en ESTE contexto — no una explicación de qué es SCA en general]
**Acción sugerida:** [acción concreta y ejecutable: "bump a versión X.Y.Z", "eliminar del package.json si no se usa (confirmar con `grep -r` en el código)", "sin fix disponible, monitorear el advisory"]
**Cómo refutar si no aplica:** [una condición verificable por el propio dev, sin depender de ningún documento externo — ej. "si al buscar el import de este paquete en el código no aparece ningún uso real, es seguro eliminarlo del package.json en vez de solo actualizarlo"]

[... un bloque por hallazgo ...]

## 2. Código / SAST
[mismo formato, con archivo:línea exacto]

## 3. Secretos
[mismo formato]

## 4. OWASP
[mismo formato]

## 5. Testing / Cobertura
**Cobertura actual:** [N]% ([herramienta usada])
[hallazgos si cobertura < umbral esperado, o "sin hallazgos" si es aceptable]

## 6. Accesibilidad
[mismo formato, o "No aplica — proyecto sin frontend"]

## Categorías no evaluadas en esta auditoría
- Rendimiento — no evaluado, fuera del alcance de las herramientas usadas en esta auditoría
- Observabilidad — no evaluado, fuera del alcance de las herramientas usadas en esta auditoría
- CI/CD — no evaluado, fuera del alcance de las herramientas usadas en esta auditoría
- Compliance PII/salud — no evaluado, fuera del alcance de las herramientas usadas en esta auditoría

*Auditoría generada el [fecha]. La comparación con auditorías futuras
(¿bajó el conteo de hallazgos?, ¿aparecieron nuevos?) es manual — este
documento es una fotografía de un momento, no un tracker.*
```

### Entregable 2 — `Entregables/{TS}/hallazgos-preprod.html`

HTML autocontenido (un solo archivo, sin build step — sigue
`SKILL-frontend-design.md`), agrupado por categoría igual que el .md,
pensado para que un QA copie una tarjeta y pegue su contenido directo en
un ticket de Azure DevOps/Jira. Cada hallazgo es una tarjeta con botón de
copiar. Usar exactamente esta estructura base:

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Auditoría Pre-Productiva — [Proyecto] — [fecha]</title>
<style>
:root {
  --color-surface-app: #f8fafc; --color-surface-card: #fff;
  --color-text-primary: #0f172a; --color-text-secondary: #64748b;
  --color-border-default: #e2e8f0; --font-sans: -apple-system, "Segoe UI", sans-serif;
  --zone-verde: #16a34a; --zone-ambar: #d97706; --zone-roja: #dc2626;
  --zone-verde-bg: #f0fdf4; --zone-ambar-bg: #fffbeb; --zone-roja-bg: #fef2f2;
  --no-evaluado-bg: #f1f5f9;
}
body { margin:0; background:var(--color-surface-app); color:var(--color-text-primary); font-family:var(--font-sans); padding:32px; max-width:900px; margin:0 auto; }
h1 { font-size:24px; } h2 { font-size:16px; border-bottom:2px solid var(--color-border-default); padding-bottom:8px; margin-top:32px; }
.card { background:var(--color-surface-card); border:1px solid var(--color-border-default); border-radius:10px; padding:16px; margin-bottom:12px; border-left-width:4px; }
.card.verde { border-left-color:var(--zone-verde); background:var(--zone-verde-bg); }
.card.ambar { border-left-color:var(--zone-ambar); background:var(--zone-ambar-bg); }
.card.roja  { border-left-color:var(--zone-roja); background:var(--zone-roja-bg); }
.card-title { font-weight:700; margin:0 0 8px; }
.card-body p { margin:4px 0; font-size:14px; }
.copy-btn { background:#2563eb; color:#fff; border:none; border-radius:6px; padding:6px 14px; font-size:13px; cursor:pointer; margin-top:8px; }
.no-evaluado { background:var(--no-evaluado-bg); border:1px dashed var(--color-border-default); border-radius:10px; padding:16px; color:var(--color-text-secondary); }
</style>
</head>
<body>
<h1>Auditoría Pre-Productiva — [Proyecto]</h1>
<p>[fecha] · [N] hallazgos totales</p>

<h2>1. Dependencias (SCA)</h2>
<div class="card roja" id="finding-1">
  <p class="card-title">🔴 [Paquete] — [severidad]</p>
  <div class="card-body">
    <p><strong>Qué es:</strong> [descripción]</p>
    <p><strong>Por qué importa:</strong> [impacto]</p>
    <p><strong>Acción sugerida:</strong> [acción]</p>
  </div>
  <button class="copy-btn" onclick="copyFinding('finding-1')">Copiar para ticket</button>
</div>
<!-- repetir .card por cada hallazgo, agrupado por categoría con su <h2> -->

<h2>Categorías no evaluadas</h2>
<div class="no-evaluado">
  Rendimiento, Observabilidad, CI/CD, Compliance PII — no evaluadas en esta auditoría, fuera del alcance de las herramientas usadas.
</div>

<script>
function copyFinding(id) {
  const text = document.getElementById(id).innerText.replace('Copiar para ticket', '').trim();
  navigator.clipboard.writeText(text);
}
</script>
</body>
</html>
```

---

## Paso 4 — Reporte final al usuario (en el chat, no en el entregable)

```
Auditoría completa. [N] hallazgos (🟢[N] 🟡[N] 🔴[N]).
Categorías evaluadas: 6/10. No evaluadas: rendimiento, observabilidad, CI/CD, compliance PII.
Entregables en: Entregables/[TS]/
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
- No dejar ninguna referencia a `IA_Memoria/`, `IA_Skill/`, `SKILL-*.md` ni
  a la palabra "template" dentro del cuerpo de un hallazgo en los 2
  entregables — quien los recibe (dev o su propia IA) no tiene ese
  contexto y no debería necesitarlo para actuar
- No escribir campos genéricos que apliquen a cualquier hallazgo de la
  misma categoría — cada "Qué es"/"Por qué importa"/"Acción sugerida" debe
  ser específico al paquete/archivo/línea real encontrado
