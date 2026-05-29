# SKILL — NestJS Best Practices

## Cuándo usar esta skill
Antes de crear o modificar cualquier archivo de backend en NestJS 10+.
Leer antes de implementar modules, controllers, services, guards, pipes o interceptors.

---

## Arquitectura modular (obligatorio)

```
src/
├── app.module.ts              # Módulo raíz
├── common/                    # Compartido entre módulos
│   ├── decorators/
│   ├── filters/               # Exception filters
│   ├── guards/                # Auth guards
│   ├── interceptors/          # Response transform, logging
│   ├── pipes/                 # Validation pipes
│   └── dto/                   # DTOs compartidos (pagination, response)
├── config/                    # Configuración y variables de entorno
├── database/                  # DbContext, migrations, seeds
└── modules/                   # Un módulo por dominio de negocio
    ├── auth/
    │   ├── auth.module.ts
    │   ├── auth.controller.ts
    │   ├── auth.service.ts
    │   ├── strategies/        # Passport strategies
    │   ├── guards/
    │   └── dto/
    ├── users/
    │   ├── users.module.ts
    │   ├── users.controller.ts
    │   ├── users.service.ts
    │   ├── users.repository.ts
    │   ├── entities/
    │   └── dto/
    └── [feature]/
```

Regla: un módulo = un contexto de negocio cohesivo.
No crear módulos por tipo técnico (no "services module", "repositories module").

---

## Módulo base

```typescript
@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    // otros módulos que este necesita
  ],
  controllers: [UsersController],
  providers: [UsersService, UsersRepository],
  exports: [UsersService], // solo exportar lo que otros módulos necesitan
})
export class UsersModule {}
```

---

## Controllers

### Responsabilidades
- Definir rutas y métodos HTTP
- Aplicar guards, pipes e interceptors
- Delegar al service
- NUNCA lógica de negocio

```typescript
@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'Listar usuarios con paginación' })
  async findAll(@Query() filter: UserFilterDto): Promise<ApiResponse<PagedResult<UserResponseDto>>> {
    const result = await this.usersService.findAll(filter);
    return ApiResponse.success(result);
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string): Promise<ApiResponse<UserResponseDto>> {
    const result = await this.usersService.findOne(id);
    return ApiResponse.success(result);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateUserDto): Promise<ApiResponse<UserResponseDto>> {
    const result = await this.usersService.create(dto);
    return ApiResponse.success(result, 'Usuario creado correctamente');
  }

  @Put(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
  ): Promise<ApiResponse<UserResponseDto>> {
    const result = await this.usersService.update(id, dto);
    return ApiResponse.success(result);
  }

  @Delete(':id')
  async remove(@Param('id', ParseUUIDPipe) id: string): Promise<ApiResponse<void>> {
    await this.usersService.remove(id);
    return ApiResponse.success(null, 'Usuario eliminado correctamente');
  }
}
```

---

## Services

### Responsabilidades
- Toda la lógica de negocio
- Llamar al repository para acceso a datos
- Lanzar HttpException o excepciones de dominio
- Logging de operaciones importantes

```typescript
@Injectable()
export class UsersService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly logger: Logger,
  ) {}

  async findAll(filter: UserFilterDto): Promise<PagedResult<UserResponseDto>> {
    const [users, total] = await this.usersRepository.findAll(filter);
    return {
      items: users.map(this.mapToDto),
      total,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: Math.ceil(total / filter.pageSize),
    };
  }

  async findOne(id: string): Promise<UserResponseDto> {
    const user = await this.usersRepository.findById(id);
    if (!user) throw new NotFoundException('Usuario no encontrado');
    return this.mapToDto(user);
  }

  async create(dto: CreateUserDto): Promise<UserResponseDto> {
    const exists = await this.usersRepository.existsByEmail(dto.email);
    if (exists) throw new ConflictException('El correo ya está registrado');

    const user = this.usersRepository.create({
      ...dto,
      password: await bcrypt.hash(dto.password, 12),
    });

    const saved = await this.usersRepository.save(user);
    this.logger.log(`Usuario creado: ${saved.id}`, UsersService.name);
    return this.mapToDto(saved);
  }

  async remove(id: string): Promise<void> {
    const user = await this.usersRepository.findById(id);
    if (!user) throw new NotFoundException('Usuario no encontrado');
    await this.usersRepository.softDelete(id); // soft delete obligatorio
    this.logger.log(`Usuario eliminado: ${id}`, UsersService.name);
  }

  private mapToDto(user: User): UserResponseDto {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      createdAt: user.createdAt,
    };
  }
}
```

---

## Repositories con TypeORM

```typescript
@Injectable()
export class UsersRepository extends Repository<User> {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {
    super(repo.target, repo.manager, repo.queryRunner);
  }

  async findById(id: string): Promise<User | null> {
    return this.repo.findOne({ where: { id, isActive: true } });
  }

  async findAll(filter: UserFilterDto): Promise<[User[], number]> {
    const query = this.repo.createQueryBuilder('user')
      .where('user.isActive = :isActive', { isActive: true });

    if (filter.search) {
      query.andWhere('(user.email ILIKE :search OR user.fullName ILIKE :search)',
        { search: `%${filter.search}%` });
    }

    return query
      .orderBy('user.createdAt', 'DESC')
      .skip((filter.page - 1) * filter.pageSize)
      .take(filter.pageSize)
      .getManyAndCount();
  }

  async existsByEmail(email: string): Promise<boolean> {
    const count = await this.repo.count({ where: { email, isActive: true } });
    return count > 0;
  }

  async softDelete(id: string): Promise<void> {
    await this.repo.update(id, { isActive: false, updatedAt: new Date() });
  }
}
```

---

## DTOs con class-validator y class-transformer

```typescript
// Request DTO
export class CreateUserDto {
  @ApiProperty({ example: 'usuario@example.com' })
  @IsEmail({}, { message: 'El correo electrónico no es válido' })
  @Transform(({ value }) => value?.toLowerCase().trim())
  email: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  password: string;

  @ApiProperty({ example: 'Juan García' })
  @IsString()
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @MaxLength(200)
  @Transform(({ value }) => value?.trim())
  fullName: string;
}

// Response DTO
export class UserResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  email: string;

  @ApiProperty()
  fullName: string;

  @ApiProperty()
  createdAt: Date;
}

// Filter/Query DTO
export class UserFilterDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize: number = 20;
}
```

---

## Respuesta estandarizada

```typescript
export class ApiResponse<T> {
  success: boolean;
  data: T | null;
  message: string;
  errors: string[];
  pagination?: PaginationInfo;

  static success<T>(data: T, message = 'Operación exitosa'): ApiResponse<T> {
    return { success: true, data, message, errors: [] };
  }

  static error(message: string, errors: string[] = []): ApiResponse<null> {
    return { success: false, data: null, message, errors };
  }
}
```

---

## Guards (autenticación y autorización)

```typescript
// JWT Guard — protege todos los endpoints por defecto
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }

  handleRequest(err: any, user: any) {
    if (err || !user) {
      throw new UnauthorizedException('Token inválido o expirado');
    }
    return user;
  }
}

// Roles Guard
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<string[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!roles) return true;

    const { user } = context.switchToHttp().getRequest();
    return roles.some(role => user.roles?.includes(role));
  }
}

// Decorator de roles
export const Roles = (...roles: string[]) => SetMetadata('roles', roles);

// Uso en controller
@Get('admin')
@Roles('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
async adminOnly() { }
```

---

## Interceptors

```typescript
// Transform response — asegurar formato estandarizado
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map(data => {
        // Si ya es ApiResponse, no transformar
        if (data && 'success' in data) return data;
        return ApiResponse.success(data);
      }),
    );
  }
}

// Logging interceptor
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  constructor(private readonly logger: Logger) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url } = request;
    const start = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - start;
        this.logger.log(`${method} ${url} - ${duration}ms`);
      }),
    );
  }
}
```

---

## Exception Filter global

```typescript
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private readonly logger: Logger) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Error interno del servidor';
    let errors: string[] = [];

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      message = typeof exceptionResponse === 'string'
        ? exceptionResponse
        : (exceptionResponse as any).message || message;

      if (Array.isArray(message)) {
        errors = message;
        message = 'Error de validación';
      }
    } else {
      this.logger.error('Error no controlado:', exception);
    }

    response.status(status).json(ApiResponse.error(message, errors));
  }
}
```

---

## Configuración en main.ts

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Prefijo global de API
  app.setGlobalPrefix('api/v1');

  // Validación automática de DTOs
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,        // eliminar propiedades no declaradas en DTO
    forbidNonWhitelisted: false,
    transform: true,        // transformar tipos automáticamente
    transformOptions: { enableImplicitConversion: true },
  }));

  // Exception filter global
  app.useGlobalFilters(new GlobalExceptionFilter(new Logger()));

  // Interceptor de transformación global
  app.useGlobalInterceptors(new TransformInterceptor());

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('API Documentation')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('swagger', app, SwaggerModule.createDocument(app, config));

  // CORS
  app.enableCors({ origin: process.env.FRONTEND_URL });

  await app.listen(process.env.PORT ?? 3000);
}
```

---

## Convenciones de nomenclatura NestJS

- Archivos: kebab-case → `users.service.ts`, `jwt-auth.guard.ts`
- Clases: PascalCase → `UsersService`, `JwtAuthGuard`
- Métodos: camelCase → `findAll`, `createUser`
- Variables: camelCase → `userId`, `accessToken`
- Constantes: SCREAMING_SNAKE_CASE → `JWT_SECRET`, `MAX_RETRIES`
- Módulos: siempre en carpeta propia con su nombre → `users/users.module.ts`

---

## Checklist antes de PR

- [ ] Módulo con imports, exports y providers correctos
- [ ] Controller sin lógica de negocio
- [ ] Service con toda la lógica encapsulada
- [ ] DTOs con validaciones class-validator
- [ ] Soft delete (no delete físico en tablas de negocio)
- [ ] Guards aplicados en endpoints protegidos
- [ ] Logging en operaciones críticas
- [ ] Respuesta estandarizada con ApiResponse
- [ ] Swagger documentado en endpoints públicos
- [ ] Variables de entorno en config/ (no hardcoded)
