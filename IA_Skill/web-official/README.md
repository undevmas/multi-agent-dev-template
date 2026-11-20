# Skills oficiales de la Plataforma Web (GoogleChrome / modern-web-guidance)

Copia curada de [github.com/GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance) —
skills y guías de mejores prácticas de la plataforma web moderna, mantenidas colaborativamente por
los equipos de Google Chrome, Microsoft Edge, Mozilla Firefox y MDN. Código bajo licencia Apache 2.0
(ver `LICENSE`); contenido de guías bajo [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)
con porciones derivadas de MDN Web Docs, W3C, WHATWG e IETF.

- **Versión instalada:** ver `SOURCE.txt` (commit, fecha, cantidad de guías).
- **Qué se instala:** `skills.manifest` define los paquetes sincronizados. Se instala
  `modern-web-guidance` (`SKILL.md` + 210 guías curadas en `guides/`). Se excluye `chrome-extensions`
  por estar fuera del stack aprobado.
- **Idioma:** inglés, sin modificar. **No editar** los archivos dentro de `modern-web-guidance/`: el
  script de sincronización los sobrescribe. Las adaptaciones a la plantilla van en este README o en
  las skills propias de `IA_Skill/`.

---

## Regla de precedencia (obligatoria)

Estas guías **complementan** a las skills propias de `IA_Skill/` (`frontend-design/*`,
`SKILL-frontend-design.md`, `SKILL-approved-libraries.md`, `SKILL-security-angular.md`); no las
reemplazan.

1. `AGENTS.md` (fuente única; `CLAUDE.md` y demás punteros la importan) → 2. `IA_Memoria/convenciones.md`
   → 3. skill propia de `IA_Skill/` → 4. guía oficial de esta carpeta (`modern-web-guidance`).
2. Leer primero la skill propia de la situación (según el catálogo `IA_Skill/README.md`); la guía
   oficial aporta el estándar moderno de la plataforma web (APIs nativas del navegador, CSS moderno,
   accesibilidad, rendimiento y fallbacks).
3. **Modo de consulta (local, obligatorio):** Todas las guías ya viven localmente en
   `IA_Skill/web-official/modern-web-guidance/guides/<categoria>/<id>.md`. El agente **lee el archivo
   local** (o busca con `grep`/`find` en esta carpeta). Aunque las guías indiquen `npx -y modern-web-guidance@latest`
   (más de 100 menciones), ejecutarlo **requiere confirmación explícita del dev**: descarga y ejecuta la última
   versión de un paquete npm de terceros sin versión fijada (riesgo de cadena de suministro), usa red y puede
   enviar telemetría (`DISABLE_TELEMETRY=1` si se autoriza).
4. Si una guía oficial contradice a la plantilla, **gana la plantilla**. Conflictos ya identificados:

| Guía / sección oficial | Lo que dice | Lo que aplica en la plantilla |
|---|---|---|
| `SKILL.md` (Step 1 & 2: `npx -y modern-web-guidance@latest search/retrieve`) | Ejecutar `npx` en cada tarea de HTML/CSS/JS | **Lectura local obligatoria** en `IA_Skill/web-official/modern-web-guidance/guides/<categoria>/<id>.md`. Ejecutar el CLI (`search`, `retrieve`, `legacy-scan`) solo con confirmación explícita del dev: es código de terceros sin versión fijada, usa red y puede enviar telemetría |
| `SKILL.md` (Step 4: Disclose Skill Usage) | Terminar la respuesta con una sección `### Modern Web Guidance` en primera persona y citas textuales | **Opcional / subordinado al formato de entrega de la tarea.** En implementaciones guiadas por Spec (`SKILL-implementation.md`) o reportes del router, respetar el formato de la plantilla y **nunca** romper el candado `Claro team` de la primera línea |
| `SKILL.md` y varias guías (`dialog`, `menu`, `tabs`, `persistent-toast-notifications`, `sanitize-untrusted-html`) | Instalar polyfills o librerías por npm (`invokers-polyfill`, `@oddbird/popover-polyfill`, `@oddbird/css-anchor-positioning`, `@microsoft/focusgroup-polyfill`, `SimpleWebAuthn`, `workbox-*`) | Ninguna dependencia fuera de `SKILL-approved-libraries.md` se instala sin **confirmación explícita** del dev. En el track **HTML/JS vanilla** (`SKILL-frontend-design.md`) está prohibido `npm` y cualquier build step: usar el fallback de `@supports` / JS nativo que la propia guía ofrece |
| `guides/ui-components/*` y `guides/html/web-components.md` | Construir componentes con HTML/JS vanilla o Web Components (`customElements.define`, Shadow DOM) | Respetar la arquitectura del track del proyecto (`SKILL-approved-libraries.md`): en **Angular**, CDK + Material híbrido re-temeado (`--mat-sys-*`); en **React**, Radix UI + `shadcn/ui`; en **HTML vanilla**, las guías nativas (`<dialog>`, `[popover]`, `<details>`) aplican directo |
| `guides/visual-design/dark-mode.md` y `guides/ui-components/dark-mode-toggle.md` | Theming vía `<meta name="color-scheme">` + `light-dark()` y sincronización en `localStorage` | Excelente complemento (`color-scheme: light dark` evita FOUC y estiliza scrollbars/inputs nativos). En Angular/React mantener compatibilidad con los tokens semánticos en `:root` y `[data-theme="dark"]` / `.dark` de `SKILL-dark-mode-theming.md` y `SKILL-design-tokens.md`. Nota: guardar la preferencia de tema (`light`/`dark`) en `localStorage` es válido; lo prohibido por `AGENTS.md` es guardar **tokens de autenticación o datos sensibles** en `localStorage`/`sessionStorage` |
| `guides/ui-atoms/icons.md` | Motor de íconos en CSS con `@property --icon-start`, `@container style()` y máscaras SVG | En Angular (`lucide-angular`), React (`lucide-react`) y vanilla (SVG inline de Lucide) el estándar de la plantilla es **Lucide** (`SKILL-approved-libraries.md`). Las reglas de accesibilidad (`aria-hidden="true"` en decorativos, contraste ≥ 3:1, `forced-color-adjust`) sí aplican en todos los tracks |
| `guides/ui-atoms/responsive-table.md` y `guides/ui-behaviors/sortable-table.md` | Tabla HTML nativa con `@container`, headers sticky y sort en cliente | En Angular con paginación/sort server-side aplica `SKILL-angular-data-table-pattern.md` (`CdkTable` + `MatPaginator`/`MatSort` re-temeados, nunca paginar/ordenar todo el dataset en cliente). Las mejoras CSS (`position: sticky`, `@container`, `role="region"` + `tabindex="0"` en el wrapper scrollable) sí complementan la tabla |
| `guides/security/passkeys.md` (`passkey-*`, `quick-sign-ins`) y `guides/privacy/privacy.md` (`FedCM`) | WebAuthn / Passkeys directo en cliente, `SimpleWebAuthn` / `fido2-net-lib` en servidor, FedCM | La autenticación del proyecto sigue estrictamente el **Perfil A (OIDC + PKCE + BFF)** o **Perfil B (ASP.NET Core Identity)** registrado en `IA_Memoria/arquitectura.md` (`SKILL-auth-patterns.md`). Solo usar las guías de Passkeys cuando la Spec del proyecto incluya WebAuthn/Passkeys explícitamente |
| `guides/built-in-ai/*` (`language-model`, `summarizer`, `translator`, `language-detection`) y `guides/webmcp/*` | APIs experimentales en el navegador (`LanguageModel`, `Summarizer`, `Translator`, `document.modelContext` / WebMCP en Chrome Early Preview) | Son APIs no-Baseline / Early Preview. No incorporarlas sin que la Spec o el usuario lo pidan explícitamente. La integración de IA de negocio en backend .NET sigue `SKILL-stack-policy.md` (`Microsoft.Extensions.AI`) |

---

## Mapa de disciplinas y guías instaladas (210 guías en 17 categorías)

Ubicación base: `IA_Skill/web-official/modern-web-guidance/guides/`

| Categoría | Guía raíz (disciplina) | Qué cubre y guías destacadas |
|---|---|---|
| `css/` (18) | `css/css.md`, `css/css-layout.md`, `css/responsive-design.md` | `@layer`, `@scope`, `:has()`, `:is()`/`:where()`, logical properties, Subgrid, `@container` (size y style queries), `fluid-scaling`, `animate-to-intrinsic-sizes` (`interpolate-size`), `calc-size()` |
| `visual-design/` (22) | `visual-design/color.md`, `visual-design/typography.md`, `visual-design/dark-mode.md`, `visual-design/visual-effects.md`, `visual-design/browser-ui-theming.md` | `color-scheme`, `light-dark()`, `color-mix(in oklab, ...)` (evitando el bug de `oklch` en neutros), Forced Colors Mode, `text-wrap: balance`/`pretty`, `clamp()` accesible al zoom 200%, `scrollbar-color`, `accent-color`, `visually-stable-font-fallbacks` |
| `forms/` (19) | `forms/forms.md` | Semántica `<form>`/`<search>`/`<fieldset>`, matriz de controles (radio vs select vs checkbox), validación tardía con `:user-invalid` (nunca `:invalid` crudo), timing `blur`/`input`/`submit`, `inputmode`, `enterkeyhint`, `autocomplete`, OTP en un solo `<input autocomplete="one-time-code">` (`sms-otp-form`), `field-sizing: content`, `switch`, `ime-safe-enter-submit` |
| `ui-components/` (22) | `dialog.md`, `navigation-drawer.md`, `tabs.md`, `menu.md`, `accordion.md`, `card.md`, `persistent-toast-notifications.md`, `navbar.md`, `carousel.md`, `toolbar.md` | `<dialog>` modal (`showModal()`, `closedby`, `overscroll-behavior: contain` en `:modal` y `::backdrop`), Popover API (`popover="auto"` vs `popover="manual"`), `<details name="...">` y `::details-content`, `focusgroup`, `hidden="until-found"` |
| `ui-behaviors/` (40) | `ui-behaviors/motion.md` | `@starting-style` + `transition-behavior: allow-discrete` + `overlay` (`animate-element-entry-exit`, `animate-to-from-top-layer`), Invoker Commands (`commandfor`/`command` en `declarative-dialog-popover-control`), View Transitions (`same-document-transitions`, `scoped-component-transitions`, `cross-document-transitions`), Scroll-Driven Animations (`animation-timeline: scroll()`), `moveBefore()` (`move-dom-element-without-losing-state`), `anchor-positioning-tab-underline`, `search-hidden-content` |
| `ui-atoms/` (13) | `responsive-table.md`, `viewport-aware-dropdowns.md`, `position-aware-tooltips.md`, `single-line-overflow.md`, `state-aware-sticky-headers.md`, `scrollability-affordance-hints.md` | CSS Anchor Positioning (`position-area`, `position-try-fallbacks: flip-block, flip-inline`), tablas adaptativas con `@container` y sticky headers, sombras/fades de scroll con scroll-driven animations |
| `accessibility/` (4) | `accessibility/accessibility.md` | Landmarks, jerarquía de headings, `.visually-hidden`, gestión de foco, tamaño mínimo de objetivo (`24×24px` WCAG AA / `44–48px` en `pointer: coarse`), `accessible-error-announcement`, `accessible-generated-content` (`content: ... / "alt"`), `respect-os-text-scale` |
| `performance/` (26) | `performance/performance.md` | Core Web Vitals: LCP (`fetchpriority="high"`, nunca `loading="lazy"` above-the-fold), INP (`scheduler.yield()` en `break-up-long-tasks`, `identify-inp-causes`), CLS (`aspect-ratio`, dimensiones explícitas, `content-visibility: auto` + `contain-intrinsic-size` en `defer-rendering-heavy-content`), `improve-next-page-load-performance` (Speculation Rules), `batch-analytics-events` (`fetchLater`) |
| `security/` (17) | `security/security.md` | CSP con nonces/hashes + `'strict-dynamic'`, `trusted-types` (`require-trusted-types-for 'script'`), Sanitizer API (`setHTML()` + fallback a `DOMPurify` en `sanitize-untrusted-html`), cookies `__Host-`/`HttpOnly`/`SameSite`, `frame-ancestors`, COOP/CORP, Fetch Metadata (`Sec-Fetch-*`), SRI (`secure-external-subresources`), `validate-origins`, `Clear-Site-Data`, `passkeys` |
| `html/` (8) | `html/html.md`, `html/web-components.md` | Semántica HTML5 (`<search>`, `<dialog>`, `[popover]`, `<details>`, `inert`), `custom-elements`, `shadow-dom`, `form-associated-custom-elements`, `accessible-web-components` (`ElementInternals`) |
| `js/` (6) | `js/js.md` | `structuredClone()`, métodos inmutables de Array (`.toSorted()`, `.toReversed()`, `.toSpliced()`, `.with()`, `.findLast()`), `Object.groupBy()` / `Map.groupBy()`, `Promise.withResolvers()`, `AbortSignal.timeout()` / `AbortSignal.any()`, `Error(..., { cause })`, `URLSearchParams`, `TextEncoder`/`TextDecoder`, `Element.replaceChildren()`, `Temporal` (`calculate-event-differentials`, `capture-location-agnostic-data`, `coordinate-global-events`) |
| `user-experience/` (3) | `content-first-noise-reduction.md`, `form-factor-adaptation.md`, `natural-interactions.md` | Reducción de ruido visual, adaptación a factor de forma (touch/pointer/teclado), micro-interacciones naturales |
| `privacy/` (1) | `privacy/privacy.md` | Minimización de datos, `Permissions-Policy`, `Referrer-Policy`, `Clear-Site-Data`, patrón Façade para embeds, Feature Detection vs User-Agent fingerprinting |
| `pwa/` (2) | `install-web-app.md`, `migrate-web-app-origin.md` | Web App Manifest con `id` estable, instalación con `<install>` / `navigator.install()` y fallback a `beforeinstallprompt` |
| `built-in-ai/` (5), `wasm/` (1), `webmcp/` (3) | `language-model.md`, `cpp-on-the-web.md`, `webmcp.md` | Consulta puntual solo si el proyecto requiere IA local en navegador, WebAssembly o WebMCP |

---

## Excluidas a propósito

| Skill pack | Motivo |
|---|---|
| `chrome-extensions` | Construcción y publicación de extensiones de Chrome (Manifest V3 / Chrome Web Store); fuera del stack de aplicaciones web de la plantilla. Si un proyecto futuro es una extensión de navegador, agregarla a `skills.manifest` con aprobación |

---

## Actualizar o cambiar la selección

```powershell
# Windows
.\IA_Skill\web-official\sync-web-skills.ps1
```

```bash
# Linux / macOS / Git Bash
./IA_Skill/web-official/sync-web-skills.sh
```

El script clona solo `skills/` del repo en una carpeta temporal, valida que todas las entradas de
`skills.manifest` existan (si alguna cambió, aborta sin borrar nada), reemplaza las carpetas de
skills instaladas, copia `LICENSE` y reescribe `SOURCE.txt`. Acepta `-Source <ruta>` (o argumento
posicional en bash) hacia un clon local para trabajar sin red.

Después de sincronizar:
1. Revisar el diff (`git diff IA_Skill/web-official`) — es contenido de terceros que los agentes
   van a seguir. Verificar que no se hayan incluido binarios o scripts que contradigan la tabla de
   precedencia.
2. Si cambiaron rutas de guías citadas en `IA_Skill/README.md` o `IA_Skill/SKILL-instruction-router.md`,
   actualizarlas y correr `.\IA_Skill\check-instruction-policy-sync.ps1` y
   `.\IA_Skill\test-antigravity-workflow.ps1`.
3. Actualizar la tabla de conflictos de este README si aparece uno nuevo.
