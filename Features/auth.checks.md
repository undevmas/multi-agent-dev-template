# Checks de Verificación: Autenticación

> **Ejemplo canónico** — Lista de verificación que el agente de implementación completa
> antes de marcar la feature como `in-review`. Cada check es verificable inspeccionando
> el código — no requiere ejecutar el sistema.
>
> Checks marcados con `[LEGADO]` solo aplican si el módulo es nuevo.
> Si hay código previo que no los cumple, registrar en `IA_Memoria/deuda-tecnica.md`
> y continuar — no bloquear la implementación nueva por deuda existente.

**Feature:** [auth.md](auth.md)
**Spec:** [auth.spec.md](auth.spec.md)
**Aplica sobre:** código nuevo generado en esta implementación

---

## Checks de estructura

- [ ] Existe `AuthController` con los 3 endpoints declarados en spec: `/login`, `/refresh`, `/logout`
- [ ] Existe `AuthService` con la lógica de negocio — ninguna regla de negocio en el controller
- [ ] Existe `IAuthService` como interfaz — el controller depende de la interfaz, no de la implementación
- [ ] Existe `AuthRepository` o equivalente — ningún query directo a BD en el Service
- [ ] Los DTOs de request y response existen como clases separadas (`LoginRequest`, `LoginResponse`, `RefreshResponse`)
- [ ] Las entidades `User`, `RefreshToken`, `RevokedToken` tienen su clase de entidad correspondiente
- [ ] Los archivos de migración existen para las 3 tablas: `Users`, `RefreshTokens`, `RevokedTokens`

---

## Checks de seguridad

- [ ] El endpoint `/login` no tiene guard — es público
- [ ] Los endpoints `/refresh` y `/logout` están protegidos o procesan tokens manualmente según spec
- [ ] `PasswordHash` nunca aparece en ningún DTO de response ni en logs
- [ ] El accessToken viaja solo en el body del response — nunca en cookies
- [ ] El refreshToken viaja solo en cookie `HttpOnly; Secure; SameSite=Strict` — nunca en el body
- [ ] La cookie del refreshToken tiene `Path=/api/v1/auth/refresh` — scope mínimo
- [ ] El JWT se firma con clave desde variable de entorno — no hardcodeada en código
- [ ] La clave JWT no aparece en ningún archivo del repositorio

---

## Checks de convenciones del proyecto

- [ ] [LEGADO] IDs son `UNIQUEIDENTIFIER` con `NEWID()` — no int secuencial
- [ ] [LEGADO] Soft delete en `Users`: campo `IsActive BIT DEFAULT 1` — no hay `DELETE FROM Users`
- [ ] Los 3 endpoints retornan `{ success, data, message, errors }` exactamente
- [ ] Código en inglés (clases, métodos, variables, columnas), mensajes al usuario en español
- [ ] Migraciones versionadas con timestamp — no modifican tablas ya aplicadas

---

## Checks de reglas de negocio

- [ ] **RN-01** — Email normalizado a lowercase: existe llamada a `.ToLower()` o `.ToLowerInvariant()` en el Service antes de buscar en BD y antes de guardar
- [ ] **RN-02** — bcrypt con cost factor 12: la librería usada es BCrypt.Net o equivalente, y el cost factor es exactamente 12 (no el default)
- [ ] **RN-03** — SystemAdmin no se bloquea: existe condición explícita `if (user.Role != "SystemAdmin")` antes de aplicar bloqueo
- [ ] **RN-04** — Reset al login exitoso: tras autenticación exitosa, `FailedAttempts = 0` y `LockedUntil = null` se persisten
- [ ] **RN-05** — Rotación de refresh token: al usar un token, se marca `IsUsed = true` Y se crea un nuevo token antes de retornar el response
- [ ] **RN-06** — Revocación total por reuso: al detectar `IsUsed == true`, existe query que marca `IsRevoked = true` en TODOS los RefreshTokens del usuario (no solo el actual)
- [ ] **RN-07** — Lista negra de accessTokens: el logout inserta en `RevokedTokens` y el guard verifica esa tabla
- [ ] **RN-08** — Bloqueo no se extiende: en el flujo de login con cuenta bloqueada, NO hay actualización de `LockedUntil` — solo se lee y se calcula el tiempo restante

---

## Checks de User Stories

- [ ] **US-1 — Escenario exitoso:** login con credenciales válidas retorna 200 con accessToken en body y refreshToken en cookie
- [ ] **US-1 — Escenario password incorrecto:** retorna 401 con mensaje genérico "Credenciales inválidas" y FailedAttempts se incrementa
- [ ] **US-1 — Escenario 5to intento fallido:** retorna 423 con mensaje de bloqueo y LockedUntil = NOW() + 15 minutos
- [ ] **US-1 — Escenario cuenta bloqueada:** retorna 423 con tiempo restante aunque el password sea correcto
- [ ] **US-1 — Escenario bloqueo expirado:** LockedUntil vencido + credenciales correctas = login exitoso + LockedUntil = NULL
- [ ] **US-2 — Escenario refresh exitoso:** nuevo accessToken en body, cookie actualizada, token anterior marcado IsUsed=1
- [ ] **US-2 — Escenario reuso de refresh:** retorna 401 y TODOS los RefreshTokens del usuario quedan IsRevoked=1
- [ ] **US-2 — Escenario token expirado:** retorna 401 con "Sesión expirada. Inicie sesión nuevamente"
- [ ] **US-3 — Escenario logout exitoso:** retorna 200, cookie eliminada (Max-Age=0), accessToken en RevokedTokens
- [ ] **US-3 — Escenario token ya revocado:** retorna 401

---

## Checks de integración

- [ ] El guard de autenticación verifica `RevokedTokens` además de la firma del JWT
- [ ] El guard extrae `userId` y `role` del payload del JWT y los inyecta en el contexto del request
- [ ] No hay dependencias circulares entre `AuthModule` y otros módulos del sistema

---

## Reporte al finalizar

> El agente de implementación completa este bloque antes de marcar `in-review`.

```
Checks completados: [ ]/[ ]
Checks fallidos: [ ninguno / lista con descripción ]
Checks [LEGADO] no aplicables: [ lista / ninguno ]
Deuda registrada en deuda-tecnica.md: [ no / sí — describir entradas ]
Defaults usados por [NEEDS CLARIFICATION]: [ ninguno / lista ]
Listo para revisión del dev: [ sí / no ]
```
