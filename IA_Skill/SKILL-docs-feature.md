# SKILL — Docs Feature (Documentación por Feature)

## Cuándo usar esta skill
Al terminar de implementar una feature completa.
Trigger: cuando el dev dice "documenta [nombre feature]", "genera docs de [feature]",
"feature terminada", "actualiza documentación de [módulo]".

NO usar durante el desarrollo — documentar cuando el código es real y funcional.

---

## Workflow

### Paso 1 — Confirmar qué documentar

Antes de generar, preguntar en un solo mensaje:

```
Para documentar esta feature necesito confirmar:

1. ¿Qué feature terminaste? (nombre del módulo)
2. ¿Está en el backend .NET, NestJS, o ambos?
3. ¿Tiene interfaz en Angular?
4. ¿Hubo cambios en la base de datos (nuevas tablas, columnas, migraciones)?
```

Si el dev ya dio esa información, saltar directo al Paso 2.

---

### Paso 2 — Leer el código real

Nunca generar documentación de suposiciones. Leer en este orden:

#### Backend .NET
```
src/Features/[NombreFeature]/
  [Feature]Controller.cs       → endpoints, rutas, verbos HTTP
  [Feature]Service.cs          → lógica de negocio implementada
  DTOs/                        → estructura de request y response
Migrations/                    → última migración relacionada
```

#### Backend NestJS
```
src/modules/[nombre-feature]/
  [feature].controller.ts      → endpoints, decoradores, guards
  [feature].service.ts         → lógica implementada
  dto/                         → DTOs con validaciones
  entities/                    → entidad TypeORM
```

#### Frontend Angular
```
src/app/features/[nombre]/
  pages/                       → páginas y rutas
  components/                  → componentes del módulo
  services/[nombre].service.ts → llamadas HTTP al backend
  models/                      → interfaces y tipos
```

#### Base de datos
```
Migrations/ o src/database/migrations/
  → última migración aplicada para esta feature
Features/[nombre].md
  → definición original para comparar con lo implementado
```

---

### Paso 3 — Generar documentación

Crear archivos en `Codigo/docs/features/[nombre-feature]/`.
Cada sección debe reflejar el código real, no el plan original.

---

## Documento 1: README.md del feature

```markdown
# Feature: [Nombre del Feature]

**Estado:** ✅ Completado
**Fecha:** [fecha actual]
**Stack:** [Angular | .NET | NestJS | BD] — solo los que aplican

---

## Qué hace este módulo

[2-3 oraciones describiendo qué resuelve este módulo para el negocio.
Escrito para que cualquier dev del equipo entienda sin ver el código.]

---

## Cómo usarlo (guía rápida)

[Flujo principal desde la perspectiva del usuario:
1. El usuario hace X
2. El sistema responde con Y
3. Si hay error, muestra Z]

---

## Componentes del módulo

| Capa | Archivo/Clase | Responsabilidad |
|---|---|---|
| Controller (.NET/NestJS) | [nombre] | [qué hace] |
| Service | [nombre] | [qué hace] |
| Repository | [nombre] | [qué hace] |
| DTOs | [lista] | [qué representan] |
| Entidad/Modelo BD | [nombre] | [tabla que mapea] |
| Componente Angular | [lista] | [qué renderiza] |
| Servicio Angular | [nombre] | [endpoints que consume] |

---

## Dependencias con otros módulos

[Listar qué otros módulos usa este feature y para qué.
Ejemplo: "Usa AuthModule para verificar el token JWT"]

---

## Consideraciones importantes

[Cualquier decisión técnica relevante, limitación conocida,
o cosa que el próximo dev debe saber antes de tocar este módulo.]
```

---

## Documento 2: api-endpoints.md

```markdown
# API Endpoints — [Nombre del Feature]

**Base URL:** `/api/v1/[recurso]`
**Autenticación:** JWT Bearer Token requerido en todos los endpoints
**Roles requeridos:** [listar si aplica]

---

## Endpoints

### [VERBO] /api/v1/[ruta]

**Propósito:** [qué hace en una línea]
**Autenticación:** Requerida / Pública
**Rol mínimo:** [Admin | Manager | Analyst | ReadOnly | Cualquiera]

**Request:**
```http
[VERBO] /api/v1/[ruta]
Authorization: Bearer {token}
Content-Type: application/json

{
  "campo": "tipo — descripción",
  "campoopcional": "tipo — descripción (opcional)"
}
```

**Response exitosa (2XX):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "campo": "valor de ejemplo"
  },
  "message": "Mensaje en español",
  "errors": []
}
```

**Respuestas de error:**
| Código | Cuándo ocurre |
|---|---|
| 400 | [descripción] |
| 401 | Token inválido o expirado |
| 403 | Sin permisos suficientes |
| 404 | [recurso] no encontrado |
| 409 | [descripción de conflicto] |
| 422 | [descripción de error de negocio] |

---

[Repetir sección por cada endpoint del feature]

---

## Ejemplos de uso (curl)

```bash
# [Descripción del ejemplo]
curl -X [VERBO] https://api.dominio.com/api/v1/[ruta] \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"campo": "valor"}'
```
```

---

## Documento 3: database.md

```markdown
# Base de Datos — [Nombre del Feature]

**Motor:** SQL Server / PostgreSQL (según entorno)
**ORM:** Entity Framework Core (.NET) / TypeORM (NestJS)

---

## Tablas involucradas

### [NombreTabla] (tabla principal del feature)

**Propósito:** [qué representa esta tabla en el negocio]

| Columna | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| Id / id | UNIQUEIDENTIFIER / UUID | Sí | NEWID() / gen_random_uuid() | Clave primaria |
| [columna] | [tipo] | Sí/No | [valor] | [descripción] |
| IsActive / is_active | BIT / BOOLEAN | Sí | 1 / true | Soft delete |
| CreatedAt / created_at | DATETIME / TIMESTAMP | Sí | GETDATE() / NOW() | Fecha de creación |
| UpdatedAt / updated_at | DATETIME / TIMESTAMP | Sí | GETDATE() / NOW() | Última modificación |
| CreatedBy / created_by | UNIQUEIDENTIFIER / UUID | No | NULL | FK → Users |
| UpdatedBy / updated_by | UNIQUEIDENTIFIER / UUID | No | NULL | FK → Users |

**Índices:**
| Nombre | Columnas | Tipo | Propósito |
|---|---|---|---|
| PK_[Tabla] | Id | Primary Key | Identificador único |
| IX_[Tabla]_[Col] | [columna] | Index | [para qué consulta] |

**Relaciones:**
| Tabla relacionada | Tipo | Columna FK | Descripción |
|---|---|---|---|
| Users | N:1 | CreatedBy | Usuario que creó el registro |
| [otra tabla] | [tipo] | [FK] | [descripción] |

---

## Migraciones aplicadas

| Migración | Fecha | Descripción |
|---|---|---|
| [NombreMigracion] | [fecha] | [qué cambió en la BD] |

**Comando para revertir si es necesario:**
```bash
# .NET EF Core
dotnet ef migrations remove

# TypeORM
npx typeorm migration:revert
```

---

## Queries frecuentes (referencia)

```sql
-- [Descripción de la query]
SELECT [columnas]
FROM [tabla]
WHERE IsActive = 1
  AND [condición]
ORDER BY CreatedAt DESC;
```
```

---

## Documento 4: frontend.md

```markdown
# Frontend Angular — [Nombre del Feature]

**Ruta base:** `/[ruta-en-la-app]`
**Módulo:** `[nombre-feature].module.ts` (o standalone routes)
**Guard requerido:** AuthGuard + RoleGuard (roles: [lista])

---

## Rutas del módulo

| Ruta | Componente | Descripción | Guard |
|---|---|---|---|
| `/[ruta]` | [NombreComponent] | [qué muestra] | AuthGuard |
| `/[ruta]/:id` | [NombreComponent] | [qué muestra] | AuthGuard |

---

## Componentes

### [NombreComponent]

**Archivo:** `[ruta/al/componente]`
**Propósito:** [qué renderiza y qué responsabilidad tiene]

**Inputs:**
| @Input | Tipo | Descripción |
|---|---|---|
| [nombre] | [tipo] | [qué recibe] |

**Outputs:**
| @Output | Tipo | Cuándo emite |
|---|---|---|
| [nombre] | EventEmitter<[tipo]> | [cuándo] |

**Estados manejados:**
- [ ] Loading — [cómo se muestra]
- [ ] Empty — [qué mensaje/acción]
- [ ] Error — [qué mensaje/acción]
- [ ] Success — [confirmación y redirect]

---

## Servicio Angular

**Archivo:** `[ruta/al/servicio]`

| Método | Endpoint que consume | Retorna | Descripción |
|---|---|---|---|
| `getAll(filter)` | GET /api/v1/[recurso] | `Observable<PagedResult<[Dto]>>` | [descripción] |
| `getById(id)` | GET /api/v1/[recurso]/:id | `Observable<[Dto]>` | [descripción] |
| `create(dto)` | POST /api/v1/[recurso] | `Observable<[Dto]>` | [descripción] |
| `update(id, dto)` | PUT /api/v1/[recurso]/:id | `Observable<[Dto]>` | [descripción] |
| `delete(id)` | DELETE /api/v1/[recurso]/:id | `Observable<void>` | [descripción] |

---

## Modelos TypeScript

```typescript
// [NombreDto] — respuesta del backend
export interface [Nombre]Dto {
  id: string;
  [campo]: [tipo]; // [descripción]
}

// [CreateNombreDto] — request para crear
export interface Create[Nombre]Dto {
  [campo]: [tipo]; // [descripción, requerido/opcional]
}
```

---

## Navegación relacionada

| Desde | Acción | Navega a |
|---|---|---|
| [página] | [acción del usuario] | [ruta destino] |
```

---

### Paso 4 — Actualizar IA_Memoria

Después de generar los documentos, actualizar automáticamente:

#### IA_Memoria/progreso.md
- Mover la feature de "En progreso" a "Completado"
- Agregar fecha de completado
- Actualizar "Próximos pasos" si corresponde

#### IA_Memoria/arquitectura.md
- Agregar nuevos endpoints a la tabla de la capa correspondiente
- Agregar nuevas tablas a la sección de base de datos
- Actualizar el diagrama de flujo si el módulo agrega una nueva pieza

---

### Paso 5 — Mostrar resumen

```
📄 Documentación generada para: [Nombre Feature]

  Codigo/docs/features/[nombre]/
  ├── README.md          — Descripción y guía del módulo
  ├── api-endpoints.md   — [N] endpoints documentados
  ├── database.md        — [N] tablas, [N] migraciones
  └── frontend.md        — [N] componentes, [N] rutas

✅ IA_Memoria/progreso.md actualizado
✅ IA_Memoria/arquitectura.md actualizado

Próxima feature sugerida según progreso.md: [nombre]
```

---

## Reglas importantes

1. **Documentar lo que existe, no lo que se planeó**
   Leer el código real. Si algo del plan en `Features/[nombre].md`
   no se implementó, NO documentarlo — solo lo que está en el código.

2. **Lenguaje del código vs documentación**
   Código: inglés
   Documentación: español
   Ejemplos de API (JSON, curl): inglés para campos, español para descripciones

3. **Nunca incluir en la documentación**
   Credenciales reales, connection strings, tokens, passwords.
   Solo nombres de variables de entorno.

4. **Completitud sobre velocidad**
   Mejor documentar bien un módulo que documentar rápido todos.
   Si falta información, preguntar antes de inventar.

5. **Actualizar siempre IA_Memoria**
   La documentación de feature sin actualizar la memoria del proyecto
   no sirve — el agente no sabrá en la próxima sesión que ese módulo existe.

---

## Estructura final del workspace con docs

```
workspace-proyecto/
├── Codigo/                    ← repo git
│   └── docs/                  ← documentación generada (se versiona)
│       └── features/
│           ├── login/
│           │   ├── README.md
│           │   ├── api-endpoints.md
│           │   ├── database.md
│           │   └── frontend.md
│           └── [próxima-feature]/
├── IA_Memoria/
│   ├── arquitectura.md        ← actualizado por esta skill
│   ├── convenciones.md
│   └── progreso.md            ← actualizado por esta skill
└── Features/                  ← definición (antes de implementar)
    └── [feature].md
```
