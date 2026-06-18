# Convenciones del Proyecto

> Respetar estas convenciones en todo el código.
> Si necesitas hacer una excepción, documentarla aquí.

---

## Naming por capa

| Elemento | Convención | Ejemplo |
|---|---|---|
| Ramas Git | `tipo/descripcion-corta` | `feature/login-oauth` |
| Commits | Conventional Commits | `feat: agregar refresh token` |
| Variables JS/TS | camelCase | `userId`, `contractList` |
| Clases C# | PascalCase | `UserService`, `ContractRepository` |
| Interfaces C# | `I` + PascalCase | `IUserService` |
| Tablas SQL Server | PascalCase | `Users`, `ContractRequests` |
| Tablas PostgreSQL | snake_case | `users`, `contract_requests` |
| Columnas SQL Server | PascalCase | `CreatedAt`, `IsActive` |
| Columnas PostgreSQL | snake_case | `created_at`, `is_active` |
| Endpoints REST | kebab-case plural | `/api/v1/contract-requests` |
| Archivos Angular | kebab-case | `user-list.component.ts` |
| Archivos React | PascalCase | `UserList.tsx` |
| Archivos NestJS | kebab-case | `user.service.ts` |

---

## Tipos de commit (Conventional Commits)

```
feat:      nueva funcionalidad
fix:       corrección de bug
docs:      solo documentación
style:     formato sin cambio de lógica
refactor:  refactorización sin nueva funcionalidad
test:      agregar o corregir tests
chore:     mantenimiento, dependencias
ci:        cambios en pipelines de CI/CD
perf:      mejoras de performance
```

**Scope opcional:** `feat(auth): implementar refresh token`

---

## Idioma en el código

| Qué | Idioma | Razón |
|---|---|---|
| Variables, funciones, clases | Inglés | Estándar de industria |
| Comentarios de código | Español | El equipo es hispanohablante |
| Mensajes de error en API | Español | Los ve el usuario final |
| Logs del sistema | Inglés | Herramientas de monitoreo |
| Nombres de tablas y columnas | Inglés | Portabilidad |
| Documentación técnica | Español | Consumida por el equipo |

---

## Formato de respuesta API

> El agente detecta y escribe esta sección al leer el snapshot. No modificar manualmente salvo excepción documentada.

[COMPLETAR — el agente lo llena al inspeccionar los controllers en el snapshot]

Incluir: campos de la respuesta, estructura del objeto de error, campos adicionales (traceId, paginación, etc.)

---

## Arquitectura y patrones detectados

> El agente detecta y escribe esta sección al leer el snapshot.

| Aspecto | Patrón detectado |
|---|---|
| Arquitectura de capas | [COMPLETAR] |
| Patrón de acceso a datos | [COMPLETAR] |
| Manejo de excepciones | [COMPLETAR] |
| Estructura de carpetas por capa | [COMPLETAR] |

---

## Versionado de API

- Prefijo: `/api/v1/`
- Al hacer cambios breaking: incrementar versión `/api/v2/`
- Mantener v1 activa durante período de migración

---

## Manejo de errores HTTP

| Código | Cuándo usarlo |
|---|---|
| 200 | Operación exitosa con datos |
| 201 | Recurso creado exitosamente |
| 204 | Operación exitosa sin datos |
| 400 | Error de validación / datos inválidos |
| 401 | No autenticado (sin token o token inválido) |
| 403 | Autenticado pero sin permisos |
| 404 | Recurso no encontrado |
| 409 | Conflicto (duplicado, estado inválido) |
| 422 | Error de negocio específico |
| 500 | Error interno (no exponer detalles al cliente) |

---

## Excepciones / desviaciones registradas

| Fecha | Módulo | Convención que se rompió | Razón |
|---|---|---|---|
| — | — | — | — |
