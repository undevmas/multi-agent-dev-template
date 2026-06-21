---
name: frontend-design/layout-spacing-system
description: >
  Define el sistema de layout y espaciado para dashboards y PWA: grid de página,
  densidad de información, sidebar + contenido principal, scroll areas, y la
  escala de spacing aplicada a componentes. Úsala para construir layouts que
  no colapsen en mobile y que soporten múltiples modos de densidad.
stack: Angular 17+ · React 18+ · CSS Grid · CSS Custom Properties · Flexbox
contexts: Dashboard · Admin panel · PWA · Formularios multi-paso
---

# SKILL: Layout & Spacing System — Ritmo y Densidad

## Cuándo usar esta skill

Actívala cuando la spec incluya:
- Vistas con múltiples secciones o paneles (dashboard con métricas + tabla + sidebar)
- Formularios con más de 3 campos o flujos multi-paso
- Tablas de administración con acciones por fila
- Navegación principal (sidebar, top nav, bottom nav en mobile)
- Cualquier layout que deba funcionar en mobile (PWA) y desktop (admin)

---

## Cómo leer la spec para extraer señales de layout

| Señal en la spec | Necesidad de layout |
|---|---|
| Múltiples actores con vistas diferentes (User, Admin, SystemAdmin) | Layout con sidebar de navegación + área de contenido |
| Flujo de 2 pasos (initiate → confirm) | Layout de wizard: header de progreso + contenido centrado + footer de acciones |
| Tabla de datos con acciones por fila | Layout de tabla con columnas fijas y scroll horizontal en mobile |
| Métricas de estado (totpEnrolled, mfaRequired) | Grid de cards de métricas + sección de detalle |
| Formulario de código TOTP de 6 dígitos | Layout centrado, ancho máximo restringido (formulario ≤ 400px) |
| Panel de administración con lista de usuarios | Layout de dos columnas: filtros sidebar + lista principal |

---

## Sistema de layout — estructura base

### 1. Layout de aplicación (App Shell)

```css
/* app-shell.css */
.app-shell {
  display: grid;
  grid-template-areas:
    "sidebar topbar"
    "sidebar content";
  grid-template-columns: var(--sidebar-width, 260px) 1fr;
  grid-template-rows: var(--topbar-height, 56px) 1fr;
  height: 100dvh; /* dvh respeta la barra de navegación mobile */
  overflow: hidden;
  background: var(--color-surface-app);
}

.app-shell__sidebar  { grid-area: sidebar;  overflow-y: auto; }
.app-shell__topbar   { grid-area: topbar;   position: sticky; top: 0; z-index: var(--z-sticky); }
.app-shell__content  {
  grid-area: content;
  overflow-y: auto;
  overflow-x: hidden;
  padding: var(--space-6);
  /* Scroll suave en iOS */
  -webkit-overflow-scrolling: touch;
}

/* Mobile: sidebar se convierte en drawer */
@media (max-width: 768px) {
  .app-shell {
    grid-template-areas:
      "topbar"
      "content";
    grid-template-columns: 1fr;
    grid-template-rows: var(--topbar-height, 56px) 1fr;
  }
  .app-shell__sidebar {
    position: fixed;
    inset: 0;
    z-index: var(--z-overlay);
    transform: translateX(-100%);
    transition: transform var(--duration-normal) var(--ease-standard);

    &.is-open { transform: translateX(0); }
  }
}
```

### 2. Grid de contenido (dentro de `app-shell__content`)

```css
/* content-grid.css */
.content-grid {
  display: grid;
  gap: var(--space-6);
  max-width: 1280px;
  margin-inline: auto;
  width: 100%;
}

/* Grid de métricas: 4 columnas → 2 → 1 */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-4);

  @media (max-width: 1024px) { grid-template-columns: repeat(2, 1fr); }
  @media (max-width: 640px)  { grid-template-columns: 1fr; }
}

/* Grid 2/3 + 1/3 (tabla principal + panel lateral) */
.split-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: var(--space-6);
  align-items: start;

  @media (max-width: 1024px) { grid-template-columns: 1fr; }
}
```

### 3. Layout de wizard / flujo multi-paso

```css
/* wizard-layout.css */
.wizard {
  display: flex;
  flex-direction: column;
  min-height: 100%;
}

.wizard__progress {
  padding: var(--space-4) var(--space-6);
  border-bottom: 1px solid var(--color-border-default);
  background: var(--color-surface-card);
  position: sticky;
  top: 0;
  z-index: var(--z-raised);
}

.wizard__body {
  flex: 1;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: var(--space-8) var(--space-4);
}

.wizard__card {
  width: 100%;
  max-width: 480px; /* formularios de auth/seguridad: máx 480px */
  background: var(--color-surface-card);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  padding: var(--space-8);

  @media (max-width: 640px) {
    padding: var(--space-6) var(--space-4);
    border-radius: var(--radius-md);
    box-shadow: none;
    border: 1px solid var(--color-border-default);
  }
}

.wizard__footer {
  padding: var(--space-4) var(--space-6);
  border-top: 1px solid var(--color-border-default);
  background: var(--color-surface-card);
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);

  @media (max-width: 640px) {
    flex-direction: column-reverse;
  }
}
```

---

## Modos de densidad (dashboard admin)

Los dashboards de admin tienen 3 modos de densidad según el tipo de usuario:

```css
/* density.css */
:root {
  /* Comfortable: default para la mayoría */
  --density-row-height:  52px;
  --density-cell-pad-v:  var(--space-3);
  --density-cell-pad-h:  var(--space-4);
  --density-gap:         var(--space-4);
}

[data-density="compact"] {
  --density-row-height:  36px;
  --density-cell-pad-v:  var(--space-2);
  --density-cell-pad-h:  var(--space-3);
  --density-gap:         var(--space-2);
}

[data-density="spacious"] {
  --density-row-height:  68px;
  --density-cell-pad-v:  var(--space-4);
  --density-cell-pad-h:  var(--space-6);
  --density-gap:         var(--space-6);
}

/* Aplicación en tabla */
.data-table td, .data-table th {
  padding: var(--density-cell-pad-v) var(--density-cell-pad-h);
  height: var(--density-row-height);
}

/* Aplicación en listas */
.list-item { gap: var(--density-gap); }
```

---

## Reglas de espaciado

### Cuándo usar cada propiedad

| Propiedad | Cuándo usarla |
|---|---|
| `gap` | Entre elementos hermanos en grid/flex — nunca entre elemento y su contenedor |
| `padding` | Espacio interior entre el contenedor y su contenido |
| `margin` | Espacio exterior — solo para separar secciones semánticamente distintas |
| `margin-inline: auto` | Centrar un elemento en su contenedor |

### Escala de spacing aplicada por contexto

| Contexto | Valor | Token |
|---|---|---|
| Entre icono y texto inline | 4px | `--space-1` |
| Entre label y input | 8px | `--space-2` |
| Entre campos en un formulario | 16px | `--space-4` |
| Padding interior de card | 24px | `--space-6` |
| Entre cards en un grid | 16–24px | `--space-4` / `--space-6` |
| Entre secciones de página | 32px | `--space-8` |
| Padding lateral de página en desktop | 24px | `--space-6` |
| Padding lateral de página en mobile | 16px | `--space-4` |
| Altura de topbar | 56px | hardcoded en app-shell |
| Ancho de sidebar | 260px | `--sidebar-width` variable |

---

## Tabla de administración — layout responsive

```css
/* data-table.css */
.table-container {
  background: var(--color-surface-card);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  overflow: hidden;
}

/* Scroll horizontal en mobile sin romper el layout */
.table-scroll-wrapper {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  /* Indica al usuario que hay más contenido */
  background:
    linear-gradient(to right, var(--color-surface-card) 30%, rgba(255,255,255,0)),
    linear-gradient(to right, rgba(255,255,255,0), var(--color-surface-card) 70%)
    0 100%;
  background-attachment: local, scroll;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 600px; /* fuerza scroll antes de colapsar columnas */
}

.data-table th {
  text-align: left;
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  letter-spacing: var(--tracking-wider);
  text-transform: uppercase;
  color: var(--color-text-secondary);
  background: var(--color-surface-sunken);
  border-bottom: 1px solid var(--color-border-default);
  white-space: nowrap;
  user-select: none;
}

.data-table td {
  border-bottom: 1px solid var(--color-border-default);
  vertical-align: middle;
}

.data-table tr:last-child td { border-bottom: none; }

.data-table tr:hover td {
  background: var(--color-surface-sunken);
  transition: background var(--duration-fast) var(--ease-standard);
}
```

---

## Angular — Layout component

```typescript
// dashboard-layout.component.ts
@Component({
  selector: 'app-dashboard-layout',
  standalone: true,
  template: `
    <div class="app-shell" [attr.data-density]="density()">
      <aside class="app-shell__sidebar" [class.is-open]="sidebarOpen()">
        <ng-content select="[slot=sidebar]" />
      </aside>
      <header class="app-shell__topbar">
        <ng-content select="[slot=topbar]" />
      </header>
      <main class="app-shell__content" id="main-content" tabindex="-1">
        <ng-content />
      </main>
    </div>
  `,
})
export class DashboardLayoutComponent {
  density = signal<'compact' | 'comfortable' | 'spacious'>('comfortable');
  sidebarOpen = signal(false);

  toggleSidebar() { this.sidebarOpen.update(v => !v); }
}
```

---

## ❌ Qué NO hacer

- **No usar `height: 100vh` en páginas PWA.** Usar `100dvh` para que respete la barra de navegación del navegador mobile.
- **No usar `margin` para separar elementos dentro de un flex/grid container.** Usar `gap`.
- **No hardcodear `width: 260px` en el sidebar dentro de los componentes hijos.** El ancho del sidebar está en `--sidebar-width` — los hijos no saben su contexto.
- **No usar `position: absolute` para posicionar elementos dentro de un flujo de layout.** Solo para overlays, tooltips, y dropdowns.
- **No crear layouts con tablas HTML (`<table>`) para alinear formularios.** Usar CSS Grid.
- **No hacer scroll en `<body>` en un dashboard.** El scroll debe estar en `app-shell__content`, no en el body — de lo contrario el sidebar también scrollea.
- **No omitir `max-width` en formularios de autenticación.** Un formulario de 6 dígitos TOTP en pantalla completa 1440px es inutilizable.

---

## Checklist de verificación

- [ ] El app shell usa `100dvh` (no `100vh`)
- [ ] El sidebar se convierte en drawer en mobile con `position: fixed` y transición slide
- [ ] Los formularios de auth/seguridad tienen `max-width: 480px` y están centrados
- [ ] Las tablas de admin tienen `overflow-x: auto` en su wrapper para scroll horizontal en mobile
- [ ] El sistema de densidad está implementado con `data-density` en el root del layout
- [ ] El espaciado entre elementos usa `gap` en flex/grid y `padding` para contenido interno
- [ ] Los `main` de contenido tienen `id="main-content"` y `tabindex="-1"` para skip links (a11y)
- [ ] Ningún componente hijo asume el ancho disponible — todos son fluidos dentro de su contexto
