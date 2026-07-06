---
name: frontend-design/gradient-accents
description: >
  Eleva los colores de acción (botones primarios, CTAs, focus rings) de un azul
  plano genérico a un sistema con profundidad tonal — gradiente sutil de 2 tonos
  dentro de la misma familia de color — y define un componente aparte de mesh
  gradient para heroes de marketing. Úsala cuando un botón primario o CTA se vea
  "azul tipo Bootstrap sin personalizar" y necesite un tratamiento más premium,
  sin caer en gradientes decorativos multicolor fuera de lugar en dashboards/admin.
stack: Angular 17+ · React 18+ · HTML/CSS vanilla (CSS Custom Properties) · Tailwind (opcional)
contexts: Dashboard · Admin panel · Landing/marketing page · Formularios
---

# SKILL: Gradient Accents — Botones con Profundidad + Mesh Gradient de Marketing

## Cuándo usar esta skill

Actívala cuando:
- Un botón primario o CTA se vea plano/genérico — el síntoma es "azul sólido tipo Bootstrap default" sin ningún tratamiento adicional.
- Se esté construyendo una landing o página de marketing con hero y se busque un fondo tipo "mesh gradient" (Stripe/Linear/Vercel-style).
- Se quiera diferenciar visualmente un CTA principal del resto de acciones secundarias sin introducir un segundo color semántico.

**No la actives para reemplazar toda la paleta de un dashboard.** El mesh gradient de este documento es un componente de **hero/marketing únicamente**. En dashboards y admin panels (`SKILL-visual-identity-override.md`, estilo "Moderate") el fondo se mantiene plano — solo los botones/CTAs ganan el tratamiento de gradiente sutil de 2 tonos.

---

## Regla central: dos niveles de intensidad, nunca se mezclan

| Contexto | Tratamiento permitido | Tratamiento prohibido |
|---|---|---|
| Botón primario en dashboard/admin/formulario | Gradiente sutil de 2 tonos, misma familia de color (ej. blue-600 → blue-700, o blue-600 → indigo-600) | Gradiente multicolor, mesh, o más de 2 stops |
| CTA principal de landing/marketing (hero) | Gradiente sutil de 2 tonos igual que arriba, **o** el botón puede vivir sobre un fondo mesh gradient | — |
| Fondo de sección / hero de marketing | Mesh gradient (`--gradient-mesh-hero`, ver abajo) | Nunca en dashboards, tablas, formularios internos, admin panels |

La razón de no mezclar: un botón con gradiente de 2 tonos se lee como "pulido"; un fondo mesh gradient detrás de una tabla de datos se lee como "sitio de marketing", no como herramienta de trabajo — rompe la seriedad que ya definiste en `visual-identity-override` para admin/dashboard.

---

## 1. Tokens — extienden, no reemplazan, los de `SKILL-design-tokens.md` / `SKILL-frontend-design.md`

```css
:root {
  /* Ya existentes — no tocar */
  --color-action-primary:       var(--primitive-blue-600);
  --color-action-primary-hover: var(--primitive-blue-500);

  /* NUEVOS — gradiente de acción, 2 tonos, misma familia */
  --gradient-action-primary: linear-gradient(135deg, #2563eb 0%, #4f46e5 100%);
  --gradient-action-primary-hover: linear-gradient(135deg, #1d4ed8 0%, #4338ca 100%);
  --gradient-action-danger: linear-gradient(135deg, #dc2626 0%, #be123c 100%);

  /* Sombra de color a juego con el gradiente — reemplaza el shadow gris genérico en el CTA principal */
  --shadow-action-primary: 0 4px 14px rgba(37, 99, 235, 0.32);
  --shadow-action-primary-hover: 0 6px 20px rgba(37, 99, 235, 0.4);

  /* Mesh gradient — SOLO para hero de marketing, nunca en dashboard */
  --gradient-mesh-hero:
    radial-gradient(at 15% 20%, hsla(280, 90%, 78%, 0.85) 0px, transparent 55%),
    radial-gradient(at 80% 15%, hsla(210, 90%, 65%, 0.8) 0px, transparent 50%),
    radial-gradient(at 70% 65%, hsla(340, 90%, 60%, 0.85) 0px, transparent 55%),
    radial-gradient(at 20% 75%, hsla(25, 95%, 65%, 0.8) 0px, transparent 55%),
    linear-gradient(135deg, #dceeff 0%, #eef2ff 100%);
}

[data-theme="dark"] {
  --shadow-action-primary: 0 4px 18px rgba(79, 70, 229, 0.45);
}
```

Por qué 2 stops y no más en los botones: un gradiente de más de 2 colores en un elemento de 40px de alto no se percibe como "elegante", se percibe como ruido — el ojo no alcanza a leer la transición. El efecto premium viene de la sutileza (mismo hue, distinto tono), no de la cantidad de color.

---

## 2. Botón primario con gradiente (reemplaza el botón plano)

```css
.btn-primary {
  background: var(--gradient-action-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-sm, 8px);
  padding: 10px 20px;
  font: 600 14px var(--font-sans, sans-serif);
  cursor: pointer;
  box-shadow: var(--shadow-action-primary);
  transition: box-shadow 200ms cubic-bezier(0.4,0,0.2,1),
              transform 100ms cubic-bezier(0.4,0,0.2,1);
}
.btn-primary:hover {
  background: var(--gradient-action-primary-hover);
  box-shadow: var(--shadow-action-primary-hover);
}
.btn-primary:active { transform: scale(0.98); }
.btn-primary:focus-visible {
  outline: none;
  box-shadow: var(--shadow-action-primary), 0 0 0 3px rgba(37,99,235,.35);
}
.btn-primary:disabled {
  background: var(--color-border-strong, #cbd5e1);
  box-shadow: none;
  cursor: not-allowed;
}
```

Esto es un reemplazo directo de cualquier `.btn-primary { background: var(--color-action-primary); }` plano — mismo nombre de clase, mismo lugar en el HTML, solo cambia el valor de `background` y se añade `box-shadow` de color. No requiere tocar markup.

### Integración React/Tailwind (clase utilitaria, sin config extra)

```jsx
<button className="bg-gradient-to-br from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700
                    text-white font-semibold px-5 py-2.5 rounded-lg
                    shadow-[0_4px_14px_rgba(37,99,235,0.32)]
                    hover:shadow-[0_6px_20px_rgba(37,99,235,0.4)]
                    active:scale-[0.98] transition-all">
  Continuar
</button>
```

### Integración Angular (misma clase CSS, sin lógica adicional)

```html
<button class="btn-primary" (click)="onSubmit()">Continuar</button>
```

---

## 3. Mesh gradient hero — SOLO para landing/marketing

```css
.hero-mesh {
  background: var(--gradient-mesh-hero);
  background-color: #eef2ff; /* fallback si el navegador no soporta múltiples radial-gradient */
  border-radius: var(--radius-lg, 20px);
  padding: var(--space-8, 32px);
  position: relative;
  overflow: hidden;
}

/* Nav dentro del hero — texto claro sobre el mesh, nunca --color-text-primary oscuro */
.hero-mesh .hero-nav { display: flex; justify-content: space-between; align-items: center; }
.hero-mesh .hero-brand { color: #fff; font-weight: 700; font-size: 14px; letter-spacing: .02em; }
.hero-mesh .hero-cta {
  background: rgba(255,255,255,0.22);
  backdrop-filter: blur(8px);
  color: #fff;
  border: 1px solid rgba(255,255,255,0.35);
  border-radius: 999px;
  padding: 8px 18px;
  font: 600 13px var(--font-sans, sans-serif);
}
```

```html
<section class="hero-mesh">
  <nav class="hero-nav">
    <span class="hero-brand">MYWEBSITE</span>
    <button class="hero-cta">Sign In →</button>
  </nav>
  <!-- contenido del hero: headline, subheadline, CTA principal -->
</section>
```

Genera el mesh combinando 3–5 `radial-gradient` con `hsla()` (facilita ajustar solo el matiz/saturación sin recalcular hex) y transiciones suaves vía `transparent` como stop final. Nunca usar `conic-gradient` para este efecto — el mesh busca manchas orgánicas, no un giro geométrico.

---

## 4. Card con profundidad — gradiente + hover-lift (sin animación infinita)

El efecto "card premium" (fondo con gradiente, sombra que escala en hover, ligero levantamiento) se logra con transform + box-shadow, sin animar el gradiente en loop — animar `hue-rotate` de forma infinita no comunica ningún cambio de estado y contradice el principio de `SKILL-animation-microinteractions.md` ("cada animación responde una pregunta"). Usar la versión con propósito:

```css
.card-gradient {
  background: linear-gradient(135deg, #4338ca 0%, #7c3aed 100%);
  border-radius: var(--radius-lg, 16px);
  padding: var(--space-8, 32px);
  color: #fff;
  text-align: center;
  box-shadow: 0 10px 30px rgba(76, 29, 149, 0.35);
  transition: transform 300ms cubic-bezier(0.4,0,0.2,1),
              box-shadow 300ms cubic-bezier(0.4,0,0.2,1);
}
.card-gradient:hover {
  transform: translateY(-6px);
  box-shadow: 0 18px 40px rgba(76, 29, 149, 0.45);
}
.card-gradient .card-title { font: 700 26px var(--font-sans, sans-serif); margin: 0 0 var(--space-4, 16px); }
.card-gradient .card-text { font: 400 15px/1.6 var(--font-sans, sans-serif); opacity: 0.9; margin: 0 0 var(--space-6, 24px); }

/* Botón dentro de la card — glass, no gradiente propio (ya está sobre uno) */
.card-gradient .btn-on-gradient {
  background: rgba(255,255,255,0.12);
  border: 1px solid rgba(255,255,255,0.3);
  backdrop-filter: blur(6px);
  color: #fff;
  padding: 12px 28px;
  border-radius: var(--radius-md, 10px);
  font: 600 14px var(--font-sans, sans-serif);
  transition: background 200ms ease, transform 100ms ease;
}
.card-gradient .btn-on-gradient:hover { background: rgba(255,255,255,0.22); }
.card-gradient .btn-on-gradient:active { transform: scale(0.97); }
```

Uso permitido: cards destacadas en landing/marketing (pricing card destacado, feature card hero). **No usar `.card-gradient` en dashboards/admin** — ahí la card se queda con `SKILL-design-tokens.md` estándar (`--color-surface-card` blanco, `--shadow-card` neutro), consistente con la regla central de esta skill.

Si de verdad quieres algo de movimiento en el fondo sin loop infinito, la alternativa con propósito es animar el gradiente **una sola vez** al entrar en viewport (`animation-iteration-count: 1`), nunca `infinite`.


- No animar un gradiente de fondo en loop infinito (`hue-rotate` u otro) — no comunica ningún cambio de estado, consume batería sin propósito, y contradice el principio central de `SKILL-animation-microinteractions.md`. Si necesitas movimiento, que sea una sola vez (`animation-iteration-count: 1`) al entrar en viewport, nunca `infinite`.
- No aplicar `--gradient-mesh-hero` como fondo de un dashboard, tabla, formulario interno o admin panel — es exclusivo de landing/marketing. Si dudas, revisa `visual-identity-override.md`: si el contexto es "Admin panel con datos técnicos", el fondo se queda plano.
- No usar más de 2 stops de color en un botón — el mesh multicolor vive en fondos grandes (hero), no en elementos de 40px.
- No poner texto oscuro (`--color-text-primary`) sobre el mesh gradient — siempre blanco o con `backdrop-filter` de por medio.
- No mezclar el mesh gradient con el estilo "Sharp" (2–4px radius) de `visual-identity-override` — el mesh pide esquinas más suaves (`--radius-lg` o mayor), o se ve inconsistente.
- No reutilizar el mismo mesh gradient en dos landings distintas del mismo cliente sin variar el hue — se vuelve una plantilla reconocible en vez de una identidad propia.

---

## Checklist de verificación

- [ ] El botón primario usa `--gradient-action-primary` (2 stops, misma familia de color), no un color sólido plano
- [ ] El hover del botón primario cambia a `--gradient-action-primary-hover` + sombra más pronunciada
- [ ] El mesh gradient (`--gradient-mesh-hero`) solo aparece en secciones de landing/marketing, nunca en dashboard/admin
- [ ] El texto sobre el mesh gradient es blanco o usa `backdrop-filter`, nunca `--color-text-primary`
- [ ] Ningún botón de dashboard/formulario interno usa el mesh gradient de fondo
- [ ] Las cards con `.card-gradient` (hover-lift + sombra de color) solo aparecen en landing/marketing, nunca en dashboard/admin
- [ ] Ningún gradiente de fondo anima en loop infinito — máximo una vez al entrar en viewport
- [ ] El focus-visible del botón primario sigue siendo visible sobre el gradiente (anillo blanco/azul con suficiente contraste)
