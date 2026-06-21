---
name: frontend-design/accessibility-a11y
description: >
  Define los requerimientos de accesibilidad WCAG AA obligatorios para PWA y
  dashboards: ARIA semántico, navegación por teclado, focus management, contraste
  de color, y patrones para formularios, modales y notificaciones. Úsala para
  que la IA genere componentes accesibles por defecto, no como afterthought.
stack: Angular 17+ · React 18+ · ARIA · WCAG 2.1 AA
contexts: PWA · Dashboard · Admin panel · Formularios · Modales
---

# SKILL: Accessibility (a11y) — Calidad PWA

## Cuándo usar esta skill

Actívala siempre que la spec incluya:
- Formularios con campos de entrada y validación (inputs, OTP, selects)
- Modales, drawers, o dialogs de confirmación
- Notificaciones dinámicas (toasts, alerts, mensajes de error/éxito)
- Cambios de estado visibles (loading, confirmado, revocado)
- Navegación entre vistas o pasos de un flujo

---

## Cómo leer la spec para extraer señales de a11y

| Señal en la spec | Requerimiento de accesibilidad |
|---|---|
| Código de 6 dígitos TOTP | `inputMode="numeric"`, `autocomplete="one-time-code"`, `aria-label` |
| Mensajes de error inline (`TOTP_CODE_INVALID`) | `role="alert"` + `aria-describedby` conectando input con error |
| Flujo de 2 pasos | `aria-live` para anunciar el cambio de paso |
| HTTP 202 → loading → resultado | `aria-busy="true"` durante la carga |
| Acciones destructivas (revoke) con confirm dialog | Focus trap en el dialog + `aria-modal="true"` |
| Múltiples actores (User, Admin) | Rutas protegidas con feedback claro de 403 accesible |
| `totpEnrolled: true/false` en status badge | `aria-label` descriptivo (no solo color) |

---

## Reglas semánticas — HTML primero

### Principio: usar el elemento HTML correcto antes de ARIA

```html
<!-- ❌ MAL: div con role -->
<div role="button" onclick="submit()">Verificar</div>

<!-- ✅ BIEN: elemento nativo -->
<button type="submit">Verificar</button>
```

```html
<!-- ❌ MAL: div como formulario -->
<div class="form">
  <div class="field">...</div>
</div>

<!-- ✅ BIEN: form con novalidate (validación manual) -->
<form novalidate (ngSubmit)="onSubmit()" aria-label="Verificación de código TOTP">
  <fieldset>
    <legend class="type-label">Código de verificación</legend>
    <!-- campos -->
  </fieldset>
</form>
```

---

## Focus management

### Regla general: el foco siempre sigue al usuario

```typescript
// Angular — mover foco programáticamente tras cambio de paso
import { Component, ElementRef, ViewChild, AfterViewInit } from '@angular/core';

@Component({
  template: `
    <h1 #stepTitle tabindex="-1">{{ stepHeading() }}</h1>
  `
})
export class StepComponent {
  @ViewChild('stepTitle') stepTitle!: ElementRef<HTMLHeadingElement>;

  advanceStep() {
    this.currentStep.update(s => s + 1);
    // Mover foco al heading del nuevo paso tras el re-render
    setTimeout(() => this.stepTitle.nativeElement.focus(), 50);
  }
}
```

```tsx
// React — useRef para focus tras cambio
import { useRef, useEffect } from 'react';

function MultiStepFlow({ step }: { step: number }) {
  const headingRef = useRef<HTMLHeadingElement>(null);

  useEffect(() => {
    // Al cambiar de paso, enfocar el heading del nuevo paso
    headingRef.current?.focus();
  }, [step]);

  return <h1 ref={headingRef} tabIndex={-1}>{stepHeadings[step]}</h1>;
}
```

### Focus trap en modales y dialogs

```typescript
// Angular — directive de focus trap
@Directive({ selector: '[appFocusTrap]', standalone: true })
export class FocusTrapDirective implements AfterViewInit, OnDestroy {
  private el = inject(ElementRef<HTMLElement>);
  private previouslyFocused: HTMLElement | null = null;

  private get focusableElements(): HTMLElement[] {
    return Array.from(this.el.nativeElement.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), ' +
      'textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    ));
  }

  ngAfterViewInit() {
    this.previouslyFocused = document.activeElement as HTMLElement;
    // Enfocar primer elemento del modal
    this.focusableElements[0]?.focus();
    this.el.nativeElement.addEventListener('keydown', this.handleKeydown);
  }

  ngOnDestroy() {
    // Devolver foco al elemento que abrió el modal
    this.previouslyFocused?.focus();
    this.el.nativeElement.removeEventListener('keydown', this.handleKeydown);
  }

  private handleKeydown = (e: KeyboardEvent) => {
    if (e.key !== 'Tab') return;
    const elements = this.focusableElements;
    const first = elements[0];
    const last = elements[elements.length - 1];

    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  };
}
```

---

## Formularios accesibles

### Input con validación conectada por ARIA

```html
<!-- Angular -->
<div class="form-field">
  <label [for]="inputId" class="type-label">
    Código de verificación
    <span class="sr-only">(6 dígitos)</span>
  </label>

  <input
    [id]="inputId"
    type="text"
    inputmode="numeric"
    autocomplete="one-time-code"
    maxlength="6"
    pattern="\d{6}"
    [attr.aria-invalid]="hasError()"
    [attr.aria-describedby]="hasError() ? inputId + '-error' : null"
    [attr.aria-required]="true"
  />

  @if (hasError()) {
    <p
      [id]="inputId + '-error'"
      role="alert"
      class="type-caption"
      style="color: var(--color-feedback-error)"
    >
      {{ errorMessage() }}
    </p>
  }
</div>
```

```tsx
// React — FormField compound component ya cubre esto
// Ver SKILL-component-patterns → FormField

// El atributo autocomplete="one-time-code" es crítico para TOTP:
// activa el autocompletado de SMS/email OTP en iOS y Android
<FormField.Input
  type="text"
  inputMode="numeric"
  autoComplete="one-time-code"
  maxLength={6}
  pattern="\d{6}"
  aria-required="true"
/>
```

---

## Notificaciones dinámicas (aria-live)

```html
<!-- Zona de notificaciones — SIEMPRE presente en el DOM, aunque vacía -->
<!-- Angular / HTML -->
<div
  aria-live="polite"
  aria-atomic="true"
  class="sr-only"
  id="notification-region"
>
  <!-- El contenido se inyecta dinámicamente -->
  {{ accessibleNotification() }}
</div>

<!-- Para errores críticos: aria-live="assertive" -->
<div
  aria-live="assertive"
  aria-atomic="true"
  class="sr-only"
  id="error-region"
>
  {{ criticalError() }}
</div>
```

```css
/* sr-only: visible para screen readers, invisible para ojos */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

**Cuándo usar `assertive` vs `polite`:**
| Tipo | Región | Cuándo |
|---|---|---|
| Errores de seguridad (código inválido, token expirado) | `assertive` | El usuario NECESITA saber ahora |
| Confirmaciones de éxito (enrollment completado) | `polite` | Espera a que el usuario termine de leer |
| Mensajes de estado (cargando...) | `polite` | Informativo, no urgente |

---

## Modales y dialogs accesibles

```html
<!-- Angular -->
<div
  role="dialog"
  aria-modal="true"
  [attr.aria-labelledby]="dialogTitleId"
  [attr.aria-describedby]="dialogDescId"
  appFocusTrap
>
  <h2 [id]="dialogTitleId" class="type-heading-2">Revocar autenticación TOTP</h2>
  <p [id]="dialogDescId" class="type-body">
    Al revocar el TOTP, tu cuenta quedará protegida solo con contraseña.
    ¿Deseas continuar?
  </p>
  <div class="dialog-actions">
    <!-- Botón cancelar PRIMERO en el DOM (tab order correcto) -->
    <app-button variant="ghost" (clicked)="close()">Cancelar</app-button>
    <app-button variant="danger" (clicked)="confirm()">Revocar</app-button>
  </div>
</div>
```

**Reglas de dialog:**
- `role="dialog"` + `aria-modal="true"` en el contenedor
- `aria-labelledby` apunta al heading del dialog
- `aria-describedby` apunta al texto descriptivo
- Focus trap activo mientras el dialog está abierto
- `Escape` cierra el dialog y devuelve el foco al elemento que lo abrió

---

## Skip link (obligatorio en toda app con navegación)

```html
<!-- index.html — primer elemento del body -->
<a href="#main-content" class="skip-link">Saltar al contenido principal</a>

<!-- En el layout — el main debe tener id="main-content" -->
<main id="main-content" tabindex="-1">
  <!-- contenido -->
</main>
```

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: var(--space-4);
  z-index: var(--z-toast);
  padding: var(--space-2) var(--space-4);
  background: var(--color-action-primary);
  color: var(--color-text-inverse);
  border-radius: var(--radius-md);
  font-weight: var(--font-semibold);
  text-decoration: none;

  &:focus {
    top: var(--space-4);
  }
}
```

---

## StatusBadge accesible (no comunicar estado solo con color)

```tsx
// ❌ MAL: solo color comunica el estado
<span className="badge badge--success">●</span>

// ✅ BIEN: texto + color + aria-label descriptivo
<span
  className={badgeStyles[variant]}
  role="status"
  aria-label={`Estado: ${label}`}
>
  <span aria-hidden="true">{icon}</span>
  {label}
</span>

// Para el caso totpEnrolled:
<StatusBadge variant={totpEnrolled ? 'success' : 'neutral'}>
  {totpEnrolled ? 'TOTP activo' : 'Sin TOTP'}
</StatusBadge>
// aria-label implícito en el texto visible — no es solo un punto de color
```

---

## Contraste de color — checklist por componente

| Componente | Par de colores | Ratio requerido |
|---|---|---|
| Texto body | `--color-text-primary` / `--color-surface-app` | ≥ 4.5:1 |
| Texto secundario | `--color-text-secondary` / `--color-surface-app` | ≥ 4.5:1 |
| Texto en badges | texto badge / fondo badge | ≥ 4.5:1 |
| Borde de input | `--color-border-default` / `--color-surface-card` | ≥ 3:1 |
| Icono en botón | ícono / fondo botón | ≥ 3:1 |
| Focus ring | `--shadow-focus` visible sobre cualquier fondo | ≥ 3:1 |

---

## ❌ Qué NO hacer

- **No usar `<div role="button">` si puede ser `<button>`.** Los elementos nativos tienen comportamiento de teclado incluido.
- **No usar `aria-label` en elementos con texto visible.** El texto visible ya ES el label — `aria-label` lo sobreescribe y confunde.
- **No poner `tabindex="0"` en elementos no interactivos.** Solo los elementos que el usuario puede activar (click, input) necesitan ser focusables.
- **No comunicar estado SOLO con color.** Un badge rojo que dice solo "●" es inaccesible. Necesita texto ("Error") o `aria-label`.
- **No abrir un modal sin mover el foco dentro del modal.** El usuario de teclado queda "atrapado" fuera.
- **No usar `aria-live="assertive"` para mensajes de confirmación de éxito.** `assertive` interrumpe al screen reader — reservar para errores críticos.
- **No omitir `autocomplete="one-time-code"` en inputs de código TOTP.** Sin esto, iOS/Android no ofrece autocompletado del SMS/push.

---

## Checklist de verificación

- [ ] Todos los inputs tienen `<label>` asociado con `for`/`htmlFor` (no solo placeholder)
- [ ] Los mensajes de error inline usan `role="alert"` y están conectados con `aria-describedby`
- [ ] Los inputs de código TOTP tienen `inputmode="numeric"` y `autocomplete="one-time-code"`
- [ ] Los modales tienen `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, y focus trap
- [ ] Existe una zona `aria-live="polite"` para notificaciones de éxito
- [ ] Existe una zona `aria-live="assertive"` para errores críticos de seguridad
- [ ] El skip link está en `index.html` y el `<main>` tiene `id="main-content"`
- [ ] Ningún estado se comunica SOLO con color (todos los badges tienen texto legible)
- [ ] El foco se mueve al heading del nuevo paso en flujos multi-paso
- [ ] El Escape cierra modales y devuelve el foco al elemento que los abrió
