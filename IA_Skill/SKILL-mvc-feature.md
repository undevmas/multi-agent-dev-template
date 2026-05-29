# SKILL — Crear una Feature Completa (Full Stack)

## Cuándo usar esta skill
Cuando se implementa un módulo nuevo de principio a fin **sin spec previa**.
Leer ANTES de escribir cualquier línea de código de una feature nueva.

> Si existe `Features/[mod].spec.md` en estado `ready`, usar
> `IA_Skill/SKILL-implementation.md` en su lugar — esa skill consume el contrato
> técnico ya generado. Esta skill es para implementación directa sin spec.

---

## Orden de implementación (no saltarse pasos)

```
1. Base de datos
   └── Diseñar tabla(s) → Crear migración → Ejecutar → Seed de datos de prueba

2. Backend — capa de datos
   └── Entidad/Modelo → Interfaz Repository → Implementación Repository

3. Backend — capa de negocio
   └── Interfaz Service → Implementación Service → Tests unitarios del Service

4. Backend — capa de presentación
   └── DTOs (Request/Response) → Controller → Documentar endpoints

5. Contrato API
   └── Crear o actualizar Features/[feature].spec.md con los endpoints, payloads
       y respuestas implementados — el contrato técnico vive en .spec.md, no en .md
       Si Features/[feature].md no existe, crearlo con Estado: in-progress y
       descripción del módulo en lenguaje de negocio (sin endpoints ni SQL)

6. Frontend — integración
   └── Modelo TypeScript → Servicio HTTP → Store/State

7. Frontend — UI
   └── Componentes → Página → Manejo de estados (loading, empty, error, success)

8. Cierre
   └── Test E2E del flujo completo → Actualizar IA_Memoria/progreso.md
```

---

## Patrón REST estándar del proyecto

```
GET    /api/v1/[recurso]              Listar con paginación y filtros
GET    /api/v1/[recurso]/:id          Obtener uno por ID
POST   /api/v1/[recurso]              Crear nuevo
PUT    /api/v1/[recurso]/:id          Reemplazar completo
PATCH  /api/v1/[recurso]/:id          Actualizar campos específicos
DELETE /api/v1/[recurso]/:id          Soft delete (marcar inactivo)
GET    /api/v1/[recurso]/:id/[sub]    Sub-recurso relacionado
```

---

## Respuesta estandarizada (TODOS los endpoints)

```json
{
  "success": true,
  "data": {},
  "message": "Operación exitosa",
  "errors": [],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

En errores:
```json
{
  "success": false,
  "data": null,
  "message": "No se pudo completar la operación",
  "errors": [
    { "field": "email", "message": "El correo ya está registrado" }
  ]
}
```

---

## Estructura de archivos por feature

### .NET 8
```
Features/[NombreFeature]/
├── [NombreFeature]Controller.cs
├── [NombreFeature]Service.cs
├── I[NombreFeature]Service.cs
├── [NombreFeature]Repository.cs
├── I[NombreFeature]Repository.cs
└── DTOs/
    ├── Create[NombreFeature]Request.cs
    ├── Update[NombreFeature]Request.cs
    └── [NombreFeature]Response.cs
```

### NestJS
```
src/[nombre-feature]/
├── [nombre-feature].module.ts
├── [nombre-feature].controller.ts
├── [nombre-feature].service.ts
├── [nombre-feature].repository.ts
├── entities/
│   └── [nombre-feature].entity.ts
└── dto/
    ├── create-[nombre-feature].dto.ts
    ├── update-[nombre-feature].dto.ts
    └── [nombre-feature]-response.dto.ts
```

### Angular
```
src/app/features/[nombre-feature]/
├── [nombre-feature].module.ts       (o routes si es standalone)
├── pages/
│   ├── [nombre-feature]-list/
│   └── [nombre-feature]-detail/
├── components/
│   └── [componentes reutilizables de esta feature]
├── services/
│   └── [nombre-feature].service.ts
└── models/
    └── [nombre-feature].model.ts
```

---

## Campos obligatorios en toda tabla

```sql
-- SQL Server
Id          UNIQUEIDENTIFIER  PRIMARY KEY DEFAULT NEWID()
CreatedAt   DATETIME          NOT NULL DEFAULT GETDATE()
UpdatedAt   DATETIME          NOT NULL DEFAULT GETDATE()
IsActive    BIT               NOT NULL DEFAULT 1
CreatedBy   UNIQUEIDENTIFIER  NULL  REFERENCES Users(Id)
UpdatedBy   UNIQUEIDENTIFIER  NULL  REFERENCES Users(Id)
```

```sql
-- PostgreSQL
id          UUID              PRIMARY KEY DEFAULT gen_random_uuid()
created_at  TIMESTAMP         NOT NULL DEFAULT NOW()
updated_at  TIMESTAMP         NOT NULL DEFAULT NOW()
is_active   BOOLEAN           NOT NULL DEFAULT TRUE
created_by  UUID              NULL  REFERENCES users(id)
updated_by  UUID              NULL  REFERENCES users(id)
```

---

## Checklist antes de marcar feature como lista ✅

- [ ] Migración de BD ejecutada y existe script de rollback
- [ ] Validaciones de entrada implementadas (FluentValidation / class-validator)
- [ ] Manejo de errores en todos los endpoints (try-catch + respuesta estándar)
- [ ] Tests unitarios: mínimo happy path + un caso de error por Service
- [ ] Paginación implementada en endpoints de listado
- [ ] Los 4 estados de UI: loading, empty, error, success
- [ ] Responsive verificado en móvil (375px mínimo)
- [ ] `Features/[nombre].spec.md` existe con los contratos de API y reglas de negocio implementados
- [ ] `Features/[nombre].md` actualizado con Estado: in-review (fuente de verdad — actualizar primero)
- [ ] `IA_Memoria/progreso.md` sincronizado con el estado de `Features/[nombre].md`
