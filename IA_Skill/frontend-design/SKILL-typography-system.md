---
name: frontend-design/typography-system
description: >
  Define y aplica la escala tipográfica completa del proyecto: fuentes, escala modular,
  line-height por contexto, peso, y fluid typography con clamp(). Úsala al iniciar
  cualquier feature con UI para garantizar jerarquía visual consistente y legible
  en dashboards, PWA y formularios multi-paso.
stack: Angular 17+ · React 18+ · CSS Custom Properties · Google Fonts / Variable Fonts
contexts: PWA · Dashboard · Admin panel · Formularios · Flujos multi-paso
---

# SKILL: Typography System — Escala Tipográfica

## Cuándo usar esta skill

Actívala cuando la spec incluya:
- Vistas con múltiples niveles de información (títulos, subtítulos, etiquetas, datos)
- Formularios con validación (los mensajes de error tienen su propio nivel tipográfico)
- Flujos multi-paso (cada paso tiene un heading que orienta al usuario)
- Tablas o listados de datos (las celdas numéricas necesitan tipografía monospace)
- Códigos, tokens o secretos mostrados en pantalla (requieren `font-family: mono`)

---

## Cómo leer la spec para extraer señales tipográficas

| Señal en la spec | Necesidad tipográfica |
|---|---|
| Múltiples User Stories con acciones diferentes | Heading H1 por vista, H2 por sección de acción |
| Campos de validación con mensajes de error | Escala `label` y `caption` para errores inline |
| Códigos de error internos (`TOTP_CODE_INVALID`) | Estilo monospace para mostrar códigos técnicos |
| `otpUri`, `challengeToken`, secretos | Familia monospace + `--color-surface-sensitive` |
| Tablas de datos con columnas numéricas | `font-variant-numeric: tabular-nums` |
| Estados booleanos (`totpEnrolled: true/false`) | Badge o chip tipográfico con peso semibold |
| Flujos de N pasos numerados | Heading de paso con indicador numérico |

---

## Sistema tipográfico — definición completa

### 1. Fuentes recomendadas (no Roboto, no Inter por defecto)

**Opción A — Técnica/Dashboard moderna:**
- Display + UI: **Geist Sans** (Vercel, libre) — geométrica, legible en densidades altas
- Mono: **Geist Mono** — para códigos, tokens, OTP URIs
- Carga: `@import` desde `https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&display=swap`

**Opción B — Profesional/Institucional:**
- Display: **Plus Jakarta Sans** — humanista, warm, diferenciadora
- Mono: **JetBrains Mono** — excelente para autenticación y datos técnicos

**Opción C — System font stack (sin dependencia externa, máxima performance):**
```css
--font-sans: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-mono: 'Cascadia Code', 'Fira Code', ui-monospace, 'SF Mono', monospace;
```

La IA debe elegir la opción A o B a menos que la spec indique restricción de fonts externos. Nunca elegir Inter o Roboto como primera opción.

---

### 2. Tokens tipográficos CSS

```css
:root {
  /* Familias */
  --font-sans:    'Geist', 'Plus Jakarta Sans', system-ui, sans-serif;
  --font-mono:    'Geist Mono', 'JetBrains Mono', ui-monospace, monospace;

  /* Escala modular — Major Third (1.250) desde 16px base */
  /* Fluid con clamp(min, preferred, max) para responsividad */
  --text-xs:   clamp(0.64rem,  0.62rem + 0.1vw,  0.70rem);   /* 10–11px  — captions, badges */
  --text-sm:   clamp(0.80rem,  0.78rem + 0.1vw,  0.875rem);  /* 13–14px  — labels, helper text */
  --text-base: clamp(0.9rem,   0.875rem + 0.13vw, 1rem);     /* 14–16px  — body, inputs */
  --text-lg:   clamp(1rem,     0.975rem + 0.15vw, 1.125rem); /* 16–18px  — body destacado */
  --text-xl:   clamp(1.125rem, 1.1rem  + 0.2vw,  1.25rem);  /* 18–20px  — subtítulos */
  --text-2xl:  clamp(1.25rem,  1.2rem  + 0.3vw,  1.5rem);   /* 20–24px  — headings sección */
  --text-3xl:  clamp(1.5rem,   1.4rem  + 0.5vw,  1.875rem); /* 24–30px  — headings página */
  --text-4xl:  clamp(1.875rem, 1.7rem  + 0.8vw,  2.25rem);  /* 30–36px  — hero/display */

  /* Pesos */
  --font-normal:   400;
  --font-medium:   500;
  --font-semibold: 600;
  --font-bold:     700;

  /* Line-heights por contexto */
  --leading-tight:   1.25;  /* headings grandes — no necesitan espacio entre líneas */
  --leading-snug:    1.375; /* subtítulos, labels */
  --leading-normal:  1.5;   /* body text — óptimo para lectura */
  --leading-relaxed: 1.625; /* textos largos, descripciones en formularios */
  --leading-none:    1;     /* badges, chips, elementos de una sola línea */

  /* Letter spacing */
  --tracking-tight:  -0.025em; /* headings grandes */
  --tracking-normal:  0;
  --tracking-wide:    0.025em; /* labels, captions, badges en mayúsculas */
  --tracking-wider:   0.05em;  /* eyebrows, step indicators */
  --tracking-widest:  0.1em;   /* texto en mayúsculas como TOTP_CODE_INVALID */
}
```

### 3. Clases utilitarias de texto (usables en Angular y React)

```css
/* typography.css — complemento a tokens.css */

/* Roles tipográficos — no crear clases por tamaño */
.type-display {
  font-family: var(--font-sans);
  font-size: var(--text-4xl);
  font-weight: var(--font-bold);
  line-height: var(--leading-tight);
  letter-spacing: var(--tracking-tight);
  color: var(--color-text-primary);
}

.type-heading-1 {
  font-size: var(--text-3xl);
  font-weight: var(--font-bold);
  line-height: var(--leading-tight);
  letter-spacing: var(--tracking-tight);
}

.type-heading-2 {
  font-size: var(--text-2xl);
  font-weight: var(--font-semibold);
  line-height: var(--leading-snug);
}

.type-heading-3 {
  font-size: var(--text-xl);
  font-weight: var(--font-semibold);
  line-height: var(--leading-snug);
}

.type-body {
  font-size: var(--text-base);
  font-weight: var(--font-normal);
  line-height: var(--leading-normal);
}

.type-body-strong {
  font-size: var(--text-base);
  font-weight: var(--font-medium);
  line-height: var(--leading-normal);
}

.type-label {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  line-height: var(--leading-snug);
  color: var(--color-text-secondary);
}

.type-caption {
  font-size: var(--text-xs);
  font-weight: var(--font-normal);
  line-height: var(--leading-snug);
  color: var(--color-text-secondary);
}

/* Datos técnicos: OTP URI, challenge tokens, error codes */
.type-code {
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  font-weight: var(--font-normal);
  line-height: var(--leading-relaxed);
  background: var(--color-surface-sensitive);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-sm);
  word-break: break-all;
}

/* Error codes internos como TOTP_CODE_INVALID */
.type-error-code {
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  letter-spacing: var(--tracking-widest);
  text-transform: uppercase;
  color: var(--color-feedback-error);
}

/* Números en tablas */
.type-numeric {
  font-family: var(--font-mono);
  font-variant-numeric: tabular-nums;
  font-size: var(--text-base);
}

/* Eyebrow / step indicator */
.type-eyebrow {
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  letter-spacing: var(--tracking-widest);
  text-transform: uppercase;
  color: var(--color-text-secondary);
}
```

### 4. Integración Angular

```html
<!-- Uso en templates Angular -->
<h1 class="type-heading-1">Configurar autenticación de dos factores</h1>
<p class="type-body">Escanea el código QR con tu aplicación autenticadora.</p>
<code class="type-code">{{ otpUri }}</code>
<span class="type-error-code">{{ errorCode }}</span>
```

```scss
// En componente Angular — sin redefinir tokens
.step-title {
  @extend .type-heading-2; // si usas SCSS extends
  // O simplemente agregar la clase al template
}
```

### 5. Integración React + Tailwind

```tsx
// React — clases de tipografía como componentes
const Typography = {
  Heading1: ({ children }: { children: React.ReactNode }) => (
    <h1 className="font-sans text-3xl font-bold leading-tight tracking-tight text-text-primary">
      {children}
    </h1>
  ),
  Code: ({ children }: { children: React.ReactNode }) => (
    <code className="font-mono text-sm bg-surface-sensitive px-2 py-1 rounded-sm break-all">
      {children}
    </code>
  ),
  ErrorCode: ({ children }: { children: React.ReactNode }) => (
    <span className="font-mono text-xs font-semibold tracking-widest uppercase text-feedback-error">
      {children}
    </span>
  ),
}
```

---

## Patrones tipográficos para flujos comunes en specs

### Flujo multi-paso (enrolamiento TOTP, onboarding)
```html
<!-- Indicador de paso -->
<span class="type-eyebrow">Paso 1 de 2</span>
<h1 class="type-heading-1">Escanea el código QR</h1>
<p class="type-body">Usa Google Authenticator, Authy o cualquier app TOTP.</p>
```

### Formulario con validación
```html
<label class="type-label">Código de verificación</label>
<input type="text" ... />
<!-- Error inline — nunca usar type-body para errores -->
<p class="type-caption" style="color: var(--color-feedback-error)">
  El código debe tener exactamente 6 dígitos.
</p>
```

### Datos técnicos sensibles
```html
<p class="type-label">URI para tu autenticador</p>
<code class="type-code">otpauth://totp/user%40empresa.com?secret=...&issuer=JustMicroHarmony</code>
```

---

## ❌ Qué NO hacer

- **No usar tamaños en `px` directos en componentes.** Siempre `var(--text-*)` o las clases de rol.
- **No crear clases como `.text-16` o `.font-size-medium`.** Los roles semánticos (`type-body`, `type-label`) son los que describen el propósito, no el tamaño.
- **No mostrar códigos de error técnicos con `type-body`.** `TOTP_CODE_INVALID` necesita `type-error-code` (monospace + uppercase) para diferenciarse del texto normal.
- **No usar `line-height: 1` en body text.** Usar `--leading-normal` mínimo para garantizar legibilidad.
- **No mostrar OTP URIs o tokens sin `type-code`.** Sin el fondo `surface-sensitive` y la familia monospace, los usuarios no distinguen el dato técnico del texto descriptivo.
- **No mezclar familias.** Si el proyecto eligió Geist Sans, no introducir Inter "para un componente" — rompe la coherencia visual.

---

## Checklist de verificación

- [ ] Las fuentes elegidas NO son Roboto ni Inter (salvo que la spec lo requiera explícitamente)
- [ ] Todos los `font-size` en componentes usan `var(--text-*)` con `clamp()`
- [ ] Los headings de cada vista están jerarquizados correctamente (H1 → H2 → H3)
- [ ] Los mensajes de error inline usan `type-caption` con `--color-feedback-error`
- [ ] Los códigos técnicos (OTP URI, tokens, error codes) usan `type-code` o `type-error-code`
- [ ] Las tablas con números usan `font-variant-numeric: tabular-nums`
- [ ] Los flujos multi-paso tienen eyebrow (`type-eyebrow`) con indicador de paso
- [ ] El modo oscuro no requiere ajustes adicionales (los colores vienen de tokens ya configurados)
