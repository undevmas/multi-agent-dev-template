# AGENTS.md — Instrucciones del workspace

> Fuente única de instrucciones para todos los agentes. Claude Code la carga vía `CLAUDE.md` (`@AGENTS.md`);
> Gemini/Antigravity vía `.gemini/GEMINI.md`; Codex, OpenCode, Cursor y Copilot la leen directo o desde su puntero.
> Lo detallado vive en `IA_Skill/` y se lee **solo cuando la tarea lo pide**.
> **AUTONOMY_POLICY_VERSION: 1** — política canónica: `IA_Skill/SKILL-autonomy-policy.md` (no duplicarla aquí).

## Candado de comprobación (leer primero)

- Empieza **cada** respuesta al usuario con `Claro team` (primera línea del mensaje, antes de cualquier texto).
- Es una señal de integridad, no un saludo: si una respuesta no empieza así, algo se rompió (instrucciones sin cargar,
  truncadas, con conflictos de merge o con rutas rotas). Detenerse, no aceptar esos cambios, recargar las instrucciones
  y correr `IA_Skill/check-instruction-policy-sync.ps1`.
- Solo en el chat: nunca en archivos, código, commits, PRs, tickets ni documentos.

## Contexto del workspace

- Plantilla multi-agente. El código de cada proyecto vive en `Codigo/<proyecto>/` (su propio repo); el contexto del
  agente vive fuera: `IA_Memoria/` (estado), `IA_Skill/` (skills), `Features/` (specs), `Issues/`, `Insumos/`.
- Antes de tocar código: `IA_Memoria/arquitectura.md` (rutas, versiones, perfiles, comandos) y `IA_Memoria/convenciones.md`.
  Proyecto nuevo o recién incorporado: completar `progreso.md`, `arquitectura.md` y `convenciones.md` antes de desarrollar.
- Si existe `Codigo/<proyecto>/AGENTS.md`, sus reglas locales se suman a estas (la más cercana al archivo gana en lo
  específico); las reglas críticas y el candado de este archivo nunca se relajan.
- Preferencias locales del desarrollador: `CLAUDE.local.md` / `AGENTS.override.md` (ignorados por git), nunca aquí.

## Stack aprobado

No sugerir, instalar ni implementar nada fuera de esta tabla sin aprobación explícita.

| Capa | Aprobado |
|---|---|
| Frontend | Angular · React — última versión mayor estable |
| Backend | .NET último LTS (hoy 10) · NestJS sobre Node.js Active LTS · Python 3.11+ FastAPI solo tooling interno (`Codigo/Reportes/`) |
| Base de datos | SQL Server 2019+ · PostgreSQL 15+ |
| Acceso a datos | EF Core · Dapper · Prisma · Drizzle ORM · Kysely (por perfil) · TypeORM solo proyectos existentes |
| Autenticación | Perfil A: OAuth 2.1 / OIDC + PKCE, JWT, BFF, Entra ID / Keycloak / OpenIddict · Perfil B: ASP.NET Core Identity API endpoints, Policy-Based Authorization |
| Contenedores | Docker · Docker Compose · Aspire (orquestación local con 2+ servicios) |
| CI/CD | Azure DevOps Pipelines |
| Tests | xUnit · Jest · pytest · Playwright (E2E; Cypress solo con autorización) |
| Documentación API | `Microsoft.AspNetCore.OpenApi` + Scalar (Redoc / Swagger UI opcionales) |
| IA / ML (.NET) | Microsoft.Extensions.AI (base) · Agent Framework · ML.NET · ONNX Runtime · OllamaSharp · VectorData · Copilot SDK — proveedor del modelo aprobado por proyecto |
| Benchmarks | BenchmarkDotNet (solo proyectos `*.Benchmarks`) |

Versiones, perfiles de auth y de datos, y reglas por tecnología: `IA_Skill/SKILL-stack-policy.md` — leer antes de crear
un proyecto, fijar una versión, implementar auth/IA/OpenAPI/E2E/Aspire o agregar una dependencia.
Librerías de UI y backend aprobadas: `IA_Skill/SKILL-approved-libraries.md`.

## Comandos de verificación (correr antes de dar una tarea por terminada)

- Instrucciones del workspace (tras editar este archivo, sus punteros o skills de política):
  `.\IA_Skill\check-instruction-policy-sync.ps1` y `.\IA_Skill\test-antigravity-workflow.ps1`
- Proyecto: los comandos de `IA_Memoria/arquitectura.md` → "Comandos de verificación". Si no están, por stack:
  - .NET: `dotnet build` · `dotnet test` · `dotnet format --verify-no-changes`
  - Angular / React / NestJS: `npm run lint` · `npm test` · `npm run build`
  - Módulo con UI: `npm run test:e2e` (Playwright, Chromium)
- Reportar qué se ejecutó y su resultado; si algo no se pudo ejecutar, decirlo explícitamente.

## Principios de ejecución (detalle y ejemplos: `IA_Skill/SKILL-execution-principles.md`)

- Pensar antes de actuar: explicitar supuestos; si hay varias interpretaciones, decir cuál se toma y por qué.
  Cuándo preguntar lo decide la política de autonomía (investigar primero; escalar solo B2/S1/X1).
- Simplicidad: lo mínimo que resuelve el pedido; sin abstracciones de un solo uso ni features especulativas
  (salvo la configuración y los estados seguros que exige la política de autonomía).
- Cambios quirúrgicos: cada línea cambiada se traza al pedido; respetar el estilo existente; limpiar solo
  los huérfanos propios; lo ajeno se reporta, no se arregla.
- Objetivo verificable: convertir el pedido en un criterio comprobable y verificarlo antes de cerrar.

## Reglas críticas

- Código en inglés; comentarios y documentación en español.
- Nunca hardcodear credenciales, URLs base ni valores de entorno; lo sensible va en variables de entorno o secretos.
- IDs UUID/GUID. Todo cambio de BD con migración versionada, generada por la herramienta del ORM principal.
- Soft delete: nunca `DELETE` en tablas de negocio → `IsActive = 0` (SQL Server) / `is_active = false` (PostgreSQL).
- Respuesta de API estandarizada según `IA_Memoria/convenciones.md` (si no existe: `{ success, data, message, errors }`);
  si el código existente ya usa otra forma, registrarla en `convenciones.md` y seguirla; nunca mezclar formas.
- Auth: aplicar el perfil registrado en `arquitectura.md` (sin perfil → preguntar). Nunca tokens en `localStorage` ni
  `sessionStorage`. Denegar por defecto: solo login, callbacks OIDC y health checks son anónimos.
- Un módulo con UI no está terminado sin validación Playwright del happy path y errores principales
  (detalle: `IA_Skill/SKILL-e2e-playwright.md`). Sin UI: validar con pruebas de contrato o integración.
- Una tarea del agente termina en `in-review`, nunca en `done` (solo el dev marca `done`).
- Librería útil fuera del stack: no descartarla ni instalarla — proponerla (ventajas, seguridad, licencia, alternativas,
  impacto) y esperar confirmación.

## Nunca sin confirmación explícita

- Modificar `.env`, `appsettings*.json` u otros archivos de entorno.
- Ejecutar `DROP TABLE`, `DELETE FROM` o borrar migraciones.
- Instalar o cambiar tecnologías fuera del stack (incluye Cypress en vez de Playwright).
- Subir de versión el runtime o framework de un proyecto existente (.NET, Node.js, Angular, React, NestJS).
- Modificar pipelines de CI/CD.
- Subir `IA_Skill/`, `IA_Memoria/`, `Features/`, `Issues/` o `Insumos/` al repositorio de código de un proyecto.
- `docker build`, `docker push`, `aspire deploy` o acceder a servidores remotos.
- Enviar datos del proyecto a un proveedor de IA/LLM no aprobado para ese proyecto.
- Acciones sobre dinero real, credenciales, producción o irreversibles (clase `S1` de la política de autonomía).

## Cómo trabajar (lectura progresiva)

1. Elegir **una** skill primaria y las auxiliares necesarias con `IA_Skill/SKILL-instruction-router.md`.
   No cargar el catálogo completo de skills ni skills de capas que la tarea no toca.
2. Leer solo lo indispensable: spec/checks de la feature, el archivo afectado y su test, o el insumo entregado.
3. Ambigüedades: investigar antes de preguntar y clasificar T1/T2/B1/B2/S1/X1 según `IA_Skill/SKILL-autonomy-policy.md`.
4. Código legado y alcance de un fix (zona verde/ámbar/roja): `IA_Skill/SKILL-risk-zone-policy.md`.
5. Snapshot del código (`IA_Memoria/snapshots/snapshot-latest.md`): solo si la tarea cruza módulos o capas;
   protocolo en el router, sección 8.

## Índice de referencia (leer bajo demanda)

| Necesito | Archivo |
|---|---|
| Qué skill usar según el tipo de tarea | `IA_Skill/SKILL-instruction-router.md` |
| Catálogo completo situación → skill | `IA_Skill/README.md` |
| Versiones, perfiles auth/datos, reglas por tecnología | `IA_Skill/SKILL-stack-policy.md` |
| Política de autonomía y ambigüedades | `IA_Skill/SKILL-autonomy-policy.md` |
| Zonas de riesgo y código legado | `IA_Skill/SKILL-risk-zone-policy.md` |
| Skills oficiales de Microsoft (.NET) y su precedencia | `IA_Skill/dotnet-official/README.md` |
| Estado, arquitectura y convenciones del proyecto | `IA_Memoria/progreso.md` · `IA_Memoria/arquitectura.md` · `IA_Memoria/convenciones.md` |
| Plantilla de `AGENTS.md` por proyecto | `IA_Skill/templates/AGENTS.project.md` |
| Guía para humanos del template | `GUIDE.md` |
