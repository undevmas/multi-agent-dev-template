---
name: frontend-design/component-patterns
description: >
  Define los patrones de composición de componentes UI para Angular y React:
  variantes con CVA/HostBinding, compound components, slots, y la convención
  de nombrado. Úsala al implementar cualquier componente reutilizable para
  garantizar APIs predecibles que cualquier IA pueda generar correctamente.
stack: Angular 17+ (Signals, Standalone) · React 18+ · CVA · class-variance-authority
contexts: PWA · Dashboard · Admin panel · Formularios · Design system interno
---

# SKILL: Component Patterns — Patrones de Composición

## Cuándo usar esta skill

Actívala cuando la spec incluya:
- Componentes que aparecen en más de un User Story (ej: el botón de acción primaria aparece en todos los flujos)
- Múltiples variantes de un mismo elemento (botón primario/secundario/danger, badge success/error/warning)
- Layouts con zonas intercambiables (sidebar + contenido principal, modal con header/body/footer)
- Formularios con campos reutilizables entre vistas

---

## Cómo leer la spec para extraer componentes necesarios

| Señal en la spec | Componentes a crear |
|---|---|
| Respuestas HTTP con códigos (`400`, `202`, `404`) | `<AlertBanner>` con variantes por tipo de feedback |
| Flujo de N pasos (`initiate → confirm`) | `<StepIndicator>` + `<StepCard>` |
| Campos de validación con errores inline | `<FormField>` con slots para label, input, error |
| Estados booleanos (`totpEnrolled`, `mfaRequired`) | `<StatusBadge>` con variantes semánticas |
| Acciones destructivas (`DELETE`, `revoke`) | `<ConfirmDialog>` + `<Button variant="danger">` |
| Datos sensibles (`otpUri`, `challengeToken`) | `<SensitiveData>` con toggle show/hide |
| Tablas de datos de admin | `<DataTable>` con sort, filter, y estados vacíos |
| Código de 6 dígitos (TOTP) | `<OtpInput>` con 6 celdas individuales |

---

## Patrones de variantes

### Angular — Input + HostBinding

```typescript
// button.component.ts
import { Component, Input, HostBinding } from '@angular/core';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
type ButtonSize = 'sm' | 'md' | 'lg';

@Component({
  selector: 'app-button',
  standalone: true,
  template: `
    <button
      [class]="computedClass"
      [disabled]="disabled || loading"
      [attr.aria-disabled]="disabled || loading"
      [attr.aria-busy]="loading"
      (click)="!disabled && !loading && clicked.emit($event)"
    >
      @if (loading) {
        <span class="btn__spinner" aria-hidden="true"></span>
      }
      <ng-content />
    </button>
  `,
  styleUrls: ['./button.component.scss']
})
export class ButtonComponent {
  @Input() variant: ButtonVariant = 'primary';
  @Input() size: ButtonSize = 'md';
  @Input() disabled = false;
  @Input() loading = false;
  @Input() fullWidth = false;

  @Output() clicked = new EventEmitter<MouseEvent>();

  get computedClass(): string {
    return [
      'btn',
      `btn--${this.variant}`,
      `btn--${this.size}`,
      this.fullWidth ? 'btn--full' : '',
      this.loading ? 'btn--loading' : '',
    ].filter(Boolean).join(' ');
  }
}
```

```scss
// button.component.scss
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-weight: var(--font-medium);
  border: 1px solid transparent;
  cursor: pointer;
  transition:
    background var(--duration-fast) var(--ease-standard),
    border-color var(--duration-fast) var(--ease-standard),
    box-shadow var(--duration-fast) var(--ease-standard),
    opacity var(--duration-fast) var(--ease-standard);

  &:focus-visible {
    outline: none;
    box-shadow: var(--shadow-focus);
  }

  // Tamaños
  &--sm  { padding: var(--space-1) var(--space-3); font-size: var(--text-sm);   min-height: 32px; }
  &--md  { padding: var(--space-2) var(--space-4); font-size: var(--text-base); min-height: 40px; }
  &--lg  { padding: var(--space-3) var(--space-6); font-size: var(--text-lg);   min-height: 48px; }

  // Variantes
  &--primary {
    background: var(--color-action-primary);
    color: var(--color-text-inverse);
    &:hover:not(:disabled) { background: var(--color-action-primary-hover); }
  }
  &--secondary {
    background: transparent;
    color: var(--color-action-primary);
    border-color: var(--color-action-primary);
    &:hover:not(:disabled) { background: var(--color-feedback-info-bg); }
  }
  &--ghost {
    background: transparent;
    color: var(--color-text-primary);
    &:hover:not(:disabled) { background: var(--color-surface-sunken); }
  }
  &--danger {
    background: var(--color-action-danger);
    color: var(--color-text-inverse);
    &:hover:not(:disabled) { background: var(--color-action-danger-hover); }
  }

  &--full { width: 100%; }

  &:disabled, &--loading {
    opacity: 0.5;
    cursor: not-allowed;
    pointer-events: none;
  }

  &__spinner {
    width: 16px;
    height: 16px;
    border: 2px solid currentColor;
    border-top-color: transparent;
    border-radius: var(--radius-full);
    animation: spin 600ms linear infinite;
  }
}

@keyframes spin { to { transform: rotate(360deg); } }
```

### React — CVA (class-variance-authority)

```tsx
// components/ui/button.tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { forwardRef } from 'react';

const buttonVariants = cva(
  // Base — siempre aplicada
  'inline-flex items-center justify-center gap-2 rounded-md font-sans font-medium border border-transparent cursor-pointer transition-all duration-fast ease-standard focus-visible:outline-none focus-visible:shadow-focus disabled:opacity-50 disabled:cursor-not-allowed',
  {
    variants: {
      variant: {
        primary:   'bg-action-primary text-white hover:bg-action-primary-hover',
        secondary: 'bg-transparent text-action-primary border-action-primary hover:bg-feedback-info/10',
        ghost:     'bg-transparent text-text-primary hover:bg-surface-sunken',
        danger:    'bg-action-danger text-white hover:bg-action-danger/90',
      },
      size: {
        sm: 'px-3 py-1 text-sm min-h-[32px]',
        md: 'px-4 py-2 text-base min-h-[40px]',
        lg: 'px-6 py-3 text-lg min-h-[48px]',
      },
      fullWidth: {
        true: 'w-full',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant, size, fullWidth, loading, disabled, children, className, ...props }, ref) => (
    <button
      ref={ref}
      disabled={disabled || loading}
      aria-disabled={disabled || loading}
      aria-busy={loading}
      className={buttonVariants({ variant, size, fullWidth, className })}
      {...props}
    >
      {loading && (
        <span
          className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"
          aria-hidden="true"
        />
      )}
      {children}
    </button>
  )
);
Button.displayName = 'Button';
```

---

## Patrón Compound Component (para composición de partes)

Usa este patrón cuando un componente tiene múltiples partes configurables (Card, Modal, FormField).

### React — Compound Component con Context

```tsx
// components/ui/form-field.tsx
import { createContext, useContext, useId } from 'react';

interface FormFieldContextValue {
  id: string;
  hasError: boolean;
}

const FormFieldContext = createContext<FormFieldContextValue | null>(null);
const useFormField = () => {
  const ctx = useContext(FormFieldContext);
  if (!ctx) throw new Error('useFormField debe usarse dentro de <FormField>');
  return ctx;
};

// Componente raíz
function FormField({ children, error }: { children: React.ReactNode; error?: string }) {
  const id = useId();
  return (
    <FormFieldContext.Provider value={{ id, hasError: Boolean(error) }}>
      <div className="flex flex-col gap-1">
        {children}
        {error && <FormFieldError>{error}</FormFieldError>}
      </div>
    </FormFieldContext.Provider>
  );
}

function FormFieldLabel({ children }: { children: React.ReactNode }) {
  const { id, hasError } = useFormField();
  return (
    <label
      htmlFor={id}
      className={`type-label ${hasError ? 'text-feedback-error' : ''}`}
    >
      {children}
    </label>
  );
}

function FormFieldInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  const { id, hasError } = useFormField();
  return (
    <input
      id={id}
      aria-describedby={hasError ? `${id}-error` : undefined}
      aria-invalid={hasError}
      className={`
        w-full px-4 py-2 rounded-md border bg-surface-card text-text-primary
        font-sans text-base transition-colors duration-fast
        focus:outline-none focus:shadow-focus
        ${hasError
          ? 'border-border-error'
          : 'border-border-default focus:border-border-focus'}
      `}
      {...props}
    />
  );
}

function FormFieldError({ children }: { children: React.ReactNode }) {
  const { id } = useFormField();
  return (
    <p id={`${id}-error`} role="alert" className="type-caption text-feedback-error">
      {children}
    </p>
  );
}

// Exportación como namespace
FormField.Label = FormFieldLabel;
FormField.Input = FormFieldInput;
FormField.Error = FormFieldError;

export { FormField };

// Uso:
// <FormField error="El código debe tener exactamente 6 dígitos.">
//   <FormField.Label>Código de verificación</FormField.Label>
//   <FormField.Input type="text" maxLength={6} inputMode="numeric" />
// </FormField>
```

### Angular — Proyección de contenido con slots

```typescript
// card.component.ts
@Component({
  selector: 'app-card',
  standalone: true,
  template: `
    <div class="card" [class.card--elevated]="elevated">
      @if (hasHeader) {
        <div class="card__header">
          <ng-content select="[slot=header]" />
        </div>
      }
      <div class="card__body">
        <ng-content />
      </div>
      @if (hasFooter) {
        <div class="card__footer">
          <ng-content select="[slot=footer]" />
        </div>
      }
    </div>
  `,
})
export class CardComponent {
  @Input() elevated = false;
  @ContentChild('[slot=header]') headerSlot?: ElementRef;
  @ContentChild('[slot=footer]') footerSlot?: ElementRef;
  get hasHeader() { return Boolean(this.headerSlot); }
  get hasFooter() { return Boolean(this.footerSlot); }
}

// Uso:
// <app-card [elevated]="true">
//   <div slot="header"><h2 class="type-heading-2">Configurar TOTP</h2></div>
//   <p class="type-body">Escanea el código QR...</p>
//   <div slot="footer">
//     <app-button variant="primary">Continuar</app-button>
//   </div>
// </app-card>
```

---

## StatusBadge — componente de estado frecuente en specs

```tsx
// React — status-badge.tsx
type BadgeVariant = 'success' | 'warning' | 'error' | 'info' | 'neutral';

const badgeStyles: Record<BadgeVariant, string> = {
  success: 'bg-[var(--color-feedback-success-bg)] text-[var(--color-feedback-success)]',
  warning: 'bg-[var(--color-feedback-warning-bg)] text-[var(--color-feedback-warning)]',
  error:   'bg-[var(--color-feedback-error-bg)] text-[var(--color-feedback-error)]',
  info:    'bg-[var(--color-feedback-info-bg)] text-[var(--color-feedback-info)]',
  neutral: 'bg-surface-sunken text-text-secondary',
};

export function StatusBadge({ variant, children }: { variant: BadgeVariant; children: React.ReactNode }) {
  return (
    <span className={`
      inline-flex items-center gap-1 px-2 py-0.5 rounded-full
      font-sans text-xs font-semibold leading-none
      ${badgeStyles[variant]}
    `}>
      {children}
    </span>
  );
}

// Uso derivado de spec:
// <StatusBadge variant="success">TOTP activo</StatusBadge>
// <StatusBadge variant="warning">Pendiente de confirmar</StatusBadge>
// <StatusBadge variant="error">Revocado</StatusBadge>
```

---

## Convención de nombrado de componentes

| Contexto | Angular | React |
|---|---|---|
| Componente de UI base | `ButtonComponent` → `<app-button>` | `Button` → `<Button>` |
| Componente de feature | `MfaEnrollComponent` | `MfaEnrollPage` |
| Layout de página | `DashboardLayoutComponent` | `DashboardLayout` |
| Diálogo/modal | `ConfirmRevokeDialogComponent` | `ConfirmRevokeDialog` |
| Input especializado | `OtpInputComponent` | `OtpInput` |

---

## ❌ Qué NO hacer

- **No crear un componente por cada pantalla sin extraer los elementos reutilizables.** Si el botón "Continuar" aparece en 3 pantallas con las mismas variantes, es un `<Button>` reutilizable.
- **No pasar colores como props.** `<Button color="#ef4444">` está prohibido; usar `variant="danger"`.
- **No crear variantes ad-hoc.** Si el componente necesita una variante nueva no contemplada, actualizar el sistema de variantes — no hacerle `style` inline.
- **No mezclar la lógica de negocio en componentes UI.** Un `<Button>` no sabe qué hace cuando se hace click; solo emite el evento.
- **No usar `!important` para sobreescribir estilos de variante.** Si necesitas `!important`, el sistema de variantes está mal diseñado.
- **No nombrar variantes por color** (`variant="blue"`). Nombrarlas por semántica (`variant="primary"`).

---

## Checklist de verificación

- [ ] Los componentes reutilizables identificados en la spec están implementados como componentes compartidos
- [ ] Las variantes usan nombres semánticos (`primary`, `danger`) no visuales (`blue`, `red`)
- [ ] Los formularios usan compound components con `FormField.Label`, `FormField.Input`, `FormField.Error`
- [ ] Los estados de carga (`loading`) y deshabilitado (`disabled`) están implementados en todos los botones de acción
- [ ] Los `StatusBadge` reflejan los estados de la spec (confirmed, pending, revoked)
- [ ] Los componentes Angular usan `standalone: true` y Signals donde hay estado reactivo
- [ ] Los componentes React exponen tipos TypeScript correctos (no `any`)
- [ ] Ningún componente hardcodea un color o tamaño — todos consumen tokens CSS
