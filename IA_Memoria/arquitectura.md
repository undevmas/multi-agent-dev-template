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

**Autenticación:** [COMPLETAR — JWT + Refresh Token / OAuth2 / otro]
**Documentación API:** [COMPLETAR — Swagger en /swagger / otro]

---

### Base de datos

| Motor | Entorno | Host local | Esquema principal |
|---|---|---|---|
| [COMPLETAR] | [COMPLETAR] | [COMPLETAR] | [COMPLETAR] |

**Herramienta de migraciones:** [COMPLETAR — EF Core Migrations / TypeORM / Prisma / otro]

---

## Infraestructura

| Componente | Tecnología | Notas |
|---|---|---|
| Contenedores | [COMPLETAR si usa Docker] | — |
| CI/CD | [COMPLETAR] | — |

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

## Snapshot verificado — PersonalCripto (2026-09-04)

- Raíz del código: `Codigo/personal-cripto/`.
- Backend: monorepo .NET 10 (`net10.0`) con Gateway, Identity, Worker y servicios Business, Catalogo, Reportes y Trading.
- Frontend: Angular 22 en `src/Frontend/gestion-pwa`, standalone/zoneless/signals y PWA.
- Datos e infraestructura: EF Core 10 con PostgreSQL y SQL Server, Redis y .NET Aspire para orquestación local.
- Integraciones: Azure Service Bus/Key Vault, RabbitMQ, AWS SQS/SNS, OpenTelemetry y Serilog.
- Patrones detectados: capas Domain/Application/Infrastructure, MediatR, EF Core y Dapper.

## Notas importantes para el agente IA

- Antes de crear cualquier módulo, verificar en `IA_Memoria/progreso.md` si ya existe
- Respetar la estructura de carpetas existente en `Codigo/`
- Los archivos `.env` y `appsettings.*.json` nunca se modifican sin confirmación explícita
