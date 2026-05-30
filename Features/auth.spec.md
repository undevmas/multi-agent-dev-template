# Spec Técnica: Autenticación

> **Ejemplo canónico** — Contrato técnico generado desde auth.md por el agente spec.
> El agente de implementación lee este archivo como fuente de verdad técnica.
> No modificar sin pasar por el agente spec o con confirmación explícita del dev.

**Feature:** [auth.md](auth.md)
**Estado:** ready
**Stack involucrado:** .NET 8 (C#) · SQL Server · Angular 17+

---

## Entidades y esquema de datos

### Users — tabla `Users`

**Motor:** SQL Server

| Columna | Tipo | Requerido | Default | Regla de negocio |
|---|---|---|---|---|
| Id | UNIQUEIDENTIFIER | Sí | NEWID() | Clave primaria |
| Email | NVARCHAR(256) | Sí | — | Único, normalizar a lowercase antes de guardar (RN-01) |
| PasswordHash | NVARCHAR(512) | Sí | — | bcrypt con cost factor 12. Nunca retornar en ningún response |
| Role | NVARCHAR(50) | Sí | 'User' | Valores permitidos: 'User', 'Admin', 'SystemAdmin' |
| IsActive | BIT | Sí | 1 | Soft delete — nunca DELETE |
| FailedAttempts | INT | Sí | 0 | Resetear a 0 al login exitoso |
| LockedUntil | DATETIME | No | NULL | NULL = sin bloqueo activo. Verificar contra GETDATE() |
| LastLoginAt | DATETIME | No | NULL | Actualizar en cada login exitoso |
| CreatedAt | DATETIME | Sí | GETDATE() | — |
| UpdatedAt | DATETIME | Sí | GETDATE() | Actualizar en cada PUT/PATCH |

**Índices:**
- `IX_Users_Email` en `Email` (UNIQUE) — búsqueda frecuente en login

---

### RefreshTokens — tabla `RefreshTokens`

| Columna | Tipo | Requerido | Default | Regla de negocio |
|---|---|---|---|---|
| Id | UNIQUEIDENTIFIER | Sí | NEWID() | Clave primaria |
| UserId | UNIQUEIDENTIFIER | Sí | — | FK → Users.Id |
| Token | NVARCHAR(512) | Sí | — | Hash SHA-256 del token real. Único por registro |
| IsUsed | BIT | Sí | 0 | Marcar 1 al usar — nunca reutilizar (RN-05) |
| IsRevoked | BIT | Sí | 0 | Marcar 1 al revocar toda la sesión |
| ExpiresAt | DATETIME | Sí | — | GETDATE() + 7 días al crear |
| CreatedAt | DATETIME | Sí | GETDATE() | — |
| ReplacedByToken | NVARCHAR(512) | No | NULL | Token que lo reemplazó — para auditoría de rotación |

**Relaciones:**
- `RefreshTokens` N:1 `Users` via `UserId` — un usuario puede tener historial de tokens

**Índices:**
- `IX_RefreshTokens_Token` en `Token` (UNIQUE) — búsqueda en cada refresh
- `IX_RefreshTokens_UserId` en `UserId` — para revocar todos los tokens de un usuario

---

### RevokedTokens — tabla `RevokedTokens`

> Lista negra de accessTokens revocados antes de su expiración (logout).

| Columna | Tipo | Requerido | Default | Regla de negocio |
|---|---|---|---|---|
| Id | UNIQUEIDENTIFIER | Sí | NEWID() | Clave primaria |
| TokenHash | NVARCHAR(512) | Sí | — | Hash SHA-256 del accessToken revocado. Único |
| ExpiresAt | DATETIME | Sí | — | Mismo ExpiresAt del JWT original — para limpiar registros vencidos |
| RevokedAt | DATETIME | Sí | GETDATE() | — |

**Índices:**
- `IX_RevokedTokens_TokenHash` en `TokenHash` (UNIQUE) — verificación en cada request

---

## Contratos de API

### POST /api/v1/auth/login

**Propósito:** autenticar usuario con email y password
**Autenticación:** ninguna — endpoint público
**Roles permitidos:** todos (sin guard)
**User Story que cubre:** US-1

**Request body:**
```json
{
  "email": "string — requerido, formato email, max 256 chars",
  "password": "string — requerido, min 8 chars, max 128 chars"
}
```

**Response exitosa (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "string — JWT firmado, expira en 8 horas",
    "tokenType": "Bearer",
    "expiresIn": 28800
  },
  "message": "Sesión iniciada correctamente",
  "errors": []
}
```

**Cookie en response (HttpOnly, Secure, SameSite=Strict):**
```
Set-Cookie: refreshToken=[token]; HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth/refresh; Max-Age=604800
```

**Códigos de error:**

| Código | Condición | Mensaje |
|---|---|---|
| 400 | Email o password ausentes o formato inválido | "El email y la contraseña son requeridos" |
| 401 | Credenciales incorrectas (usuario no existe o password incorrecto) | "Credenciales inválidas" |
| 423 | Cuenta bloqueada (LockedUntil > NOW()) | "Cuenta bloqueada. Intente nuevamente en {N} minutos" |

> **Seguridad:** el mensaje 401 es intencionalmente genérico. No revelar si el email existe o no.

---

### POST /api/v1/auth/refresh

**Propósito:** renovar accessToken usando el refreshToken de la cookie
**Autenticación:** refreshToken en cookie HttpOnly (no requiere Authorization header)
**Roles permitidos:** cualquier usuario con refreshToken válido
**User Story que cubre:** US-2

**Request body:** vacío — el token viene en la cookie

**Response exitosa (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "string — nuevo JWT firmado, expira en 8 horas",
    "tokenType": "Bearer",
    "expiresIn": 28800
  },
  "message": "Sesión renovada correctamente",
  "errors": []
}
```

**Cookie en response:** nuevo refreshToken (el anterior queda marcado como IsUsed=1)

**Códigos de error:**

| Código | Condición | Mensaje |
|---|---|---|
| 401 | Cookie ausente o token no encontrado en BD | "Sesión expirada. Inicie sesión nuevamente" |
| 401 | Token ya usado (IsUsed=1) — posible robo de token | "Sesión inválida. Inicie sesión nuevamente" |
| 401 | Token revocado (IsRevoked=1) | "Sesión inválida. Inicie sesión nuevamente" |
| 401 | Token expirado (ExpiresAt < NOW()) | "Sesión expirada. Inicie sesión nuevamente" |

> **Seguridad:** al detectar reuso (token ya usado), revocar TODOS los RefreshTokens activos del usuario (RN-06).

---

### POST /api/v1/auth/logout

**Propósito:** cerrar sesión activa del usuario
**Autenticación:** JWT Bearer requerido
**Roles permitidos:** cualquier usuario autenticado
**User Story que cubre:** US-3

**Request body:** vacío — el accessToken viene en el header Authorization

**Response exitosa (200):**
```json
{
  "success": true,
  "data": null,
  "message": "Sesión cerrada correctamente",
  "errors": []
}
```

**Cookie en response:** `Set-Cookie: refreshToken=; Max-Age=0` (eliminar cookie)

**Códigos de error:**

| Código | Condición | Mensaje |
|---|---|---|
| 401 | Token ausente, inválido o ya en lista negra | "No autenticado" |

---

## Reglas de negocio precisas

- **RN-01:** El email se normaliza a lowercase en la capa de servicio antes de cualquier operación (búsqueda, guardado, comparación). `"Usuario@Empresa.com"` → `"usuario@empresa.com"`

- **RN-02:** El password nunca se almacena en texto plano. Usar bcrypt con cost factor 12. El hash se genera en la capa de servicio, nunca en el controller ni en el repository.

- **RN-03:** El bloqueo por intentos fallidos (`FailedAttempts >= 5`) aplica a todos los roles **excepto** `SystemAdmin`. Un SystemAdmin nunca queda bloqueado aunque acumule intentos fallidos — sus intentos sí se registran.

- **RN-04:** Al producirse un login exitoso, el campo `FailedAttempts` se resetea a 0 y `LockedUntil` se establece en NULL, independientemente de su valor anterior.

- **RN-05:** Cada refreshToken es de un solo uso. Al usarlo para renovar, marcarlo como `IsUsed=1` y crear un nuevo token (rotación). El campo `ReplacedByToken` del token viejo apunta al hash del token nuevo.

- **RN-06:** Si se detecta reuso de un refreshToken (`IsUsed=1` ya estaba marcado), revocar **todos** los RefreshTokens del usuario (`IsRevoked=1` en todos sus registros activos). Esto indica posible robo de token — forzar re-autenticación completa.

- **RN-07:** El accessToken revocado por logout se agrega a `RevokedTokens` con el mismo `ExpiresAt` del JWT. El guard debe verificar esta tabla en cada request. Limpiar registros con `ExpiresAt < NOW()` en un job periódico (no en el flujo de request).

- **RN-08:** El tiempo de bloqueo es exactamente 15 minutos desde el quinto intento fallido: `LockedUntil = GETDATE() + 15 minutos`. Si el usuario vuelve a intentar estando bloqueado, `LockedUntil` **no** se extiende — solo se informa el tiempo restante.

---

## Validaciones por campo

| Campo | Validaciones | Mensaje de error |
|---|---|---|
| email | Requerido, formato email válido, max 256 chars | "El email es inválido o demasiado largo" |
| password | Requerido, min 8 chars, max 128 chars | "La contraseña debe tener entre 8 y 128 caracteres" |

---

## Interacciones con otros módulos

| Módulo | Tipo de interacción | Cuándo ocurre |
|---|---|---|
| Users (gestión) | Lee | Login — buscar usuario por email y verificar IsActive |
| Todos los módulos | Proporciona | El guard de autenticación verifica el JWT en cada request protegido |

---

## JWT — estructura del payload

```json
{
  "sub": "uuid-del-usuario",
  "email": "usuario@empresa.com",
  "role": "User | Admin | SystemAdmin",
  "iat": 1705000000,
  "exp": 1705028800
}
```

El campo `role` viene del campo `Role` en la tabla `Users` al momento del login.
No actualizar el rol en el token hasta el próximo login — es comportamiento esperado.
