---
name: frontend-design/design-tokens
description: >
  Define y aplica el sistema de tokens de diseño como única fuente de verdad
  para color, espaciado, tipografía, radio y sombras. Úsala antes de escribir
  cualquier estilo en Angular o React para garantizar consistencia entre
  componentes y soporte nativo de modo oscuro/theming.
stack: Angular 17+ · React 18+ · CSS Custom Properties · Tailwind (opcional)
contexts: PWA · Dashboard · Admin panel
---

# SKILL: Design Tokens — Base del Sistema

## Cuándo usar esta skill

Actívala cuando la spec (`.md`) o la spec técnica (`.spec.md`) mencione:
- Más de una pantalla o vista
- Modo oscuro, theming por tenant, o branding personalizable
- Componentes que se reutilizan en múltiples features

Actívala también al inicio de cualquier feature nueva antes de escribir el primer selector CSS.

---

## Cómo leer la spec para extraer señales de tokens

La spec no define tokens, pero sí da señales sobre qué necesitas:

| Señal en la spec | Token que necesitas definir |
|---|---|
| Estados: `IsConfirmed`, `IsDeleted`, `mfaRequired` | `color-status-success`, `color-status-warning`, `color-status-error` |
| Acciones destructivas (`DELETE`, `revoke`) | `color-action-danger`, `color-action-danger-hover` |
| Flujos de múltiples pasos (enrolamiento en 2 pasos) | `color-step-active`, `color-step-complete`, `color-step-pending` |
| Respuestas HTTP 202, 400, 401, 403, 404 | `color-feedback-info`, `color-feedback-error`, `color-feedback-warning` |
| Entidades sensibles (tokens, secretos, credenciales) | `color-surface-sensitive` para destacar visualmente datos críticos |

---

## Sistema de tokens — estructura obligatoria

### 1. Variables CSS (fuente de verdad — framework-agnostic)

```css
/* tokens.css — importar en el root de la app */
:root {
  /* ── Primitivos (nunca usar directamente en componentes) ── */
  --primitive-blue-50:  #eff6ff;
  --primitive-blue-500: #3b82f6;
  --primitive-blue-600: #2563eb;
  --primitive-blue-900: #1e3a8a;

  --primitive-red-400:  #f87171;
  --primitive-red-500:  #ef4444;
  --primitive-red-600:  #dc2626;

  --primitive-green-400: #4ade80;
  --primitive-green-500: #22c55e;

  --primitive-yellow-400: #facc15;
  --primitive-yellow-500: #eab308;

  --primitive-neutral-0:   #ffffff;
  --primitive-neutral-50:  #f8fafc;
  --primitive-neutral-100: #f1f5f9;
  --primitive-neutral-200: #e2e8f0;
  --primitive-neutral-300: #cbd5e1;
  --primitive-neutral-400: #94a3b8;
  --primitive-neutral-500: #64748b;
  --primitive-neutral-600: #475569;
  --primitive-neutral-700: #334155;
  --primitive-neutral-800: #1e293b;
  --primitive-neutral-900: #0f172a;
  --primitive-neutral-950: #020617;

  /* ── Semánticos — modo claro ── */
  /* Superficies */
  --color-surface-app:        var(--primitive-neutral-50);
  --color-surface-card:       var(--primitive-neutral-0);
  --color-surface-overlay:    rgba(15, 23, 42, 0.5);
  --color-surface-sensitive:  #fefce8; /* datos críticos: tokens, secretos */
  --color-surface-sunken:     var(--primitive-neutral-100);

  /* Texto */
  --color-text-primary:   var(--primitive-neutral-900);
  --color-text-secondary: var(--primitive-neutral-500);
  --color-text-disabled:  var(--primitive-neutral-300);
  --color-text-inverse:   var(--primitive-neutral-0);
  --color-text-link:      var(--primitive-blue-600);

  /* Bordes */
  --color-border-default:  var(--primitive-neutral-200);
  --color-border-strong:   var(--primitive-neutral-300);
  --color-border-focus:    var(--primitive-blue-500);
  --color-border-error:    var(--primitive-red-500);

  /* Acciones */
  --color-action-primary:       var(--primitive-blue-600);
  --color-action-primary-hover: var(--primitive-blue-500);
  --color-action-danger:        var(--primitive-red-600);
  --color-action-danger-hover:  var(--primitive-red-500);

  /* Feedback / estados */
  --color-feedback-success: var(--primitive-green-500);
  --color-feedback-warning: var(--primitive-yellow-500);
  --color-feedback-error:   var(--primitive-red-500);
  --color-feedback-info:    var(--primitive-blue-500);

  /* Feedback — fondos suaves */
  --color-feedback-success-bg: #f0fdf4;
  --color-feedback-warning-bg: #fefce8;
  --color-feedback-error-bg:   #fef2f2;
  --color-feedback-info-bg:    #eff6ff;

  /* Espaciado — escala 4px */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  20px;
  --space-6:  24px;
  --space-8:  32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;
  --space-20: 80px;

  /* Radio */
  --radius-sm:   4px;
  --radius-md:   8px;
  --radius-lg:   12px;
  --radius-xl:   16px;
  --radius-full: 9999px;

  /* Sombras semánticas */
  --shadow-card:   0 1px 3px rgba(0,0,0,.10), 0 1px 2px rgba(0,0,0,.06);
  --shadow-modal:  0 10px 25px rgba(0,0,0,.15), 0 4px 6px rgba(0,0,0,.08);
  --shadow-raised: 0 4px 12px rgba(0,0,0,.12);
  --shadow-focus:  0 0 0 3px rgba(59,130,246,.4);

  /* Z-index */
  --z-base:    0;
  --z-raised:  10;
  --z-sticky:  100;
  --z-overlay: 200;
  --z-modal:   300;
  --z-toast:   400;

  /* Transiciones */
  --duration-fast:   100ms;
  --duration-normal: 200ms;
  --duration-slow:   300ms;
  --ease-standard:   cubic-bezier(0.4, 0, 0.2, 1);
  --ease-enter:      cubic-bezier(0.0, 0, 0.2, 1);
  --ease-exit:       cubic-bezier(0.4, 0, 1, 1);
}

/* ── Modo oscuro ── */
[data-theme="dark"],
.dark {
  --color-surface-app:        var(--primitive-neutral-950);
  --color-surface-card:       var(--primitive-neutral-900);
  --color-surface-overlay:    rgba(0, 0, 0, 0.7);
  --color-surface-sensitive:  #2d2b1a;
  --color-surface-sunken:     var(--primitive-neutral-800);

  --color-text-primary:   var(--primitive-neutral-50);
  --color-text-secondary: var(--primitive-neutral-400);
  --color-text-disabled:  var(--primitive-neutral-600);
  --color-text-inverse:   var(--primitive-neutral-900);
  --color-text-link:      var(--primitive-blue-400);

  --color-border-default: var(--primitive-neutral-700);
  --color-border-strong:  var(--primitive-neutral-600);

  --color-feedback-success-bg: #052e16;
  --color-feedback-warning-bg: #1c1917;
  --color-feedback-error-bg:   #1c0505;
  --color-feedback-info-bg:    #0c1e3c;

  --shadow-card:   0 1px 3px rgba(0,0,0,.40);
  --shadow-modal:  0 10px 25px rgba(0,0,0,.60);
  --shadow-raised: 0 4px 12px rgba(0,0,0,.40);
}
```

### 2. Integración Angular — SCSS

```scss
// styles/_tokens.scss — importar en angular.json "styles"
// No redefinir los tokens aquí; solo crear aliases SCSS si es necesario
// para integración con librerías que aceptan variables SCSS.

// Ejemplo: Angular Material custom theme que consume los tokens CSS
@use '@angular/material' as mat;

$primary: mat.define-palette((
  500: var(--color-action-primary),   // uso en tema Material
  contrast: (500: var(--color-text-inverse))
));
```

### 3. Integración React — Tailwind

```js
// tailwind.config.js
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        surface: {
          app:       'var(--color-surface-app)',
          card:      'var(--color-surface-card)',
          sensitive: 'var(--color-surface-sensitive)',
          sunken:    'var(--color-surface-sunken)',
        },
        text: {
          primary:   'var(--color-text-primary)',
          secondary: 'var(--color-text-secondary)',
          disabled:  'var(--color-text-disabled)',
          link:      'var(--color-text-link)',
        },
        border: {
          default: 'var(--color-border-default)',
          focus:   'var(--color-border-focus)',
          error:   'var(--color-border-error)',
        },
        action: {
          primary:       'var(--color-action-primary)',
          'primary-hover': 'var(--color-action-primary-hover)',
          danger:        'var(--color-action-danger)',
        },
        feedback: {
          success: 'var(--color-feedback-success)',
          warning: 'var(--color-feedback-warning)',
          error:   'var(--color-feedback-error)',
          info:    'var(--color-feedback-info)',
        },
      },
      spacing: {
        1: 'var(--space-1)',
        2: 'var(--space-2)',
        3: 'var(--space-3)',
        4: 'var(--space-4)',
        6: 'var(--space-6)',
        8: 'var(--space-8)',
        12: 'var(--space-12)',
        16: 'var(--space-16)',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
      },
      boxShadow: {
        card:   'var(--shadow-card)',
        modal:  'var(--shadow-modal)',
        raised: 'var(--shadow-raised)',
        focus:  'var(--shadow-focus)',
      },
      transitionDuration: {
        fast:   'var(--duration-fast)',
        normal: 'var(--duration-normal)',
        slow:   'var(--duration-slow)',
      },
    },
  },
}
```

---

## ❌ Qué NO hacer

- **No usar valores hardcoded en componentes.** `color: #3b82f6` está prohibido; usar `color: var(--color-action-primary)`.
- **No usar tokens primitivos en componentes.** `var(--primitive-blue-500)` solo existe para alimentar semánticos. En componentes solo van tokens semánticos.
- **No crear tokens por componente.** `--button-background` no es un token; es un alias innecesario. Los tokens son semánticos, no de componente.
- **No duplicar los tokens en SCSS variables.** Si tienes `$primary-color: #3b82f6` en SCSS y también `--color-action-primary: #3b82f6` en CSS, cualquier cambio requiere actualización en dos lugares.
- **No omitir el modo oscuro al definir un token nuevo.** Todo token semántico debe tener su contraparte en `[data-theme="dark"]`.

---

## Checklist de verificación

Antes de dar por completado el sistema de tokens para una feature:

- [ ] Todos los colores de la UI vienen de tokens semánticos (ningún valor hex directo en componentes)
- [ ] El modo oscuro tiene override para cada token semántico de superficie y texto
- [ ] Los estados de la spec (éxito, error, advertencia, deshabilitado) tienen tokens de feedback asignados
- [ ] Las acciones destructivas identificadas en la spec usan `--color-action-danger`
- [ ] El espaciado usa la escala de 4px (`--space-*`) sin valores intermedios inventados
- [ ] Los datos sensibles (tokens, secretos, códigos) usan `--color-surface-sensitive`
- [ ] La integración con el framework (Angular SCSS / React Tailwind) consume los tokens CSS, no redefine valores
