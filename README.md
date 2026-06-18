# AI Dev Workspace Template

Capa de contexto y gobierno para sesiones de desarrollo con IA. Estandariza cómo trabaja el agente en el proyecto — sin perder convenciones entre sesiones ni depender de un solo proveedor.

---

## Estructura del workspace

```
workspace-proyecto/
├── CLAUDE.md / AGENTS.md / GEMINI.md    ← Instrucciones del agente (fuente de verdad)
│
├── Insumos/                             ← Material de entrada para el agente
│   ├── mockups/                         ← Pantallas y wireframes
│   ├── especificaciones/                ← Docs de reglas de negocio, HU, PDFs
│   └── datos/                           ← Seeds y escenarios de prueba
│
├── Features/                            ← Specs de cada módulo (3 archivos por feature)
│   ├── [mod].md                         ← Requisitos de negocio + estado del ciclo
│   ├── [mod].spec.md                    ← Contrato técnico: entidades, API, reglas
│   └── [mod].checks.md                  ← Verificación post-implementación
│
├── IA_Skill/                            ← Guías técnicas que consulta el agente
├── IA_Memoria/                          ← Estado persistente del proyecto
│   ├── progreso.md
│   ├── arquitectura.md
│   └── convenciones.md
├── Issues/                              ← Bugs registrados
│
└── Codigo/                              ← ÚNICO que se versiona en git
```

---

## Cómo usar la plantilla

### 1. Deposita el insumo en `Insumos/`

Antes de pedirle algo al agente, coloca el material de entrada:

| Tipo de insumo | Dónde va |
|---|---|
| Mockup, pantalla, wireframe | `Insumos/mockups/` |
| Documento Word, PDF, historia de usuario | `Insumos/especificaciones/` |
| Datos de prueba o seed de BD | `Insumos/datos/` |
| Notas sueltas | Pégalas directo en el chat |

### 2. Pídele al agente que genere la spec

```
Genera la spec para la feature [nombre].
Lee IA_Skill/SKILL-spec-generator.md primero.
El insumo está en Insumos/[carpeta]/[archivo].
```

El agente generará tres archivos en `Features/`: `.md`, `.spec.md` y `.checks.md`.

### 3. Valida la spec (tú, el dev)

Abre `Features/[mod].spec.md` y verifica:
- ¿Los flujos reflejan lo que pediste?
- ¿Las entidades y campos son correctos?
- ¿Las reglas de negocio están completas?

Corrige lo que falte y cambia `**Estado:**` a `ready` en `[mod].md`.

### 4. Pídele al agente que implemente

```
Implementa Features/[nombre].
Lee IA_Skill/SKILL-implementation.md primero.
```

El agente implementará por capas (BD → backend → frontend), marcará `in-review` al terminar y actualizará `IA_Memoria/progreso.md`.

### 5. Valida la implementación (tú, el dev)

Abre `Features/[mod].checks.md` y verifica cada punto contra el código generado.
Cuando todo esté correcto, cambia `**Estado:**` a `done` en `[mod].md`.

### 6. Pídele al agente que cierre el progreso

```
La feature [nombre] quedó done. Actualiza IA_Memoria/progreso.md.
```

El agente sincronizará la vista agregada del proyecto. Esto garantiza que la próxima sesión arranque con contexto real.

---

## Cómo va avanzando el dev

El dev valida en dos momentos y el agente mantiene el progreso:

```
Insumo entregado
      ↓
Agente genera spec  → DEV REVISA spec            → aprueba → Estado: ready
      ↓
Agente implementa   → actualiza progreso.md (in-review)
      ↓
DEV REVISA checks   → aprueba → Estado: done
      ↓
Agente sincroniza   → actualiza progreso.md (done)
```

El estado de cada feature vive en `Features/[mod].md`.
La vista general de todos los módulos vive en `IA_Memoria/progreso.md`.

---

## Stack aprobado

No usar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa | Tecnología |
|---|---|
| Frontend | Angular 17+ · React 18+ |
| Backend | .NET 8+ (C#) · NestJS 10+ (TypeScript) |
| Base de datos | SQL Server 2019+ · PostgreSQL 15+ |
| ORM | Entity Framework Core · TypeORM · Prisma |
| Autenticación | JWT + Refresh Token · OAuth2 · ASP.NET Identity |
| Contenedores | Docker · Docker Compose |
| CI/CD | Azure DevOps Pipelines |
| Testing | xUnit · Jest · Cypress |
| Documentación API | Swagger / OpenAPI |

---

## Reglas críticas

| Regla | Detalle |
|---|---|
| **Soft delete obligatorio** | Nunca `DELETE FROM` en tablas de negocio — usar `is_active = false` |
| **IDs UUID/GUID** | Nunca enteros secuenciales |
| **Respuesta de API estandarizada** | `{ success, data, message, errors }` en todos los endpoints |
| **Endpoints protegidos** | Guard/middleware en todo excepto login |
| **Sin hardcodeo** | Credenciales y URLs siempre en variables de entorno |
| **Migraciones versionadas** | Todo cambio de BD requiere su migración |

---

## Qué versionar

| Qué | ¿Va a git? |
|---|---|
| `Codigo/` | ✅ Siempre |
| `CLAUDE.md`, `AGENTS.md`, bridges | ✅ Recomendado |
| `IA_Memoria/` | Opcional — útil para equipos |
| `Features/`, `Issues/` | Opcional — útil como documentación compartida |
| `IA_Skill/` | No recomendado |
| `IA_Memoria/snapshots/` | Nunca |
