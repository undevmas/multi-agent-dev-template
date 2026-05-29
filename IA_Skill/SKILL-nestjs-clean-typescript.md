# SKILL — NestJS Clean TypeScript

## Cuándo usar esta skill
Al escribir cualquier código TypeScript en el proyecto NestJS.
Leer antes de crear o modificar archivos .ts en el backend NestJS.
Complementa SKILL-nestjs-best-practices.md — esta skill se enfoca
en calidad del código TypeScript específicamente.

---

## Configuración TypeScript estricta

```json
// tsconfig.json — configuración recomendada para NestJS
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "strict": true
  }
}
```

Con `strict: true` activado, TypeScript detecta:
- Variables sin tipo definido
- Posibles null/undefined no manejados
- Parámetros con tipo implícito any
- Propiedades de clase no inicializadas

---

## Tipado estricto — reglas

### Nunca usar `any`
```typescript
// MAL
function processData(data: any): any {
  return data.value;
}

// BIEN — tipar correctamente
function processData(data: UserData): ProcessedResult {
  return { value: data.value, processed: true };
}

// Cuando el tipo es realmente desconocido, usar unknown
function parseExternalData(raw: unknown): UserData {
  if (!isUserData(raw)) throw new Error('Datos inválidos');
  return raw;
}

// Type guard
function isUserData(value: unknown): value is UserData {
  return typeof value === 'object' &&
    value !== null &&
    'email' in value &&
    typeof (value as any).email === 'string';
}
```

### Tipos de retorno explícitos en métodos públicos
```typescript
// MAL — TypeScript infiere pero no es explícito
async findAll(filter: UserFilterDto) {
  return this.repo.findAll(filter);
}

// BIEN — explícito y documentado
async findAll(filter: UserFilterDto): Promise<PagedResult<UserResponseDto>> {
  return this.repo.findAll(filter);
}
```

### Nullability explícita
```typescript
// MAL — puede ser null sin indicarlo
async findById(id: string): Promise<User> {
  return this.repo.findOne({ where: { id } }); // puede retornar null
}

// BIEN — null explícito en el tipo
async findById(id: string): Promise<User | null> {
  return this.repo.findOne({ where: { id } });
}

// Y en quien lo llama, manejar el null
const user = await this.usersRepository.findById(id);
if (!user) throw new NotFoundException('Usuario no encontrado');
// Aquí TypeScript ya sabe que user no es null
```

---

## Interfaces vs Types vs Classes

### Cuándo usar cada uno

**Interface** — para contratos y estructuras de datos puros:
```typescript
// Para DTOs de respuesta, payloads, estructuras de datos
export interface UserResponseDto {
  id: string;
  email: string;
  fullName: string;
  createdAt: Date;
}

// Para contratos de servicios/repositorios
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  findAll(filter: UserFilterDto): Promise<[User[], number]>;
  save(user: Partial<User>): Promise<User>;
  softDelete(id: string): Promise<void>;
}
```

**Type** — para uniones, intersecciones y alias complejos:
```typescript
// Unión de tipos
type UserStatus = 'active' | 'inactive' | 'blocked';
type NotificationChannel = 'email' | 'sms' | 'push';

// Intersección
type AdminUser = User & { adminLevel: number; permissions: string[] };

// Utility types
type CreateUserRequest = Omit<User, 'id' | 'createdAt' | 'updatedAt'>;
type UpdateUserRequest = Partial<Pick<User, 'fullName' | 'phone'>>;

// Tipo condicional
type AsyncReturnType<T extends (...args: any) => Promise<any>> =
  T extends (...args: any) => Promise<infer R> ? R : never;
```

**Class** — para entidades con comportamiento y para DTOs con validaciones:
```typescript
// Entidades TypeORM — siempre class
@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // comportamiento de dominio en la entidad
  block(): void {
    if (this.status === 'blocked') throw new Error('Ya está bloqueado');
    this.status = 'blocked';
    this.blockedAt = new Date();
  }
}

// DTOs con class-validator — siempre class
export class CreateUserDto {
  @IsEmail()
  email: string;

  @MinLength(8)
  password: string;
}
```

---

## Genéricos para código reutilizable

```typescript
// Resultado paginado genérico
export class PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;

  get totalPages(): number {
    return Math.ceil(this.total / this.pageSize);
  }

  get hasNextPage(): boolean {
    return this.page < this.totalPages;
  }
}

// ApiResponse genérico
export class ApiResponse<T = void> {
  success: boolean;
  data: T | null;
  message: string;
  errors: string[];

  static success<T>(data: T, message = 'Operación exitosa'): ApiResponse<T> {
    return { success: true, data, message, errors: [] };
  }

  static error(message: string, errors: string[] = []): ApiResponse<never> {
    return { success: false, data: null as never, message, errors };
  }
}

// Base repository genérico
export abstract class BaseRepository<
  TEntity extends BaseEntity,
  TFilter extends BaseFilterDto
> {
  abstract findById(id: string): Promise<TEntity | null>;
  abstract findAll(filter: TFilter): Promise<[TEntity[], number]>;
  abstract save(entity: Partial<TEntity>): Promise<TEntity>;
  abstract softDelete(id: string): Promise<void>;
}
```

---

## Enums para valores constantes

```typescript
// Usar enums para estados y categorías
export enum UserStatus {
  Active = 'active',
  Inactive = 'inactive',
  Blocked = 'blocked',
  PendingVerification = 'pending_verification',
}

export enum ContractStatus {
  Draft = 'draft',
  PendingApproval = 'pending_approval',
  Approved = 'approved',
  Rejected = 'rejected',
  Active = 'active',
  Expired = 'expired',
  Cancelled = 'cancelled',
}

export enum UserRole {
  Admin = 'admin',
  Manager = 'manager',
  Analyst = 'analyst',
  ReadOnly = 'read_only',
}

// Uso en entidades
@Entity('users')
export class User {
  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.Active })
  status: UserStatus;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.ReadOnly })
  role: UserRole;
}

// Uso en validaciones de DTO
export class UpdateUserDto {
  @IsOptional()
  @IsEnum(UserRole, { message: 'Rol no válido' })
  role?: UserRole;
}
```

---

## Utility Types — usar los de TypeScript

```typescript
// Partial — todos los campos opcionales
type UpdateContractDto = Partial<CreateContractDto>;

// Required — todos los campos requeridos
type CompleteUser = Required<User>;

// Pick — solo algunos campos
type UserSummary = Pick<User, 'id' | 'email' | 'fullName'>;

// Omit — todos excepto algunos
type CreateUserRequest = Omit<User, 'id' | 'createdAt' | 'updatedAt' | 'isActive'>;

// Readonly — inmutable
type ImmutableConfig = Readonly<AppConfig>;

// Record — diccionario tipado
type PermissionMap = Record<UserRole, string[]>;
const permissions: PermissionMap = {
  [UserRole.Admin]: ['read', 'write', 'delete'],
  [UserRole.Manager]: ['read', 'write'],
  [UserRole.Analyst]: ['read'],
  [UserRole.ReadOnly]: ['read'],
};

// NonNullable — eliminar null y undefined
type GuaranteedUser = NonNullable<User | null | undefined>; // = User

// ReturnType — inferir tipo de retorno
type ServiceResult = ReturnType<typeof usersService.findAll>;

// Parameters — inferir parámetros de una función
type FindAllParams = Parameters<typeof usersService.findAll>[0]; // UserFilterDto
```

---

## Async/Await — patrones correctos

```typescript
// Siempre usar async/await, nunca mezclar con .then()
// MAL
findAll(): Promise<User[]> {
  return this.repo.findAll().then(users => users.filter(u => u.isActive));
}

// BIEN
async findAll(): Promise<User[]> {
  const users = await this.repo.findAll();
  return users.filter(u => u.isActive);
}

// Operaciones en paralelo cuando son independientes
async getUserWithContracts(userId: string) {
  // MAL — secuencial innecesario
  const user = await this.usersRepository.findById(userId);
  const contracts = await this.contractsRepository.findByUserId(userId);
  const stats = await this.statsRepository.getUserStats(userId);

  // BIEN — paralelo cuando no hay dependencia
  const [user, contracts, stats] = await Promise.all([
    this.usersRepository.findById(userId),
    this.contractsRepository.findByUserId(userId),
    this.statsRepository.getUserStats(userId),
  ]);

  return { user, contracts, stats };
}

// Promise.allSettled cuando algunos pueden fallar
async getMultipleUsers(ids: string[]) {
  const results = await Promise.allSettled(
    ids.map(id => this.usersRepository.findById(id))
  );

  return results
    .filter((r): r is PromiseFulfilledResult<User> => r.status === 'fulfilled')
    .map(r => r.value);
}
```

---

## Immutabilidad y funcional

```typescript
// Preferir inmutabilidad cuando sea posible
// MAL — mutar arrays y objetos directamente
function addRole(user: User, role: UserRole): User {
  user.roles.push(role); // mutación
  return user;
}

// BIEN — retornar nuevo objeto
function addRole(user: User, role: UserRole): User {
  return {
    ...user,
    roles: [...user.roles, role],
  };
}

// Usar const por defecto, let solo cuando necesites reasignar
const userId = request.params.id;        // correcto
const users = await this.findAll();      // correcto, aunque sea array

// Object.freeze para configuración que no debe cambiar
const DB_CONFIG = Object.freeze({
  maxConnections: 10,
  timeout: 30000,
});
```

---

## Naming conventions TypeScript

```typescript
// Interfaces: PascalCase con prefijo I opcional (preferir sin I en NestJS)
interface UserRepository { }       // correcto en NestJS
interface IUserRepository { }      // también correcto, más explícito

// Types: PascalCase
type UserId = string;
type UserStatus = 'active' | 'inactive';

// Enums: PascalCase, valores PascalCase
enum UserRole { Admin = 'admin', Manager = 'manager' }

// Generics: una letra mayúscula o nombre descriptivo
function identity<T>(value: T): T { return value; }
function mapItems<TInput, TOutput>(items: TInput[], fn: (item: TInput) => TOutput): TOutput[]

// Funciones puras: camelCase descriptivo con verbo
function calculateTotal(items: OrderItem[]): number { }
function validateEmail(email: string): boolean { }
function mapUserToDto(user: User): UserResponseDto { }

// Booleanos: prefijo is, has, can, should
const isActive: boolean;
const hasPermission: boolean;
const canDelete: boolean;
const shouldNotify: boolean;
```

---

## Evitar code smells comunes en TypeScript

```typescript
// MAL — Type Assertion excesivo (as any o as unknown as T)
const user = data as any as User; // evadir el sistema de tipos

// BIEN — validar y tipar correctamente
function toUser(data: unknown): User {
  if (!isValidUser(data)) throw new Error('Datos de usuario inválidos');
  return data as User; // solo después de validar
}

// MAL — casting innecesario
const id = user.id as string; // ya es string

// MAL — Non-null assertion excesivo (!)
const name = user.fullName!; // afirmar que no es null sin verificar

// BIEN — verificar antes de usar
if (!user.fullName) throw new NotFoundException('Nombre no encontrado');
const name = user.fullName; // TypeScript ya sabe que no es null

// MAL — ignorar errores de TypeScript con @ts-ignore
// @ts-ignore
const result = riskyOperation();

// BIEN — tipar correctamente o usar @ts-expect-error con comentario
// @ts-expect-error: La librería X tiene tipos incorrectos en v2.3
const result = riskyOperation();
```

---

## Checklist TypeScript antes de PR

- [ ] Sin uso de `any` (usar `unknown` si el tipo es desconocido)
- [ ] Tipos de retorno explícitos en métodos públicos de services y repositories
- [ ] Nullability manejada explícitamente (T | null donde corresponde)
- [ ] Enums para estados, roles y categorías (no strings literales dispersos)
- [ ] Utility types usados donde simplifican el código
- [ ] Sin type assertions sin validación previa
- [ ] Operaciones async independientes en Promise.all
- [ ] Interfaces/types bien definidos para contratos entre capas
