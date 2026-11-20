---
name: vanilla-animation-microinteractions
description: Add purposeful, accessible CSS micro-interactions to HTML, CSS, and JavaScript interfaces without a framework, npm package, or build step.
---

# Micro-interacciones para HTML/JS vanilla

Úsala solo para interfaces HTML/CSS/JS sin framework cuando el movimiento comunica un cambio de estado, carga, éxito, error, apertura o cierre. No usarla como decoración permanente.

## Reglas

- Implementar con CSS propio y clases que JavaScript agregue o retire; no instalar librerías.
- Usar `transform` y `opacity`; no animar `width`, `height`, `top` ni `left`.
- Duraciones: 100–150 ms para feedback, 200–300 ms para entradas o salidas. No superar 500 ms tras una acción del usuario.
- Incluir siempre `prefers-reduced-motion: reduce` para desactivar transiciones y animaciones no esenciales.
- No retrasar validaciones, navegación ni acciones de seguridad por una animación.

## Patrones permitidos

- Error de campo: una sacudida breve y mensaje visible, sin depender solo del movimiento.
- Carga: skeleton para listas o tablas; spinner breve para una acción puntual.
- Confirmación: `fade` o `scale` discreto para toast, modal o icono de éxito.
- Flujo por pasos: transición horizontal corta que indique avance o retroceso.

## Base obligatoria

```css
:root {
  --duration-fast: 120ms;
  --duration-normal: 220ms;
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Verificar que el estado se entiende sin animación y que el foco permanece en el control que lo requiere.
