---
name: frontend-design/responsive-pwa-patterns
description: >
  Define los patrones responsive y PWA-específicos para Angular y React: breakpoints
  semánticos, touch targets, navegación adaptativa, offline states, safe area insets,
  y skeleton screens. Úsala para que la IA genere layouts que funcionen correctamente
  en mobile-first sin sacrificar la experiencia de desktop en dashboards.
stack: Angular 17+ · React 18+ · CSS · PWA (Service Worker) · Web App Manifest
contexts: PWA instalable · Dashboard responsive · Admin panel mobile-friendly
---

# SKILL: Responsive & PWA Patterns — Mobile + PWA

## Cuándo usar esta skill

Actívala cuando la spec mencione:
- PWA instalable o "funciona offline"
- Vistas que el usuario accede desde mobile (autenticación, perfil, MFA)
- Dashboards que también son accesibles en tablet
- Cualquier formulario con inputs (los teclados virtuales cambian el viewport)
- Navegación principal que debe adaptarse entre mobile y desktop

---

## Cómo leer la spec para extraer señales responsive

| Señal en la spec | Patrón responsive necesario |
|---|---|
| Actores que usan la app desde dispositivos variados | Breakpoints semánticos + navegación adaptativa |
| Formulario de código TOTP de 6 dígitos | Input numérico con teclado numérico en mobile (`inputmode="numeric"`) |
| Múltiples User Stories con distintos flujos | Bottom navigation en mobile, sidebar en desktop |
| Admin con tabla de usuarios | Tabla con scroll horizontal en mobile o card view alternativo |
| PWA instalable | Manifest.json + safe area insets para notch/iOS |
| Estado de carga async (HTTP 202 → espera) | Skeleton screen + offline fallback |

---

## Breakpoints semánticos

```css
/* breakpoints.css — NO usar md:/lg: genéricos sin semántica */
:root {
  --bp-mobile:  640px;   /* teléfonos — diseñar para esto primero */
  --bp-tablet:  768px;   /* tablets en portrait, teléfonos landscape */
  --bp-desktop: 1024px;  /* laptops, tablets landscape */
  --bp-wide:    1280px;  /* desktops, monitores */
  --bp-ultra:   1536px;  /* monitores grandes, modo wide dashboard */
}

/* Mixins SCSS (Angular) */
@mixin mobile  { @media (max-width: 639px)  { @content; } }
@mixin tablet  { @media (min-width: 640px) and (max-width: 1023px) { @content; } }
@mixin desktop { @media (min-width: 1024px) { @content; } }
@mixin touch   { @media (hover: none) and (pointer: coarse) { @content; } }

/* Uso: */
.card {
  padding: var(--space-4);
  @include desktop { padding: var(--space-6); }
}
```

```tsx
// React — hook para breakpoint semántico
import { useState, useEffect } from 'react';

type Breakpoint = 'mobile' | 'tablet' | 'desktop' | 'wide';

function useBreakpoint(): Breakpoint {
  const getBreakpoint = (): Breakpoint => {
    const w = window.innerWidth;
    if (w < 640)  return 'mobile';
    if (w < 1024) return 'tablet';
    if (w < 1280) return 'desktop';
    return 'wide';
  };

  const [bp, setBp] = useState<Breakpoint>(getBreakpoint);

  useEffect(() => {
    const handler = () => setBp(getBreakpoint());
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);

  return bp;
}

// Uso:
// const bp = useBreakpoint();
// if (bp === 'mobile') return <BottomNav />;
// return <Sidebar />;
```

---

## Touch targets (regla obligatoria para PWA)

Todo elemento interactivo debe tener un área mínima de toque de **44×44px** aunque visualmente sea más pequeño:

```css
/* touch-targets.css */
.touch-target {
  /* Técnica: agrandar el área de toque sin cambiar el tamaño visual */
  position: relative;

  &::after {
    content: '';
    position: absolute;
    inset: -8px; /* agranda el área de toque 8px en todas las direcciones */
    min-width: 44px;
    min-height: 44px;
  }
}

/* Para botones pequeños (iconos, toggle) */
.btn-icon {
  min-width: 44px;
  min-height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Regla: nunca un botón de acción menor a 44px en mobile */
@media (max-width: 639px) {
  button, [role="button"], a {
    min-height: 44px;
  }
}
```

---

## Navegación adaptativa

```typescript
// Angular — navegación responsive con signal
@Component({
  selector: 'app-nav',
  standalone: true,
  template: `
    @if (isMobile()) {
      <!-- Bottom Navigation para mobile -->
      <nav class="bottom-nav" aria-label="Navegación principal">
        @for (item of navItems; track item.route) {
          <a [routerLink]="item.route" class="bottom-nav__item"
             [class.active]="isActive(item.route)"
             [attr.aria-current]="isActive(item.route) ? 'page' : null">
            <lucide-icon [name]="item.icon" [size]="22" strokeWidth="1.5" aria-hidden="true" />
            <span class="type-caption">{{ item.label }}</span>
          </a>
        }
      </nav>
    } @else {
      <!-- Sidebar para desktop -->
      <nav class="sidebar-nav" aria-label="Navegación principal">
        <!-- ... -->
      </nav>
    }
  `
})
export class NavComponent {
  isMobile = toSignal(
    fromEvent(window, 'resize').pipe(
      map(() => window.innerWidth < 640),
      startWith(window.innerWidth < 640)
    )
  );
}
```

```css
/* bottom-nav.css */
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: var(--z-sticky);
  display: flex;
  background: var(--color-surface-card);
  border-top: 1px solid var(--color-border-default);

  /* Safe area para iOS (notch bottom) */
  padding-bottom: env(safe-area-inset-bottom, 0);

  &__item {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: var(--space-1);
    padding: var(--space-2) var(--space-1);
    min-height: 56px;
    color: var(--color-text-secondary);
    text-decoration: none;
    transition: color var(--duration-fast) var(--ease-standard);

    &.active {
      color: var(--color-action-primary);
    }

    &:focus-visible {
      outline: none;
      box-shadow: inset var(--shadow-focus);
    }
  }
}
```

---

## Safe area insets (iOS notch + Android gesture bar)

```css
/* safe-area.css — aplicar en el app shell */
.app-shell {
  /* Padding que respeta el notch y gesture bar */
  padding-top: env(safe-area-inset-top, 0);
  padding-bottom: env(safe-area-inset-bottom, 0);
  padding-left: env(safe-area-inset-left, 0);
  padding-right: env(safe-area-inset-right, 0);
}

/* Para el topbar fijo */
.app-shell__topbar {
  padding-top: env(safe-area-inset-top, 0);
  height: calc(var(--topbar-height) + env(safe-area-inset-top, 0));
}

/* Para el bottom nav fijo */
.bottom-nav {
  padding-bottom: env(safe-area-inset-bottom, 0);
}
```

```html
<!-- index.html: meta tag obligatorio para safe area en iOS -->
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

---

## Teclado virtual (el viewport encoge en mobile)

```css
/* Evitar que el layout se rompa cuando aparece el teclado virtual */
.full-height-layout {
  /* dvh (dynamic viewport height) ya incluye este comportamiento en browsers modernos */
  height: 100dvh;

  /* Fallback para browsers sin soporte dvh */
  @supports not (height: 100dvh) {
    height: 100vh;
    height: -webkit-fill-available;
  }
}

/* Para formularios que deben quedar visibles cuando aparece el teclado */
.form-container {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
```

---

## Offline state y estados de red

```typescript
// Angular — servicio de conectividad
@Injectable({ providedIn: 'root' })
export class NetworkStatusService {
  readonly isOnline = toSignal(
    merge(
      fromEvent(window, 'online').pipe(map(() => true)),
      fromEvent(window, 'offline').pipe(map(() => false))
    ).pipe(startWith(navigator.onLine))
  );
}
```

```html
<!-- Banner de offline — siempre en el layout, visible cuando isOnline() es false -->
@if (!networkStatus.isOnline()) {
  <div
    class="offline-banner"
    role="status"
    aria-live="polite"
    aria-label="Sin conexión a internet"
  >
    <lucide-icon name="wifi-off" [size]="16" aria-hidden="true" />
    <span class="type-caption">Sin conexión — algunos datos pueden estar desactualizados</span>
  </div>
}
```

```css
.offline-banner {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  background: var(--color-feedback-warning-bg);
  color: var(--color-feedback-warning);
  border-bottom: 1px solid var(--color-feedback-warning);
}
```

---

## Web App Manifest (PWA instalable)

```json
// public/manifest.json
{
  "name": "JustMicroHarmony",
  "short_name": "JMH",
  "description": "Panel de administración y gestión",
  "start_url": "/",
  "display": "standalone",
  "orientation": "any",
  "background_color": "#020617",
  "theme_color": "#2563EB",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ],
  "screenshots": [],
  "categories": ["productivity", "utilities"]
}
```

```html
<!-- index.html -->
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#2563EB">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<link rel="apple-touch-icon" href="/icons/icon-192.png">
```

---

## Tabla responsive — card view en mobile

```css
/* Para tablas de admin que no caben en mobile */
@media (max-width: 639px) {
  .data-table-responsive {
    /* Ocultar la tabla y mostrar cards equivalentes */
    display: none;
  }

  .data-table-cards {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .data-table-card {
    background: var(--color-surface-card);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    border: 1px solid var(--color-border-default);
    display: grid;
    grid-template-columns: auto 1fr;
    gap: var(--space-2) var(--space-4);

    &__label {
      color: var(--color-text-secondary);
      font-size: var(--text-xs);
      font-weight: var(--font-semibold);
      text-transform: uppercase;
      letter-spacing: var(--tracking-wide);
    }

    &__value { font-size: var(--text-sm); }
  }
}

@media (min-width: 640px) {
  .data-table-cards { display: none; }
}
```

---

## ❌ Qué NO hacer

- **No usar `100vh` en layouts PWA.** En iOS Safari, `100vh` incluye la barra de navegación → usa `100dvh`.
- **No posicionar elementos fijos sin `env(safe-area-inset-*)`.** En iPhone con notch, el contenido queda bajo la dynamic island.
- **No usar `<meta name="viewport">` sin `viewport-fit=cover`** si hay elementos fijos en el borde de la pantalla.
- **No hacer touch targets menores a 44×44px.** En mobile, los botones de icono deben tener área de toque mínima aunque sean visualmente pequeños.
- **No esconder la navegación mobile con solo `display:none`.** Usar el patrón adaptativo que muestra Bottom Nav en mobile y Sidebar en desktop.
- **No usar `resize` en JavaScript para detectar mobile.** Usar `matchMedia` o el hook `useBreakpoint` — es más performante.
- **No mostrar un error 503 genérico cuando la app está offline.** Mostrar el `offline-banner` y los datos cacheados disponibles.

---

## Checklist de verificación

- [ ] El viewport meta tag incluye `viewport-fit=cover`
- [ ] El layout usa `100dvh` (no `100vh`)
- [ ] Los safe area insets están aplicados en topbar y bottom nav
- [ ] Todos los touch targets son ≥ 44×44px en mobile
- [ ] La navegación cambia a Bottom Nav en mobile y Sidebar en desktop
- [ ] El `manifest.json` está completo con íconos en 192 y 512px (incluyendo maskable)
- [ ] Existe un banner de offline que detecta pérdida de red con `aria-live="polite"`
- [ ] Los inputs de código numérico tienen `inputmode="numeric"` (teclado numérico en mobile)
- [ ] Las tablas de admin tienen card view alternativo en mobile o scroll horizontal
- [ ] El formulario de autenticación (máx 480px) no se expande a pantalla completa en desktop
