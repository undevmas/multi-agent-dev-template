# SKILL — OWASP Security Checklist (Multi-Stack)

## Cuándo usar esta skill
Como revisión final antes de subir a staging o producción.
Al implementar cualquier feature que maneje autenticación, datos de usuarios, archivos o pagos.
Como punto de entrada para auditorías de seguridad.
Para determinar qué skill específica leer según la tecnología involucrada.

Para implementaciones detalladas, ir a la skill correspondiente:
- Angular → SKILL-security-angular.md
- .NET 8  → SKILL-security-dotnet.md
- NestJS  → SKILL-security-nestjs.md

---

## Mapa de skills por tecnología y riesgo

| Situación | Skill a leer |
|---|---|
| Crear guard o interceptor en Angular | SKILL-security-angular.md |
| Usar [innerHTML] o bypassSecurityTrust* | SKILL-security-angular.md |
| Crear endpoint en .NET | SKILL-security-dotnet.md |
| Autenticación o JWT en .NET | SKILL-security-dotnet.md |
| Crear endpoint en NestJS | SKILL-security-nestjs.md |
| Autenticación o JWT en NestJS | SKILL-security-nestjs.md |
| Subir archivos (cualquier stack) | skill del stack correspondiente |
| Revisión antes de producción | Este archivo (checklist completo) |

---

## OWASP Top 10 — 2021 aplicado al proyecto

### A01 — Broken Access Control ⚠️ El más crítico

Concepto universal: verificar que el usuario puede hacer lo que intenta.

```
Principios:
- Autenticación ≠ Autorización
  Autenticado = el usuario es quien dice ser
  Autorizado   = el usuario puede hacer lo que intenta

- Verificar pertenencia del recurso en CADA operación
  No basta con que el usuario esté autenticado
  Verificar que el recurso le pertenece O tiene rol suficiente

- Denegar por defecto
  Si no se puede verificar el acceso, denegar
  Usar el mismo mensaje para "no existe" y "no tienes acceso"
  (evitar revelar si el recurso existe)

- IDs no predecibles
  Usar UUID en lugar de IDs secuenciales
  Los IDs secuenciales permiten enumerar recursos fácilmente
```

Checklist A01:
```
Angular
  [ ] Rutas protegidas con AuthGuard
  [ ] Roles verificados con RoleGuard + data.roles
  [ ] UI oculta por rol con directiva HasRole
      (recordar: ocultar UI es solo UX, no seguridad)

.NET
  [ ] [Authorize] en todos los controllers/acciones que lo requieren
  [ ] Pertenencia verificada en el service (no solo en controller)
  [ ] Endpoints públicos documentados explícitamente

NestJS
  [ ] JwtAuthGuard global activo
  [ ] @Public() solo en endpoints que realmente son públicos
  [ ] RolesGuard con @Roles() donde aplica
  [ ] Pertenencia verificada en el service

Todos los stacks
  [ ] IDs como UUID (no int/bigint secuencial)
  [ ] Mensaje genérico al denegar acceso (no revelar existencia)
```

---

### A02 — Cryptographic Failures

Concepto universal: proteger datos en tránsito y en reposo.

```
Principios:
- HTTPS obligatorio en producción (nunca HTTP para datos sensibles)
- Contraseñas con algoritmo de hash diseñado para eso (bcrypt, Argon2)
  NO usar: MD5, SHA1, SHA256 sin salt — son rápidos, por eso inseguros para contraseñas
- Secretos fuera del código fuente
- JWT con expiración corta y secreto fuerte
```

Checklist A02:
```
Angular
  [ ] Sin secretos ni API keys en environment.ts (son públicos en el bundle)
  [ ] Tokens en memoria o sessionStorage (no localStorage)
  [ ] HTTPS configurado en el servidor/CDN de producción

.NET
  [ ] BCrypt con work factor >= 12
  [ ] Secreto JWT >= 32 caracteres en variables de entorno
  [ ] HSTS configurado (Strict-Transport-Security)
  [ ] ConnectionString en variables de entorno (no en appsettings.json commiteado)

NestJS
  [ ] BCrypt con salt rounds >= 12
  [ ] JWT_SECRET >= 32 caracteres en .env (no hardcodeado)
  [ ] Refresh token generado con randomBytes (no Math.random())
  [ ] Variables de entorno validadas con Joi al inicio

Todos los stacks
  [ ] .gitignore incluye archivos con secretos (.env, appsettings.Development.json)
  [ ] Sin credenciales en el historial de git
```

---

### A03 — Injection

Concepto universal: nunca mezclar datos del usuario con instrucciones.

```
Principios:
- SQL Injection: siempre usar ORM o parámetros preparados
- XSS: escapar output, sanitizar HTML si es necesario
- Command Injection: nunca ejecutar comandos del sistema con input del usuario
```

Checklist A03:
```
Angular
  [ ] Sin [innerHTML] con datos del usuario sin DOMPurify primero
  [ ] Sin bypassSecurityTrust* sin sanitizar antes
  [ ] URLs dinámicas validadas (solo http/https)

.NET
  [ ] Sin concatenación en raw SQL (usar FromSqlInterpolated o parámetros)
  [ ] EF Core usado correctamente en todas las queries

NestJS
  [ ] Sin concatenación en raw queries TypeORM
  [ ] QueryBuilder siempre con parámetros nombrados (:param)
  [ ] Sanitización de HTML en campos de texto libre (sanitize-html o DOMPurify)

Todos los stacks
  [ ] ValidationPipe / FluentValidation activos
  [ ] Todos los DTOs de entrada tienen validaciones
  [ ] Sin ejecución de comandos del sistema con input del usuario
```

---

### A04 — Insecure Design

Concepto universal: seguridad desde el diseño, no como parche.

```
Principios:
- Mínimo privilegio: cada componente tiene solo los permisos que necesita
- Defense in depth: múltiples capas de validación (frontend + backend + BD)
- Fail securely: en caso de duda, denegar
- Separación de responsabilidades: auth separado de lógica de negocio
```

Checklist A04:
```
Todos los stacks
  [ ] JWT payload mínimo (sin datos sensibles innecesarios)
  [ ] Validación en frontend Y en backend (nunca solo en uno)
  [ ] Roles con permisos mínimos necesarios (no "admin para todo")
  [ ] Flujos de autenticación no revelan información
      (mismo mensaje para "usuario no existe" y "contraseña incorrecta")
```

---

### A05 — Security Misconfiguration

Concepto universal: la configuración por defecto no es segura.

```
Principios:
- Headers de seguridad configurados explícitamente
- CORS solo con orígenes específicos
- Variables de entorno validadas al inicio
- Rate limiting en endpoints sensibles
```

Checklist A05:
```
Angular
  [ ] CSP configurado en el servidor (no solo meta tag)
  [ ] HttpClientXsrfModule habilitado

.NET
  [ ] Helmet equivalente (headers manuales en middleware)
  [ ] CORS con WithOrigins específicos (no AllowAnyOrigin)
  [ ] Rate limiting con [EnableRateLimiting] en auth endpoints
  [ ] Variables de entorno verificadas al inicio de la app

NestJS
  [ ] Helmet instalado y activo
  [ ] CORS con origins específicos
  [ ] ThrottlerGuard global activo
  [ ] Variables de entorno validadas con Joi

Todos los stacks
  [ ] Sin Swagger expuesto en producción (o protegido con auth)
  [ ] Sin stack traces en respuestas HTTP
  [ ] Sin modo debug activo en producción
```

---

### A06 — Vulnerable and Outdated Components

Checklist A06:
```
Todos los stacks
  [ ] npm audit / dotnet list package --vulnerable sin issues críticos/altos
  [ ] Dependencias actualizadas (npm outdated / dotnet outdated)
  [ ] Política de actualización documentada en IA_Memoria/

Ejecutar antes de cada release:
  npm audit --audit-level=high   (NestJS/Angular)
  dotnet list package --vulnerable  (.NET)
```

---

### A07 — Identification and Authentication Failures

Checklist A07:
```
Angular
  [ ] Token expirado maneja refresh automático o logout
  [ ] Sin tokens en localStorage

.NET
  [ ] Rate limiting en /login con [EnableRateLimiting]
  [ ] Bloqueo tras 5 intentos fallidos (15 min mínimo)
  [ ] Refresh token con rotación y revocación
  [ ] JWT con ClockSkew = TimeSpan.Zero

NestJS
  [ ] @Throttle en endpoints de auth
  [ ] Bloqueo tras 5 intentos fallidos
  [ ] Refresh token con rotación
  [ ] JwtStrategy con ignoreExpiration: false

Todos los stacks
  [ ] Logout invalida tokens (blacklist o revocación en BD)
  [ ] Contraseñas con bcrypt (rounds >= 12 / work factor >= 12)
  [ ] Reset de contraseña con token de un solo uso
```

---

### A08 — Software and Data Integrity Failures

Checklist A08:
```
Todos los stacks
  [ ] Webhooks verifican firma HMAC antes de procesar
  [ ] Archivos subidos validados por contenido (no solo extensión)
  [ ] Deserialización con validación estricta (no aceptar tipos arbitrarios)
  [ ] Dependencias de terceros con integridad verificada (lockfiles commiteados)
      package-lock.json o yarn.lock en Angular/NestJS
      packages.lock.json en .NET
```

---

### A09 — Security Logging and Monitoring Failures

Eventos que SIEMPRE deben loggearse en todos los stacks:
```
LOGIN_SUCCESS         → userId, ip, timestamp
LOGIN_FAILURE         → email (no password), ip, intentos restantes
ACCOUNT_LOCKED        → userId, ip
PASSWORD_CHANGED      → userId
PASSWORD_RESET        → userId
PERMISSION_DENIED     → userId, recurso, acción
TOKEN_EXPIRED         → userId
SUSPICIOUS_ACTIVITY   → userId, detalle
USER_CREATED          → userId, createdBy
USER_DELETED          → userId, deletedBy
ROLE_CHANGED          → userId, oldRole, newRole
DATA_EXPORT           → userId, exportType
```

Lo que NUNCA debe aparecer en logs:
```
❌ Contraseñas (en ninguna forma)
❌ Tokens completos (JWT, refresh tokens)
❌ Números de tarjeta o datos financieros
❌ Stack traces en respuestas HTTP (solo en logs internos)
❌ Datos personales sensibles (CURP, RFC, datos médicos)
```

Checklist A09:
```
Todos los stacks
  [ ] Eventos de seguridad loggeados en todos los stacks
  [ ] Logs sin datos sensibles
  [ ] Stack traces solo en logs del servidor, nunca en respuestas
  [ ] Retención de logs configurada (mínimo 30 días)
```

---

### A10 — Server-Side Request Forgery (SSRF)

Checklist A10:
```
.NET y NestJS (aplica cuando el backend hace requests HTTP)
  [ ] URLs externas validadas con lista blanca de dominios permitidos
  [ ] Solo HTTPS permitido para URLs externas
  [ ] IPs privadas y localhost bloqueados si se hacen fetch externos
  [ ] Sin seguir redirects automáticamente en requests externos
```

---

## Checklist de revisión rápida pre-producción

Ejecutar en este orden:

```
1. Análisis de dependencias
   npm audit --audit-level=high
   dotnet list package --vulnerable

2. Variables de entorno
   Verificar que TODOS los secretos están en variables de entorno
   Verificar que .env y appsettings.Development.json están en .gitignore

3. Endpoints públicos
   Listar todos los endpoints sin autenticación
   Verificar que cada uno debe ser público

4. Rate limiting
   Verificar que /login, /register, /forgot-password tienen throttling

5. Logs de seguridad
   Verificar que login exitoso y fallido se loggean
   Verificar que no hay datos sensibles en los logs

6. Headers HTTP
   Verificar X-Frame-Options, CSP, HSTS en producción

7. CORS
   Verificar que AllowedOrigins no es wildcard (*)

8. Archivos subidos
   Verificar validación de tipo y tamaño
   Verificar que los nombres son generados internamente (UUID)
```

---

## Niveles de severidad para priorizar

```
CRÍTICO — bloquear deploy
  Credenciales en código fuente
  SQL injection confirmado
  Endpoint sin autenticación que debería tenerlo
  Contraseñas en texto plano o MD5/SHA1

ALTO — corregir antes de producción
  Sin rate limiting en login
  CORS con wildcard (*)
  JWT sin expiración
  Sin bloqueo por intentos fallidos
  Stack traces expuestos en respuestas

MEDIO — corregir en el sprint
  Sin headers de seguridad (Helmet/CSP)
  Tokens en localStorage
  Sin logs de eventos de seguridad
  Validación solo en frontend

BAJO — registrar en Issues y planificar
  Dependencias desactualizadas (sin CVE conocido)
  Mensajes de error muy descriptivos
  Sin retención de logs configurada
```
