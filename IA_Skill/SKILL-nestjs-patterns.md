# SKILL — NestJS Patterns

## Cuándo usar esta skill
Al implementar patrones arquitectónicos avanzados en NestJS:
CQRS, Event Driven, Queues, Caching, Circuit Breaker, o cualquier
patrón que va más allá del CRUD básico.

Complementa SKILL-nestjs-best-practices.md — esa skill cubre lo básico,
esta cubre patrones para escalar y mantener sistemas complejos.

---

## CQRS — Command Query Responsibility Segregation

Separar operaciones de lectura (queries) de escritura (commands).
Usar cuando la lógica de negocio se vuelve compleja o cuando
lecturas y escrituras tienen necesidades distintas de optimización.

```typescript
// Instalar: npm install @nestjs/cqrs

// app.module.ts
import { CqrsModule } from '@nestjs/cqrs';

@Module({
  imports: [CqrsModule],
})

// Command — operación de escritura
export class CreateUserCommand {
  constructor(
    public readonly email: string,
    public readonly password: string,
    public readonly fullName: string,
  ) {}
}

// Command Handler
@CommandHandler(CreateUserCommand)
export class CreateUserHandler implements ICommandHandler<CreateUserCommand> {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly eventBus: EventBus,
  ) {}

  async execute(command: CreateUserCommand): Promise<UserResponseDto> {
    const exists = await this.usersRepository.existsByEmail(command.email);
    if (exists) throw new ConflictException('El correo ya está registrado');

    const user = await this.usersRepository.save({
      email: command.email,
      password: await bcrypt.hash(command.password, 12),
      fullName: command.fullName,
    });

    // Publicar evento de dominio
    this.eventBus.publish(new UserCreatedEvent(user.id, user.email));
    return this.mapToDto(user);
  }
}

// Query — operación de lectura
export class GetUsersQuery {
  constructor(public readonly filter: UserFilterDto) {}
}

// Query Handler
@QueryHandler(GetUsersQuery)
export class GetUsersHandler implements IQueryHandler<GetUsersQuery> {
  constructor(private readonly usersRepository: UsersRepository) {}

  async execute(query: GetUsersQuery): Promise<PagedResult<UserResponseDto>> {
    const [users, total] = await this.usersRepository.findAll(query.filter);
    return {
      items: users.map(this.mapToDto),
      total,
      page: query.filter.page,
      pageSize: query.filter.pageSize,
    };
  }
}

// Controller usando CQRS
@Controller('users')
export class UsersController {
  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  @Get()
  async findAll(@Query() filter: UserFilterDto) {
    return this.queryBus.execute(new GetUsersQuery(filter));
  }

  @Post()
  async create(@Body() dto: CreateUserDto) {
    return this.commandBus.execute(
      new CreateUserCommand(dto.email, dto.password, dto.fullName)
    );
  }
}

// Registrar handlers en el módulo
@Module({
  imports: [CqrsModule],
  controllers: [UsersController],
  providers: [
    CreateUserHandler,
    GetUsersHandler,
    UserCreatedHandler, // event handler
  ],
})
export class UsersModule {}
```

---

## Event-Driven — Domain Events

```typescript
// Evento de dominio
export class UserCreatedEvent {
  constructor(
    public readonly userId: string,
    public readonly email: string,
    public readonly createdAt: Date = new Date(),
  ) {}
}

// Event Handler — reaccionar al evento
@EventsHandler(UserCreatedEvent)
export class UserCreatedHandler implements IEventHandler<UserCreatedEvent> {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly logger: Logger,
  ) {}

  async handle(event: UserCreatedEvent) {
    this.logger.log(`Usuario creado: ${event.userId}`, UserCreatedHandler.name);

    // Enviar email de bienvenida de forma desacoplada
    await this.notificationService.sendWelcomeEmail(event.email);
  }
}

// Múltiples handlers para el mismo evento
@EventsHandler(UserCreatedEvent)
export class AuditUserCreatedHandler implements IEventHandler<UserCreatedEvent> {
  async handle(event: UserCreatedEvent) {
    await this.auditService.log('USER_CREATED', event.userId);
  }
}
```

---

## Caching con Cache Manager

```typescript
// Instalar: npm install @nestjs/cache-manager cache-manager

// app.module.ts
import { CacheModule } from '@nestjs/cache-manager';

@Module({
  imports: [
    CacheModule.register({
      ttl: 60 * 1000, // 60 segundos en ms
      max: 100,       // máximo 100 items en cache
      isGlobal: true,
    }),
  ],
})

// En el service
@Injectable()
export class UsersService {
  constructor(
    private readonly usersRepository: UsersRepository,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

  async findOne(id: string): Promise<UserResponseDto> {
    const cacheKey = `user:${id}`;

    // Intentar desde cache
    const cached = await this.cacheManager.get<UserResponseDto>(cacheKey);
    if (cached) return cached;

    // Si no está en cache, buscar en DB
    const user = await this.usersRepository.findById(id);
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const dto = this.mapToDto(user);

    // Guardar en cache por 5 minutos
    await this.cacheManager.set(cacheKey, dto, 5 * 60 * 1000);
    return dto;
  }

  async update(id: string, dto: UpdateUserDto): Promise<UserResponseDto> {
    const user = await this.usersRepository.findById(id);
    if (!user) throw new NotFoundException('Usuario no encontrado');

    Object.assign(user, dto);
    const saved = await this.usersRepository.save(user);

    // Invalidar cache al actualizar
    await this.cacheManager.del(`user:${id}`);
    return this.mapToDto(saved);
  }
}

// Cache con decorador (más simple para endpoints de lectura)
@Controller('users')
@UseInterceptors(CacheInterceptor)
export class UsersController {
  @Get()
  @CacheTTL(30 * 1000) // 30 segundos
  async findAll(@Query() filter: UserFilterDto) {
    return this.usersService.findAll(filter);
  }
}
```

---

## Queue Pattern con Bull (procesamiento asíncrono)

```typescript
// Instalar: npm install @nestjs/bull bull

// app.module.ts
import { BullModule } from '@nestjs/bull';

@Module({
  imports: [
    BullModule.forRoot({
      redis: { host: process.env.REDIS_HOST, port: 6379 },
    }),
    BullModule.registerQueue({ name: 'notifications' }),
    BullModule.registerQueue({ name: 'reports' }),
  ],
})

// Producer — agregar jobs a la cola
@Injectable()
export class NotificationService {
  constructor(
    @InjectQueue('notifications') private notificationsQueue: Queue,
  ) {}

  async sendWelcomeEmail(email: string, userId: string) {
    await this.notificationsQueue.add('welcome-email', {
      email,
      userId,
    }, {
      attempts: 3,          // reintentar 3 veces si falla
      backoff: 5000,        // esperar 5s entre reintentos
      removeOnComplete: true,
    });
  }

  async sendBulkNotification(userIds: string[], message: string) {
    const jobs = userIds.map(userId => ({
      name: 'push-notification',
      data: { userId, message },
    }));
    await this.notificationsQueue.addBulk(jobs);
  }
}

// Consumer — procesar los jobs
@Processor('notifications')
export class NotificationsProcessor {
  private readonly logger = new Logger(NotificationsProcessor.name);

  @Process('welcome-email')
  async handleWelcomeEmail(job: Job<{ email: string; userId: string }>) {
    this.logger.log(`Procesando email de bienvenida para ${job.data.email}`);
    // lógica de envío de email
    await this.emailProvider.send({
      to: job.data.email,
      subject: 'Bienvenido',
      template: 'welcome',
    });
  }

  @Process('push-notification')
  async handlePushNotification(job: Job<{ userId: string; message: string }>) {
    await this.pushService.send(job.data.userId, job.data.message);
  }

  @OnQueueFailed()
  onFailed(job: Job, error: Error) {
    this.logger.error(`Job ${job.id} falló: ${error.message}`);
  }
}
```

---

## Decoradores personalizados

```typescript
// Obtener usuario autenticado del request
export const CurrentUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);

// Uso en controller
@Get('profile')
async getProfile(@CurrentUser() user: JwtPayload) {
  return this.usersService.findOne(user.sub);
}

@Get('email')
async getEmail(@CurrentUser('email') email: string) {
  return { email };
}

// Decorator para marcar endpoints como públicos (sin auth)
export const Public = () => SetMetadata('isPublic', true);

// En el JWT guard, verificar si es público
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>('isPublic', [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;
    return super.canActivate(context);
  }
}

// Uso
@Public()
@Post('login')
async login(@Body() dto: LoginDto) { }
```

---

## Repository Pattern con TypeORM — avanzado

```typescript
// Base repository genérico
export abstract class BaseRepository<T extends { id: string; isActive: boolean }> {
  constructor(protected readonly repo: Repository<T>) {}

  async findById(id: string): Promise<T | null> {
    return this.repo.findOne({ where: { id, isActive: true } as any });
  }

  async findAll(
    where: Partial<T> = {},
    page = 1,
    pageSize = 20,
  ): Promise<[T[], number]> {
    return this.repo.findAndCount({
      where: { ...where, isActive: true } as any,
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
  }

  async save(entity: Partial<T>): Promise<T> {
    return this.repo.save(entity as T);
  }

  async softDelete(id: string): Promise<void> {
    await this.repo.update(id, { isActive: false, updatedAt: new Date() } as any);
  }

  async exists(where: Partial<T>): Promise<boolean> {
    const count = await this.repo.count({ where: { ...where, isActive: true } as any });
    return count > 0;
  }
}

// Repository específico extendiendo la base
@Injectable()
export class UsersRepository extends BaseRepository<User> {
  constructor(@InjectRepository(User) repo: Repository<User>) {
    super(repo);
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.repo.findOne({ where: { email, isActive: true } });
  }

  async findWithContracts(id: string): Promise<User | null> {
    return this.repo.findOne({
      where: { id, isActive: true },
      relations: ['contracts'],
    });
  }
}
```

---

## Health Checks

```typescript
// Instalar: npm install @nestjs/terminus

@Module({
  imports: [TerminusModule, TypeOrmModule],
  controllers: [HealthController],
})

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private http: HttpHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.db.pingCheck('database'),
    ]);
  }
}
```

---

## Configuración con variables de entorno

```typescript
// config/app.config.ts
export default registerAs('app', () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiration: process.env.JWT_EXPIRATION || '8h',
  frontendUrl: process.env.FRONTEND_URL,
}));

// config/database.config.ts
export default registerAs('database', () => ({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  name: process.env.DB_NAME,
}));

// app.module.ts
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig],
      validationSchema: Joi.object({
        PORT: Joi.number().default(3000),
        JWT_SECRET: Joi.string().required(),
        DB_HOST: Joi.string().required(),
        DB_PASSWORD: Joi.string().required(),
      }),
    }),
  ],
})

// Uso en un service
@Injectable()
export class AuthService {
  constructor(
    @Inject(appConfig.KEY) private config: ConfigType<typeof appConfig>,
    private jwtService: JwtService,
  ) {}

  generateToken(payload: JwtPayload): string {
    return this.jwtService.sign(payload, {
      secret: this.config.jwtSecret,
      expiresIn: this.config.jwtExpiration,
    });
  }
}
```

---

## Patrones de manejo de errores de dominio

```typescript
// Excepciones de dominio tipadas
export class UserNotFoundException extends NotFoundException {
  constructor(id: string) {
    super(`Usuario con ID ${id} no encontrado`);
  }
}

export class DuplicateEmailException extends ConflictException {
  constructor(email: string) {
    super(`El correo ${email} ya está registrado`);
  }
}

export class InsufficientPermissionsException extends ForbiddenException {
  constructor(action: string) {
    super(`No tienes permisos para ${action}`);
  }
}

// Uso en services — errores descriptivos y tipados
async findOne(id: string): Promise<User> {
  const user = await this.usersRepository.findById(id);
  if (!user) throw new UserNotFoundException(id);
  return user;
}
```
