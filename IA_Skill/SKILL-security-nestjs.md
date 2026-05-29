# SKILL — Security NestJS

## Cuándo usar esta skill
Al crear o revisar cualquier módulo, controller, service, guard, pipe
o configuración en el proyecto NestJS que maneje autenticación,
autorización, datos del usuario, archivos o información sensible.

---

## SQL Injection — TypeORM

TypeORM usa consultas parametrizadas por defecto — seguro en uso normal:

```typescript
// SEGURO — TypeORM parametriza automáticamente
const user = await this.repo.findOne({
  where: { email, isActive: true }
});

// SEGURO — QueryBuilder con parámetros nombrados
const users = await this.repo.createQueryBuilder('user')
  .where('user.email = :email', { email })
  .andWhere('user.isActive = :isActive', { isActive: true })
  .getMany();
```

El riesgo aparece con queries raw:
```typescript
// MAL — concatenación directa en query raw
const users = await this.dataSource.query(
  `SELECT * FROM users WHERE email = '${email}'` // vulnerable
);

// MAL — template literal en createQueryBuilder
const users = await this.repo.createQueryBuilder('user')
  .where(`user.email = '${email}'`) // vulnerable
  .getMany();

// BIEN — query raw con parámetros posicionales (PostgreSQL)
const users = await this.dataSource.query(
  'SELECT * FROM users WHERE email = $1 AND is_active = $2',
  [email, true]
);

// BIEN — query raw con parámetros posicionales (SQL Server)
const users = await this.dataSource.query(
  'SELECT * FROM users WHERE email = @0 AND is_active = @1',
  [email, true]
);
```

---

## Contraseñas — bcrypt obligatorio

```typescript
// Instalar: npm install bcrypt @types/bcrypt

@Injectable()
export class PasswordService {
  private readonly SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '12');

  async hash(password: string): Promise<string> {
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }

  async verify(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }
}

// MAL — comparación directa (timing attack)
if (user.password === inputPassword) { }

// BIEN — comparación segura con bcrypt
const isValid = await this.passwordService.verify(inputPassword, user.passwordHash);
```

---

## JWT — configuración segura con Passport

```typescript
// Instalar: npm install @nestjs/passport @nestjs/jwt passport passport-jwt

// auth.module.ts
@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'), // falla si no existe
        signOptions: {
          expiresIn: config.get('JWT_EXPIRATION', '8h'),
          issuer: config.getOrThrow('JWT_ISSUER'),
          audience: config.getOrThrow('JWT_AUDIENCE'),
        },
      }),
    }),
  ],
})

// jwt.strategy.ts
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false, // siempre verificar expiración
      secretOrKey: config.getOrThrow<string>('JWT_SECRET'),
      issuer: config.getOrThrow('JWT_ISSUER'),
      audience: config.getOrThrow('JWT_AUDIENCE'),
    });
  }

  async validate(payload: JwtPayload): Promise<AuthUser> {
    // Verificar que el usuario sigue activo en BD
    const user = await this.usersService.findActiveById(payload.sub);
    if (!user) throw new UnauthorizedException('Usuario no encontrado o inactivo');
    return { id: payload.sub, email: payload.email, role: payload.role };
  }
}

// Generación de tokens — payload mínimo
generateTokens(user: User): AuthResponseDto {
  const payload: JwtPayload = {
    sub: user.id,
    email: user.email,
    role: user.role,
  };
  // NUNCA incluir: password, datos financieros, datos sensibles

  const accessToken = this.jwtService.sign(payload);
  const refreshToken = this.generateRefreshToken();

  return { accessToken, refreshToken, expiresIn: 8 * 3600 };
}

private generateRefreshToken(): string {
  // Bytes aleatorios seguros
  return randomBytes(64).toString('hex');
}
```

---

## Guards — autenticación y autorización

```typescript
// jwt-auth.guard.ts — protección base
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext): boolean | Promise<boolean> | Observable<boolean> {
    // Verificar si el endpoint es público
    const isPublic = this.reflector.getAllAndOverride<boolean>('isPublic', [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    return super.canActivate(context);
  }

  handleRequest(err: any, user: any, info: any): any {
    if (err || !user) {
      if (info?.name === 'TokenExpiredError') {
        throw new UnauthorizedException('Token expirado');
      }
      throw new UnauthorizedException('Token inválido o no proporcionado');
    }
    return user;
  }
}

// roles.guard.ts — verificación de roles
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) return true;

    const { user } = context.switchToHttp().getRequest<RequestWithUser>();
    const hasRole = requiredRoles.includes(user.role);

    if (!hasRole) {
      throw new ForbiddenException('No tienes permisos para realizar esta acción');
    }

    return true;
  }
}

// Decoradores helper
export const Public = () => SetMetadata('isPublic', true);
export const Roles = (...roles: UserRole[]) => SetMetadata('roles', roles);

// Aplicación global en main.ts
app.useGlobalGuards(
  new JwtAuthGuard(reflector),
  new RolesGuard(reflector),
);

// Uso en controllers
@Controller('users')
export class UsersController {
  @Public()
  @Post('login')
  async login(@Body() dto: LoginDto) { }

  @Get()
  async findAll() { } // protegido por JwtAuthGuard global

  @Delete(':id')
  @Roles(UserRole.Admin)
  async remove(@Param('id', ParseUUIDPipe) id: string) { }
}
```

---

## Rate Limiting — Throttler

```typescript
// Instalar: npm install @nestjs/throttler

// app.module.ts
@Module({
  imports: [
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          name: 'short',
          ttl: 1000,   // 1 segundo
          limit: 10,   // 10 requests por segundo
        },
        {
          name: 'medium',
          ttl: 60000,  // 1 minuto
          limit: 100,  // 100 requests por minuto
        },
      ],
    }),
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard }, // global
  ],
})

// Rate limit estricto en endpoints sensibles
@Controller('auth')
export class AuthController {
  @Public()
  @Post('login')
  @Throttle({ short: { limit: 5, ttl: 60000 } }) // 5 intentos por minuto
  async login(@Body() dto: LoginDto) { }

  @Public()
  @Post('forgot-password')
  @Throttle({ short: { limit: 3, ttl: 3600000 } }) // 3 intentos por hora
  async forgotPassword(@Body() dto: ForgotPasswordDto) { }
}
```

---

## Bloqueo por intentos fallidos

```typescript
@Injectable()
export class AuthService {
  private readonly MAX_ATTEMPTS = 5;
  private readonly LOCKOUT_MINUTES = 15;

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.usersRepository.findByEmail(dto.email);

    // Mensaje genérico — no revelar si el email existe
    if (!user) throw new UnauthorizedException('Credenciales inválidas');

    // Verificar bloqueo temporal
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      const minutesLeft = Math.ceil(
        (user.lockedUntil.getTime() - Date.now()) / 60000
      );
      throw new UnauthorizedException(
        `Cuenta bloqueada. Intenta en ${minutesLeft} minutos.`
      );
    }

    const isValid = await this.passwordService.verify(dto.password, user.passwordHash);

    if (!isValid) {
      await this.handleFailedAttempt(user);
      throw new UnauthorizedException('Credenciales inválidas');
    }

    // Reset intentos en login exitoso
    await this.usersRepository.update(user.id, {
      failedAttempts: 0,
      lockedUntil: null,
    });

    this.securityAudit.logLoginSuccess(user.id);
    return this.generateTokens(user);
  }

  private async handleFailedAttempt(user: User): Promise<void> {
    const newAttempts = user.failedAttempts + 1;

    if (newAttempts >= this.MAX_ATTEMPTS) {
      const lockedUntil = new Date(Date.now() + this.LOCKOUT_MINUTES * 60 * 1000);
      await this.usersRepository.update(user.id, {
        failedAttempts: newAttempts,
        lockedUntil,
      });
      this.securityAudit.logAccountLocked(user.id);
    } else {
      await this.usersRepository.update(user.id, { failedAttempts: newAttempts });
      this.securityAudit.logLoginFailure(user.email, newAttempts);
    }
  }
}
```

---

## Validación y sanitización de entrada

```typescript
// main.ts — ValidationPipe global con opciones de seguridad
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,              // eliminar propiedades no declaradas en DTO
  forbidNonWhitelisted: false,  // no lanzar error, solo ignorar propiedades extra
  transform: true,              // transformar tipos automáticamente
  transformOptions: { enableImplicitConversion: true },
  stopAtFirstError: false,      // mostrar todos los errores de validación
}));

// DTOs con sanitización incluida
export class CreateUserDto {
  @IsEmail({}, { message: 'El correo no es válido' })
  @Transform(({ value }) => value?.toLowerCase().trim())
  @MaxLength(255)
  email: string;

  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @MaxLength(128)
  // Nunca loggear el password
  password: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  @Transform(({ value }) => value?.trim())
  // Sanitizar HTML para prevenir XSS si se va a mostrar en UI
  @Transform(({ value }) => sanitizeHtml(value, { allowedTags: [] }))
  fullName: string;
}
```

---

## Headers de seguridad con Helmet

```typescript
// Instalar: npm install helmet

// main.ts
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false, // puede romper algunas funcionalidades
  frameguard: { action: 'deny' },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

// CORS — orígenes específicos
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
});
```

---

## Manejo seguro de archivos

```typescript
@Post('upload')
@UseInterceptors(FileInterceptor('file', {
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB máximo
    files: 1,                   // un archivo a la vez
  },
  fileFilter: (req, file, callback) => {
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'application/pdf'];
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
    const ext = extname(file.originalname).toLowerCase();

    if (!allowedMimeTypes.includes(file.mimetype) || !allowedExtensions.includes(ext)) {
      return callback(
        new BadRequestException('Tipo de archivo no permitido'),
        false
      );
    }
    callback(null, true);
  },
}))
async uploadFile(@UploadedFile() file: Express.Multer.File): Promise<ApiResponse<string>> {
  if (!file) throw new BadRequestException('Archivo requerido');

  // Generar nombre seguro — nunca usar nombre original del usuario
  const safeFilename = `${uuidv4()}${extname(file.originalname).toLowerCase()}`;

  // Guardar con nombre seguro
  const uploadPath = join(process.env.UPLOAD_PATH!, safeFilename);
  await writeFile(uploadPath, file.buffer);

  return ApiResponse.success(safeFilename, 'Archivo subido correctamente');
}
```

---

## Logging de seguridad

```typescript
@Injectable()
export class SecurityAuditService {
  private readonly logger = new Logger('SECURITY');

  logLoginSuccess(userId: string, ip?: string): void {
    this.logger.log(`LOGIN_SUCCESS | userId=${userId} | ip=${ip ?? 'unknown'}`);
  }

  logLoginFailure(email: string, attempts: number, ip?: string): void {
    this.logger.warn(
      `LOGIN_FAILURE | email=${email} | attempts=${attempts} | ip=${ip ?? 'unknown'}`
      // NUNCA incluir la contraseña en el log
    );
  }

  logAccountLocked(userId: string, ip?: string): void {
    this.logger.warn(`ACCOUNT_LOCKED | userId=${userId} | ip=${ip ?? 'unknown'}`);
  }

  logPermissionDenied(userId: string, resource: string, action: string): void {
    this.logger.warn(
      `PERMISSION_DENIED | userId=${userId} | resource=${resource} | action=${action}`
    );
  }

  logPasswordChanged(userId: string): void {
    this.logger.log(`PASSWORD_CHANGED | userId=${userId}`);
  }

  logSuspiciousActivity(userId: string, detail: string): void {
    this.logger.warn(`SUSPICIOUS_ACTIVITY | userId=${userId} | detail=${detail}`);
  }
}
```

---

## Validación de variables de entorno al inicio

```typescript
// config/env.validation.ts
import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'staging', 'production')
    .required(),
  PORT: Joi.number().default(3000),
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRATION: Joi.string().default('8h'),
  JWT_ISSUER: Joi.string().required(),
  JWT_AUDIENCE: Joi.string().required(),
  DB_HOST: Joi.string().required(),
  DB_PORT: Joi.number().default(5432),
  DB_USERNAME: Joi.string().required(),
  DB_PASSWORD: Joi.string().min(8).required(),
  DB_NAME: Joi.string().required(),
  ALLOWED_ORIGINS: Joi.string().required(),
  BCRYPT_SALT_ROUNDS: Joi.number().min(10).default(12),
  UPLOAD_PATH: Joi.string().required(),
});

// app.module.ts
ConfigModule.forRoot({
  isGlobal: true,
  validationSchema: envValidationSchema,
  validationOptions: {
    abortEarly: false, // mostrar todos los errores juntos
    allowUnknown: true,
  },
})
```

---

## Checklist seguridad NestJS antes de PR

### SQL y datos
- [ ] Sin concatenación en queries raw (usar parámetros posicionales)
- [ ] QueryBuilder con parámetros nombrados (:param)
- [ ] Soft delete implementado en todas las entidades de negocio

### Autenticación
- [ ] BCrypt con salt rounds >= 12
- [ ] JWT con expiración, issuer y audience configurados
- [ ] Secreto JWT >= 32 caracteres en variables de entorno
- [ ] Rate limiting en endpoints de auth con @Throttle
- [ ] Bloqueo por intentos fallidos implementado (5 intentos, 15 min)
- [ ] Refresh token con rotación

### Autorización
- [ ] JwtAuthGuard global activo
- [ ] Endpoints públicos marcados con @Public()
- [ ] Roles verificados con RolesGuard donde aplica
- [ ] Pertenencia de recursos verificada en el service

### Validación
- [ ] ValidationPipe global con whitelist: true
- [ ] DTOs con class-validator en todos los endpoints
- [ ] Sanitización de HTML en campos de texto libre

### Configuración
- [ ] Helmet instalado y activo
- [ ] CORS con origins específicos
- [ ] Variables de entorno validadas con Joi al inicio
- [ ] Sin secretos hardcodeados en el código

### Archivos
- [ ] Límite de tamaño configurado
- [ ] Validación de MIME type y extensión
- [ ] Nombre de archivo generado con UUID

### Logging
- [ ] Eventos de seguridad loggeados con SecurityAuditService
- [ ] Sin passwords ni tokens en logs
- [ ] Stack traces solo en logs internos
