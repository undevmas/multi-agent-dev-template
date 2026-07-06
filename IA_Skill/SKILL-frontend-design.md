---
name: frontend-design-vanilla
description: >
  Define y aplica un sistema de diseño completo (tokens, tipografía, layout,
  componentes, estados) para páginas HTML/CSS/JS servidas sin framework y sin
  build step — dashboards internos, reportes, herramientas de tooling servidas
  por Python/FastAPI u otros backends ligeros. Úsala ANTES de escribir el
  primer selector CSS de cualquier página HTML standalone, para evitar caer en
  estilos por defecto del navegador o de Bootstrap sin personalizar.
stack: HTML5 · CSS Custom Properties · JavaScript vanilla (sin frameworks, sin npm, sin build step)
contexts: Dashboards internos · Reportes (ReporteadorV2) · Herramientas de tooling · Páginas de administración ligeras
---

# SKILL: Frontend Design Vanilla — HTML/CSS/JS sin framework

## Cuándo usar esta skill

Actívala cuando:
- La página se sirve como `.html` estático o generado por un backend (FastAPI, scripts) sin Angular/React.
- No hay build step (webpack, vite, angular-cli) ni `npm install` en el flujo del proyecto.
- El resultado final es un dashboard, reporte, panel de administración interno o herramienta de tooling.

**No uses las skills de `IA_Skill/frontend-design/*` para este caso.** Esas están escritas para Angular/React (componentes, SCSS, Tailwind config) y asumen un pipeline de build. Esta skill cubre los mismos principios pero traducidos a HTML/CSS/JS plano.

Secuencia recomendada: esta skill → `IA_Skill/SKILL-animation-microinteractions.md` (si la vista lo justifica) → `IA_Skill/frontend-design/SKILL-accessibility-a11y.md` (los criterios de accesibilidad sí son agnósticos de framework y aplican igual).

---

## El síntoma que esta skill previene

Sin un sistema de diseño explícito, el resultado por defecto es: tabla con bordes grises del navegador, links azul `#0000EE` sin estilizar, cards blancas sin sombra ni jerarquía, tipografía del sistema operativo, cero espaciado intencional. Es reconocible al instante como "sin diseñar" aunque el HTML/CSS esté técnicamente correcto. Esta skill existe para que la primera pasada ya tenga identidad visual, no para corregirla después.

---

## Cómo leer la tarea para extraer señales de diseño

| Señal en la tarea | Qué define |
|---|---|
| Dashboard con métricas (cards de números) | Grid de cards con jerarquía tipográfica número/etiqueta |
| Tabla de datos con estados (Closed, Active, Resolved) | Tokens de color por estado + badges, no texto plano |
| Filtros (selects, dropdowns) | Estilizar `<select>` nativo, no dejarlo con el look del SO |
| Severidad / prioridad (Critical, High, Medium, Low) | Escala de color semántica consistente en toda la vista |
| Navegación lateral (sidebar con secciones) | Sidebar con estado activo visualmente distinguible |
| Botón de acción principal ("Cargar resumen") | Botón con color de marca, no botón HTML por defecto |

---

## 1. Tokens — `tokens.css` (archivo propio, importado con `<link>`)

```css
/* tokens.css */
:root {
  /* Primitivos */
  --primitive-blue-50:  #eff6ff;
  --primitive-blue-500: #3b82f6;
  --primitive-blue-600: #2563eb;
  --primitive-blue-700: #1d4ed8;

  --primitive-red-500:   #ef4444;
  --primitive-red-600:   #dc2626;
  --primitive-amber-500: #f59e0b;
  --primitive-green-500: #22c55e;
  --primitive-green-600: #16a34a;

  --primitive-slate-50:  #f8fafc;
  --primitive-slate-100: #f1f5f9;
  --primitive-slate-200: #e2e8f0;
  --primitive-slate-300: #cbd5e1;
  --primitive-slate-500: #64748b;
  --primitive-slate-600: #475569;
  --primitive-slate-900: #0f172a;

  /* Semánticos */
  --color-surface-app:   var(--primitive-slate-50);
  --color-surface-card:  #ffffff;
  --color-surface-sunken: var(--primitive-slate-100);

  --color-text-primary:   var(--primitive-slate-900);
  --color-text-secondary: var(--primitive-slate-500);
  --color-text-link:      var(--primitive-blue-600);

  --color-border-default: var(--primitive-slate-200);
  --color-border-strong:  var(--primitive-slate-300);

  --color-action-primary:       var(--primitive-blue-600);
  --color-action-primary-hover: var(--primitive-blue-700);

  /* Estados / severidad — usar SIEMPRE estos, nunca inventar uno nuevo por vista */
  --color-status-critical: var(--primitive-red-600);
  --color-status-high:     var(--primitive-red-500);
  --color-status-medium:   var(--primitive-amber-500);
  --color-status-low:      var(--primitive-blue-500);
  --color-status-success:  var(--primitive-green-600);
  --color-status-closed:   var(--primitive-slate-500);

  /* Espaciado — escala 4px, no valores sueltos */
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px; --space-4: 16px;
  --space-5: 20px; --space-6: 24px; --space-8: 32px; --space-10: 40px;

  --radius-sm: 6px; --radius-md: 10px; --radius-lg: 14px;

  --shadow-card: 0 1px 3px rgba(15,23,42,.08), 0 1px 2px rgba(15,23,42,.04);

  --font-sans: -apple-system, "Segoe UI", Inter, Roboto, sans-serif;
  --font-mono: "SF Mono", "Cascadia Code", Consolas, monospace;
}

[data-theme="dark"] {
  --color-surface-app:  var(--primitive-slate-900);
  --color-surface-card: #1e293b;
  --color-text-primary: var(--primitive-slate-50);
  --color-border-default: #334155;
}
```

Reglas duras (idénticas a las de Angular/React, solo cambia el destino):
- Ningún color hardcoded (`#3b82f6`) fuera de `tokens.css`. Todo componente consume `var(--color-*)`.
- Sin Bootstrap, sin frameworks CSS de terceros. Google Fonts vía `<link>` está permitido.
- Un solo archivo `styles.css` (o `dashboard.css`) por página, nunca estilos inline `style="..."`.

---

## 2. Tipografía

```css
h1 { font: 600 28px/1.25 var(--font-sans); color: var(--color-text-primary); margin: 0; }
h2 { font: 600 18px/1.4 var(--font-sans); color: var(--color-text-primary); margin: 0 0 var(--space-4); }
.eyebrow {
  font: 600 12px/1 var(--font-sans);
  letter-spacing: .06em;
  text-transform: uppercase;
  color: var(--color-text-secondary);
}
.metric-value { font: 700 32px/1 var(--font-sans); color: var(--color-text-primary); }
.metric-label { font: 500 13px/1.4 var(--font-sans); color: var(--color-text-secondary); }
table { font: 14px/1.5 var(--font-sans); }
code, .mono { font-family: var(--font-mono); font-size: .9em; }
```

Jerarquía mínima obligatoria en cualquier dashboard: eyebrow (contexto) → H1 (título de vista) → texto secundario (descripción) → H2 (secciones) → cuerpo de tabla/cards.

---

## 3. Layout — grid de dashboard con sidebar

```css
.app-shell {
  display: grid;
  grid-template-columns: 240px 1fr;
  min-height: 100vh;
  background: var(--color-surface-app);
}
.sidebar {
  background: var(--color-surface-card);
  border-right: 1px solid var(--color-border-default);
  padding: var(--space-4);
}
.sidebar-item {
  display: flex; align-items: center; gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  color: var(--color-text-secondary);
  text-decoration: none;
}
.sidebar-item.active {
  background: var(--color-surface-sunken);
  color: var(--color-action-primary);
  font-weight: 600;
}
.content { padding: var(--space-8); }

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: var(--space-4);
  margin-bottom: var(--space-8);
}
```

En mobile (`max-width: 768px`): `.app-shell` colapsa a una columna, sidebar se vuelve barra superior o menú hamburguesa.

---

## 4. Componentes base

**Card de métrica**
```html
<div class="card metric-card">
  <p class="metric-label">Bugs_DEV (Active/New)</p>
  <p class="metric-value">6</p>
</div>
```
```css
.card {
  background: var(--color-surface-card);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  padding: var(--space-5);
}
```

**Botón primario** (nunca usar `<button>` sin clase)
```css
.btn-primary {
  background: var(--color-action-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-sm);
  padding: var(--space-2) var(--space-4);
  font: 600 14px var(--font-sans);
  cursor: pointer;
  transition: background var(--duration, 150ms) ease;
}
.btn-primary:hover { background: var(--color-action-primary-hover); }
```

**Badge de estado/severidad** — nunca texto plano en una celda de tabla para un estado
```html
<span class="badge badge-high">2 - High</span>
```
```css
.badge {
  display: inline-flex; align-items: center;
  padding: 2px var(--space-2);
  border-radius: var(--radius-sm);
  font: 600 12px var(--font-sans);
}
.badge-critical { color: var(--color-status-critical); background: color-mix(in srgb, var(--color-status-critical) 12%, white); }
.badge-high     { color: var(--color-status-high);     background: color-mix(in srgb, var(--color-status-high) 12%, white); }
.badge-medium   { color: var(--color-status-medium);   background: color-mix(in srgb, var(--color-status-medium) 12%, white); }
.badge-closed   { color: var(--color-status-closed);   background: var(--color-surface-sunken); }
```

**Tabla de datos**
```css
table { width: 100%; border-collapse: collapse; background: var(--color-surface-card); border-radius: var(--radius-md); overflow: hidden; }
th {
  text-align: left; padding: var(--space-3) var(--space-4);
  font: 600 12px var(--font-sans); text-transform: uppercase; letter-spacing: .04em;
  color: var(--color-text-secondary); background: var(--color-surface-sunken);
}
td { padding: var(--space-3) var(--space-4); border-top: 1px solid var(--color-border-default); }
tr:hover td { background: var(--color-surface-sunken); }
```

**Select de filtro** (estilizar, nunca dejar el nativo del SO)
```css
select {
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-sm);
  padding: var(--space-2) var(--space-3);
  font: 14px var(--font-sans);
  background: var(--color-surface-card);
  color: var(--color-text-primary);
}
select:focus { outline: none; border-color: var(--color-action-primary); box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-action-primary) 20%, transparent); }
```

---

## ❌ Qué NO hacer

- No dejar el link `<a>` con el azul/morado por defecto del navegador — siempre `color: var(--color-text-link); text-decoration: none;` con hover explícito.
- No usar `<select>`, `<table>`, `<button>` sin clase — el estilo del navegador/SO es el primer indicador de "no diseñado".
- No escribir estados (Closed, Critical, High) como texto plano — siempre badge con color semántico.
- No usar sombras o bordes por defecto de un framework CSS de terceros (Bootstrap, Bulma) — está prohibido por `CLAUDE.md`.
- No mezclar `style="..."` inline con el archivo CSS — todo el estilo vive en `tokens.css` + `styles.css`.

---

## Checklist antes de dar por terminada una página HTML standalone

- [ ] Existe `tokens.css` con al menos superficie, texto, borde, acción y estados semánticos
- [ ] Ningún color hex fuera de `tokens.css`
- [ ] Hay jerarquía tipográfica clara (eyebrow/H1/H2/body) definida en CSS, no heredada del navegador
- [ ] Cards, tablas, badges y selects tienen clase propia — cero elementos nativos sin estilizar
- [ ] Los estados (severidad, status) usan la escala de color semántica, no texto plano
- [ ] La vista es usable en una ventana de ~1000px sin scroll horizontal inesperado
