# Feature: Autenticación

> **Ejemplo canónico** — Este archivo muestra el formato correcto producido por el agente spec.
> Para tu proyecto: reemplazar todo el contenido por la spec real de tu módulo.
> Para generar una spec nueva: `"Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [módulo]"`

**Estado:** ready
**Tipo:** Feature
**Creado:** 2025-01-15
**Última actualización:** 2025-01-15
**Dependencias:** ninguna — este módulo es prerequisito de todos los demás

---

## Qué problema resuelve

El sistema necesita verificar la identidad de cada usuario antes de permitirle
acceder a cualquier recurso. Sin autenticación, cualquier persona puede ver o
modificar datos de otros usuarios o ejecutar acciones sin autorización.

---

## Actores

| Actor | Descripción | Permisos relevantes |
|---|---|---|
| Usuario activo | Cualquier persona con cuenta en el sistema | Puede iniciar sesión, renovar su sesión y cerrarla |
| Usuario bloqueado | Cuenta con demasiados intentos fallidos | No puede iniciar sesión hasta que expire el bloqueo |
| SystemAdmin | Administrador del sistema | Puede iniciar sesión sin restricción de intentos fallidos |

---

## User Stories

### US-1 — Iniciar sesión con credenciales (Prioridad: P1)

Un usuario con cuenta activa ingresa su email y contraseña para obtener acceso al sistema.
Al autenticarse correctamente recibe un token de acceso y un token de refresco.

**Por qué esta prioridad:** sin esto no existe ningún otro flujo del sistema.
**MVP independiente:** sí — entrega valor completo por sí sola.

**Escenarios de aceptación:**

- **Dado** un usuario activo con credenciales válidas, **Cuando** envía POST /api/v1/auth/login con email y password correctos, **Entonces** recibe 200 con accessToken en el body y refreshToken en cookie HttpOnly, y el campo LastLoginAt se actualiza
- **Dado** un usuario activo, **Cuando** envía credenciales con password incorrecto, **Entonces** recibe 401 con mensaje "Credenciales inválidas", el contador FailedAttempts se incrementa en 1
- **Dado** un usuario activo, **Cuando** acumula 5 intentos fallidos consecutivos, **Entonces** recibe 423 con mensaje "Cuenta bloqueada. Intente nuevamente en 15 minutos" y LockedUntil se establece en NOW() + 15 minutos
- **Dado** un usuario con LockedUntil en el futuro, **Cuando** intenta iniciar sesión aunque sea con password correcto, **Entonces** recibe 423 con el tiempo restante de bloqueo en el mensaje
- **Dado** un usuario con LockedUntil ya vencido, **Cuando** intenta iniciar sesión con credenciales correctas, **Entonces** el bloqueo se libera automáticamente y la sesión inicia normalmente

---

### US-2 — Renovar sesión con refresh token (Prioridad: P1)

Un usuario con sesión activa renueva su accessToken sin necesidad de volver a ingresar
sus credenciales, usando el refreshToken almacenado en su navegador.

**Por qué esta prioridad:** sin esto el usuario debe re-autenticarse cada 8 horas,
lo que es inaceptable en una aplicación de uso continuo.
**MVP independiente:** no — depende de US-1 (requiere que exista el refresh token).

**Escenarios de aceptación:**

- **Dado** un usuario con refreshToken válido en cookie, **Cuando** hace POST /api/v1/auth/refresh, **Entonces** recibe 200 con nuevo accessToken y el refreshToken anterior queda invalidado (rotación)
- **Dado** un usuario que intenta usar el mismo refreshToken dos veces, **Cuando** hace el segundo POST /api/v1/auth/refresh, **Entonces** recibe 401 y la sesión completa se revoca por seguridad (detección de reuso)
- **Dado** un usuario con refreshToken expirado (más de 7 días), **Cuando** intenta renovar, **Entonces** recibe 401 con mensaje "Sesión expirada. Inicie sesión nuevamente"

---

### US-3 — Cerrar sesión (Prioridad: P2)

Un usuario cierra su sesión activa de forma explícita, invalidando sus tokens.

**Por qué esta prioridad:** es necesario para cumplir con buenas prácticas de seguridad,
pero no bloquea el funcionamiento del sistema si no está en v1 inmediata.
**MVP independiente:** sí — puede implementarse independientemente de US-2.

**Escenarios de aceptación:**

- **Dado** un usuario autenticado, **Cuando** hace POST /api/v1/auth/logout con su accessToken, **Entonces** recibe 200, el refreshToken en cookie se elimina y el token queda en lista negra hasta su expiración natural
- **Dado** un usuario que ya cerró sesión, **Cuando** intenta usar el accessToken anterior, **Entonces** recibe 401 con mensaje "Sesión inválida"

---

## Edge Cases

- ¿Qué pasa si el email tiene mayúsculas? → se normaliza a lowercase antes de comparar (RN-01)
- ¿Qué pasa si el sistema reinicia durante un bloqueo? → LockedUntil persiste en BD, el bloqueo se mantiene
- ¿Qué pasa si dos peticiones de refresh llegan simultáneamente con el mismo token? → solo la primera tiene éxito; la segunda recibe 401 y se revoca la sesión
- ¿Qué pasa si un SystemAdmin acumula 5 intentos fallidos? → se registran pero no se bloquea la cuenta (RN-03)

---

## Criterios de éxito

- **CE-01:** Un usuario con credenciales válidas completa el login en menos de 2 segundos en condiciones normales de red
- **CE-02:** Ningún password se almacena en texto plano ni aparece en logs del sistema
- **CE-03:** Un refreshToken usado más de una vez revoca la sesión completa en menos de 500ms
- **CE-04:** El bloqueo por intentos persiste entre reinicios del servidor

---

## Supuestos

- Se asume que el email es el identificador único de cada usuario — no el nombre de usuario
- Se asume que la gestión de usuarios (crear, editar, roles) es un módulo separado; este módulo solo autentica
- Se asume stack .NET para el backend de este ejemplo

---

## Fuera de scope (v1)

- Login con Google / OAuth2 — se especificará en auth-oauth.md
- Autenticación de dos factores (2FA) — backlog
- Sesiones múltiples por usuario — en v1 un refresh token activo por usuario
