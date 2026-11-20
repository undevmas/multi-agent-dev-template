# SKILL — Política de stack, versiones y reglas por tecnología

> Detalle del stack aprobado que `AGENTS.md` resume en una línea por capa. Leer antes de crear
> un proyecto, fijar una versión, implementar autenticación, IA/ML, documentación de API,
> E2E u orquestación, o agregar una dependencia.

## Stack tecnológico — reglas duras

No sugerir, instalar ni implementar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa | Tecnología aprobada |
|---|---|
| **Frontend** | Angular · React — siempre la última versión mayor estable (ver "Política de versiones") |
| **Backend** | .NET — último LTS (hoy .NET 10) (C#) · NestJS — última versión mayor estable sobre Node.js Active LTS (TypeScript) · Python 3.11+ (FastAPI) — solo para tooling interno / scripts de reporting, no para apps de línea de negocio |
| **Base de datos** | SQL Server 2019+ · PostgreSQL 15+ |
| **ORM / acceso a datos** | EF Core · Dapper · Prisma · Drizzle ORM · Kysely — por perfil (ver "Perfiles de acceso a datos"). TypeORM solo para mantener proyectos existentes |
| **Autenticación** | OAuth 2.1 / OpenID Connect (PKCE) · JWT · patrón BFF · Entra ID / Keycloak / OpenIddict · ASP.NET Core Identity (Identity API endpoints) · Policy-Based Authorization — por perfil (ver "Perfiles de autenticación") |
| **Contenedores y orquestación** | Docker · Docker Compose · Aspire (orquestación local de soluciones con 2+ servicios) |
| **CI/CD** | Azure DevOps Pipelines |
| **Testing unitario** | xUnit (.NET) · Jest (TS/JS) · pytest (Python) |
| **Testing E2E** | Playwright (por defecto) — Cypress solo con autorización explícita |
| **Documentación API** | OpenAPI nativo (`Microsoft.AspNetCore.OpenApi`) + Scalar (`Scalar.AspNetCore`) como UI por defecto · Redoc / Swagger UI opcionales — en NestJS: `@nestjs/swagger` genera el documento OpenAPI y Scalar es la UI |
| **IA / ML (.NET)** | Microsoft.Extensions.AI (`IChatClient`, base obligatoria) · Microsoft Agent Framework (`Microsoft.Agents.AI`, agentes) · ML.NET (ML clásico) · ONNX Runtime (inferencia) · OllamaSharp (LLM local) · Microsoft.Extensions.VectorData (RAG sobre la BD del stack) · GitHub Copilot SDK (extensiones de Copilot) — el **proveedor** del modelo se aprueba por proyecto (ver "IA / ML (.NET)" en Reglas de codificación) |
| **Benchmarking (.NET)** | BenchmarkDotNet — solo en proyectos de benchmark separados, nunca referenciado por código productivo |

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
| **A — Empresarial** | Microservicios, multi-tenant, SSO corporativo, varias APIs o clientes de terceros | OAuth 2.1 / OpenID Connect (Authorization Code + PKCE) · access tokens JWT validados en cada API · patrón BFF para SPAs · IdP: Entra ID / Keycloak / OpenIddict |
| **B — Monolito / desarrollo rápido** | Una API + un frontend, sin SSO corporativo (.NET 10) | ASP.NET Core Identity (`AddIdentityApiEndpoints` + `MapIdentityApi`) · cookie HttpOnly (SPA en el mismo sitio) o bearer token (clientes no-navegador) · Policy-Based Authorization |

### Perfiles de acceso a datos

Elegir el perfil al arrancar el proyecto y registrarlo en `IA_Memoria/arquitectura.md`.

| Perfil | Cuándo | .NET | TypeScript |
|---|---|---|---|
| **Equilibrado (default)** | CRUD de negocio — la mayoría de los proyectos | EF Core (+ Dapper para consultas puntuales de lectura pesada) | Prisma o Drizzle ORM |
| **Alto rendimiento / CQRS** | Lecturas intensivas, reporting, CQRS, SQL type-safe | EF Core 10 (escritura + migraciones) + Dapper (lectura) | Drizzle ORM o Kysely |

- Un ORM principal por backend. La única combinación permitida es EF Core (escritura) + Dapper (lectura) en .NET.
- El esquema y las migraciones los gestiona siempre la herramienta del ORM principal (EF Core Migrations, `prisma migrate`, `drizzle-kit`, Kysely `Migrator`). Dapper nunca gestiona esquema.
- TypeORM: solo para mantener proyectos que ya lo usan; no se elige para proyectos nuevos.

## Reglas de codificación

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
