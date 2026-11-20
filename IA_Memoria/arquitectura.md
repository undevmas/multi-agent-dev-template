# Arquitectura del Proyecto

> Mantener actualizado. El agente lee este archivo al inicio de cada sesión.
> Es la fuente de verdad sobre qué hace cada parte del sistema.
> Se completa la primera vez ejecutando repomix y el prompt de inspección.
>
> Si las secciones "Ruta raíz del proyecto" o "Mapa de rutas por capa" están en `[COMPLETAR]`,
> volver a correr repomix antes de iniciar cualquier sesión de implementación.
> Sin esos datos, el agente de implementación explorará el filesystem a ciegas.

---

## Visión general del sistema

[COMPLETAR: Describir en 2-3 líneas qué hace el sistema]

Ejemplo: "Sistema de gestión de amparos legales que permite registrar, dar seguimiento
y resolver solicitudes ciudadanas, con flujos de aprobación multinivel,
asignación a responsables y generación de reportes ejecutivos."

---

## Ruta raíz del proyecto

> Campo crítico — el agente lo usa para acceder a cualquier archivo sin explorar.

```
Codigo/[COMPLETAR — nombre exacto de la carpeta del proyecto, ej: MiProyecto/]
```

Ruta completa al código fuente: `Codigo/[COMPLETAR]/src/` (o la que corresponda si no usa /src)

---

## Mapa de rutas por capa

> El agente completa esta sección al correr repomix. Son las rutas reales desde la raíz del workspace.
> Con este mapa, cualquier agente puede acceder a cualquier archivo sin explorar.

| Capa | Ruta desde Codigo/ | Notas |
|---|---|---|
| [COMPLETAR] | [COMPLETAR] | — |

---

## Estructura de Codigo/

> Resumen de carpetas de primer nivel dentro de Codigo/.

| Carpeta en Codigo/ | Contenido | Tecnología detectada |
|---|---|---|
| [COMPLETAR] | [COMPLETAR] | [COMPLETAR] |

---

## Capas del sistema

> Completar solo las capas que existan en el proyecto. Eliminar las que no apliquen.

### Frontend

| Carpeta en Codigo/ | Tecnología | Puerto local | Estado |
|---|---|---|---|
| [COMPLETAR] | [COMPLETAR] | [COMPLETAR] | 🔄 En desarrollo |

**Módulos implementados:**
- [ ] [Completar con los módulos ya existentes en el proyecto]

**Design system:** [COMPLETAR — Angular Material / Tailwind / otro]
**Gestión de estado:** [COMPLETAR — NgRx / Signals / Redux / otro]

---

### Backend

| Carpeta en Codigo/ | Tecnología | Puerto local | Rol |
|---|---|---|---|
| [COMPLETAR] | [COMPLETAR] | [COMPLETAR] | [COMPLETAR] |

**Versión de runtime/framework:** [COMPLETAR — ej. .NET 10 (LTS) / NestJS 11 sobre Node.js 24 LTS — verificada en fuente oficial el AAAA-MM-DD]
**Autenticación — perfil:** [COMPLETAR — A: OIDC + PKCE + BFF, IdP = Entra ID / Keycloak / OpenIddict · B: ASP.NET Core Identity API endpoints (cookie / bearer)] — ver `IA_Skill/SKILL-auth-patterns.md`
**Autorización:** [COMPLETAR — políticas definidas y fallback policy (denegar por defecto)]
**Documentación API:** [COMPLETAR — OpenAPI en /openapi/v1.json + Scalar en /scalar (solo Development) / otro]

---

### Base de datos

| Motor | Entorno | Host local | Esquema principal |
|---|---|---|---|
| [COMPLETAR] | [COMPLETAR] | [COMPLETAR] | [COMPLETAR] |

**Perfil de acceso a datos:** [COMPLETAR — Equilibrado (EF Core / Prisma / Drizzle) · Alto rendimiento-CQRS (EF Core 10 + Dapper / Drizzle / Kysely)]
**Herramienta de migraciones:** [COMPLETAR — EF Core Migrations / prisma migrate / drizzle-kit / Kysely Migrator / TypeORM (solo legado)]

---

## Infraestructura

| Componente | Tecnología | Notas |
|---|---|---|
| Contenedores | [COMPLETAR si usa Docker / Docker Compose] | — |
| Orquestación local | [COMPLETAR — Aspire AppHost en `Codigo/.../[Proyecto].AppHost/` / no aplica (servicio único)] | Dashboard Aspire en [puerto] |
| Testing E2E | [COMPLETAR — Playwright / Cypress (legado, autorizado)] | — |
| CI/CD | [COMPLETAR] | — |

---

## Comandos de verificación

> El agente los ejecuta antes de dar una tarea por terminada (ver `AGENTS.md`). Completar con los comandos reales.

| Qué | Comando | Desde |
|---|---|---|
| Build | [COMPLETAR — ej. `dotnet build src/Proyecto.sln --no-restore`] | [ruta] |
| Tests unitarios | [COMPLETAR — ej. `dotnet test --filter Category=Unit` / `npm test`] | [ruta] |
| Formato / lint | [COMPLETAR — ej. `dotnet format --verify-no-changes` / `npm run lint`] | [ruta] |
| Levantar la app local | [COMPLETAR — ej. `aspire run` / `npm start`] | [ruta] |
| E2E | [COMPLETAR — ej. `npm run test:e2e`] | raíz del workspace |

---

## Flujo principal del sistema

[COMPLETAR: diagrama de cómo se comunican las capas del sistema]

Ejemplo:
```
Usuario
  └── Frontend (puerto)
        └── HTTP/JWT → Backend (puerto)
                          └── Base de datos (puerto)
```

---

## Variables de entorno requeridas

[COMPLETAR: listar variables por componente según lo detectado en el código]

---

## Notas importantes para el agente IA

- Antes de crear cualquier módulo, verificar en `IA_Memoria/progreso.md` si ya existe
- Respetar la estructura de carpetas existente en `Codigo/`
- Los archivos `.env` y `appsettings.*.json` nunca se modifican sin confirmación explícita
