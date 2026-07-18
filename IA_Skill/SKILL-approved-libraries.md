# SKILL — Librerías de Terceros Aprobadas

## Cuándo usar esta skill

Antes de agregar cualquier dependencia de UI/animación/gráficas/iconos a un
proyecto del stack (Angular, React o HTML vanilla). Si la librería que se
necesita no está en esta lista, no se asume que está aprobada — se pregunta
antes de instalarla.

Regla de evaluación para cualquier librería nueva no listada aquí: ¿tiene
tipos TypeScript oficiales?, ¿tuvo commits en los últimos 6 meses?, ¿su
documentación vive en un solo lugar consistente? Si las tres son sí, es
candidata razonable — de lo contrario, preguntar antes de sumarla.

---

## Tabla resumen por track

| Categoría | Angular | React | HTML vanilla |
|---|---|---|---|
| Componentes | CDK (3 tipos: utilidades puras, primitivos headless, híbridos con Material) — ver detalle abajo | Radix UI (headless) + shadcn/ui | Componentes propios — ver `SKILL-frontend-design.md` |
| Iconos | Lucide (`lucide-angular`) | Lucide (`lucide-react`) | Lucide (SVG inline) |
| CSS | SCSS + tokens (`SKILL-design-tokens.md`) | Tailwind CSS (vía tokens) | CSS puro (`SKILL-frontend-design.md`) — sin build step |
| Gráficas simples | Chart.js | Chart.js / Recharts | Chart.js |
| Gráficas complejas | ECharts | ECharts | ECharts |
| Animación | `@angular/animations` + CSS (`SKILL-animation-microinteractions.md`) | Motion (`motion.dev`) | CSS (`SKILL-animation-microinteractions.md`) — Motion opcional si el proyecto no es trivial |

---

## Componentes

### Angular — CDK + Material híbrido (no Material puro, no CDK puro)

Decisión de arquitectura para este template: **CDK para todo lo que es
estructura sin necesidad de estado UI complejo** (tabla, menús, overlays) +
**Angular Material solo para los widgets que ya traen lógica de interacción
resuelta** (paginador, ordenamiento, validación de formularios), siempre
re-temeados con `mat.theme()` — nunca aceptando la paleta M3 de fábrica.

Ver `SKILL-angular-data-table-pattern.md` para el patrón completo de tabla
server-side con esta combinación.

#### Catálogo completo de `@angular/cdk` — 3 categorías, no una lista plana

**Tipo 1 — Utilidades puras (cero markup, cero estilo, usar siempre sin re-temear nada):**

| Módulo | Para qué sirve |
|---|---|
| `a11y` | Focus trap, LiveAnnouncer, FocusMonitor — ver `SKILL-accessibility-a11y.md` |
| `bidi` | Detectar/reaccionar a layout LTR/RTL |
| `clipboard` | Copiar al portapapeles del sistema |
| `coercion` | Normalizar `@Input()` (string→boolean, string→number) |
| `collections` | `SelectionModel` y utilidades de colecciones |
| `testing` | Component test harnesses — usar en specs, ver `SKILL-angular-test-frameworks.md` |
| `layout` | `BreakpointObserver` — responsive vía JS cuando CSS no basta |
| `observers` | `ContentObserver` — reaccionar a cambios de contenido proyectado |
| `platform` | Detectar navegador/SO (para workarounds puntuales, no para decisiones de diseño) |
| `portal` | Renderizar contenido en un destino distinto del árbol (base de `overlay`) |
| `scrolling` | `CdkVirtualScrollViewport` — listas largas sin renderizar todo el DOM |
| `text-field` | `cdkTextareaAutosize` — textarea que crece con el contenido |

Ninguno de estos requiere `SKILL-frontend-design.md` porque no dibujan
nada — son lógica pura. Se usan libremente, sin pasar por el checklist de
re-temeado.

**Tipo 2 — Primitivos con estructura, sin estilo (headless real, mismo espíritu que Radix en React):**

| Módulo | Uso típico | Estilo |
|---|---|---|
| `accordion` | Secciones expandibles (FAQ, filtros colapsables) | 100% tuyo, tokens de `SKILL-frontend-design.md` |
| `dialog` | Modales | 100% tuyo — ver patrón de `cdkTrapFocus` ya en `SKILL-accessibility-a11y.md` |
| `drag-drop` | Reordenar listas/kanban | 100% tuyo — no tiene equivalente en Material que valga la pena preferir |
| `listbox` | Select custom, combobox | 100% tuyo |
| `menu` | Dropdowns de navegación/acciones | 100% tuyo — ya documentado en `SKILL-angular-data-table-pattern.md` |
| `overlay` | Base de tooltips, popovers, dialogs flotantes | 100% tuyo |
| `tree` | Árboles jerárquicos (ej. estructura de permisos/roles) | 100% tuyo — preferir sobre `mat-tree` por la misma razón que `CdkTable` sobre `mat-table` |

Regla para estos: van directo con tus tokens, sin necesidad de re-temear
nada de Material — son el equivalente exacto de usar Radix en React.

**Tipo 3 — Casos híbridos (CDK + Material re-temeado, solo cuando Material resuelve algo caro de reconstruir):**

| Módulo | Cuándo sí usar el widget de Material | Cuándo quedarse en CDK puro |
|---|---|---|
| `table` + `MatSort`/`MatPaginator` | Server-side con paginación/ordenamiento — ver `SKILL-angular-data-table-pattern.md` | Tabla simple sin paginar: `CdkTable` solo |
| `stepper` | Wizard multi-step con validación de formulario integrada entre pasos | Flujo de pasos simple sin validación cruzada: construir con CSS + estado propio |

En ambos, si se usa la pieza de Material, se re-temea con `--mat-sys-*`
(ver `SKILL-angular-data-table-pattern.md`), nunca se acepta el look M3
de fábrica.

### React — Radix UI (headless) + shadcn/ui

Radix son primitivos sin estilo — el agente los envuelve con las clases de
Tailwind/tokens del proyecto, sin pelear contra un estilo de fábrica.
`shadcn/ui` genera el componente y lo copia al repo (no vive en
`node_modules` como caja negra), así que el agente puede leer y modificar
el código directo.

```bash
npx shadcn@latest add dialog
# el componente queda en src/components/ui/dialog.tsx, editable directo
```

### Vanilla — componentes propios

No se instala ninguna librería de componentes en HTML/CSS/JS sin build
step. Ver `SKILL-frontend-design.md` para los patrones de card, badge,
tabla, select, etc.

---

## Accesibilidad — Angular CDK a11y

`@angular/cdk/a11y` **no es una librería de componentes** — son directivas
de comportamiento sin markup ni estilos propios, que se aplican sobre HTML
ya existente:

- `cdkTrapFocus` — atrapa el foco dentro de un contenedor (modales, drawers)
- `LiveAnnouncer` — anuncia mensajes a lectores de pantalla vía `aria-live`
- `FocusMonitor` — detecta si el foco vino de teclado o mouse, para mostrar
  el anillo de foco solo cuando corresponde
- `A11yModule` — agrupa las anteriores

Esta es la implementación de referencia para el track Angular de
`SKILL-accessibility-a11y.md` — no se documenta aparte, se usa desde ahí.

---

## Iconos — Lucide (todos los tracks)

```bash
npm install lucide-react      # React
npm install lucide-angular    # Angular
```
Vanilla: SVG inline copiado directo del sitio de Lucide, sin dependencia de
paquete (evita cualquier build step).

No usar: Font Awesome (peso innecesario si solo se usan unos íconos,
además requiere @import de CSS de terceros), Material Icons (asociación
visual directa con Google, ver `SKILL-visual-identity-override.md`).

---

## Gráficas — Chart.js por defecto, ECharts para casos complejos

**Chart.js**: donut, barras, línea, pie — el 90% de los dashboards de este
template (ver `bugs.html`, `panorama-general.html`).

**ECharts**: solo cuando el caso lo justifique — mapas, sankey, treemap,
dashboards con muchas series simultáneas. Más pesado en bundle, no usar
"por defecto" para gráficos simples.

### Puente de tokens para ECharts (obligatorio)

ECharts renderiza en `<canvas>` y **no puede leer `var(--color-*)`
directamente** en su objeto `option` — necesita el valor resuelto. Sin este
puente, el agente termina hardcodeando colores hex dentro del `option`,
rompiendo la regla de "todo color viene de tokens".

```js
function token(name) {
  return getComputedStyle(document.documentElement)
    .getPropertyValue(name)
    .trim();
}

// uso:
option.color = [
  token('--color-status-critical'),
  token('--color-status-high'),
  token('--primitive-blue-500'),
];
```

Chart.js no tiene este problema — sus opciones aceptan directamente
`getComputedStyle(...)` de la misma forma, pero al ser gráficos más
simples rara vez hace falta ese nivel de indirección; aun así, aplica el
mismo puente si se necesita.

---

## Animación — Motion solo en React/vanilla, NUNCA en Angular

**Motion** (`motion.dev`, antes Framer Motion) es válido para React y HTML
vanilla — API declarativa moderna, sin legado de jQuery, buen soporte TS.

**Prohibido en Angular.** Angular ya tiene su propio sistema de animaciones
(`@angular/animations`) integrado al ciclo de vida del componente y al
change detection. Meter Motion en un proyecto Angular crea dos sistemas de
animación compitiendo sin criterio claro de cuál usar para qué — sería el
mismo tipo de inconsistencia que ya se corrigió con el routing roto de
`SKILL-frontend-design.md`. En Angular: `@angular/animations` +
`SKILL-animation-microinteractions.md` (CSS puro, funciona igual en los
tres tracks).

---

## CSS — Tailwind (Angular/React) vs. CSS puro (vanilla) — no compiten

No es "Tailwind O CSS puro" — es un track por proyecto, ambos leen la
misma fuente de tokens (`SKILL-design-tokens.md` para Angular/React,
`SKILL-frontend-design.md` para vanilla). Tailwind no define sus propios
colores, apunta a `var(--color-*)` vía `tailwind.config.js`.

Tailwind necesita build step o CDN JIT — por eso no se usa en los
dashboards vanilla de ReporteadorV2 (`SKILL-frontend-design.md` prohíbe
explícitamente build step ahí). No es un conflicto de diseño, es un
conflicto de infraestructura: van en carriles separados por proyecto, no
mezclados dentro del mismo.

---

## ❌ Prohibido en cualquier track

- **jQuery** — y cualquier plugin que lo requiera como dependencia
  (jQuery UI, plugins de Bootstrap 4 o anteriores que aún dependen de él)
- **Bootstrap** (ya prohibido en `CLAUDE.md`) — su JS de versiones ≤4
  arrastra jQuery; incluso en v5 el resultado visual es genérico por
  default (ver el síntoma documentado en `SKILL-frontend-design.md`)
- **Materialize CSS** — sin mantenimiento activo, alto riesgo de que un
  agente alucine una API vieja
- **Semantic UI** — abandonado, mismo riesgo
- **Font Awesome** como dependencia de paquete — usar Lucide

---

## Checklist antes de sumar una librería nueva no listada aquí

- [ ] Tiene tipos TypeScript oficiales (no solo `@types/` de la comunidad, desactualizados)
- [ ] Tuvo commits en los últimos 6 meses
- [ ] Su documentación vive en un solo lugar consistente, no wikis fragmentados
- [ ] No requiere jQuery ni ningún paquete de esta lista de prohibidos como dependencia
- [ ] Se preguntó al usuario antes de instalarla, si no está en la tabla resumen
