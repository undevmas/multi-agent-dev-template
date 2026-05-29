# SKILL — NestJS Test Frameworks

## Cuándo usar esta skill
Al escribir, revisar o estructurar tests en el proyecto NestJS.
Leer antes de crear cualquier archivo de test en el backend NestJS.

Framework principal: Jest
Módulo de testing: @nestjs/testing
HTTP integration: Supertest
Mocking: jest.fn() / jest.spyOn()
Assertions: expect() nativo de Jest

---

## Estructura de proyectos de test

```
Codigo/
└── backend-nestjs/
    └── src/
        └── modules/
            └── [feature]/
                ├── [feature].service.ts
                ├── [feature].service.spec.ts      ← tests unitarios del service
                ├── [feature].controller.spec.ts   ← tests unitarios del controller
                └── [feature].guard.spec.ts        ← tests unitarios de guards
    └── test/
        └── [feature].e2e-spec.ts                  ← tests de integración HTTP
```

Convención de nombres:
- Archivo: `[clase-testeada].spec.ts`
- Describe: nombre de la clase
- It: `[método] [escenario] [resultado esperado]`

Ejemplo: `it('create cuando email duplicado lanza ConflictException')`

---

## Configuración Jest

```json
// jest.config.js o en package.json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": "src",
  "testRegex": ".*\\.spec\\.ts$",
  "transform": { "^.+\\.(t|j)s$": "ts-jest" },
  "collectCoverageFrom": ["**/*.(t|j)s"],
  "coverageDirectory": "../coverage",
  "testEnvironment": "node"
}
```

---

## Tests unitarios de Services — patrón AAA

Arrange: preparar datos y mocks
Act: ejecutar el método bajo prueba
Assert: verificar el resultado

```typescript
// users.service.spec.ts
describe('UsersService', () => {
  let service: UsersService;
  let usersRepository: jest.Mocked<UsersRepository>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: UsersRepository,
          useValue: {
            findById: jest.fn(),
            findAll: jest.fn(),
            existsByEmail: jest.fn(),
            save: jest.fn(),
            softDelete: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    usersRepository = module.get(UsersRepository);
  });

  afterEach(() => jest.clearAllMocks());

  describe('findOne', () => {
    it('cuando el usuario existe retorna UserResponseDto', async () => {
      // Arrange
      const userId = 'uuid-1';
      const mockUser: User = {
        id: userId,
        email: 'test@example.com',
        fullName: 'Test User',
        isActive: true,
        createdAt: new Date(),
      } as User;
      usersRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await service.findOne(userId);

      // Assert
      expect(result).toBeDefined();
      expect(result.email).toBe('test@example.com');
      expect(usersRepository.findById).toHaveBeenCalledWith(userId);
      expect(usersRepository.findById).toHaveBeenCalledTimes(1);
    });

    it('cuando el usuario no existe lanza NotFoundException', async () => {
      // Arrange
      usersRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(service.findOne('uuid-inexistente'))
        .rejects
        .toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('con datos válidos crea y retorna el usuario', async () => {
      // Arrange
      const dto: CreateUserDto = {
        email: 'nuevo@example.com',
        password: 'Password123!',
        fullName: 'Nuevo Usuario',
      };
      const savedUser = { id: 'new-uuid', ...dto, isActive: true } as User;

      usersRepository.existsByEmail.mockResolvedValue(false);
      usersRepository.save.mockResolvedValue(savedUser);

      // Act
      const result = await service.create(dto);

      // Assert
      expect(result.email).toBe(dto.email);
      expect(usersRepository.existsByEmail).toHaveBeenCalledWith(dto.email);
      expect(usersRepository.save).toHaveBeenCalledTimes(1);
    });

    it('con email duplicado lanza ConflictException', async () => {
      // Arrange
      usersRepository.existsByEmail.mockResolvedValue(true);

      // Act & Assert
      await expect(service.create({
        email: 'existente@example.com',
        password: 'Pass123!',
        fullName: 'Ya Existe',
      })).rejects.toThrow(ConflictException);

      expect(usersRepository.save).not.toHaveBeenCalled();
    });

    it('nunca guarda la contraseña en texto plano', async () => {
      // Arrange
      const dto: CreateUserDto = {
        email: 'test@example.com',
        password: 'MiPassword123!',
        fullName: 'Test',
      };
      usersRepository.existsByEmail.mockResolvedValue(false);
      usersRepository.save.mockImplementation(async (user) => ({ ...user, id: 'new-uuid' } as User));

      // Act
      await service.create(dto);

      // Assert
      const savedArg = usersRepository.save.mock.calls[0][0] as Partial<User>;
      expect(savedArg.password).not.toBe(dto.password);
      expect(savedArg.password).toMatch(/^\$2[ab]\$\d+\$/); // bcrypt hash
    });
  });

  describe('remove', () => {
    it('hace soft delete — no borra el registro', async () => {
      // Arrange
      const mockUser = { id: 'uuid-1', isActive: true } as User;
      usersRepository.findById.mockResolvedValue(mockUser);
      usersRepository.softDelete.mockResolvedValue(undefined);

      // Act
      await service.remove('uuid-1');

      // Assert
      expect(usersRepository.softDelete).toHaveBeenCalledWith('uuid-1');
    });
  });
});
```

---

## Tests unitarios de Guards

```typescript
// jwt-auth.guard.spec.ts
describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let reflector: jest.Mocked<Reflector>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JwtAuthGuard,
        {
          provide: Reflector,
          useValue: { getAllAndOverride: jest.fn() },
        },
      ],
    }).compile();

    guard = module.get<JwtAuthGuard>(JwtAuthGuard);
    reflector = module.get(Reflector);
  });

  it('permite acceso a endpoints públicos (@Public)', () => {
    reflector.getAllAndOverride.mockReturnValue(true); // isPublic = true

    const context = createMockExecutionContext();
    const result = guard.canActivate(context);

    expect(result).toBe(true);
  });

  it('lanza UnauthorizedException si no hay token', () => {
    reflector.getAllAndOverride.mockReturnValue(false);

    expect(() => guard.handleRequest(null, null, null))
      .toThrow(UnauthorizedException);
  });
});

// Helper para crear un ExecutionContext de prueba
function createMockExecutionContext(): ExecutionContext {
  return {
    getHandler: jest.fn(),
    getClass: jest.fn(),
    switchToHttp: jest.fn().mockReturnValue({
      getRequest: jest.fn().mockReturnValue({ headers: {} }),
    }),
  } as unknown as ExecutionContext;
}
```

---

## Tests unitarios de Pipes y Validators

```typescript
// parse-uuid.pipe.spec.ts
describe('ParseUUIDPipe', () => {
  const pipe = new ParseUUIDPipe();

  it('acepta UUID válido', async () => {
    const uuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    const result = await pipe.transform(uuid, { type: 'param', metatype: String, data: 'id' });
    expect(result).toBe(uuid);
  });

  it('rechaza string que no es UUID', async () => {
    await expect(
      pipe.transform('no-es-uuid', { type: 'param', metatype: String, data: 'id' })
    ).rejects.toThrow(BadRequestException);
  });
});

// DTO validation (class-validator)
describe('CreateUserDto validaciones', () => {
  async function validate(dto: Partial<CreateUserDto>) {
    const obj = plainToInstance(CreateUserDto, dto);
    return validateOrReject(obj).catch(errors => errors);
  }

  it('con datos válidos pasa la validación', async () => {
    const errors = await validate({
      email: 'valid@example.com',
      password: 'Password123!',
      fullName: 'Nombre Válido',
    });
    expect(errors).toBeUndefined();
  });

  it('con email inválido falla la validación', async () => {
    const errors = await validate({ email: 'no-es-email', password: 'Pass123!', fullName: 'Test' });
    expect(errors).toBeDefined();
    expect(errors[0].property).toBe('email');
  });

  it('con contraseña corta falla la validación', async () => {
    const errors = await validate({ email: 'test@test.com', password: 'corta', fullName: 'Test' });
    expect(errors).toBeDefined();
    expect(errors[0].property).toBe('password');
  });
});
```

---

## Tests de integración con Supertest

```typescript
// test/users.e2e-spec.ts
describe('UsersController (e2e)', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(getRepositoryToken(User))
      .useValue({
        findOne: jest.fn(),
        find: jest.fn(),
        save: jest.fn(),
        findAndCount: jest.fn().mockResolvedValue([[], 0]),
      })
      .compile();

    app = moduleFixture.createNestApplication();

    // Misma configuración que main.ts
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    app.useGlobalFilters(new GlobalExceptionFilter(new Logger()));

    await app.init();

    // Obtener token para las pruebas protegidas
    const loginRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'admin@test.com', password: 'Admin123!' });
    authToken = loginRes.body.data.accessToken;
  });

  afterAll(async () => await app.close());

  describe('GET /api/v1/users', () => {
    it('sin token retorna 401', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/users')
        .expect(401);
    });

    it('con token válido retorna 200 y estructura estandarizada', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/users')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.message).toBeDefined();
      expect(response.body.errors).toEqual([]);
    });
  });

  describe('POST /api/v1/users', () => {
    it('con datos válidos retorna 201', async () => {
      const dto = {
        email: `test_${Date.now()}@example.com`,
        password: 'Password123!',
        fullName: 'Usuario Test',
      };

      const response = await request(app.getHttpServer())
        .post('/api/v1/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send(dto)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.email).toBe(dto.email);
    });

    it('con email inválido retorna 400', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ email: 'no-es-email', password: 'Pass123!', fullName: 'Test' })
        .expect(400);
    });
  });
});
```

---

## Patrones de mocking frecuentes

```typescript
// Mock de un service completo
const mockUsersService = {
  findAll: jest.fn().mockResolvedValue({ items: [], total: 0, page: 1, pageSize: 20 }),
  findOne: jest.fn().mockResolvedValue({ id: 'uuid', email: 'test@test.com' }),
  create: jest.fn(),
  update: jest.fn(),
  remove: jest.fn(),
};

// Restaurar mocks entre tests
afterEach(() => jest.clearAllMocks());
afterAll(() => jest.restoreAllMocks());

// Spy en un método sin reemplazarlo
jest.spyOn(service, 'findOne');
expect(service.findOne).toHaveBeenCalledWith('uuid-123');

// Mock de módulos externos (bcrypt, randomBytes)
jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('$2b$12$hashed'),
  compare: jest.fn().mockResolvedValue(true),
}));
```

---

## Ejecutar tests

```bash
# Todos los tests
npm run test

# Solo unitarios (archivos .spec.ts en src/)
npm run test

# Tests e2e (archivos .e2e-spec.ts en test/)
npm run test:e2e

# Con cobertura
npm run test:cov

# Un archivo específico
npx jest users.service.spec.ts

# Watch mode durante desarrollo
npx jest --watch
```

---

## Cobertura mínima requerida

- Services: 80% mínimo (happy path + principales casos de error)
- Guards: 90% (cubrir casos público / autenticado / rol insuficiente)
- Pipes y validators: 100% (cada regla de validación)
- Controllers: cubiertos por tests e2e
- Repositories: cubiertos por tests e2e o con BD en memoria
