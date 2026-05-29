# Feature: Login y Autenticación

**Estado:** ✅ Base completada | 📋 Mejoras pendientes
**Stack:** Angular · .NET · SQL Server

---

## Descripción
Sistema de autenticación con usuario y contraseña, JWT con refresh token,
control de intentos fallidos y recuperación de contraseña.

---

## Requisitos funcionales

- [x] Login con email y contraseña
- [x] Generación de JWT al autenticar
- [ ] Refresh token automático (renovar sin re-login)
- [ ] Bloqueo por intentos fallidos (máx 5 intentos, bloqueo 15 min)
- [ ] Contador visible de intentos restantes
- [ ] Recuperación de contraseña por email
- [ ] Autenticación con Azure AD (OAuth2) — pendiente decisión

---

## Endpoints

```
POST /api/v1/auth/login
  Body: { email, password }
  Response: { token, refreshToken, expiresIn, user: { id, name, email, roles } }

POST /api/v1/auth/refresh
  Body: { refreshToken }
  Response: { token, refreshToken, expiresIn }

POST /api/v1/auth/logout
  Header: Authorization: Bearer [token]
  Response: { success: true }

POST /api/v1/auth/forgot-password
  Body: { email }
  Response: { success: true, message: "Si el correo existe, recibirás instrucciones" }

POST /api/v1/auth/reset-password
  Body: { token, newPassword, confirmPassword }
  Response: { success: true }
```

---

## Base de datos

```sql
-- SQL Server
Users (
  Id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  Email           NVARCHAR(255) NOT NULL UNIQUE,
  PasswordHash    NVARCHAR(500) NOT NULL,
  FullName        NVARCHAR(200) NOT NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  FailedAttempts  INT NOT NULL DEFAULT 0,
  LockedUntil     DATETIME NULL,
  LastLoginAt     DATETIME NULL,
  CreatedAt       DATETIME NOT NULL DEFAULT GETDATE(),
  UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
)

RefreshTokens (
  Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(Id),
  Token       NVARCHAR(500) NOT NULL UNIQUE,
  ExpiresAt   DATETIME NOT NULL,
  IsRevoked   BIT NOT NULL DEFAULT 0,
  CreatedAt   DATETIME NOT NULL DEFAULT GETDATE()
)
```

---

## Notas técnicas
- Hash de contraseña: BCrypt, salt rounds 12
- JWT expiration: 8 horas
- Refresh token: 30 días, rotación en cada uso (el viejo se invalida)
- Tokens de reset de contraseña: 1 hora de vigencia, uso único
