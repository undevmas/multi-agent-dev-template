# Catálogo de skills — situación → skill

> Índice completo para elegir skill por situación. Leer bajo demanda: primero el router
> (`IA_Skill/SKILL-instruction-router.md`) define la skill primaria y las auxiliares; este
> catálogo resuelve el caso puntual. Rutas relativas a la raíz del workspace.

### Punto de entrada — Auditoría Pre-Productiva

| Situación | Skill a leer |
|---|---|
| "Actúa como agente analista pre-productivo", "corre el checklist pre-prod", "auditoría de seguridad antes de liberar [todo el proyecto]" | IA_Skill/SKILL-preprod-security-audit.md — orquesta el resto, no leer las skills de seguridad sueltas directamente para este caso. Es la única fila de esta tabla que dispara con la palabra "pre-producción"/"pre-prod" a secas — si el pedido es sobre una feature/endpoint puntual (no "todo el proyecto"), no aplica esta fila, ver "Revisión OWASP" en la sección Seguridad |

### Frontend

| Situación | Skill a leer |
|---|---|
| Crear o modificar componente reutilizable con variantes | IA_Skill/frontend-design/SKILL-component-patterns.md |
| Definir o aplicar tokens de diseño (color, espaciado, radio, sombras) | IA_Skill/frontend-design/SKILL-design-tokens.md |
| Configurar o ajustar sistema tipográfico del proyecto | IA_Skill/frontend-design/SKILL-typography-system.md |
| Diseñar layout, grid o sistema de espaciado | IA_Skill/frontend-design/SKILL-layout-spacing-system.md |
| Definir identidad visual (paleta de brand, radius, iconografía) | IA_Skill/frontend-design/SKILL-visual-identity-override.md |
| Librería de terceros a usar (componentes, iconos, gráficas, animación) — antes de instalar cualquier dependencia | IA_Skill/SKILL-approved-libraries.md |
| Tabla server-side/paginación/sort en Angular | IA_Skill/frontend-design/SKILL-angular-data-table-pattern.md |
| Botones/CTAs con gradiente premium, o hero de landing tipo mesh gradient | IA_Skill/frontend-design/SKILL-gradient-accents.md — el mesh gradient es SOLO para landing/marketing, nunca dashboard/admin |
| Implementar dark mode o theming (claro/oscuro, multi-tenant) | IA_Skill/frontend-design/SKILL-dark-mode-theming.md |
| Implementar diseño responsive o patrones PWA | IA_Skill/frontend-design/SKILL-responsive-pwa-patterns.md |
| Agregar animaciones o micro-interacciones a componentes | IA_Skill/frontend-design/SKILL-animation-microinteractions.md |
| Implementar accesibilidad (a11y / WCAG AA) en componentes o pantallas | IA_Skill/frontend-design/SKILL-accessibility-a11y.md |
| Code review o generación de código frontend enfocado en calidad/mantenibilidad (no estética) | IA_Skill/SKILL-impeccable.md |
| Decisiones de UX avanzadas: formularios complejos, flujos multi-paso, dashboards, estados de carga/error | IA_Skill/SKILL-ui-ux-pro-max.md |
| Crear o modificar una vista pública indexable (login, landing) — SEO | IA_Skill/SKILL-seo.md |
| Escribir tests en Angular (TestBed, Jest) | IA_Skill/SKILL-angular-test-frameworks.md |
| Escribir tests en React (Jest + Testing Library) | IA_Skill/SKILL-react-test-frameworks.md |
| Diseño moderno en HTML/JS vanilla (sin framework, sin npm) | Leer en secuencia: IA_Skill/SKILL-frontend-design.md (tokens, tipografía, layout y componentes para HTML/CSS/JS puro) → IA_Skill/SKILL-animation-microinteractions.md → IA_Skill/SKILL-gradient-accents.md → IA_Skill/frontend-design/SKILL-accessibility-a11y.md. Sin Bootstrap en output final, sin npm, sin build step, sin frameworks JS (React, Vue, Alpine). Google Fonts vía `<link>` permitido. CSS en archivo propio, no inline. |

### Frontend — plataforma web moderna (GoogleChrome / modern-web-guidance, complementarias)

Copia curada de [GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance) en `IA_Skill/web-official/` (210 guías en inglés, sin modificar; origen, versión, exclusiones y reglas en `IA_Skill/web-official/README.md`). Leer primero la skill propia de la tabla de arriba (`frontend-design/*` o `SKILL-frontend-design.md`); la guía oficial aporta el estándar moderno del navegador (APIs nativas, CSS moderno, accesibilidad, rendimiento y fallbacks). **Leer siempre el archivo local bajo `IA_Skill/web-official/`. Ejecutar `npx modern-web-guidance` (incluido `legacy-scan`) requiere confirmación explícita del dev: descarga y ejecuta la última versión de un paquete npm de terceros, sin versión fijada. Si contradice a esta plantilla, gana la plantilla**: arquitectura por track de `SKILL-approved-libraries.md` (CDK+Material re-temeado en Angular, Radix+shadcn en React, sin npm en vanilla), íconos con Lucide, perfiles de auth A/B de `SKILL-auth-patterns.md` y confirmación explícita antes de instalar cualquier polyfill o paquete npm. La tabla completa de conflictos está en `IA_Skill/web-official/README.md`.

| Situación | Guía oficial (bajo `IA_Skill/web-official/`) |
|---|---|
| Arquitectura CSS moderna (`@layer`, `@scope`, `:has()`, `:is()`/`:where()`, logical properties, tokens) | `modern-web-guidance/guides/css/css.md` |
| Layouts CSS modernos: Flexbox, Grid, Subgrid, `@container` (size y style queries), `aspect-ratio`, `dvh`/`svh`, `scrollbar-gutter` | `modern-web-guidance/guides/css/css-layout.md` · `modern-web-guidance/guides/css/responsive-design.md` · `modern-web-guidance/guides/css/size-aware-styling.md` · `modern-web-guidance/guides/css/fluid-scaling.md` |
| Modales, drawers y overlays nativos (`<dialog>`, `showModal()`, `closedby`, `[popover]`, Invoker Commands `commandfor`/`command`) | `modern-web-guidance/guides/ui-components/dialog.md` · `modern-web-guidance/guides/ui-components/navigation-drawer.md` · `modern-web-guidance/guides/ui-behaviors/declarative-dialog-popover-control.md` · `modern-web-guidance/guides/ui-behaviors/prevent-page-scroll-under-modal-dialog.md` |
| Dropdowns, menús, tooltips y elementos anclados con CSS Anchor Positioning (`position-area`, `position-try-fallbacks`) | `modern-web-guidance/guides/ui-components/menu.md` · `modern-web-guidance/guides/ui-atoms/viewport-aware-dropdowns.md` · `modern-web-guidance/guides/ui-atoms/position-aware-tooltips.md` · `modern-web-guidance/guides/ui-behaviors/interest-triggered-tooltips.md` |
| Componentes UI nativos y patrones de interacción: tabs (`focusgroup`, `hidden="until-found"`), accordions (`<details name>`), cards (`subgrid`, `@container`), toasts (`popover="manual"`, `ariaNotify`) | `modern-web-guidance/guides/ui-components/tabs.md` · `modern-web-guidance/guides/ui-components/accordion.md` · `modern-web-guidance/guides/ui-components/card.md` · `modern-web-guidance/guides/ui-components/persistent-toast-notifications.md` · `modern-web-guidance/guides/ui-atoms/responsive-table.md` |
| Formularios modernos: semántica `<form>`/`<search>`, validación tardía (`:user-invalid`, timing `blur`/`input`/`submit`), `autocomplete`, `inputmode`, `enterkeyhint`, OTP (`one-time-code`), `<select>` estilizado (`appearance: base-select`), `field-sizing: content`, `switch` | `modern-web-guidance/guides/forms/forms.md` · `modern-web-guidance/guides/forms/validate-input-after-interaction.md` · `modern-web-guidance/guides/forms/required-field-feedback.md` · `modern-web-guidance/guides/forms/sms-otp-form.md` · `modern-web-guidance/guides/forms/branded-select-styling.md` · `modern-web-guidance/guides/forms/form-fields-automatically-fit-contents.md` · `modern-web-guidance/guides/forms/switch.md` |
| Modo oscuro, color, tipografía y theming de UI nativa (`<meta name="color-scheme">`, `light-dark()`, `color-mix(in oklab, ...)`, Forced Colors Mode, `text-wrap: balance`/`pretty`, `clamp()`, `scrollbar-color`, `accent-color`) | `modern-web-guidance/guides/visual-design/dark-mode.md` · `modern-web-guidance/guides/ui-components/dark-mode-toggle.md` · `modern-web-guidance/guides/visual-design/color.md` · `modern-web-guidance/guides/visual-design/typography.md` · `modern-web-guidance/guides/visual-design/browser-ui-theming.md` · `modern-web-guidance/guides/visual-design/visual-effects.md` |
| Animaciones de entrada/salida, Top Layer, View Transitions y Scroll-Driven Animations (`@starting-style`, `transition-behavior: allow-discrete`, `overlay`, `interpolate-size`, `animation-timeline: scroll()`) | `modern-web-guidance/guides/ui-behaviors/motion.md` · `modern-web-guidance/guides/ui-behaviors/animate-element-entry-exit.md` · `modern-web-guidance/guides/ui-behaviors/animate-to-from-top-layer.md` · `modern-web-guidance/guides/css/animate-to-intrinsic-sizes.md` · `modern-web-guidance/guides/ui-behaviors/same-document-transitions.md` · `modern-web-guidance/guides/ui-behaviors/scoped-component-transitions.md` |
| Accesibilidad web (WCAG AA, landmarks, nombres accesibles, `.visually-hidden`, anuncios de error con `:user-invalid` + `aria-invalid`, contenido generado accesible) | `modern-web-guidance/guides/accessibility/accessibility.md` · `modern-web-guidance/guides/accessibility/accessible-error-announcement.md` · `modern-web-guidance/guides/accessibility/accessible-generated-content.md` · `modern-web-guidance/guides/accessibility/respect-os-text-scale.md` |
| Rendimiento web y Core Web Vitals: LCP (`fetchpriority="high"`), INP (`scheduler.yield()`), CLS (`aspect-ratio`, `content-visibility: auto` + `contain-intrinsic-size`), Speculation Rules | `modern-web-guidance/guides/performance/performance.md` · `modern-web-guidance/guides/performance/optimize-image-priority.md` · `modern-web-guidance/guides/performance/break-up-long-tasks.md` · `modern-web-guidance/guides/performance/defer-rendering-heavy-content.md` · `modern-web-guidance/guides/performance/interactions-in-complex-layouts.md` · `modern-web-guidance/guides/performance/improve-next-page-load-performance.md` |
| Seguridad y privacidad en el navegador (CSP con nonces/hashes + `'strict-dynamic'`, Trusted Types, Sanitizer API `setHTML()` + fallback DOMPurify, cookies `__Host-`, COOP/CORP, Fetch Metadata, SRI, `Clear-Site-Data`) | `modern-web-guidance/guides/security/security.md` · `modern-web-guidance/guides/security/sanitize-untrusted-html.md` · `modern-web-guidance/guides/security/trusted-types.md` · `modern-web-guidance/guides/security/secure-external-subresources.md` · `modern-web-guidance/guides/security/validate-origins.md` · `modern-web-guidance/guides/privacy/privacy.md` |
| HTML semántico, Web Components y JavaScript moderno (`structuredClone`, `.toSorted()`, `Object.groupBy`, `Promise.withResolvers`, `AbortSignal.timeout`/`any`, `URLSearchParams`, `replaceChildren`, `Temporal`) | `modern-web-guidance/guides/html/html.md` · `modern-web-guidance/guides/html/web-components.md` · `modern-web-guidance/guides/js/js.md` · `modern-web-guidance/guides/pwa/install-web-app.md` |
| Buscar en el catálogo completo de 210 guías o auditar patrones web legados para modernizar | `modern-web-guidance/SKILL.md` (buscar primero en archivos locales de `IA_Skill/web-official/modern-web-guidance/guides/`; usar CLI `legacy-scan` solo con aprobación en modernizaciones amplias) |

### Backend .NET

| Situación | Skill a leer |
|---|---|
| Crear o modificar cualquier archivo .NET (controller, service, repository) | IA_Skill/SKILL-dotnet-best-practices.md |
| Code review o refactorizar código .NET existente | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Escribir tests unitarios o de integración en .NET | IA_Skill/SKILL-dotnet-test-frameworks.md |
| Configurar la documentación de la API (OpenAPI nativo + Scalar) | IA_Skill/SKILL-dotnet-best-practices.md — sección "Documentación API" |
| Migrar el proyecto a una nueva versión de .NET (incluye salir de .NET 8/9, fuera de soporte) | IA_Skill/SKILL-dotnet-upgrade.md |
| Reescribir un proyecto legado (.NET Framework 4.x, Angular sin soporte, TFVC) en el stack aprobado; mantener el legado mientras tanto | IA_Skill/SKILL-legacy-modernization.md |

### Backend .NET — skills oficiales de Microsoft (complementarias)

Copia curada de [dotnet/skills](https://github.com/dotnet/skills) en `IA_Skill/dotnet-official/` (en inglés, sin modificar; origen, versión y exclusiones en su `README.md`). Leer primero la skill propia de la tabla de arriba; la oficial aporta el detalle técnico. **Si contradice a esta plantilla, gana la plantilla**: respuesta estandarizada en vez de `ProblemDetails`, soft delete en vez de `ExecuteDelete`, xUnit como framework, y en servidores el dev ejecuta los comandos de diagnóstico. La tabla completa de conflictos está en `IA_Skill/dotnet-official/README.md`.

| Situación | Skill oficial (bajo `IA_Skill/dotnet-official/`) |
|---|---|
| Crear o modificar endpoints Web API: semántica HTTP, metadata OpenAPI, archivos `.http` | `dotnet-aspnetcore/dotnet-webapi/SKILL.md` |
| Revisar u optimizar consultas EF Core (N+1, round-trips, tracking, materialización prematura) | `dotnet-data/optimizing-ef-core-queries/SKILL.md` |
| Refactorizar C# sin cambiar comportamiento (rename, extract, move, consolidar tipos) | `dotnet/csharp-refactoring/SKILL.md` |
| Cambiar código .NET con consumidores que no controlamos (librería NuGet compartida, API pública) | `dotnet/dotnet-breaking-changes/SKILL.md` |
| Upgrade .NET 8 → 10: breaking changes detallados (complementa SKILL-dotnet-upgrade.md) | `dotnet-upgrade/migrate-dotnet8-to-dotnet9/SKILL.md` y luego `dotnet-upgrade/migrate-dotnet9-to-dotnet10/SKILL.md`, en el mismo upgrade con destino `net10.0` |
| Habilitar nullable reference types en código existente | `dotnet-upgrade/migrate-nullable-references/SKILL.md` |
| Centralizar versiones NuGet (Central Package Management, `Directory.Packages.props`) | `dotnet-nuget/convert-to-cpm/SKILL.md` |
| MSBuild: `.csproj`/`.props`/`.targets`, builds lentos o fallidos, binlogs | `dotnet/msbuild/SKILL.md` |
| Revisar código .NET por anti-patrones de rendimiento (async, memoria, LINQ, serialización) | `dotnet-diag/analyzing-dotnet-performance/SKILL.md` |
| Diagnosticar rendimiento o crashes en un entorno desplegado (trazas, dumps) — el agente propone, el dev ejecuta | `dotnet-diag/dotnet-trace-collect/SKILL.md` · `dotnet-diag/dump-collect/SKILL.md` |
| Ejecutar tests .NET o armar el comando `dotnet test` con filtros | `dotnet-test/run-tests/SKILL.md` |
| Generar, reparar o reforzar tests de código .NET existente (después de SKILL-dotnet-test-frameworks.md) | `dotnet-test/code-testing/SKILL.md` |
| Auditar calidad de tests: anti-patrones, aserciones débiles, huecos que no detectarían un bug | `dotnet-test/test-anti-patterns/SKILL.md` · `dotnet-test/assertion-quality/SKILL.md` · `dotnet-test/test-gap-analysis/SKILL.md` |
| Interpretar cobertura o calcular riesgo CRAP | `dotnet-test/coverage-analysis/SKILL.md` · `dotnet-test/crap-score/SKILL.md` |
| Hacer testeable código con dependencias estáticas (`DateTime.Now`, `File`, `Environment`) | `dotnet-test/testability-obstacle/SKILL.md` · `dotnet-test/detect-static-dependencies/SKILL.md` |
| Crear o reparar un proyecto de tests (registro en `.sln`/`.slnx`, referencias, filtros de CI) | `dotnet-test/scaffold-dotnet-test-project/SKILL.md` |
| Migrar xUnit v2 → v3, o VSTest → Microsoft.Testing.Platform | `dotnet-test-migration/migrate-xunit-to-xunit-v3/SKILL.md` · `dotnet-test-migration/migrate-vstest-to-mtp/SKILL.md` |
| Medir rendimiento con microbenchmarks (BenchmarkDotNet): diseñar, ejecutar o comparar | `dotnet-diag/microbenchmarking/SKILL.md` |
| Agregar IA/ML a un proyecto .NET: elegir tecnología (ML.NET, LLM, agentes, RAG, ONNX, Ollama) e implementarla — junto con "IA / ML (.NET)" en Reglas de codificación | `dotnet-ai/technology-selection/SKILL.md` |

### Backend NestJS

| Situación                                                       | Skill a leer                              |
| --------------------------------------------------------------- | ----------------------------------------- |
| Crear o modificar módulo, controller, service o guard en NestJS | IA_Skill/SKILL-nestjs-best-practices.md   |
| Implementar CQRS, eventos de dominio, colas o caching en NestJS | IA_Skill/SKILL-nestjs-patterns.md         |
| Mejorar calidad o revisión de TypeScript en NestJS              | IA_Skill/SKILL-nestjs-clean-typescript.md |
| Escribir tests unitarios o de integración en NestJS             | IA_Skill/SKILL-nestjs-test-frameworks.md  |

### Backend Python (FastAPI — solo tooling interno, ver nota de stack)

| Situación                                                                                                                                     | Skill a leer                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Crear o modificar cualquier archivo del backend Python de ReporteadorV2 (router, service, cliente HTTP)                                       | IA_Skill/SKILL-python-fastapi-best-practices.md |
| Escribir tests unitarios o de integración en el backend Python                                                                                | IA_Skill/SKILL-python-test-frameworks.md        |
| Seguridad en el backend Python (manejo del PAT, subprocess/PDF, exposición del servicio)                                                      | IA_Skill/SKILL-security-python.md               |

### Full Stack

| Situación | Skill a leer |
|---|---|
| Implementar una feature con `Features/[mod].spec.md` en estado `ready` | IA_Skill/SKILL-implementation.md |
| Implementar un módulo completo de principio a fin (sin spec previa) | IA_Skill/SKILL-mvc-feature.md |
| Crear, aplicar o revertir migraciones de BD (.NET/NestJS) | IA_Skill/SKILL-database-migrations.md |
| Escribir o mantener tests E2E, validar un flujo UI o reproducir un bug visual/funcional (Playwright por defecto) | IA_Skill/SKILL-e2e-playwright.md — para automatización interactiva del navegador, `.claude/skills/playwright-cli/SKILL.md` |
| Orquestar la solución en local con Aspire (AppHost, service discovery, dashboard) — soluciones con 2+ servicios | IA_Skill/SKILL-aspire-orchestration.md |

### Seguridad

| Situación | Skill a leer |
|---|---|
| Elegir o implementar autenticación/autorización (perfil A: OIDC + PKCE + BFF; perfil B: Identity API endpoints; políticas) | IA_Skill/SKILL-auth-patterns.md — leer antes que las skills de seguridad por stack |
| Crear guard, interceptor o manejar tokens en Angular | IA_Skill/SKILL-security-angular.md |
| Seguridad en cualquier endpoint o middleware .NET | IA_Skill/SKILL-security-dotnet.md |
| Seguridad en cualquier endpoint, guard o pipe NestJS | IA_Skill/SKILL-security-nestjs.md |
| Seguridad en el backend Python de ReporteadorV2 (manejo del PAT, subprocess/PDF, exposición del servicio) | IA_Skill/SKILL-security-python.md |
| Revisión OWASP de una feature/endpoint puntual con datos sensibles (no una auditoría de todo el proyecto — para eso ver "Punto de entrada — Auditoría Pre-Productiva" arriba) | IA_Skill/SKILL-security-owasp-checklist.md |
| Revisión OWASP adicional (compliance por agentes) | IA_Skill/SKILL-agent-owasp-compliance.md |
| Vulnerabilidad de dependencia/librería (npm audit, dotnet list package --vulnerable, pip-audit) — decidir qué parchar ahora vs. documentar | IA_Skill/SKILL-dependency-vulnerability-triage.md |
| Hallazgo de seguridad (SAST, código legado) en un stack que NO está en las filas de arriba (Angular/.NET/NestJS/Python-ReporteadorV2) — ej. Express, PHP, código de cliente heredado | IA_Skill/SKILL-legacy-stack-security-baseline.md — guía puntual, no modernización |
| Escaneo/sospecha de secreto expuesto (Gitleaks, .env trackeado, credencial en un commit) | IA_Skill/SKILL-secrets-scanning.md |
| Decidir si un fix (de cualquier tipo — PR, SAST, SCA, secreto, código legado) se aplica directo, se acota, o requiere ticket | IA_Skill/SKILL-risk-zone-policy.md — fuente única, todas las filas de arriba la referencian, no la redefinen |

### Texto y documentación

| Situación | Skill a leer |
|---|---|
| Escribir texto visible al usuario final (mensajes UI, emails, empty states) | IA_Skill/SKILL-humanizer.md |
| Documentar una feature terminada | IA_Skill/SKILL-docs-feature.md |
| Generar una memoria técnica formal (.docx) para cliente de gobierno/externo, con diagramas del código | IA_Skill/SKILL-technical-memory.md |
| Generar un manual de usuario (.docx) con capturas reales de pantallas | IA_Skill/SKILL-user-manual.md |
| Generar diagramas desde el código (archify) o capturas reales (Playwright) para un entregable | IA_Skill/SKILL-visual-evidence.md — archify copiado en `IA_Skill/archify-official/` (reglas en su README.md) |
| Generar especificaciones técnicas formales (.docx) para auditorías | IA_Skill/technical-audit-spec-generic.md |
| Crear, editar o inspeccionar entregables en Word o PDF (documentos nuevos: Markdown + `Tools/entregables/build-docx.mjs`) | IA_Skill/document-artifacts/SKILL.md |

### Especificaciones

| Situación | Skill a leer |
|---|---|
| Generar o actualizar specs de features con el flujo completo Features/ (`[mod].md` + `.spec.md` + `.checks.md`), sin tocar código | IA_Skill/SKILL-spec-generator.md |
| "Arma la HU", "documenta esto como especificación funcional", convertir notas sueltas/recuerdo vago de un discovery/mockups en una HU — plantilla mínima de 8 secciones (no la plantilla larga de Features/[mod].md), o el caso mencione "Fabric"/frontera de responsabilidad entre sistemas | IA_Skill/SKILL-functional-spec-elicitation.md — exige revisar código/estado actual antes de redactar; si en cambio se necesita el flujo completo de Features/, usar SKILL-spec-generator.md |
| Generar "documento técnico"/"fundamentos técnicos" que dé contexto al dev sin prescribir la solución, a partir de una HU ya redactada + revisión del código real (antes de estimar/desarrollar) | IA_Skill/SKILL-technical-foundations-brief.md — requiere acceso a código, nunca prescribe implementación; consume la HU de SKILL-functional-spec-elicitation.md o SKILL-spec-generator.md, no la redefine |

### Herramientas del agente

| Situación                                                         | Skill a leer                      |
| ----------------------------------------------------------------- | --------------------------------- |
| Necesitar información externa actualizada (versiones, CVEs, docs) | IA_Skill/SKILL-web-search.md      |
| Activar respuestas ultra-concisas para sesiones largas            | IA_Skill/SKILL-caveman.md         |
| Resolver comentarios de revisión de un Pull Request en GitHub     | IA_Skill/SKILL-pr-review-fixes.md |
| Duda de alcance o diseño de un cambio: sobreingeniería, cambio no pedido, pedido vago a convertir en criterios verificables (ejemplos .NET/Angular) | IA_Skill/SKILL-execution-principles.md |
