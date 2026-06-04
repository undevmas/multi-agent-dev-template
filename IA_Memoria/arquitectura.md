# Arquitectura del Proyecto

> Mantener actualizado. El agente lee este archivo al inicio de cada sesión.
> Es la fuente de verdad sobre qué hace cada parte del sistema.
> Se completa la primera vez ejecutando repomix y el prompt de inspección.

---

## Visión general del sistema

[COMPLETAR: Describir en 2-3 líneas qué hace el sistema]

Ejemplo: "Sistema de gestión de amparos legales que permite registrar, dar seguimiento
y resolver solicitudes ciudadanas, con flujos de aprobación multinivel,
asignación a responsables y generación de reportes ejecutivos."

---

## Estructura de Codigo/

> El agente completa esta sección al correr repomix por primera vez.
> Documentar cada carpeta que exista dentro de Codigo/ con su contenido y tecnología.

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

## Notas importantes para el agente IA

- Antes de crear cualquier módulo, verificar en `IA_Memoria/progreso.md` si ya existe
- Respetar la estructura de carpetas existente en `Codigo/`
- Los archivos `.env` y `appsettings.*.json` nunca se modifican sin confirmación explícita
