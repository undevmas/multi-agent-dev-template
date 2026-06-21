---
name: frontend-design/visual-identity-override
description: >
  Define las decisiones de identidad visual que distinguen el proyecto de los
  defaults de Material UI, Ant Design, shadcn o cualquier librería base:
  border radius system, shadow vocabulary, iconografía, paleta de brand,
  y patrones de superficie. Úsala para que la IA no genere "otro dashboard gris
  con botones azules Roboto" sino una identidad visual coherente y recordable.
stack: Angular 17+ · React 18+ · Agnostico de librería base
contexts: Cualquier contexto con UI visible
---

# SKILL: Visual Identity Override — Anti-Genérico

## Cuándo usar esta skill

Actívala siempre — es la primera skill que define el "look" del proyecto. Sin ella, cualquier IA genera los defaults de la librería base, que son idénticos a los de miles de otros proyectos.

Actívala especialmente cuando:
- La spec describe una pantalla de autenticación, onboarding, o perfil (alta visibilidad para el usuario)
- El proyecto tiene más de un tenant con posibilidad de branding
- El diseño existente usa Material UI / Ant Design y se quiere diferenciar

---

## Cómo leer la spec para extraer señales de identidad visual

| Señal en la spec | Decisión de identidad a tomar |
|---|---|
| Sistema de seguridad / autenticación (MFA, TOTP) | Paleta fría (azul-pizarra) con acentos técnicos — no warm/beige |
| Multi-tenant institucional | Border radius conservador (4–8px) — no pill-shaped |
| Admin panel con datos técnicos | Densidad alta, radius bajo, iconografía de trazo fino |
| PWA instalable por usuarios finales | Border radius más amigable (8–12px), sombras más visibles |
| Datos sensibles (tokens, secretos) | Superficie diferenciada — no confundir con contenido normal |
| Acciones destructivas explícitas en spec | Rojo semántico reservado SOLO para danger — no para decoración |

---

## Sistema de border radius

El border radius define la "personalidad" del proyecto. Elegir UNO y ser consistente:

| Estilo | Valores | Cuándo usar |
|---|---|---|
| **Sharp** | 2–4px base | Herramientas técnicas, terminales, IDEs, fintech |
| **Moderate** ✅ recomendado | 6–10px base | Admin panels, dashboards institucionales, B2B |
| **Friendly** | 10–16px base | Apps de consumidor, onboarding, salud/wellness |
| **Pill-heavy** | 20px+ en componentes | Apps móviles consumer, social, entretenimiento |

```css
/* Para un proyecto de seguridad/autenticación institucional → Moderate */
:root {
  --radius-sm:   4px;   /* inputs, badges pequeños */
  --radius-md:   8px;   /* cards, botones, inputs principales */
  --radius-lg:   12px;  /* modales, drawers, cards destacadas */
  --radius-xl:   16px;  /* banners, notificaciones grandes */
  --radius-full: 9999px; /* solo chips y avatares circulares */
}

/* REGLA: no mezclar estilos en un mismo componente */
/* ❌ MAL: card con radius-lg y botón con radius-full dentro */
/* ✅ BIEN: card con radius-lg y botón con radius-md */
```

---

## Shadow vocabulary (3–4 niveles semánticos)

Las sombras indican elevación — a mayor sombra, más "encima" está el elemento.

```css
:root {
  /* Nivel 0: sin sombra — elemento en el plano de la app */
  /* Usar para: contenido inline, texto, iconos */

  /* Nivel 1: sombra sutil — elemento ligeramente elevado */
  --shadow-card: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
  /* Usar para: cards de contenido, inputs con foco, filas de tabla hover */

  /* Nivel 2: sombra media — elemento claramente elevado */
  --shadow-raised: 0 4px 12px rgba(0, 0, 0, 0.10), 0 2px 4px rgba(0, 0, 0, 0.06);
  /* Usar para: dropdowns, popovers, tooltips, cards en hover */

  /* Nivel 3: sombra pronunciada — overlay o elemento flotante */
  --shadow-modal: 0 10px 25px rgba(0, 0, 0, 0.12), 0 4px 10px rgba(0, 0, 0, 0.08);
  /* Usar para: modales, drawers, sidebars flotantes */

  /* Especial: focus ring — NO es una sombra de elevación, es de accesibilidad */
  --shadow-focus: 0 0 0 3px rgba(59, 130, 246, 0.4);
}

/* Modo oscuro: sombras más pronunciadas porque el contraste con fondo oscuro es menor */
[data-theme="dark"] {
  --shadow-card:   0 1px 3px rgba(0, 0, 0, 0.35);
  --shadow-raised: 0 4px 12px rgba(0, 0, 0, 0.40);
  --shadow-modal:  0 10px 25px rgba(0, 0, 0, 0.55);
}
```

**Regla de consistencia:** cada nivel se usa SOLO en el contexto que le corresponde. No usar `shadow-modal` en un card por "que se vea más bonito".

---

## Sistema de iconografía

Elegir UNA librería y NO mezclar. Para este stack:

| Librería | Estilo | Cuándo usar |
|---|---|---|
| **Lucide** ✅ recomendado | Trazo fino, geométrico, 24px base | Admin panels, dashboards técnicos |
| **Phosphor** | Múltiples pesos, expresivo | Apps consumer, PWA amigable |
| **Tabler** | Trazo fino, muy completo | Herramientas técnicas, fintech |
| ❌ Material Icons | Relleno grueso, muy asociado a Google | Evitar si se quiere diferenciación |
| ❌ FontAwesome | Heterogéneo, heavy en bundle | Evitar |

```typescript
// Angular — Lucide Angular
import { LucideAngularModule, Shield, Key, CheckCircle, AlertTriangle } from 'lucide-angular';

@NgModule({
  imports: [
    LucideAngularModule.pick({ Shield, Key, CheckCircle, AlertTriangle })
  ]
})

// Template:
// <lucide-icon name="shield" [size]="20" strokeWidth="1.5" />
```

```tsx
// React — lucide-react
import { Shield, Key, CheckCircle2, AlertTriangle } from 'lucide-react';

// Uso consistente — siempre 20px en UI, 16px en botones, 24px en headings
<Shield size={20} strokeWidth={1.5} className="text-text-secondary" />
```

**Tamaños de icono por contexto:**
| Contexto | Tamaño | strokeWidth |
|---|---|---|
| Inline en texto | 16px | 1.5 |
| En botones e inputs | 20px | 1.5 |
| En cards y headings | 24px | 1.5 |
| En ilustraciones de estado vacío | 48px | 1.25 |

---

## Paleta de brand — cómo elegir sin ser genérico

**Criterio anti-genérico:** Si tu paleta es "azul primario + gris neutral + rojo de error", es idéntica al 80% de los dashboards. Diferenciarse en UNO de estos ejes:

### Eje 1 — Azul técnico (no Material Blue)
```css
/* En lugar de #2196F3 (Material Blue), usar un azul con más carácter */
--color-action-primary: #2563EB;  /* Blue 600 — más profundo */
/* O bien un azul-pizarra para contextos de seguridad */
--color-action-primary: #3B5BDB;  /* Indigo — técnico, serio */
```

### Eje 2 — Acento diferenciador (el color que hace único el proyecto)
```css
/* Para proyectos de seguridad/autenticación: */
--color-accent: #0EA5E9;          /* Sky Blue — moderno, tecnológico */
/* O un verde técnico para estados de éxito que no sea el verde default: */
--color-accent-success: #10B981;  /* Emerald — más fresco que #22C55E */
```

### Eje 3 — Neutral con carácter (no `#F5F5F5` / `#212121`)
```css
/* En lugar de grises puros, usar grises con undertone azul (slate): */
--color-surface-app:  #F8FAFC;  /* Slate 50 — fondo principal con leve calidez fría */
--color-text-primary: #0F172A;  /* Slate 900 — no negro puro */
/* En modo oscuro: */
--color-surface-app:  #020617;  /* Slate 950 — más profundo que #121212 */
```

---

## Patrones de superficie diferenciados

En lugar de "todo es blanco o gris", definir superficies con propósito:

```css
/* Las 4 superficies del sistema */
.surface-app     { background: var(--color-surface-app); }     /* fondo de página */
.surface-card    { background: var(--color-surface-card); }    /* tarjetas de contenido */
.surface-sunken  { background: var(--color-surface-sunken); }  /* inputs, zonas hundidas */
.surface-sensitive { background: var(--color-surface-sensitive); } /* datos críticos */

/* Superficie de navegación — diferente al card */
.surface-nav {
  background: var(--color-surface-card);
  border-right: 1px solid var(--color-border-default);
  /* NO usar shadow en el sidebar — el borde es suficiente */
}

/* Superficie de paso activo en wizard */
.surface-step-active {
  background: var(--color-feedback-info-bg);
  border: 1px solid var(--color-border-focus);
}
```

---

## Estados vacíos (empty states)

Las pantallas vacías son momentos de identidad. No usar el texto genérico "No hay datos":

```html
<!-- Estado vacío estructurado -->
<div class="empty-state" role="status">
  <!-- Icono a 48px, strokeWidth 1.25, color text-secondary -->
  <lucide-icon name="shield-off" [size]="48" strokeWidth="1.25"
    style="color: var(--color-text-secondary)">
  </lucide-icon>

  <h3 class="type-heading-3" style="color: var(--color-text-primary)">
    Sin autenticación de dos factores
  </h3>

  <p class="type-body" style="color: var(--color-text-secondary); max-width: 300px; text-align: center">
    Activa TOTP para añadir una capa adicional de seguridad a tu cuenta.
  </p>

  <app-button variant="primary">Activar TOTP</app-button>
</div>
```

```css
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--space-4);
  padding: var(--space-16) var(--space-8);
  text-align: center;
}
```

---

## ❌ Qué NO hacer

- **No usar 3 o más estilos de radius en el mismo proyecto.** Si usas Moderate (8px base), TODOS los componentes usan esa escala.
- **No usar `box-shadow` para simular borders.** Si necesitas un borde, usa `border` — las sombras son para elevación.
- **No mezclar librerías de iconos.** Ni "solo para este componente especial" — rompe la coherencia.
- **No usar el rojo como color de acento visual o decoración.** El rojo es exclusivamente para danger/error.
- **No dejar estados vacíos sin contenido.** "No hay registros" sin icono ni acción = oportunidad perdida de guiar al usuario.
- **No usar `#000000` ni `#FFFFFF` puros.** El negro puro es demasiado harsh; usar `--primitive-neutral-900` o `950`. El blanco puro en modo oscuro mata el contraste sutil.
- **No usar la paleta de color de Material Design o Ant Design como punto de partida.** Empezar desde los primitivos definidos en `design-tokens`.

---

## Checklist de verificación

- [ ] El border radius system tiene un estilo dominante (sharp / moderate / friendly) y es consistente
- [ ] Se eligió UNA librería de iconos y está documentada en el proyecto
- [ ] Los iconos tienen tamaño y strokeWidth consistentes por contexto
- [ ] Los neutrales usan slate (con undertone azul) no grises puros
- [ ] Los colores de acción y de feedback son semánticamente separados (azul ≠ acción, rojo ≠ decoración)
- [ ] Las 4 superficies (app, card, sunken, sensitive) están diferenciadas visualmente
- [ ] Los estados vacíos tienen icono + heading + descripción + acción primaria
- [ ] En modo oscuro, los shadows están ajustados (más pronunciados que en modo claro)
- [ ] Ningún componente nuevo introduce un color que no existe en los tokens definidos
