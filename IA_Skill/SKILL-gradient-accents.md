---
name: vanilla-gradient-accents
description: Apply restrained CSS gradient accents to HTML and JavaScript interfaces without a framework or build step.
---

# Gradientes para HTML/JS vanilla

Úsala solo para un CTA primario o un hero de marketing en una interfaz HTML/CSS/JS vanilla. No requiere npm, framework ni estilos inline.

## Límites visuales

- En dashboards, formularios y paneles internos, usar únicamente un gradiente sutil de dos tonos de la misma familia en el CTA principal.
- Reservar los mesh gradients para heroes de landing o marketing; nunca para fondos de tablas, dashboards o administración.
- Mantener contraste WCAG AA en texto, foco y estado deshabilitado. El gradiente no sustituye un foco visible.
- Centralizar colores y sombras en `tokens.css`; aplicar las clases en `styles.css`.

## Patrón de CTA

```css
:root {
  --gradient-action-primary: linear-gradient(135deg, #2563eb, #4f46e5);
  --gradient-action-primary-hover: linear-gradient(135deg, #1d4ed8, #4338ca);
  --shadow-action-primary: 0 4px 14px rgb(37 99 235 / 32%);
}

.btn-primary {
  background: var(--gradient-action-primary);
  border: 0;
  border-radius: var(--radius-sm, 8px);
  box-shadow: var(--shadow-action-primary);
  color: #fff;
}

.btn-primary:hover { background: var(--gradient-action-primary-hover); }
.btn-primary:focus-visible { outline: 3px solid rgb(37 99 235 / 45%); outline-offset: 3px; }
.btn-primary:disabled { background: #94a3b8; box-shadow: none; cursor: not-allowed; }
```

Usar un fallback `background-color` cuando el diseño lo requiera y comprobar los estados hover, focus y disabled antes de entregar.
