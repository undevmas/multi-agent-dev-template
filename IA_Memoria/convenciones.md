# Convenciones del Proyecto

> Convenciones verificadas contra el código existente el 2026-09-04.

## Naming por capa

| Elemento | Convención | Ejemplo |
|---|---|---|
| Ramas Git | `tipo/descripcion-corta` | `feature/login-oauth` |
| Commits | Conventional Commits | `feat: agregar refresh token` |
| Variables JS/TS | camelCase | `userId` |
| Clases C# | PascalCase | `UserService` |
| Interfaces C# | `I` + PascalCase | `IUserService` |
| Tablas PostgreSQL | snake_case | `tenant_invitations` |
| Columnas PostgreSQL | snake_case | `is_deleted`, `created_at` |
| Endpoints REST | kebab-case y plural cuando aplica | `/api/v1/tenant-users` |
| Archivos Angular | kebab-case | `users-list.component.ts` |
| Archivos C# | PascalCase | `UsersController.cs` |

## Formato de respuesta API

La forma real de `Dtos.ApiResponse<T>` es:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "traceId": "..."
}
```

En error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Mensaje localizado",
    "validationErrors": {
      "field": ["Detalle"]
    }
  },
  "traceId": "..."
}
```

`ApiError.ValidationErrors` es opcional. `traceId` se obtiene de `Activity.Current?.Id` o `HttpContext.TraceIdentifier` en los manejadores globales. Las respuestas paginadas envuelven el resultado en `data` como `PagedResult<T>`; los endpoints declaran `page`, `pageSize` y filtros según el módulo.

Excepciones intencionales al JSON común:

- HTTP 204 sin cuerpo para operaciones de revocación/desactivación exitosas.
- SSO usa redirects/404 porque es navegación de página completa, no XHR.
- Algunas ramas de autorización/validación de Identity aún retornan `BadRequest()`, `Forbid()` o `Unauthorized()` sin `ApiResponse`; está registrado en deuda técnica.

## Arquitectura y patrones detectados

| Aspecto | Patrón detectado |
|---|---|
| Arquitectura de capas | Clean Architecture / N-capas por módulo: Domain, Application e Infrastructure; servicios web como API composition |
| Organización funcional | Vertical Slice dentro de `Application/Features` y `Application/UseCases` |
| Casos de uso | MediatR en Identity y use cases explícitos en Catalogo, Trading y Worker |
| Integración Trading↔Python | Contratos HTTP internos versionados y Redis Streams; ningún servicio lee directamente el schema ajeno |
| Jobs de trading | Quartz.NET decide cuándo disparar; `jmh_trading` decide y ejecuta la lógica analítica |
| Acceso a datos | EF Core `DbContext` + repositorio genérico/UoW; Dapper mediante `ISqlExecutor` para SQL parametrizado puntual |
| Persistencia | Un `DbContext` y migraciones por bounded context/servicio |
| Manejo de excepciones | `IExceptionHandler` global por servicio; errores esperados se convierten a `ApiResponse.Fail`; logging con Serilog |
| Validaciones | `ModelState` en controllers, errores `VALIDATION_ERROR` con diccionario campo→mensajes y validación en use cases |
| Soft delete | `SoftDeleteSaveChangesInterceptor` para entidades `ISoftDeletable`, filtros globales `IsDeleted`; entidades con `IsActive` para estados activos |
| Multi-tenancy | `TenantResolutionMiddleware`, `ITenantContext`, filtros globales y guards de acceso por tenant |
| Frontend | Angular standalone, zoneless, signals, interceptores y guards funcionales |
| Observabilidad | OpenTelemetry, Serilog, `traceId` en respuestas de error |

## Manejo de errores HTTP

| Código | Uso observado |
|---|---|
| 200 | Operación exitosa con `ApiResponse` |
| 201 | Creación exitosa con `ApiResponse<T>` |
| 202 | Challenge/proceso asíncrono con `ApiResponse<T>` |
| 204 | Operación exitosa sin cuerpo |
| 400 | Validación o datos inválidos |
| 401 | No autenticado |
| 403 | Sin permisos |
| 404 | Recurso no encontrado |
| 409 | Conflicto de estado/duplicado |
| 422 | Error de negocio/validación semántica |
| 500 | `INTERNAL_ERROR` sin stack trace y con `traceId` |
| 503 | Dependencia externa no disponible, especialmente Trading/JmhTrading |

## Excepciones / desviaciones registradas

| Fecha | Módulo | Convención que se rompe | Razón |
|---|---|---|---|
| 2026-09-04 | Identity | Algunas ramas retornan respuestas framework crudas | Código existente; requiere ticket para normalización |
