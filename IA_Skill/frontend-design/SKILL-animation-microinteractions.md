---
name: frontend-design/animation-microinteractions
description: >
  Define cuándo, cómo y con qué duración animar elementos de la UI en Angular y React.
  Cubre micro-interacciones de componentes, transiciones de estado, feedback de formularios,
  y animaciones de ruta. Úsala para que la IA agregue movimiento con propósito sin
  sobrecargar la interfaz ni dañar la accesibilidad.
stack: Angular 17+ (Animation API) · React 18+ · CSS Transitions · Framer Motion · Animate.css
contexts: PWA · Dashboard · Admin panel · Formularios · Flujos multi-paso
---

# SKILL: Animation & Micro-interactions — Movimiento con Propósito

## Cuándo usar esta skill

Actívala cuando la spec incluya:
- Cambios de estado visibles al usuario (éxito, error, loading, confirmación)
- Flujos multi-paso donde el usuario avanza o retrocede entre pantallas
- Acciones destructivas que requieren confirmación (revocación, eliminación)
- Datos que se cargan asincrónicamente (mientras espera la API)
- Modales, drawers, toasts, o tooltips que aparecen/desaparecen

---

## Cómo leer la spec para extraer señales de animación

| Señal en la spec | Animación necesaria |
|---|---|
| HTTP 202 → espera del usuario → HTTP 200 | Loading state con spinner o skeleton |
| Flujo de 2 pasos (initiate → confirm) | Transición slide entre pasos |
| `errorCode: "TOTP_CODE_INVALID"` | Shake en el campo de input + fade-in del mensaje de error |
| `success: true` en la respuesta | Checkmark animado + fade-in de confirmación |
| Acción destructiva (`DELETE`, revoke) | Dialog de confirmación con backdrop fade + scale-in |
| `mfaRequired: true` → redirige | Fade-out de pantalla de login → fade-in de pantalla de código |
| Notificaciones toast | Slide-in desde arriba/abajo + auto-dismiss con progress |
| Skeleton loading en tabla de admin | Shimmer de izquierda a derecha |

---

## Principios de animación (leer antes de implementar)

| Principio | Regla |
|---|---|
| **Propósito** | Cada animación responde una pregunta: ¿qué cambió? ¿dónde va? ¿qué pasó? |
| **Duración** | UI feedback: 100–150ms. Transiciones: 200–300ms. Entradas de pantalla: 250–400ms. Nunca >500ms para acciones del usuario |
| **Easing** | Entradas: `ease-out` (empieza rápido, frena). Salidas: `ease-in` (empieza lento, acelera). Rebote solo en elementos lúdicos — nunca en formularios de seguridad |
| **Un centro de atención** | Si en un mismo evento animan 5 elementos, el usuario no sabe qué mirar. Elige el elemento más importante |
| **Reduced motion** | Toda animación DEBE respetar `prefers-reduced-motion: reduce` |

---

## Tokens de animación (definidos en design-tokens)

```css
:root {
  --duration-fast:   100ms;
  --duration-normal: 200ms;
  --duration-slow:   300ms;
  --ease-standard:   cubic-bezier(0.4, 0, 0.2, 1);
  --ease-enter:      cubic-bezier(0.0, 0, 0.2, 1);   /* ease-out */
  --ease-exit:       cubic-bezier(0.4, 0, 1.0, 1);   /* ease-in  */
  --ease-bounce:     cubic-bezier(0.34, 1.56, 0.64, 1); /* solo para elementos lúdicos */
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Catálogo de micro-interacciones

### 1. Input shake (error de validación)

```css
/* CSS puro — sin dependencia */
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%       { transform: translateX(-6px); }
  40%       { transform: translateX(6px); }
  60%       { transform: translateX(-4px); }
  80%       { transform: translateX(4px); }
}

.input--error {
  border-color: var(--color-border-error);
  animation: shake var(--duration-slow) var(--ease-standard);
}
```

```typescript
// Angular — agregar/quitar clase con signal
export class OtpInputComponent {
  hasError = signal(false);

  onVerificationFail() {
    this.hasError.set(true);
    setTimeout(() => this.hasError.set(false), 400); // limpia después de la animación
  }
}
// Template: [class.input--error]="hasError()"
```

```tsx
// React — useState + useEffect para limpiar
const [hasError, setHasError] = useState(false);
const triggerError = () => {
  setHasError(true);
  setTimeout(() => setHasError(false), 400);
};
// className={`input ${hasError ? 'input--error' : ''}`}
```

---

### 2. Checkmark de éxito (enrollment confirmado)

```css
@keyframes check-draw {
  0%   { stroke-dashoffset: 50; opacity: 0; }
  50%  { opacity: 1; }
  100% { stroke-dashoffset: 0; }
}

@keyframes circle-scale {
  0%   { transform: scale(0.6); opacity: 0; }
  60%  { transform: scale(1.1); }
  100% { transform: scale(1); opacity: 1; }
}

.success-icon circle {
  animation: circle-scale var(--duration-slow) var(--ease-enter) forwards;
}
.success-icon path {
  stroke-dasharray: 50;
  stroke-dashoffset: 50;
  animation: check-draw var(--duration-slow) var(--ease-standard) 150ms forwards;
}
```

```html
<!-- SVG inline — controla la animación vía CSS -->
<svg class="success-icon" viewBox="0 0 24 24" width="48" height="48">
  <circle cx="12" cy="12" r="10" fill="var(--color-feedback-success)" />
  <path
    d="M7 12l3.5 3.5L17 8"
    stroke="white" stroke-width="2"
    fill="none" stroke-linecap="round" stroke-linejoin="round"
  />
</svg>
```

---

### 3. Transición entre pasos (flujo multi-paso)

```css
/* Angular o CSS puro */
.step-container {
  overflow: hidden;
  position: relative;
}

.step {
  transition: transform var(--duration-slow) var(--ease-standard),
              opacity var(--duration-slow) var(--ease-standard);
}

.step--enter-from-right {
  transform: translateX(40px);
  opacity: 0;
}
.step--enter-active {
  transform: translateX(0);
  opacity: 1;
}
.step--exit-to-left {
  transform: translateX(-40px);
  opacity: 0;
}
```

```typescript
// Angular Animations API — para transiciones de ruta
import { trigger, transition, style, animate, query, group } from '@angular/animations';

export const stepTransition = trigger('stepTransition', [
  transition(':increment', [ // avanza al siguiente paso
    style({ position: 'relative' }),
    query(':enter, :leave', [
      style({ position: 'absolute', width: '100%' })
    ], { optional: true }),
    query(':enter', style({ transform: 'translateX(40px)', opacity: 0 }), { optional: true }),
    group([
      query(':leave', animate('250ms ease-in', style({ transform: 'translateX(-40px)', opacity: 0 })), { optional: true }),
      query(':enter', animate('250ms ease-out', style({ transform: 'translateX(0)', opacity: 1 })), { optional: true }),
    ])
  ]),
  transition(':decrement', [ // retrocede al paso anterior
    // Invertir dirección
  ])
]);
```

```tsx
// React — Framer Motion
import { AnimatePresence, motion } from 'framer-motion';

const stepVariants = {
  enter: (direction: number) => ({
    x: direction > 0 ? 40 : -40,
    opacity: 0,
  }),
  center: { x: 0, opacity: 1 },
  exit: (direction: number) => ({
    x: direction > 0 ? -40 : 40,
    opacity: 0,
  }),
};

function StepFlow({ step, direction }: { step: number; direction: number }) {
  return (
    <AnimatePresence mode="wait" custom={direction}>
      <motion.div
        key={step}
        custom={direction}
        variants={stepVariants}
        initial="enter"
        animate="center"
        exit="exit"
        transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
      >
        {/* contenido del paso actual */}
      </motion.div>
    </AnimatePresence>
  );
}
```

---

### 4. Skeleton loading (tabla de admin mientras carga)

```css
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-surface-sunken) 25%,
    var(--color-border-default) 50%,
    var(--color-surface-sunken) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: var(--radius-sm);
}

.skeleton--text { height: 14px; }
.skeleton--title { height: 20px; width: 60%; }
.skeleton--avatar { width: 40px; height: 40px; border-radius: var(--radius-full); }
.skeleton--button { height: 36px; width: 120px; border-radius: var(--radius-md); }
```

```html
<!-- Fila de skeleton para tabla admin -->
<tr class="skeleton-row" aria-hidden="true">
  <td><div class="skeleton skeleton--text" style="width: 80%"></div></td>
  <td><div class="skeleton skeleton--text" style="width: 60%"></div></td>
  <td><div class="skeleton skeleton--button"></div></td>
</tr>
```

---

### 5. Toast / Notificación

```css
@keyframes toast-in {
  from { transform: translateY(-100%); opacity: 0; }
  to   { transform: translateY(0);    opacity: 1; }
}
@keyframes toast-out {
  from { transform: translateY(0);    opacity: 1; }
  to   { transform: translateY(-100%); opacity: 0; }
}

.toast {
  animation: toast-in var(--duration-normal) var(--ease-enter) forwards;

  &.toast--dismissing {
    animation: toast-out var(--duration-normal) var(--ease-exit) forwards;
  }
}
```

---

### 6. Modal / Dialog backdrop

```css
@keyframes backdrop-in  { from { opacity: 0; } to { opacity: 1; } }
@keyframes modal-scale-in {
  from { transform: scale(0.95) translateY(8px); opacity: 0; }
  to   { transform: scale(1)    translateY(0);   opacity: 1; }
}

.modal-backdrop {
  animation: backdrop-in var(--duration-normal) var(--ease-standard);
}
.modal-content {
  animation: modal-scale-in var(--duration-normal) var(--ease-enter);
}
```

---

## Animate.css — cuándo usar el paquete vs CSS propio

| Situación | Recomendación |
|---|---|
| Entradas de componentes simples (fadeIn, slideInDown) | ✅ Animate.css (`animate__animated animate__fadeIn`) |
| Salidas con timing controlado | ✅ Animate.css con `--animate-duration` |
| Transiciones de ruta / paso multi-step | ❌ Usa Angular Animations API o Framer Motion — más control |
| Shake de error en input | ❌ CSS propio — el shake de Animate.css es demasiado pronunciado para UX de seguridad |
| Checkmark SVG de éxito | ❌ SVG + CSS propio — no es compatible con Animate.css |
| Skeletons | ❌ Siempre CSS propio — necesitas shimmer custom |

---

## ❌ Qué NO hacer

- **No animar en cada render.** Las animaciones son para transiciones de estado, no decoración permanente.
- **No usar `bounce` o `elastic` en formularios de seguridad.** El usuario que está introduciendo un código TOTP no necesita bouncing — necesita feedback claro.
- **No omitir `prefers-reduced-motion`.** El bloque global en `tokens.css` lo cubre, pero no agregar `transition` donde no es necesario.
- **No animar `width`, `height` ni `top/left`.** Animar solo `transform` y `opacity` — son las únicas propiedades que no causan reflow (performance).
- **No encadenar más de 2 animaciones simultáneas en la misma pantalla.**
- **No usar `animation-delay` > 500ms.** El usuario asume que la app se rompió.
- **No implementar animaciones en acciones críticas de seguridad** (verificación de código, submit de credenciales) si van a retrasar el feedback visible > 150ms.

---

## Checklist de verificación

- [ ] El bloque `prefers-reduced-motion` está en `tokens.css` y deshabilita todas las animaciones
- [ ] Los inputs con error tienen animación `shake` de ≤300ms
- [ ] Los flujos multi-paso tienen transición de dirección (avance → slide izquierda, retroceso → slide derecha)
- [ ] Los estados de carga usan skeleton en lugar de spinner para contenido de tabla/lista
- [ ] Las entradas de modal/dialog tienen `scale-in` + `backdrop-in`
- [ ] Solo se animian `transform` y `opacity` (ningún `width`, `height`, `top`, `left`)
- [ ] Ninguna animación de UI feedback supera 300ms
- [ ] Los toasts tienen slide-in + auto-dismiss
- [ ] El checkmark de éxito usa animación SVG path-draw, no solo un fade
