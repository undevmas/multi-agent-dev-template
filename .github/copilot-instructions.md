# GitHub Copilot — Instrucciones del Proyecto (Compacto)

## Prioridad de instrucciones (desempate)
Si hay conflicto entre instrucciones, aplicar este orden:
1. CLAUDE.md
2. IA_Memoria/convenciones.md
3. Este archivo
4. IA_Skill/[skill].md específica de la tarea

## Stack aprobado (bloqueado)
Usar solo:
- Frontend: Angular 17+ o React 18+
- Backend: .NET 8+ (C#) o NestJS 10+ (TypeScript)
- Base de datos: SQL Server 2019+ o PostgreSQL 15+
- ORM: Entity Framework Core, TypeORM, Prisma
- Auth: JWT + Refresh Token, OAuth2, ASP.NET Identity
- Contenedores: Docker, Docker Compose
- CI/CD: Azure DevOps Pipelines
- Testing unitario: xUnit (.NET), Jest (TS/JS)
- Testing E2E: Cypress
- API docs: Swagger/OpenAPI

No sugerir ni instalar tecnologías fuera de este stack sin confirmación explícita.

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
- Specs y especificaciones: SKILL-spec-generator.md
- Frontend (diseño visual): frontend-design/SKILL-component-patterns.md, frontend-design/SKILL-design-tokens.md, frontend-design/SKILL-typography-system.md, frontend-design/SKILL-layout-spacing-system.md, frontend-design/SKILL-visual-identity-override.md, frontend-design/SKILL-dark-mode-theming.md, frontend-design/SKILL-responsive-pwa-patterns.md, frontend-design/SKILL-animation-microinteractions.md, frontend-design/SKILL-accessibility-a11y.md
- Testing frontend: SKILL-angular-test-frameworks.md, SKILL-react-test-frameworks.md
- Backend .NET: SKILL-dotnet-best-practices.md, SKILL-dotnet-design-pattern-review.md, SKILL-dotnet-test-frameworks.md, SKILL-dotnet-upgrade.md
- Backend NestJS: SKILL-nestjs-best-practices.md, SKILL-nestjs-clean-typescript.md, SKILL-nestjs-patterns.md, SKILL-nestjs-test-frameworks.md
- Full stack / BD: SKILL-implementation.md (con spec ready), SKILL-mvc-feature.md (sin spec), SKILL-database-migrations.md
- Seguridad: SKILL-security-angular.md, SKILL-security-dotnet.md, SKILL-security-nestjs.md, SKILL-security-owasp-checklist.md, SKILL-agent-owasp-compliance.md
- Texto/Docs: SKILL-humanizer.md, SKILL-docs-feature.md
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
- JWT: Authorization Bearer token; refresh token en cookie HttpOnly
- Proteger todos los endpoints con guard/middleware excepto login
- Migraciones versionadas para todo cambio de BD
- IDs UUID/GUID (no enteros secuenciales)

## Política de código legado
- Código nuevo: seguir convenciones del template al 100%, sin importar el entorno
- Código existente a modificar: solo lo mínimo necesario, no refactorizar sin ticket explícito
- Código intocable: detectar antipatrones, registrar en `IA_Memoria/deuda-tecnica.md`, no tocar
- Desempate: código real gana sobre spec en legado → registrar deuda, consultar al dev

## NUNCA hacer sin confirmación explícita
- Modificar .env, appsettings.json o archivos de entorno
- Ejecutar DROP TABLE, DELETE FROM o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado
- Modificar pipelines de CI/CD
- Incluir en commits archivos de IA_Skill, IA_Memoria, Features, Issues, Insumos

## Contexto adicional
Para detalles extendidos y excepciones, usar:
- CLAUDE.md
- IA_Memoria/progreso.md
- IA_Memoria/arquitectura.md
- IA_Memoria/convenciones.md
- Features/[feature].md
- IA_Skill/[skill].md
