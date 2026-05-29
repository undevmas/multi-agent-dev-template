# Arquitectura del Proyecto

> Mantener actualizado. Claude lee este archivo al inicio de cada sesión.
> Es la fuente de verdad sobre qué hace cada parte del sistema.

---

## Visión general del sistema

[COMPLETAR: Describir en 2-3 líneas qué hace el sistema]

Ejemplo: "Sistema de gestión de amparos legales que permite registrar, dar seguimiento
y resolver solicitudes ciudadanas, con flujos de aprobación multinivel,
asignación a responsables y generación de reportes ejecutivos."

---

## Frontend

| Carpeta | Tecnología | Puerto local | Estado |
|---|---|---|---|
| `Codigo/frontend-angular/` | Angular 17+ | 4200 | 🔄 En desarrollo |

**Módulos implementados:**
- [ ] [Completar con los módulos ya existentes en el proyecto]
- [ ] [Agregar según avance]

**Design system:** [Angular Material / Tailwind — completar]
**Gestión de estado:** [NgRx / Signals — completar]

---

## Backend

| Carpeta | Tecnología | Puerto local | Rol |
|---|---|---|---|
| `Codigo/backend-net/` | .NET 8 (C#) | 5000 | API principal |
| `Codigo/backend-nestjs/` | NestJS 10 (TS) | 3000 | [Describir rol específico] |

**Autenticación:** JWT con refresh token
**Documentación API:** Swagger en `/swagger` (desarrollo)

---

## Base de datos

| Motor | Entorno | Host local | Esquema principal |
|---|---|---|---|
| SQL Server | Producción + Dev | localhost,1433 | `dbo` |
| PostgreSQL | [Si aplica] | localhost:5432 | `public` |

**Herramienta de migraciones:**
- .NET: Entity Framework Core Migrations
- NestJS: TypeORM Migrations

---

## Infraestructura

| Componente | Tecnología | Notas |
|---|---|---|
| Contenedores | Docker + Docker Compose | Para desarrollo local |
| CI/CD | Azure DevOps Pipelines | Workflows en `Codigo/workflows/` |
| Certificados | `Codigo/certs/` | Para HTTPS local |

---

## Flujo principal del sistema

```
Usuario
  └── Angular App (4200)
        └── HTTP/JWT → Backend .NET (5000) / NestJS (3000)
                          └── SQL Server / PostgreSQL
```

---

## Variables de entorno requeridas

```env
# Backend .NET (appsettings.Development.json)
ConnectionStrings__DefaultConnection=Server=...
JwtSettings__Secret=
JwtSettings__ExpirationHours=8

# Backend NestJS (.env)
DATABASE_URL=
JWT_SECRET=
JWT_EXPIRATION=8h

# Frontend Angular (environment.ts)
apiUrl=http://localhost:5000/api/v1
```

---

## Notas importantes para el agente IA

- Antes de crear cualquier módulo, verificar en `IA_Memoria/progreso.md` si ya existe
- Respetar la estructura de carpetas existente en `Codigo/`
- Los archivos `.env` y `appsettings.*.json` nunca se modifican sin confirmación explícita
