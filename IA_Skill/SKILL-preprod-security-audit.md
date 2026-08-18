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
| 1 | Dependencias (SCA) | Ejecutar el scanner del stack detectado (ver Paso 1), luego `SKILL-dependency-vulnerability-triage.md` |
| 2 | SAST / código propio | Si el stack está en la tabla aprobada: `SKILL-security-{angular,dotnet,nestjs,python}.md`. Si no: `SKILL-legacy-stack-security-baseline.md` |
| 3 | Secretos | `SKILL-secrets-scanning.md` |
| 4 | OWASP (revisión general) | `SKILL-security-owasp-checklist.md` |
| 5 | Testing / cobertura | Correr el comando de cobertura del stack (`npm test -- --coverage`, `dotnet test /p:CollectCoverage=true`, `pytest --cov`), reportar el número real — nunca asumir cobertura sin dato |
| 6 | Accesibilidad (solo frontend) | `SKILL-accessibility-a11y.md`. Si el proyecto no tiene frontend: estado "No aplica" (distinto de "no evaluado" — aquí sí se determinó que la categoría no corresponde) |
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

## Paso 1 — Detectar el stack y ejecutar los scanners

Leer `IA_Memoria/arquitectura.md` primero para saber el stack real del
proyecto (no asumir Angular/.NET solo porque es el default del template).

Para cada scanner, intentar ejecutarlo vía bash. Si el comando no existe,
**no bloquea el resto del análisis** — se marca esa categoría como
"no evaluado — herramienta no disponible en este entorno" (nota: esto es
distinto de las 4 categorías sin skill; aquí sí hay skill, pero faltó la
herramienta) y se continúa con las demás.

```bash
# Node/npm — dependencias
npm audit --json > Insumos/npm-audit.json 2>&1 || echo "npm audit no disponible"

# .NET — dependencias
dotnet list package --vulnerable --include-transitive > Insumos/dotnet-vulnerable.txt 2>&1 || echo "dotnet no disponible"

# Python — dependencias
pip-audit -f json > Insumos/pip-audit.json 2>&1 || echo "pip-audit no disponible"

# Secretos — todo el historial, no solo HEAD
gitleaks detect --source . --report-format json --report-path Insumos/gitleaks-report.json --log-opts="--all" \
  || echo "gitleaks no disponible — intentar 'pip install' o 'brew install gitleaks', si falla continuar sin bloquear"

# SAST — Semgrep con reglas OWASP/seguridad general
semgrep --config=auto --json --output=Insumos/semgrep-report.json . \
  || echo "semgrep no disponible — intentar 'pip install semgrep' (requiere Python), si falla continuar sin bloquear"

# Cobertura — según stack detectado
npm test -- --coverage 2>&1 | tee Insumos/coverage-output.txt || true
```

Si una herramienta requiere instalación y el entorno lo permite, intentar
instalarla una vez (`pip install semgrep`, `npm install -g gitleaks` no
existe pero sí hay binarios — usar el gestor de paquetes disponible). Si
falla la instalación, no reintentar en loop — marcar y seguir.

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

```markdown
# Auditoría Pre-Productiva — [Proyecto] — [fecha legible]

## Resumen ejecutivo
- Total hallazgos: [N] (🟢 [N] verde · 🟡 [N] ámbar · 🔴 [N] roja)
- Categorías evaluadas: [N]/10 · No evaluadas: [N] (ver sección al final)

## 1. Dependencias (SCA)
### [🔴|🟡|🟢] [Paquete] — [severidad CVSS] — [ID del advisory/CVE]
**Dónde:** `package.json` (o equivalente)
**Qué es:** [descripción del hallazgo, en términos que no requieren conocer el template]
**Por qué importa:** [impacto real, no genérico]
**Acción sugerida:** [bump a versión X / requiere ticket por breaking change / sin fix disponible, monitorear]
**Cómo refutar si no aplica:** [ej. "si el paquete es solo devDependency y no llega a producción, este hallazgo baja de prioridad — confirmar en package.json"]

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
- Rendimiento — sin skill de referencia en el template
- Observabilidad — sin skill de referencia en el template
- CI/CD (Azure DevOps) — sin skill de referencia en el template
- Compliance PII/salud — sin skill de referencia en el template

*Generado por el agente analista pre-productivo el [fecha]. Próxima
auditoría: comparar el conteo de hallazgos con este documento para
determinar avance — el template no hace este diff automáticamente.*
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
  Rendimiento, Observabilidad, CI/CD, Compliance PII — sin skill de referencia en el template. No se intentó evaluar.
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
