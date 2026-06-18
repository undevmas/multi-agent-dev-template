# GEMINI.md — Instrucciones del Proyecto

> Leer este archivo antes de cualquier acción en el workspace.

---

## Stack tecnológico (reglas duras — no sugerir alternativas)

| Capa | Tecnología aprobada |
|---|---|
| Frontend | Angular 17+ · React 18+ |
| Backend | .NET 8+ (C#) · NestJS 10+ (TypeScript) |
| Base de datos | SQL Server 2019+ · PostgreSQL 15+ |
| ORM / acceso a datos | Entity Framework Core · TypeORM · Prisma |
| Autenticación | JWT + Refresh Token · OAuth2 · ASP.NET Identity |
| Contenedores | Docker · Docker Compose |
| CI/CD | Azure DevOps Pipelines |
| Testing unitario | xUnit (.NET) · Jest (TS/JS) |
| Testing E2E | Cypress |
| Documentación API | Swagger / OpenAPI |

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
| Componente visual (Angular/React) | IA_Skill/SKILL-frontend-design.md |
| Formulario, flujo, UX avanzado | IA_Skill/SKILL-ui-ux-pro-max.md |
| Code review o QA de código Angular/React | IA_Skill/SKILL-impeccable.md |
| Tests en Angular (TestBed, Jest) | IA_Skill/SKILL-angular-test-frameworks.md |
| Tests en React (Jest + Testing Library) | IA_Skill/SKILL-react-test-frameworks.md |
| Página pública / SEO | IA_Skill/SKILL-seo.md |
| Implementar feature con spec en estado `ready` | IA_Skill/SKILL-implementation.md |
| Módulo completo full stack (sin spec previa) | IA_Skill/SKILL-mvc-feature.md |
| Crear, aplicar o revertir migraciones de BD (.NET/NestJS) | IA_Skill/SKILL-database-migrations.md |
| Crear/modificar backend .NET | IA_Skill/SKILL-dotnet-best-practices.md |
| Code review .NET | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Tests en .NET | IA_Skill/SKILL-dotnet-test-frameworks.md |
| Migrar versión de .NET | IA_Skill/SKILL-dotnet-upgrade.md |
| Crear/modificar backend NestJS | IA_Skill/SKILL-nestjs-best-practices.md |
| Patrones avanzados NestJS (CQRS, eventos, colas) | IA_Skill/SKILL-nestjs-patterns.md |
| TypeScript estricto en NestJS | IA_Skill/SKILL-nestjs-clean-typescript.md |
| Tests en NestJS (Jest + Supertest) | IA_Skill/SKILL-nestjs-test-frameworks.md |
| Seguridad en Angular | IA_Skill/SKILL-security-angular.md |
| Seguridad en .NET | IA_Skill/SKILL-security-dotnet.md |
| Seguridad en NestJS | IA_Skill/SKILL-security-nestjs.md |
| Revisión OWASP (pre-producción o feature con datos sensibles) | IA_Skill/SKILL-security-owasp-checklist.md |
| Revisión OWASP adicional (compliance por agentes) | IA_Skill/SKILL-agent-owasp-compliance.md |
| Generar o actualizar specs de features (sin tocar código) | IA_Skill/SKILL-spec-generator.md |
| Texto visible al usuario final (mensajes UI) | IA_Skill/SKILL-humanizer.md |
| Documentar feature terminada | IA_Skill/SKILL-docs-feature.md |
| Búsqueda web y fuentes externas actualizadas | IA_Skill/SKILL-web-search.md |
| Respuestas ultra-concisas en sesiones largas | IA_Skill/SKILL-caveman.md |
| Resolver comentarios de revisión de PR en GitHub | IA_Skill/SKILL-pr-review-fixes.md |

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

### Autenticación
- JWT en header: `Authorization: Bearer [token]`
- Refresh token en cookie HttpOnly
- Guard/middleware en TODOS los endpoints excepto login

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

Las convenciones del template no se adaptan al legado — se aplican donde es posible.

- **Zona verde — código nuevo:** estándar completo siempre, sin importar el entorno
- **Zona ámbar — código existente a modificar:** solo lo mínimo necesario, sin refactorizar sin ticket
- **Zona roja — código intocable sin ticket:** detectar, registrar en `IA_Memoria/deuda-tecnica.md`, no modificar
- **Regla de desempate:** código real > spec. Si contradicen en legado → registrar deuda, consultar al dev.

---

## NUNCA sin confirmación explícita

- Modificar `.env`, `appsettings.json` o archivos de entorno
- Ejecutar `DROP TABLE`, `DELETE FROM` o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado
- Modificar pipelines de CI/CD
- Subir archivos de `IA_Skill/`, `IA_Memoria/`, `Features/`, `Issues/`, `Insumos/` al repositorio
