# GitHub Copilot — Instrucciones del Proyecto (Compacto)

## Prioridad de instrucciones (desempate)
Si hay conflicto entre instrucciones, aplicar este orden:
1. CLAUDE.md
2. IA_Memoria/convenciones.md
3. Este archivo
4. IA_Skill/[skill].md específica de la tarea

## Stack aprobado (bloqueado)
Usar solo:
- Frontend: Angular o React — última versión mayor estable
- Backend: .NET último LTS (hoy .NET 10) o NestJS última mayor estable sobre Node.js Active LTS — Python 3.11+ (FastAPI) solo para tooling interno / scripts de reporting, no para apps de línea de negocio
- Base de datos: SQL Server 2019+ o PostgreSQL 15+
- ORM / acceso a datos por perfil — Equilibrado (default): EF Core, Dapper, Prisma, Drizzle ORM · Alto rendimiento / CQRS: EF Core 10 + Dapper, Drizzle ORM, Kysely. TypeORM solo para mantener proyectos existentes
- Auth por perfil — A (empresarial / microservicios / multi-tenant): OAuth 2.1 / OpenID Connect (PKCE), JWT, patrón BFF, Entra ID / Keycloak / OpenIddict · B (monolito / desarrollo rápido .NET 10): ASP.NET Core Identity (Identity API endpoints), bearer tokens / cookies HttpOnly, Policy-Based Authorization
- Contenedores y orquestación: Docker, Docker Compose, Aspire (orquestación local con 2+ servicios)
- CI/CD: Azure DevOps Pipelines
- Testing unitario: xUnit (.NET), Jest (TS/JS), pytest (Python)
- Testing E2E: Playwright (por defecto) — Cypress solo con autorización explícita
- API docs: OpenAPI nativo (Microsoft.AspNetCore.OpenApi) + Scalar (Scalar.AspNetCore) por defecto; Redoc / Swagger UI opcionales; NestJS: @nestjs/swagger + Scalar

No sugerir ni instalar tecnologías fuera de este stack sin confirmación explícita.
Python (FastAPI) se aprobó el 2026-07-02 solo para `Codigo/Reportes/` (ReporteadorV2) — no usarlo como backend de nuevas apps de negocio sin la misma aprobación explícita.

Política de versiones: proyecto nuevo → siempre el último LTS liberado (.NET LTS, Node.js Active LTS; Angular/React/NestJS sin LTS formal → última mayor estable, nunca RC/next). Verificar la versión vigente en la fuente oficial (SKILL-web-search.md) antes de fijarla y registrarla en IA_Memoria/arquitectura.md. Proyecto existente: no subir versión como efecto colateral; si está fuera de soporte (ej. .NET 8/9 desde 2026-11-10) registrar en deuda-tecnica.md y proponer upgrade. Perfil de auth y de acceso a datos: elegir uno por proyecto y registrarlo en IA_Memoria/arquitectura.md (detalle en CLAUDE.md).

## Protocolo de inicio (obligatorio)
Antes de codificar, leer en este orden:
1. IA_Memoria/progreso.md
2. IA_Memoria/arquitectura.md
3. IA_Memoria/convenciones.md
4. Features/[feature].md (si aplica) + Features/[feature].spec.md si existe en estado `ready` o `in-progress`
5. IA_Skill/[skill].md relevante

Regla de snapshot (Repomix) — solo cuando la tarea lo justifica:
Adjuntar IA_Memoria/snapshots/snapshot-latest.md con #file: SOLO si:
- La tarea afecta más de un módulo o capa.
- Es la primera sesión en el proyecto.
- Se toma una decisión de arquitectura o refactor amplio.
NO adjuntar para fixes puntuales, cambios de texto o config aislada.
Si el snapshot no existe o tiene más de 7 días, pedir al usuario ejecutar repomix-scan.ps1 (Windows) o repomix-scan.sh (Linux/macOS).
Al leer el snapshot, ANTES de codificar:
1. Actualizar IA_Memoria/arquitectura.md con cambios reales detectados en el snapshot.
2. Marcar en IA_Memoria/progreso.md lo que ya existe aunque no esté registrado.
3. Si el proyecto tiene código existente, actualizar IA_Memoria/convenciones.md con los patrones arquitectónicos detectados — solo agregar lo que no esté ya documentado, nunca reemplazar entradas ya completas: estructura de capas, patrón de acceso a datos, estructura de carpetas por capa, manejo de excepciones y validaciones, formato de responses en controllers.
4. Solo después de los tres pasos anteriores, proceder con la tarea.

No iniciar código sin haber leído al menos 1, 2 y 3.

## Cuándo consultar skills
Consultar IA_Skill solo cuando la tarea lo requiera por dominio técnico.

Mapa rápido:
- Specs y especificaciones: SKILL-spec-generator.md (flujo completo Features/: `[mod].md` + `.spec.md` + `.checks.md`), SKILL-functional-spec-elicitation.md (armar la HU desde notas/mockups/recuerdo vago de discovery, plantilla mínima de 8 secciones — exige revisar código antes de redactar; menciona "Fabric"/frontera de responsabilidad), SKILL-technical-foundations-brief.md (documento de "fundamentos técnicos" no prescriptivo a partir de una HU ya redactada + código real, antes de estimar/desarrollar)
- Frontend (diseño visual): frontend-design/SKILL-component-patterns.md, frontend-design/SKILL-design-tokens.md, frontend-design/SKILL-typography-system.md, frontend-design/SKILL-layout-spacing-system.md, frontend-design/SKILL-visual-identity-override.md, frontend-design/SKILL-dark-mode-theming.md, frontend-design/SKILL-responsive-pwa-patterns.md, frontend-design/SKILL-animation-microinteractions.md, frontend-design/SKILL-accessibility-a11y.md, frontend-design/SKILL-gradient-accents.md (botones premium / mesh gradient hero, solo landing), frontend-design/SKILL-angular-data-table-pattern.md (tabla server-side Angular)
- Frontend (calidad de código, UX avanzado, SEO): SKILL-impeccable.md (code review frontend, no estética), SKILL-ui-ux-pro-max.md (formularios complejos, flujos multi-paso, dashboards), SKILL-seo.md (vistas públicas indexables: login, landing)
- Punto de entrada — auditoría pre-productiva de todo el proyecto ("actúa como agente analista pre-productivo", "corre el checklist pre-prod"): SKILL-preprod-security-audit.md — orquesta el resto, no leer las skills de seguridad sueltas directamente para este caso. Si el pedido es sobre una feature/endpoint puntual, no todo el proyecto, usar en su lugar SKILL-security-owasp-checklist.md (ver bullet de Seguridad)
- Antes de instalar cualquier dependencia de terceros (componentes/iconos/gráficas/animación): SKILL-approved-libraries.md
- Testing frontend: SKILL-angular-test-frameworks.md, SKILL-react-test-frameworks.md
- Testing E2E (Playwright por defecto): SKILL-e2e-playwright.md
- Orquestación local con Aspire (AppHost, service discovery, dashboard — soluciones con 2+ servicios): SKILL-aspire-orchestration.md
- Frontend (HTML/JS vanilla, sin framework/npm): SKILL-frontend-design.md (tokens, tipografía, layout, componentes) → frontend-design/SKILL-animation-microinteractions.md → frontend-design/SKILL-gradient-accents.md → frontend-design/SKILL-accessibility-a11y.md. Sin Bootstrap en output final, sin build step, sin React/Vue/Alpine. Google Fonts vía `<link>` permitido, CSS en archivo propio.
- Backend .NET: SKILL-dotnet-best-practices.md (incluye "Documentación API": OpenAPI nativo + Scalar), SKILL-dotnet-design-pattern-review.md, SKILL-dotnet-test-frameworks.md, SKILL-dotnet-upgrade.md (incluye salir de .NET 8/9, fuera de soporte)
- Backend .NET — skills oficiales de Microsoft (complementarias, en `IA_Skill/dotnet-official/`, en inglés). Leer primero la skill propia; si una oficial contradice a la plantilla, gana la plantilla (conflictos en su README.md). Rutas relativas a esa carpeta:
  - Web API: dotnet-aspnetcore/dotnet-webapi
  - EF Core: dotnet-data/optimizing-ef-core-queries
  - C#: dotnet/csharp-refactoring y dotnet/dotnet-breaking-changes (librerías compartidas)
  - Upgrade: dotnet-upgrade/migrate-dotnet8-to-dotnet9 → migrate-dotnet9-to-dotnet10, en el mismo upgrade con destino net10.0; también dotnet-upgrade/migrate-nullable-references
  - NuGet y build: dotnet-nuget/convert-to-cpm, dotnet/msbuild
  - Rendimiento: dotnet-diag/analyzing-dotnet-performance; dotnet-diag/dotnet-trace-collect y dump-collect (en servidores el dev ejecuta)
  - Tests: dotnet-test/run-tests, code-testing, test-anti-patterns, assertion-quality, test-gap-analysis, coverage-analysis, crap-score, testability-obstacle, detect-static-dependencies, scaffold-dotnet-test-project
  - Migración de tests: dotnet-test-migration/migrate-xunit-to-xunit-v3, migrate-vstest-to-mtp
- Backend NestJS: SKILL-nestjs-best-practices.md, SKILL-nestjs-clean-typescript.md, SKILL-nestjs-patterns.md, SKILL-nestjs-test-frameworks.md
- Backend Python (FastAPI, solo tooling interno de ReporteadorV2): SKILL-python-fastapi-best-practices.md, SKILL-python-test-frameworks.md
- Full stack / BD: SKILL-implementation.md (con spec ready), SKILL-mvc-feature.md (sin spec), SKILL-database-migrations.md
- Autenticación/autorización (elegir o implementar perfil A: OIDC + PKCE + BFF; perfil B: Identity API endpoints; políticas) — leer antes que las de seguridad por stack: SKILL-auth-patterns.md
- Seguridad: SKILL-security-angular.md, SKILL-security-dotnet.md, SKILL-security-nestjs.md, SKILL-security-python.md, SKILL-security-owasp-checklist.md, SKILL-agent-owasp-compliance.md
- Triage de hallazgos (SCA/legado/secretos/zona de riesgo — usar en vez de las de arriba cuando el hallazgo no es de código propio en el stack aprobado): SKILL-dependency-vulnerability-triage.md, SKILL-legacy-stack-security-baseline.md, SKILL-secrets-scanning.md, SKILL-risk-zone-policy.md (fuente única de zonas, las demás la referencian)
- Texto/Docs: SKILL-humanizer.md, SKILL-docs-feature.md, SKILL-technical-memory.md (memoria técnica formal .docx para cliente de gobierno/externo)
- Soporte: SKILL-web-search.md, SKILL-caveman.md, SKILL-pr-review-fixes.md

Cuándo NO consultar skills:
- Tareas triviales o mecánicas (renombrar variable, ajuste menor de texto, formateo local, cambio de ruta simple)
- Lecturas rápidas de estado sin implementación
- Cambios que ya están totalmente definidos en la conversación y no requieren criterio técnico adicional

## Convenciones obligatorias
- Código en inglés (variables, funciones, clases, tablas)
- Comentarios y documentación en español
- Nunca hardcodear credenciales, URLs base ni valores de entorno
- Soft delete obligatorio: IsActive = 0 / is_active = false (nunca DELETE en negocio)
- Todos los endpoints retornan la misma estructura de respuesta — la forma concreta vive en IA_Memoria/convenciones.md (si no hay convención definida, usar `{ success, data, message, errors }` como punto de partida)
- Auth según el perfil registrado en IA_Memoria/arquitectura.md (sin perfil → preguntar). Nunca tokens en localStorage/sessionStorage. Perfil A: la SPA no maneja tokens (BFF + cookie HttpOnly/Secure/SameSite). Perfil B: cookie HttpOnly de Identity o Bearer solo para clientes no-navegador; NestJS: access token en memoria + refresh token en cookie HttpOnly
- OAuth 2.1: Authorization Code + PKCE; sin implicit ni password grant; cada API valida issuer, audience, expiración y firma (JWKS)
- Autorización por políticas; denegar por defecto (fallback policy) — solo login, callbacks OIDC y health checks anónimos
- Documentación API: Microsoft.AspNetCore.OpenApi + Scalar (sin Swashbuckle para generar el documento); solo en Development o protegida con auth
- E2E nuevos en Playwright; proyectos con Cypress lo conservan (no migrar sin ticket)
- Soluciones con 2+ servicios: AppHost de Aspire en local; Docker Compose sigue siendo el artefacto de despliegue en VM
- Migraciones versionadas para todo cambio de BD
- IDs UUID/GUID (no enteros secuenciales)
- Python (FastAPI, tooling interno): Dockerfile y docker-compose.yml obligatorios, deploy documentado en README.md dentro del proyecto, deploy real lo ejecuta el dev manualmente (el agente no hace push ni accede a servidores remotos), frontend servido por FastAPI en HTML/JS vanilla únicamente

## Política de código legado

Ver `IA_Skill/SKILL-risk-zone-policy.md` — fuente única de la política de zonas
(verde/ámbar/roja). No se redefine aquí para evitar que las 4 copias
(esta, CLAUDE.md, AGENTS.md, GEMINI.md) diverjan entre sí.

## NUNCA hacer sin confirmación explícita
- Modificar .env, appsettings.json o archivos de entorno
- Ejecutar DROP TABLE, DELETE FROM o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado (incluye usar Cypress en vez de Playwright)
- Subir de versión el runtime o framework de un proyecto existente (.NET, Node.js, Angular, React, NestJS)
- Modificar pipelines de CI/CD
- Incluir en commits archivos de IA_Skill, IA_Memoria, Features, Issues, Insumos
- Ejecutar docker build, docker push, aspire deploy o acceder a servidores remotos

## Contexto adicional
Para detalles extendidos y excepciones, usar:
- CLAUDE.md
- IA_Memoria/progreso.md
- IA_Memoria/arquitectura.md
- IA_Memoria/convenciones.md
- Features/[feature].md
- IA_Skill/[skill].md
