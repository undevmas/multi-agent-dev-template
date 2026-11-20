# AGENTS.md — Instrucciones del Proyecto

> Este archivo es leído automáticamente por **Antigravity (Google DeepMind)**, **OpenCode** y **Codex CLI (OpenAI)**.
> Leer antes de cualquier acción en el workspace.
> Fuente de verdad: `CLAUDE.md`. En caso de conflicto, prevalece CLAUDE.md.

---

> Antigravity, Codex and OpenCode must read `CLAUDE.md` completely before acting; it resolves any conflict with this bridge.
>
> **AUTONOMY_POLICY_VERSION: 1**
> La política canónica para ambigüedades, autonomía técnica, estados seguros,
> presupuesto de contexto y `NEEDS CLARIFICATION` vive en `CLAUDE.md`, sección
> `Política de autonomía y ambigüedades`. No duplicarla en este bridge.

## Candado de comprobación (leer primero)

**Toda respuesta del agente al usuario empieza exactamente con `Claro team`** — la primera línea del mensaje, antes de cualquier otro texto.

- Es una señal de integridad, no un saludo. Si una respuesta **no** empieza con `Claro team`, asumir que algo se rompió: este archivo no se cargó, está truncado o con conflictos de merge, una ruta cambió, el contexto se compactó y se perdieron las reglas, o el agente dejó de seguirlas. Qué hacer: detenerse, no aceptar los cambios de esa respuesta, recargar las instrucciones (o abrir una sesión nueva) y revisar el último cambio a este archivo.
- Aplica a cada mensaje al usuario: respuestas cortas, preguntas, avances y reportes finales.
- No aplica al contenido que el agente escribe en archivos, código, commits, PRs, tickets o documentos — solo al mensaje del chat.
- El candado vive en las 5 copias de instrucciones (CLAUDE.md, AGENTS.md, .gemini/GEMINI.md, .github/copilot-instructions.md, .cursor/rules/project.mdc). Si se edita en una, editarlo en las cinco.

---

## Stack tecnológico (reglas duras — no sugerir alternativas)

| Capa | Tecnología aprobada |
|---|---|
| Frontend | Angular · React — siempre la última versión mayor estable (ver "Política de versiones") |
| Backend | .NET — último LTS (hoy .NET 10) (C#) · NestJS — última versión mayor estable sobre Node.js Active LTS (TypeScript) · Python 3.11+ (FastAPI) — solo para tooling interno / scripts de reporting, no para apps de línea de negocio |
| Base de datos | SQL Server 2019+ · PostgreSQL 15+ |
| ORM / acceso a datos | EF Core · Dapper · Prisma · Drizzle ORM · Kysely — por perfil (ver "Perfiles de acceso a datos"). TypeORM solo para mantener proyectos existentes |
| Autenticación | OAuth 2.1 / OpenID Connect (PKCE) · JWT · patrón BFF · Entra ID / Keycloak / OpenIddict · ASP.NET Core Identity (Identity API endpoints) · Policy-Based Authorization — por perfil (ver "Perfiles de autenticación") |
| Contenedores y orquestación | Docker · Docker Compose · Aspire (orquestación local de soluciones con 2+ servicios) |
| CI/CD | Azure DevOps Pipelines |
| Testing unitario | xUnit (.NET) · Jest (TS/JS) · pytest (Python) |
| Testing E2E | Playwright (por defecto) — Cypress solo con autorización explícita |
| Documentación API | OpenAPI nativo (`Microsoft.AspNetCore.OpenApi`) + Scalar (`Scalar.AspNetCore`) como UI por defecto · Redoc / Swagger UI opcionales — en NestJS: `@nestjs/swagger` genera el documento OpenAPI y Scalar es la UI |
| IA / ML (.NET) | Microsoft.Extensions.AI (`IChatClient`, base obligatoria) · Microsoft Agent Framework (`Microsoft.Agents.AI`, agentes) · ML.NET (ML clásico) · ONNX Runtime (inferencia) · OllamaSharp (LLM local) · Microsoft.Extensions.VectorData (RAG sobre la BD del stack) · GitHub Copilot SDK (extensiones de Copilot) — el **proveedor** del modelo se aprueba por proyecto (ver "IA / ML (.NET)" en Reglas de codificación) |
| Benchmarking (.NET) | BenchmarkDotNet — solo en proyectos de benchmark separados, nunca referenciado por código productivo |

> **Python (FastAPI)** se aprobó el 2026-07-02 específicamente para el proyecto de
> `Codigo/Reportes/` (ReporteadorV2), que ya tenía lógica probada en Python
> (`ado_reporte.py`). Reutiliza esa base en vez de .NET/NestJS. No usar Python
> como backend de nuevas apps de negocio sin la misma aprobación explícita.

No sugerir, instalar ni implementar tecnologías fuera de esta tabla sin aprobación explícita.

### Política de versiones (backend y frontend)

- **Proyecto nuevo → siempre el último LTS liberado.**
  - .NET: último LTS (versiones pares; hoy .NET 10, soporte hasta nov-2028). No usar STS (versiones impares) en proyectos nuevos.
  - Node.js (runtime de NestJS y del tooling de Angular/React): la versión **Active LTS** vigente — nunca "Current".
  - Angular, React y NestJS no publican un LTS formal → usar su **última versión mayor estable** (nunca RC, `next` ni canary).
  - Paquetes atados al runtime van en la misma versión mayor: EF Core, `Microsoft.AspNetCore.*` y `Microsoft.Extensions.*` = versión de .NET; `@angular/*` alineados entre sí.
- **Verificar antes de fijar una versión:** el conocimiento del modelo puede estar desfasado. Confirmar la versión vigente en la fuente oficial (`IA_Skill/SKILL-web-search.md`) y registrarla en `IA_Memoria/arquitectura.md`.
- **Proyecto existente:** no subir de versión como efecto colateral de otra tarea. Si usa una versión fuera de soporte oficial (ej. .NET 8 y .NET 9 terminaron soporte el 2026-11-10), registrarlo en `IA_Memoria/deuda-tecnica.md` y proponer el upgrade como tarea propia (`IA_Skill/SKILL-dotnet-upgrade.md`).
- Python queda en 3.11+ por la aprobación de ReporteadorV2 — esta política no lo modifica.

### Perfiles de autenticación

Elegir **un** perfil por proyecto, registrarlo en `IA_Memoria/arquitectura.md` y no mezclarlos. Si el perfil no está definido, preguntar al dev antes de implementar autenticación. Detalle técnico: `IA_Skill/SKILL-auth-patterns.md`.

| Perfil | Cuándo | Stack |
|---|---|---|
| A — Empresarial | Microservicios, multi-tenant, SSO corporativo, varias APIs o clientes de terceros | OAuth 2.1 / OpenID Connect (Authorization Code + PKCE) · access tokens JWT validados en cada API · patrón BFF para SPAs · IdP: Entra ID / Keycloak / OpenIddict |
| B — Monolito / desarrollo rápido | Una API + un frontend, sin SSO corporativo (.NET 10) | ASP.NET Core Identity (`AddIdentityApiEndpoints` + `MapIdentityApi`) · cookie HttpOnly (SPA en el mismo sitio) o bearer token (clientes no-navegador) · Policy-Based Authorization |

### Perfiles de acceso a datos

Elegir el perfil al arrancar el proyecto y registrarlo en `IA_Memoria/arquitectura.md`.

| Perfil | Cuándo | .NET | TypeScript |
|---|---|---|---|
| Equilibrado (default) | CRUD de negocio — la mayoría de los proyectos | EF Core (+ Dapper para consultas puntuales de lectura pesada) | Prisma o Drizzle ORM |
| Alto rendimiento / CQRS | Lecturas intensivas, reporting, CQRS, SQL type-safe | EF Core 10 (escritura + migraciones) + Dapper (lectura) | Drizzle ORM o Kysely |

- Un ORM principal por backend. La única combinación permitida es EF Core (escritura) + Dapper (lectura) en .NET.
- El esquema y las migraciones los gestiona siempre la herramienta del ORM principal (EF Core Migrations, `prisma migrate`, `drizzle-kit`, Kysely `Migrator`). Dapper nunca gestiona esquema.
- TypeORM: solo para mantener proyectos que ya lo usan; no se elige para proyectos nuevos.

---

## Protocolo de inicio contextualizado y ruteo de skills

Antes de cualquier acción, consultar `IA_Skill/SKILL-instruction-router.md` para determinar la **Skill Primaria**, las **Skills Auxiliares** y las lecturas estrictamente requeridas según el tipo de tarea.

### Lecturas según tipo de tarea:

1. **Implementar SPEC `ready` o reanudar `in-progress`:**
   - Leer `Features/[feature].spec.md`, `[feature].checks.md` y `[feature].md`.
   - Consultar `IA_Memoria/arquitectura.md` y `convenciones.md` únicamente antes de generar código nuevo o navegar entre servicios.
2. **Corregir un bug puntual o refactor acotado:**
   - Ir directamente al archivo afectado y su suite de tests. NO leer `progreso.md` ni snapshots globales.
3. **Generar una SPEC o Spike técnico:**
   - Leer insumos del dev y `[feature]-epic.md` (si aplica); no cargar skills de backend, frontend ni frameworks.
4. **Tareas de investigación pura o consultas de usuario:**
   - No cargar memoria global; buscar evidencia quirúrgica con herramientas dirigidas (`find_by_name`, `grep_search`, `view_file` acotado).

Nunca empezar a codificar lógica de negocio sin verificar las convenciones y arquitectura del módulo correspondiente.

### Regla de snapshot (Repomix) — leer solo cuando la tarea lo justifica

Leer `IA_Memoria/snapshots/snapshot-latest.md` ÚNICAMENTE si se cumple alguna de estas condiciones:

- La tarea afecta más de un módulo o capa (frontend + backend, backend + BD, etc.).
- Es la primera sesión en el proyecto o no hay contexto previo del código.
- Se toma una decisión de arquitectura o refactor amplio.
- Se depura un bug cuya causa no es evidente en un solo archivo.

NO leer el snapshot para: fix puntual en un archivo conocido, cambio de texto/estilo, modificación de config aislada.

Si el snapshot no existe o tiene más de 7 días, sugerir al usuario ejecutar:

- Windows: `.\repomix-scan.ps1`
- Linux/macOS: `./repomix-scan.sh`

Protocolo post-snapshot (obligatorio al leer el snapshot):
Después de leer el snapshot, ANTES de codificar:

1. Comparar contra `IA_Memoria/arquitectura.md` — actualizar módulos, dependencias o estructura que hayan cambiado.
2. Comparar contra `IA_Memoria/progreso.md` — marcar como hecho lo que ya existe en el código aunque no estuviera registrado.
3. Si el proyecto tiene código existente, actualizar `IA_Memoria/convenciones.md` con los patrones arquitectónicos detectados en el snapshot — solo agregar lo que no esté ya documentado, nunca reemplazar entradas ya completas:
   - Estructura de capas detectada (Clean Architecture, N-capas, Vertical Slice, etc.)
   - Patrón de acceso a datos (Repository, DbContext directo, CQRS + MediatR, etc.)
   - Estructura de carpetas dentro de cada capa
   - Patrón de manejo de excepciones y validaciones
   - Formato de responses detectado en controllers existentes
4. Solo después de actualizar los tres archivos, proceder con la tarea solicitada.

---

## Cuándo leer cada Skill

> **Router central:** La selección de la **Skill Primaria** (una sola por tarea) y **Skills Auxiliares** (bajo demanda) se rige por [`IA_Skill/SKILL-instruction-router.md`](IA_Skill/SKILL-instruction-router.md). No cargar catálogos completos de skills de forma indiscriminada.

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

### Backend .NET

| Situación | Skill a leer |
|---|---|
| Crear o modificar cualquier archivo .NET (controller, service, repository) | IA_Skill/SKILL-dotnet-best-practices.md |
| Code review o refactorizar código .NET existente | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Escribir tests unitarios o de integración en .NET | IA_Skill/SKILL-dotnet-test-frameworks.md |
| Configurar la documentación de la API (OpenAPI nativo + Scalar) | IA_Skill/SKILL-dotnet-best-practices.md — sección "Documentación API" |
| Migrar el proyecto a una nueva versión de .NET (incluye salir de .NET 8/9, fuera de soporte) | IA_Skill/SKILL-dotnet-upgrade.md |

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

### Especificaciones

| Situación | Skill a leer |
|---|---|
| Generar o actualizar specs de features con el flujo completo Features/ (`[mod].md` + `.spec.md` + `.checks.md`), sin tocar código | IA_Skill/SKILL-spec-generator.md |
| "Arma la HU", "documenta esto como especificación funcional", convertir notas sueltas/recuerdo vago de un discovery/mockups en una HU — plantilla mínima de 8 secciones (no la plantilla larga de Features/[mod].md), o el caso mencione "Fabric"/frontera de responsabilidad entre sistemas | IA_Skill/SKILL-functional-spec-elicitation.md — exige revisar código/estado actual antes de redactar; si en cambio se necesita el flujo completo de Features/, usar SKILL-spec-generator.md |
| Generar "documento técnico"/"fundamentos técnicos" que dé contexto al dev sin prescribir la solución, a partir de una HU ya redactada + revisión del código real (antes de estimar/desarrollar) | IA_Skill/SKILL-technical-foundations-brief.md — requiere acceso a código, nunca prescribe implementación; consume la HU de SKILL-functional-spec-elicitation.md o SKILL-spec-generator.md, no la redefine |

### Texto y documentación

| Situación | Skill a leer |
|---|---|
| Escribir texto visible al usuario final (mensajes UI, emails, empty states) | IA_Skill/SKILL-humanizer.md |
| Documentar una feature terminada | IA_Skill/SKILL-docs-feature.md |
| Generar una memoria técnica formal (.docx) para cliente de gobierno/externo | IA_Skill/SKILL-technical-memory.md |
| Generar especificaciones técnicas formales (.docx) para auditorías | IA_Skill/technical-audit-spec-generic.md |
| Crear, editar o inspeccionar entregables en Word o PDF | IA_Skill/document-artifacts/SKILL.md |

### Herramientas del agente

| Situación                                                         | Skill a leer                      |
| ----------------------------------------------------------------- | --------------------------------- |
| Necesitar información externa actualizada (versiones, CVEs, docs) | IA_Skill/SKILL-web-search.md      |
| Activar respuestas ultra-concisas para sesiones largas            | IA_Skill/SKILL-caveman.md         |
| Resolver comentarios de revisión de un Pull Request en GitHub     | IA_Skill/SKILL-pr-review-fixes.md |

---

## Reglas de codificación

### General

- Código en inglés (variables, funciones, clases, tablas)
- Comentarios y documentación en español
- Nunca hardcodear credenciales, URLs base ni valores de entorno
- Toda configuración sensible va en variables de entorno
- Todo cambio de base de datos debe tener su migración versionada
- IDs siempre UUID/GUID (nunca int secuencial)

### Soft delete obligatorio

Nunca ejecutar DELETE en tablas de negocio.
Siempre: `IsActive = 0` (SQL Server) o `is_active = false` (PostgreSQL).

### Respuesta estandarizada de API

Todos los endpoints deben retornar la misma estructura de respuesta — sin excepciones y sin inventar formatos nuevos por endpoint.
La forma concreta (campos, anidamiento, errores, paginación) la define el proyecto en `IA_Memoria/convenciones.md`.
Si el proyecto aún no tiene convención definida, usar como punto de partida:
`{ "success": true/false, "data": {}, "message": "texto", "errors": [] }`
Si el código existente ya usa otra forma, registrarla en convenciones.md y usarla consistentemente — no mezclar formas dentro del mismo proyecto.

### Autenticación y autorización
- Aplicar el perfil registrado en `IA_Memoria/arquitectura.md` (ver "Perfiles de autenticación"). Sin perfil definido, preguntar antes de implementar.
- Nunca guardar tokens en `localStorage` ni `sessionStorage`.
  - Perfil A: la SPA no maneja tokens — el BFF los guarda del lado servidor y la SPA usa una cookie de sesión HttpOnly + Secure + SameSite.
  - Perfil B: cookie HttpOnly de Identity (SPA en el mismo sitio) o `Authorization: Bearer [token]` solo para clientes no-navegador. En NestJS: access token en memoria + refresh token en cookie HttpOnly.
- OAuth 2.1: Authorization Code + PKCE obligatorio; prohibidos implicit flow y password grant (ROPC); redirect URIs exactas; rotación de refresh tokens; nunca tokens en query string.
- Cada API valida issuer, audience, expiración y firma del token (JWKS del IdP) — no claves simétricas compartidas entre servicios.
- Autorización por políticas (`[Authorize(Policy = ...)]` / `RequireAuthorization(...)`), no chequeos de rol dispersos en el código.
- Denegar por defecto: fallback policy que exige usuario autenticado. Solo login, callbacks OIDC y health checks llevan `[AllowAnonymous]`.

### Documentación API
- Documento OpenAPI con `Microsoft.AspNetCore.OpenApi` (`AddOpenApi` / `MapOpenApi`) — no agregar Swashbuckle para generar el documento.
- UI por defecto: Scalar (`Scalar.AspNetCore` → `MapScalarApiReference`). Redoc o Swagger UI solo si el proyecto lo pide.
- Documento y UI solo en Development, o protegidos con auth — nunca públicos en producción.

### Testing E2E
- Playwright (`@playwright/test`) para todo E2E nuevo. Introducir Cypress requiere autorización explícita.
- Proyectos que ya usan Cypress lo conservan: no migrar a Playwright sin ticket.
- Tooling en la raíz del workspace (`package.json`, `playwright.config.ts`, `tests/e2e/`) y `playwright-cli` para automatización interactiva del navegador. Mapa operativo en `IA_Skill/SKILL-e2e-playwright.md`. No sustituye los tests unitarios de cada stack.

### Orquestación local (Aspire)
- Soluciones con 2+ servicios (API + frontend + BD, microservicios): AppHost de Aspire para desarrollo local — service discovery, connection strings inyectadas (nada hardcodeado) y dashboard OpenTelemetry.
- Docker Compose sigue siendo el artefacto de despliegue en VM y el de `Tools/`. Aspire no lo reemplaza en producción salvo decisión registrada en `IA_Memoria/arquitectura.md`.

### IA / ML (.NET)
- Elegir la tecnología con `IA_Skill/dotnet-official/dotnet-ai/technology-selection/SKILL.md`. Base obligatoria: `Microsoft.Extensions.AI` (`IChatClient` vía DI); la lógica de negocio nunca llama directo al SDK del proveedor.
- El proveedor del modelo (Azure OpenAI, OpenAI, Azure AI Inference, Ollama local) es un servicio externo que recibe datos: se aprueba por proyecto y se registra en `IA_Memoria/arquitectura.md`. Datos confidenciales o personales solo a proveedores aprobados para ese nivel de dato (preferir el tenant de la organización u Ollama local).
- Claves y endpoints en user-secrets / variables de entorno / Key Vault — nunca en `appsettings.json` comiteado.
- Paquetes prerelease/preview (ej. `Microsoft.Agents.AI` mientras no tenga versión estable, `Microsoft.Extensions.AI.DataIngestion`) requieren aprobación explícita por proyecto.
- RAG: vectores en la BD del stack (PostgreSQL + pgvector, o SQL Server con tipo vector cuando la versión lo soporte); cualquier otro vector store requiere aprobación.
- Límites obligatorios: `Temperature` y `MaxOutputTokens`, reintentos y timeout, tope de iteraciones y de costo en agentes; validar la salida del modelo contra un esquema; no registrar prompts ni respuestas con datos sensibles.
- Tareas tabulares (clasificación, regresión, clustering) con ML.NET, no con un LLM. Entrenar modelos en Python requiere aprobación (Python sigue restringido a tooling interno).

### Benchmarking (.NET)
- BenchmarkDotNet solo en un proyecto `*.Benchmarks` separado, nunca referenciado por código productivo; seguir `IA_Skill/dotnet-official/dotnet-diag/microbenchmarking/SKILL.md`.
- Ejecutar siempre en `Release`. Agregar benchmarks al pipeline de CI es un cambio de pipeline (requiere confirmación).

### Python (FastAPI — tooling interno)

- El Dockerfile y docker-compose.yml son entregable obligatorio en todo proyecto FastAPI
- Documentar los pasos de deploy en un README.md dentro de la carpeta del proyecto
- El deploy real en la VM lo ejecuta el dev manualmente — el agente no hace push ni accede a servidores remotos
- Frontend servido por FastAPI: HTML/JS vanilla únicamente — sin npm, sin build step, sin frameworks JS

---

## Estructura del workspace

```
workspace-proyecto/
├── Codigo/              ← ÚNICO que se versiona en GitHub / Azure DevOps
│   └── [nombre-proyecto]/   ← estructura interna libre; rutas reales en IA_Memoria/arquitectura.md
├── IA_Skill/            ← Skills permanentes del proyecto
├── IA_Memoria/          ← Estado y contexto del proyecto
├── Insumos/             ← Mockups, specs, datos de prueba
├── Features/            ← Definición detallada de cada módulo
├── Issues/              ← Bugs y problemas registrados
└── AGENTS.md            ← Este archivo (bridge para OpenCode)
```

No asumir estructura interna de Codigo/ — leer IA_Memoria/arquitectura.md.
Las carpetas IA_Skill, IA_Memoria, Insumos, Features e Issues NO se suben al repositorio.

---

## Política de trabajo con código legado

Ver `IA_Skill/SKILL-risk-zone-policy.md` — fuente única de la política de zonas
(verde/ámbar/roja). No se redefine aquí para evitar que las 4 copias (esta,
CLAUDE.md, GEMINI.md, copilot-instructions.md) diverjan entre sí.

---

## NUNCA sin confirmación explícita

- Modificar `.env`, `appsettings.json` o cualquier archivo de entorno
- Ejecutar `DROP TABLE`, `DELETE FROM` o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado (incluye usar Cypress en vez de Playwright)
- Subir de versión el runtime o framework de un proyecto existente (.NET, Node.js, Angular, React, NestJS)
- Modificar pipelines de CI/CD
- Subir archivos de `IA_Skill/`, `IA_Memoria/`, `Features/`, `Issues/`, `Insumos/` al repositorio
- Ejecutar `docker build`, `docker push`, `aspire deploy` ni acceder a servidores remotos
- Enviar datos del proyecto a un proveedor de IA/LLM no aprobado para ese proyecto

## Regla de módulo completo

Cuando una tarea construya un módulo funcional, el módulo incluye por defecto:

- Backend/API, persistencia y reglas de negocio que correspondan.
- Frontend/pantalla/flujo de usuario cuando el módulo tenga interacción visual.
- Validación directa del flujo completo mediante Playwright, ejecutando la aplicación y comprobando el comportamiento desde la UI.

La única excepción es un servicio o módulo explícitamente sin frontend (por ejemplo, un worker, una API interna, un proceso de integración o un servicio de infraestructura). En ese caso, documentar en la entrega que no aplica UI/Playwright y validar mediante pruebas de contrato, integración o smoke tests apropiados.

No considerar terminado un módulo con frontend si solo compila o tiene tests unitarios: debe existir al menos una validación Playwright del happy path y de los errores principales del flujo.
Para ejecutar esta validación, el agente debe verificar de forma autónoma que los servicios locales (AppHost/Angular en localhost:4200) estén activos (o arrancarlos en segundo plano sin bloquear la terminal) y ejecutar la prueba en modo visual/encabezado (--headed en desarrollo local contra Chromium, o interactivamente con playwright-cli open). No asumir ejecución headless silenciosa ni esperar a que el operador tenga que indicarlo en el prompt.

## Regla para librerías y plugins recomendados

Si una librería o plugin recomendado no aparece en el stack aprobado, no descartarlo automáticamente por ese único motivo. Antes de decidir no usarlo, detener la implementación y consultar al usuario presentando brevemente:

1. Qué problema resuelve y qué ventajas aporta frente a la opción aprobada o a no incorporar dependencia.
2. Evidencia de seguridad, mantenimiento, comunidad, licencia y compatibilidad con el proyecto.
3. Por qué puede ser la mejor opción para esta tarea y cuáles son las alternativas consideradas.
4. Impacto de adoptarlo: instalación, mantenimiento, lockfile, CI/CD, superficie de ataque y migración futura.

Solo después de la confirmación explícita del usuario se puede instalar o implementar una tecnología fuera del stack. Si el usuario decide no adoptarla, registrar la decisión y su razón en la memoria o spec correspondiente.
