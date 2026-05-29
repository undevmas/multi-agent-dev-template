# Feature: Catálogos (Tablas Maestras)

**Estado:** 📋 Pendiente
**Stack:** Angular · .NET · SQL Server

---

## Descripción
Gestión de tablas maestras que alimentan los dropdowns y validaciones
del resto del sistema. CRUD con activar/desactivar registros.

---

## Catálogos a implementar

- [ ] Tipos de solicitud / trámite
- [ ] Estados de proceso (Pendiente, En revisión, Aprobado, Rechazado, etc.)
- [ ] Dependencias o áreas organizacionales
- [ ] Roles de usuario
- [ ] [Agregar según análisis de negocio]

---

## Requisitos funcionales

- [ ] Listar con paginación, búsqueda y filtro por estado
- [ ] Crear nuevo registro con validación de duplicados
- [ ] Editar registro existente
- [ ] Activar / desactivar (soft delete, no eliminar)
- [ ] Auditoría: quién creó, quién modificó y cuándo
- [ ] Solo usuarios con rol Administrador pueden gestionar catálogos

---

## Patrón de endpoints (aplicar a cada catálogo)

```
GET    /api/v1/[catalogo]?page=1&pageSize=20&search=&isActive=true
GET    /api/v1/[catalogo]/:id
POST   /api/v1/[catalogo]
PUT    /api/v1/[catalogo]/:id
PATCH  /api/v1/[catalogo]/:id/toggle-active
```

---

## Estructura de tabla base (replicar por catálogo)

```sql
[NombreCatalogo] (
  Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  Name        NVARCHAR(200) NOT NULL,
  Description NVARCHAR(500) NULL,
  Code        NVARCHAR(50) NULL UNIQUE,   -- código corto si aplica
  Order       INT NOT NULL DEFAULT 0,     -- para ordenar en dropdowns
  IsActive    BIT NOT NULL DEFAULT 1,
  CreatedAt   DATETIME NOT NULL DEFAULT GETDATE(),
  UpdatedAt   DATETIME NOT NULL DEFAULT GETDATE(),
  CreatedBy   UNIQUEIDENTIFIER NULL REFERENCES Users(Id),
  UpdatedBy   UNIQUEIDENTIFIER NULL REFERENCES Users(Id)
)
```
