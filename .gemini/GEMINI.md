# GEMINI.md — Instrucciones del Proyecto

> Leer este archivo antes de cualquier acción en el workspace.

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

> **Python (FastAPI)** se aprobó el 2026-07-02 específicamente para el proyecto de
> `Codigo/Reportes/` (ReporteadorV2), que ya tenía lógica probada en Python
> (`ado_reporte.py`). Reutiliza esa base en vez de .NET/NestJS. No usar Python
> como backend de nuevas apps de negocio sin la misma aprobación explícita.

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

## Protocolo de inicio

Antes de cualquier tarea leer:
1. `IA_Memoria/progreso.md` — qué está hecho y qué sigue
2. `IA_Memoria/arquitectura.md` — cada pieza del sistema
3. `IA_Memoria/convenciones.md` — naming y estructura
4. `Features/[feature].md` — si la tarea involucra un módulo específico
   `Features/[feature].spec.md` — además, si existe y su Estado es `ready` o `in-progress`
5. `IA_Skill/[skill].md` — la skill relevante antes de codificar

Regla de snapshot (Repomix) — leer solo cuando la tarea lo justifica:

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

| Situación | Skill |
|---|---|
| "Actúa como agente analista pre-productivo", "corre el checklist pre-prod", "auditoría de seguridad antes de liberar [todo el proyecto]" | IA_Skill/SKILL-preprod-security-audit.md — orquesta el resto, no leer las skills de seguridad sueltas directamente para este caso. Dispara solo con "pre-producción"/"pre-prod" a secas sobre todo el proyecto — si el pedido es sobre una feature/endpoint puntual, ver la fila de "Revisión OWASP" más abajo |
| Componente reutilizable con variantes | IA_Skill/frontend-design/SKILL-component-patterns.md |
| Tokens de diseño (color, espaciado, radio, sombras) | IA_Skill/frontend-design/SKILL-design-tokens.md |
| Sistema tipográfico del proyecto | IA_Skill/frontend-design/SKILL-typography-system.md |
| Layout, grid o sistema de espaciado | IA_Skill/frontend-design/SKILL-layout-spacing-system.md |
| Identidad visual (paleta, radius, iconografía) | IA_Skill/frontend-design/SKILL-visual-identity-override.md |
| Librería de terceros aprobada (antes de instalar dependencias) | IA_Skill/SKILL-approved-libraries.md |
| Tabla server-side Angular (paginación/sort) | IA_Skill/frontend-design/SKILL-angular-data-table-pattern.md |
| Botones/CTAs con gradiente premium, o hero tipo mesh gradient | IA_Skill/frontend-design/SKILL-gradient-accents.md — mesh gradient SOLO landing/marketing |
| Dark mode o theming (claro/oscuro, multi-tenant) | IA_Skill/frontend-design/SKILL-dark-mode-theming.md |
| Diseño responsive o patrones PWA | IA_Skill/frontend-design/SKILL-responsive-pwa-patterns.md |
| Animaciones o micro-interacciones | IA_Skill/frontend-design/SKILL-animation-microinteractions.md |
| Accesibilidad (a11y / WCAG AA) | IA_Skill/frontend-design/SKILL-accessibility-a11y.md |
| Code review o generación de código frontend enfocado en calidad/mantenibilidad (no estética) | IA_Skill/SKILL-impeccable.md |
| Decisiones de UX avanzadas: formularios complejos, flujos multi-paso, dashboards, estados de carga/error | IA_Skill/SKILL-ui-ux-pro-max.md |
| Crear o modificar una vista pública indexable (login, landing) — SEO | IA_Skill/SKILL-seo.md |
| Tests en Angular (TestBed, Jest) | IA_Skill/SKILL-angular-test-frameworks.md |
| Tests en React (Jest + Testing Library) | IA_Skill/SKILL-react-test-frameworks.md |
| Diseño moderno en HTML/JS vanilla (sin framework, sin npm) | Leer en secuencia: IA_Skill/SKILL-frontend-design.md (tokens, tipografía, layout y componentes para HTML/CSS/JS puro) → IA_Skill/frontend-design/SKILL-animation-microinteractions.md → IA_Skill/frontend-design/SKILL-gradient-accents.md → IA_Skill/frontend-design/SKILL-accessibility-a11y.md. Sin Bootstrap en output final, sin npm, sin build step, sin frameworks JS (React, Vue, Alpine). Google Fonts vía `<link>` permitido. CSS en archivo propio, no inline. |
| Implementar feature con spec en estado `ready` | IA_Skill/SKILL-implementation.md |
| Módulo completo full stack (sin spec previa) | IA_Skill/SKILL-mvc-feature.md |
| Crear, aplicar o revertir migraciones de BD (.NET/NestJS) | IA_Skill/SKILL-database-migrations.md |
| Tests E2E (Playwright por defecto) | IA_Skill/SKILL-e2e-playwright.md |
| Orquestar la solución en local con Aspire (AppHost, service discovery, dashboard) — soluciones con 2+ servicios | IA_Skill/SKILL-aspire-orchestration.md |
| Crear/modificar backend .NET | IA_Skill/SKILL-dotnet-best-practices.md |
| Documentación de la API (OpenAPI nativo + Scalar) | IA_Skill/SKILL-dotnet-best-practices.md — sección "Documentación API" |
| Code review .NET | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Tests en .NET | IA_Skill/SKILL-dotnet-test-frameworks.md |
| Migrar versión de .NET (incluye salir de .NET 8/9, fuera de soporte) | IA_Skill/SKILL-dotnet-upgrade.md |
| Crear/modificar backend NestJS | IA_Skill/SKILL-nestjs-best-practices.md |
| Patrones avanzados NestJS (CQRS, eventos, colas) | IA_Skill/SKILL-nestjs-patterns.md |
| TypeScript estricto en NestJS | IA_Skill/SKILL-nestjs-clean-typescript.md |
| Tests en NestJS (Jest + Supertest) | IA_Skill/SKILL-nestjs-test-frameworks.md |
| Crear/modificar backend Python de ReporteadorV2 (router, service, cliente HTTP) | IA_Skill/SKILL-python-fastapi-best-practices.md |
| Tests en el backend Python | IA_Skill/SKILL-python-test-frameworks.md |
| Elegir o implementar autenticación/autorización (perfil A: OIDC + PKCE + BFF; perfil B: Identity API endpoints; políticas) | IA_Skill/SKILL-auth-patterns.md — leer antes que las skills de seguridad por stack |
| Seguridad en Angular | IA_Skill/SKILL-security-angular.md |
| Seguridad en .NET | IA_Skill/SKILL-security-dotnet.md |
| Seguridad en NestJS | IA_Skill/SKILL-security-nestjs.md |
| Seguridad en el backend Python (manejo del PAT, subprocess/PDF, exposición del servicio) | IA_Skill/SKILL-security-python.md |
| Revisión OWASP de una feature/endpoint puntual con datos sensibles (no auditoría de todo el proyecto — ver fila de arriba) | IA_Skill/SKILL-security-owasp-checklist.md |
| Revisión OWASP adicional (compliance por agentes) | IA_Skill/SKILL-agent-owasp-compliance.md |
| Vulnerabilidad de dependencia/librería (npm audit, dotnet list package --vulnerable, pip-audit) — decidir qué parchar ahora vs. documentar | IA_Skill/SKILL-dependency-vulnerability-triage.md |
| Hallazgo de seguridad (SAST, código legado) en un stack que NO está en las filas de arriba (Angular/.NET/NestJS/Python-ReporteadorV2) — ej. Express, PHP, código de cliente heredado | IA_Skill/SKILL-legacy-stack-security-baseline.md — guía puntual, no modernización |
| Escaneo/sospecha de secreto expuesto (Gitleaks, .env trackeado, credencial en un commit) | IA_Skill/SKILL-secrets-scanning.md |
| Decidir si un fix (de cualquier tipo — PR, SAST, SCA, secreto, código legado) se aplica directo, se acota, o requiere ticket | IA_Skill/SKILL-risk-zone-policy.md — fuente única, todas las filas de arriba la referencian, no la redefinen |
| Generar o actualizar specs de features con el flujo completo Features/ (`[mod].md` + `.spec.md` + `.checks.md`), sin tocar código | IA_Skill/SKILL-spec-generator.md |
| "Arma la HU", "documenta esto como especificación funcional", convertir notas sueltas/recuerdo vago de un discovery/mockups en una HU — plantilla mínima de 8 secciones (no la plantilla larga de Features/[mod].md), o el caso mencione "Fabric"/frontera de responsabilidad entre sistemas | IA_Skill/SKILL-functional-spec-elicitation.md — exige revisar código/estado actual antes de redactar; si en cambio se necesita el flujo completo de Features/, usar SKILL-spec-generator.md |
| Generar "documento técnico"/"fundamentos técnicos" que dé contexto al dev sin prescribir la solución, a partir de una HU ya redactada + revisión del código real (antes de estimar/desarrollar) | IA_Skill/SKILL-technical-foundations-brief.md — requiere acceso a código, nunca prescribe implementación; consume la HU de SKILL-functional-spec-elicitation.md o SKILL-spec-generator.md, no la redefine |
| Texto visible al usuario final (mensajes UI) | IA_Skill/SKILL-humanizer.md |
| Documentar feature terminada | IA_Skill/SKILL-docs-feature.md |
| Generar memoria técnica formal (.docx) para cliente de gobierno/externo | IA_Skill/SKILL-technical-memory.md |
| Búsqueda web y fuentes externas actualizadas | IA_Skill/SKILL-web-search.md |
| Respuestas ultra-concisas en sesiones largas | IA_Skill/SKILL-caveman.md |
| Resolver comentarios de revisión de PR en GitHub | IA_Skill/SKILL-pr-review-fixes.md |

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

---

## Reglas de codificación

### General
- Código en inglés (variables, funciones, clases, tablas)
- Comentarios y documentación en español
- Nunca hardcodear credenciales, URLs base ni valores de entorno
- Toda configuración sensible va en variables de entorno
- Todo cambio de base de datos debe tener su migración versionada
- IDs siempre UUID/GUID (no int secuencial)

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

### Orquestación local (Aspire)
- Soluciones con 2+ servicios (API + frontend + BD, microservicios): AppHost de Aspire para desarrollo local — service discovery, connection strings inyectadas (nada hardcodeado) y dashboard OpenTelemetry.
- Docker Compose sigue siendo el artefacto de despliegue en VM y el de `Tools/`. Aspire no lo reemplaza en producción salvo decisión registrada en `IA_Memoria/arquitectura.md`.

### Python (FastAPI — tooling interno)
- El Dockerfile y docker-compose.yml son entregable obligatorio en todo proyecto FastAPI
- Documentar los pasos de deploy en un README.md dentro de la carpeta del proyecto
- El deploy real en la VM lo ejecuta el dev manualmente — el agente no hace push ni accede a servidores remotos
- Frontend servido por FastAPI: HTML/JS vanilla únicamente — sin npm, sin build step, sin frameworks JS

---

## Estructura del workspace

```
workspace-proyecto/
├── Codigo/          ← ÚNICO que va a git
│   └── [nombre-proyecto]/   ← estructura interna libre; rutas reales en IA_Memoria/arquitectura.md
├── IA_Skill/        ← Skills del agente (no subir a git)
├── IA_Memoria/      ← Estado del proyecto (no subir a git)
├── Features/        ← Definición de módulos (no subir a git)
├── Issues/          ← Bugs registrados (no subir a git)
└── Insumos/         ← Mockups y specs (no subir a git)

No asumir estructura interna de Codigo/ — leer IA_Memoria/arquitectura.md.
```

---

## Política de trabajo con código legado

Ver `IA_Skill/SKILL-risk-zone-policy.md` — fuente única de la política de zonas
(verde/ámbar/roja). No se redefine aquí para evitar que las 4 copias
(esta, CLAUDE.md, AGENTS.md, copilot-instructions.md) diverjan entre sí.

---

## NUNCA sin confirmación explícita

- Modificar `.env`, `appsettings.json` o archivos de entorno
- Ejecutar `DROP TABLE`, `DELETE FROM` o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado (incluye usar Cypress en vez de Playwright)
- Subir de versión el runtime o framework de un proyecto existente (.NET, Node.js, Angular, React, NestJS)
- Modificar pipelines de CI/CD
- Subir archivos de `IA_Skill/`, `IA_Memoria/`, `Features/`, `Issues/`, `Insumos/` al repositorio
- Ejecutar `docker build`, `docker push`, `aspire deploy` ni acceder a servidores remotos
