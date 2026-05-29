# SKILL — OWASP Compliance

## Cuándo usar esta skill
Al revisar código antes de ir a producción.
Al implementar cualquier feature que maneje datos de usuarios,
autenticación, pagos, archivos, o información sensible.
Al hacer auditoría de seguridad del proyecto.

Esta skill cubre el OWASP Top 10 (2021) aplicado al stack
Angular / .NET 8 / NestJS / SQL Server / PostgreSQL.

---

## OWASP Top 10 — 2021

### A01 — Broken Access Control

El más crítico según OWASP. Ocurre cuando usuarios pueden
actuar fuera de sus permisos.

Verificar en cada endpoint:
```typescript
// Checklist A01
// [ ] El endpoint requiere autenticación
// [ ] Se verifica que el recurso pertenece al usuario autenticado
// [ ] Los roles requeridos están definidos y verificados
// [ ] No se exponen recursos de otros usuarios en listados

// Patrón correcto — siempre verificar pertenencia
async getContract(contractId: string, requestingUserId: string): Promise<Contract> {
  const contract = await this.contractsRepository.findById(contractId);

  if (!contract) {
    throw new NotFoundException('Contrato no encontrado');
  }

  // Verificar pertenencia — no solo autenticación
  const hasAccess = contract.ownerId === requestingUserId ||
    await this.userHasRole(requestingUserId, UserRole.Admin);

  if (!hasAccess) {
    // No revelar que el recurso existe — mismo error que "not found"
    throw new NotFoundException('Contrato no encontrado');
  }

  return contract;
}

// IDOR prevention — nunca confiar en IDs del cliente para determinar acceso
// MAL: asumir que si el usuario envió el ID, tiene acceso
// BIEN: siempre consultar la BD y verificar pertenencia
```

Configuración de headers de seguridad:
```typescript
// Prevenir clickjacking (X-Frame-Options)
app.use(helmet({
  frameguard: { action: 'deny' },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
}));
```

---

### A02 — Cryptographic Failures

Proteger datos en tránsito y en reposo.

```typescript
// Contraseñas — bcrypt obligatorio
// MAL: MD5, SHA1, SHA256 sin salt son inseguros para contraseñas
// BIEN:
const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(inputPassword, storedHash);

// Tokens sensibles — generar con crypto
import { randomBytes } from 'crypto';

// Token de reset de contraseña
const resetToken = randomBytes(32).toString('hex');
const hashedToken = createHash('sha256').update(resetToken).digest('hex');
// Guardar hashedToken en BD, enviar resetToken al usuario

// Datos sensibles en BD — considerar encriptación a nivel de campo
// para datos como número de documento, CURP, información médica
// Usar AES-256-GCM para encriptación simétrica

// TLS — solo HTTPS en producción
// Configurar en Azure App Service o en el servidor
// Nunca deshabilitar verificación de certificados
// MAL:
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'; // NUNCA en producción

// Secretos — nunca en código fuente
// MAL:
const apiKey = 'sk-1234567890abcdef';
// BIEN: variables de entorno, Azure Key Vault
const apiKey = process.env.EXTERNAL_API_KEY;
```

---

### A03 — Injection

```typescript
// SQL Injection — ya cubierto en SKILL-checkmarx.md
// Regla principal: NUNCA concatenar input del usuario en queries

// XSS — Cross-Site Scripting
// En Angular: Angular escapa automáticamente el HTML en templates
// Nunca usar [innerHTML] con datos del usuario sin sanitizar
// MAL en Angular:
// <div [innerHTML]="userContent"></div>
// BIEN en Angular (si es necesario HTML):
// <div [innerHTML]="sanitizer.bypassSecurityTrustHtml(safeContent)"></div>
// donde safeContent ya fue sanitizado con DOMPurify

// Template Injection — NestJS
// MAL: usar templates con input del usuario sin sanitizar
const template = `Hola ${userInput}, tu código es...`; // si userInput tiene ${}, se evalúa
// BIEN: usar librerías de templating seguras o escapar el input

// Header Injection
// MAL: construir headers HTTP con input del usuario
res.setHeader('Location', userProvidedUrl); // riesgo de header injection
// BIEN: validar y sanitizar URLs
const safeUrl = new URL(userProvidedUrl); // lanza error si no es URL válida
if (!['https:', 'http:'].includes(safeUrl.protocol)) {
  throw new BadRequestException('URL no válida');
}
```

---

### A04 — Insecure Design

Principios de diseño seguro a aplicar desde el inicio:

```
Principio de mínimo privilegio:
  - Cada rol tiene solo los permisos que necesita
  - Los tokens JWT solo contienen lo necesario (no datos sensibles)
  - Las conexiones a BD usan usuarios con permisos mínimos

Defense in depth:
  - Validar en frontend Y en backend (nunca solo en uno)
  - Autenticación + Autorización (no solo autenticación)
  - Rate limiting + Bloqueo por intentos + CAPTCHA

Fail securely:
  - En caso de error, denegar acceso por defecto
  - No exponer información de debug en producción
  - Logs de seguridad para auditoría

Separación de privilegios:
  - Admin no puede hacer operaciones de usuario regular directamente
  - Separar operaciones de lectura y escritura a nivel de rol
```

```typescript
// Diseño seguro — JWT payload mínimo
// MAL: incluir datos sensibles o innecesarios en el token
const payload = {
  sub: user.id,
  email: user.email,
  password: user.passwordHash, // NUNCA
  creditCard: user.creditCard, // NUNCA
  internalScore: user.riskScore, // innecesario
  role: user.role,
};

// BIEN: solo lo necesario para autenticación y autorización
const payload: JwtPayload = {
  sub: user.id,
  email: user.email,
  role: user.role,
  iat: Date.now(),
};
```

---

### A05 — Security Misconfiguration

```typescript
// Variables de entorno — todas las que afectan seguridad
// Verificar al inicio de la aplicación
const requiredEnvVars = [
  'JWT_SECRET',
  'DB_PASSWORD',
  'ALLOWED_ORIGINS',
  'NODE_ENV',
];

requiredEnvVars.forEach(varName => {
  if (!process.env[varName]) {
    throw new Error(`Variable de entorno requerida no configurada: ${varName}`);
  }
});

// Deshabilitar características peligrosas en producción
if (process.env.NODE_ENV === 'production') {
  // Deshabilitar Swagger en producción (o proteger con auth)
  // No exponer /health con información detallada
  // No mostrar stack traces
}

// Headers de seguridad — helmet cubre la mayoría
app.use(helmet());
// Incluye automáticamente:
// X-Content-Type-Options: nosniff
// X-Frame-Options: SAMEORIGIN
// X-XSS-Protection: 0 (deshabilitado, usar CSP en su lugar)
// Strict-Transport-Security (HSTS)
// Content-Security-Policy
```

---

### A06 — Vulnerable and Outdated Components

```bash
# Ejecutar semanalmente o en cada PR importante
npm audit

# Verificar paquetes desactualizados
npm outdated

# Actualizar dependencias con vulnerabilidades conocidas
npm audit fix

# Para vulnerabilidades que requieren breaking changes
npm audit fix --force  # revisar manualmente después

# Verificar licencias (importante en proyectos empresariales)
npx license-checker --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC'
```

Política de actualizaciones:
```
Vulnerabilidades críticas (CVSS >= 9.0): corregir en 24 horas
Vulnerabilidades altas (CVSS 7.0-8.9):  corregir en 7 días
Vulnerabilidades medias (CVSS 4.0-6.9): corregir en 30 días
Vulnerabilidades bajas (CVSS < 4.0):    corregir en próximo sprint
```

---

### A07 — Identification and Authentication Failures

```typescript
// Implementación completa de autenticación segura

// 1. Rate limiting en login
@Post('login')
@Throttle({ default: { limit: 5, ttl: 60 * 1000 } }) // 5 intentos/minuto
async login(@Body() dto: LoginDto): Promise<AuthResponseDto> {
  return this.authService.login(dto);
}

// 2. Bloqueo por intentos fallidos
async validateUser(email: string, password: string): Promise<User> {
  const user = await this.usersRepository.findByEmail(email);

  // Mensaje genérico — no revelar si el email existe
  if (!user) throw new UnauthorizedException('Credenciales inválidas');

  // Verificar bloqueo
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    const minutesLeft = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
    throw new UnauthorizedException(`Cuenta bloqueada. Intenta en ${minutesLeft} minutos`);
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);

  if (!isValid) {
    await this.handleFailedAttempt(user);
    throw new UnauthorizedException('Credenciales inválidas');
  }

  // Reset contador de intentos fallidos
  await this.usersRepository.resetFailedAttempts(user.id);
  return user;
}

private async handleFailedAttempt(user: User): Promise<void> {
  const MAX_ATTEMPTS = 5;
  const LOCK_DURATION_MINUTES = 15;

  const newAttempts = user.failedAttempts + 1;

  if (newAttempts >= MAX_ATTEMPTS) {
    const lockedUntil = new Date(Date.now() + LOCK_DURATION_MINUTES * 60 * 1000);
    await this.usersRepository.lockUser(user.id, lockedUntil);
  } else {
    await this.usersRepository.incrementFailedAttempts(user.id);
  }
}

// 3. Refresh token con rotación
async refreshToken(refreshToken: string): Promise<AuthResponseDto> {
  const tokenRecord = await this.refreshTokensRepository.findValid(refreshToken);
  if (!tokenRecord) throw new UnauthorizedException('Token inválido');

  // Rotación: invalidar el token usado, emitir uno nuevo
  await this.refreshTokensRepository.revoke(tokenRecord.id);

  const user = await this.usersRepository.findById(tokenRecord.userId);
  return this.generateTokens(user);
}

// 4. Logout — invalidar tokens
async logout(userId: string, accessToken: string): Promise<void> {
  // Agregar access token a blacklist (Redis recomendado)
  await this.tokenBlacklist.add(accessToken, this.getTokenExpiry(accessToken));
  // Revocar todos los refresh tokens del usuario
  await this.refreshTokensRepository.revokeAllByUser(userId);
}
```

---

### A08 — Software and Data Integrity Failures

```typescript
// Verificar integridad de datos recibidos
// Webhooks — validar firma
app.post('/webhooks/payment', (req, res) => {
  const signature = req.headers['x-signature'];
  const expectedSignature = createHmac('sha256', process.env.WEBHOOK_SECRET)
    .update(JSON.stringify(req.body))
    .digest('hex');

  if (signature !== expectedSignature) {
    return res.status(401).send('Firma inválida');
  }
  // procesar webhook
});

// Deserialización — validar antes de procesar
// NUNCA deserializar datos del usuario sin validar
// Usar class-validator con ValidationPipe (ya configurado)

// Integridad de archivos subidos
async validateFileIntegrity(file: Express.Multer.File): Promise<void> {
  // Verificar que el contenido coincide con el MIME type declarado
  // (un atacante puede cambiar la extensión)
  const fileType = await fromBuffer(file.buffer);
  if (!fileType || fileType.mime !== file.mimetype) {
    throw new BadRequestException('El tipo de archivo no coincide con su contenido');
  }
}
```

---

### A09 — Security Logging and Monitoring Failures

```typescript
// Eventos de seguridad que SIEMPRE deben loggearse
const SECURITY_EVENTS = [
  'LOGIN_SUCCESS',
  'LOGIN_FAILURE',
  'LOGIN_BLOCKED',
  'PASSWORD_RESET_REQUEST',
  'PASSWORD_CHANGED',
  'PERMISSION_DENIED',
  'TOKEN_EXPIRED',
  'SUSPICIOUS_ACTIVITY',
  'USER_CREATED',
  'USER_DELETED',
  'ROLE_CHANGED',
  'DATA_EXPORT',
];

@Injectable()
export class SecurityAuditService {
  constructor(private readonly logger: Logger) {}

  log(event: string, userId: string, details: Record<string, unknown> = {}): void {
    this.logger.log({
      event,
      userId,
      timestamp: new Date().toISOString(),
      ip: details.ip,
      userAgent: details.userAgent,
      ...details,
      // NUNCA incluir: password, token, secreto
    });
  }
}

// Uso en AuthService
async login(dto: LoginDto, ip: string, userAgent: string): Promise<AuthResponseDto> {
  try {
    const user = await this.validateUser(dto.email, dto.password);
    this.securityAudit.log('LOGIN_SUCCESS', user.id, { ip, userAgent });
    return this.generateTokens(user);
  } catch (error) {
    this.securityAudit.log('LOGIN_FAILURE', 'unknown', {
      email: dto.email, // email sí (para detectar ataques), password NUNCA
      ip,
      userAgent,
      reason: error.message,
    });
    throw error;
  }
}
```

---

### A10 — Server-Side Request Forgery (SSRF)

```typescript
// SSRF — cuando el servidor hace requests HTTP con URLs del usuario

// MAL — hacer fetch directo con URL del usuario
async fetchExternalContent(url: string): Promise<string> {
  const response = await fetch(url); // puede apuntar a servicios internos
  return response.text();
}

// BIEN — validar URL antes de hacer el request
async fetchExternalContent(url: string): Promise<string> {
  const parsedUrl = new URL(url);

  // Solo HTTPS
  if (parsedUrl.protocol !== 'https:') {
    throw new BadRequestException('Solo se permiten URLs HTTPS');
  }

  // Lista blanca de dominios permitidos
  const allowedDomains = process.env.ALLOWED_EXTERNAL_DOMAINS?.split(',') || [];
  if (!allowedDomains.includes(parsedUrl.hostname)) {
    throw new BadRequestException('Dominio no permitido');
  }

  // Bloquear IPs privadas y localhost
  const blockedPatterns = [
    /^localhost$/i,
    /^127\.\d+\.\d+\.\d+$/,
    /^10\.\d+\.\d+\.\d+$/,
    /^192\.168\.\d+\.\d+$/,
    /^172\.(1[6-9]|2\d|3[01])\.\d+\.\d+$/,
    /^::1$/,
    /^0\.0\.0\.0$/,
  ];

  if (blockedPatterns.some(p => p.test(parsedUrl.hostname))) {
    throw new BadRequestException('URL no permitida');
  }

  const response = await fetch(url, { redirect: 'error' }); // no seguir redirects
  return response.text();
}
```

---

## Checklist OWASP completo antes de producción

```
A01 Broken Access Control
  [ ] Todos los endpoints tienen autenticación o @Public() explícito
  [ ] Se verifica pertenencia de recursos al usuario autenticado
  [ ] Roles implementados y verificados con guards
  [ ] IDs como UUID (no secuenciales)

A02 Cryptographic Failures
  [ ] HTTPS obligatorio en producción
  [ ] Contraseñas con bcrypt (rounds >= 12)
  [ ] Secretos en variables de entorno (no en código)
  [ ] JWT con expiración y secreto fuerte (>= 32 caracteres)

A03 Injection
  [ ] Sin concatenación en queries SQL (usar ORM/parámetros)
  [ ] Input sanitizado donde se renderiza HTML
  [ ] Validación de DTOs con ValidationPipe (whitelist: true)

A04 Insecure Design
  [ ] JWT payload mínimo (sin datos sensibles)
  [ ] Principio de mínimo privilegio en roles
  [ ] Validación tanto en frontend como en backend

A05 Security Misconfiguration
  [ ] Helmet instalado y activo
  [ ] CORS configurado con origins específicos
  [ ] Variables de entorno validadas al inicio
  [ ] Rate limiting en endpoints sensibles

A06 Vulnerable Components
  [ ] npm audit sin vulnerabilidades altas/críticas
  [ ] Dependencias actualizadas

A07 Auth Failures
  [ ] Rate limiting en login (5 intentos/minuto)
  [ ] Bloqueo por intentos fallidos (5 intentos -> 15 min)
  [ ] Refresh token con rotación
  [ ] Logout invalida tokens

A08 Data Integrity
  [ ] Webhooks con verificación de firma HMAC
  [ ] Archivos validados por contenido (no solo extensión)

A09 Logging
  [ ] Eventos de seguridad loggeados (login, permisos denegados, etc.)
  [ ] Sin datos sensibles en logs (no passwords, no tokens)
  [ ] Stack traces solo en logs internos (no en respuestas)

A10 SSRF
  [ ] URLs externas validadas con lista blanca de dominios
  [ ] IPs privadas bloqueadas si se hacen requests externos
```
