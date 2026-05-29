# SKILL — .NET Design Pattern Review

## Cuándo usar esta skill
Al revisar código .NET existente, hacer code review, refactorizar,
o cuando el agente necesita evaluar si el código sigue los patrones
arquitectónicos correctos para este proyecto.

---

## Checklist de revisión por capa

### Controller — señales de alerta
```
❌ Lógica de negocio directamente en el controller
❌ Llamadas directas a DbContext desde el controller
❌ Múltiples responsabilidades en un mismo método
❌ Try-catch genérico que oculta errores
❌ Mapeo de entidades a DTOs dentro del controller
❌ Validaciones complejas con if/else anidados

✅ Solo recibe, delega al service, retorna respuesta
✅ Respuesta siempre con ApiResponse estandarizado
✅ Manejo de errores por middleware global
✅ Métodos cortos y legibles (menos de 20 líneas)
```

### Service — señales de alerta
```
❌ Acceso directo a DbContext (debe ir por repository)
❌ Lógica de presentación (formateo de strings para UI)
❌ Dependencias circulares entre services
❌ Métodos de más de 50 líneas sin extraer
❌ Sin logging en operaciones críticas

✅ Toda la lógica de negocio encapsulada aquí
✅ Llama solo a repositories e interfaces
✅ Lanza excepciones de dominio específicas
✅ Logging en creación, modificación y errores
```

### Repository — señales de alerta
```
❌ Lógica de negocio dentro del repository
❌ Queries con más de 3 joins sin justificación
❌ SELECT * sin proyección (cargar columnas innecesarias)
❌ N+1 queries (iterar y hacer query por cada item)
❌ DELETE físico de registros de negocio

✅ Solo acceso a datos, sin lógica
✅ Siempre filtrar por IsActive = true
✅ Paginación del lado del servidor
✅ Soft delete en todos los métodos de eliminación
```

---

## Patrones aplicados en este proyecto

### Repository Pattern
Separar acceso a datos de lógica de negocio.

Correcto:
```csharp
// Service llama al repository
public async Task<UserResponseDto> GetByIdAsync(Guid id)
{
    var user = await _userRepository.GetByIdAsync(id);
    if (user == null) throw new NotFoundException("Usuario no encontrado");
    return MapToDto(user);
}

// Repository solo accede a datos
public async Task<User?> GetByIdAsync(Guid id)
    => await _context.Users.Where(u => u.IsActive && u.Id == id).FirstOrDefaultAsync();
```

Incorrecto:
```csharp
// Repository con lógica de negocio — EVITAR
public async Task<User?> GetByIdAsync(Guid id)
{
    var user = await _context.Users.FindAsync(id);
    if (user == null) throw new NotFoundException("..."); // lógica de negocio aquí — MAL
    if (!user.IsActive) throw new BusinessException("..."); // también MAL
    return user;
}
```

### Unit of Work (cuando se necesitan múltiples operaciones)
```csharp
public interface IUnitOfWork
{
    IUserRepository Users { get; }
    IContractRepository Contracts { get; }
    Task<int> SaveChangesAsync();
}

// En el service cuando se necesita atomicidad
public async Task CreateContractWithUserAsync(CreateContractDto dto)
{
    var user = await _unitOfWork.Users.GetByIdAsync(dto.UserId);
    var contract = new Contract { ... };
    await _unitOfWork.Contracts.AddAsync(contract);
    await _unitOfWork.SaveChangesAsync(); // una sola transacción
}
```

### Factory Pattern (para creación compleja de entidades)
```csharp
// Cuando la creación de una entidad requiere lógica compleja
public static class UserFactory
{
    public static User Create(CreateUserDto dto)
    {
        return new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email.ToLowerInvariant().Trim(),
            PasswordHash = BCrypt.HashPassword(dto.Password, 12),
            FullName = dto.FullName.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }
}

// En el service
var user = UserFactory.Create(dto);
await _userRepository.AddAsync(user);
```

### Strategy Pattern (para algoritmos intercambiables)
```csharp
// Útil para diferentes métodos de autenticación o diferentes
// algoritmos de cálculo según el tipo de contrato

public interface IAuthStrategy
{
    Task<AuthResult> AuthenticateAsync(AuthRequest request);
}

public class JwtAuthStrategy : IAuthStrategy { ... }
public class AzureAdAuthStrategy : IAuthStrategy { ... }

// En el service
public class AuthService
{
    private readonly IEnumerable<IAuthStrategy> _strategies;

    public async Task<AuthResult> AuthenticateAsync(AuthRequest request)
    {
        var strategy = _strategies.First(s => s.CanHandle(request.Provider));
        return await strategy.AuthenticateAsync(request);
    }
}
```

### Decorator Pattern (para cross-cutting concerns)
```csharp
// Agregar logging o caching a un service sin modificarlo
public class LoggingUserServiceDecorator : IUserService
{
    private readonly IUserService _inner;
    private readonly ILogger<LoggingUserServiceDecorator> _logger;

    public async Task<UserResponseDto> GetByIdAsync(Guid id)
    {
        _logger.LogInformation("Obteniendo usuario {UserId}", id);
        var result = await _inner.GetByIdAsync(id);
        _logger.LogInformation("Usuario {UserId} obtenido", id);
        return result;
    }
}
```

---

## Anti-patrones comunes — detectar y corregir

### God Class
```
Señal: Una clase con más de 500 líneas o más de 20 métodos públicos
Solución: Separar responsabilidades en clases más pequeñas y enfocadas
```

### Anemic Domain Model
```
Señal: Entidades solo con propiedades, sin comportamiento ni validaciones
Considerar: Agregar métodos de dominio para operaciones cohesivas

// Anémico (solo propiedades)
public class Contract { public string Status { get; set; } }

// Con comportamiento de dominio
public class Contract
{
    public string Status { get; private set; }
    public void Approve(string approvedBy)
    {
        if (Status != "Pending") throw new BusinessException("Solo se pueden aprobar contratos pendientes");
        Status = "Approved";
        ApprovedBy = approvedBy;
        ApprovedAt = DateTime.UtcNow;
    }
}
```

### Service Locator (anti-patrón)
```csharp
// MAL — oculta dependencias
var userService = ServiceLocator.GetService<IUserService>();

// BIEN — inyección por constructor (siempre)
public class ContractService
{
    private readonly IUserService _userService;
    public ContractService(IUserService userService)
    {
        _userService = userService;
    }
}
```

### Primitive Obsession
```csharp
// MAL — string para todo
public void CreateUser(string email, string role, string status) { }

// BIEN — tipos con significado
public void CreateUser(Email email, UserRole role, UserStatus status) { }

public record Email(string Value)
{
    public static Email Create(string value)
    {
        if (!value.Contains('@')) throw new BusinessException("Email inválido");
        return new Email(value.ToLowerInvariant().Trim());
    }
}
```

---

## Revisión de queries EF Core

### N+1 — detectar y corregir
```csharp
// MAL — genera N+1 queries
var contracts = await _context.Contracts.ToListAsync();
foreach (var contract in contracts)
{
    var user = await _context.Users.FindAsync(contract.UserId); // query por cada contrato
}

// BIEN — una sola query con Include
var contracts = await _context.Contracts
    .Include(c => c.User)
    .Where(c => c.IsActive)
    .ToListAsync();
```

### Proyección para evitar over-fetching
```csharp
// MAL — carga toda la entidad cuando solo se necesitan 3 campos
var users = await _context.Users.ToListAsync();
return users.Select(u => new { u.Id, u.Email, u.FullName });

// BIEN — proyectar directamente en la query
var users = await _context.Users
    .Where(u => u.IsActive)
    .Select(u => new UserSummaryDto
    {
        Id = u.Id,
        Email = u.Email,
        FullName = u.FullName
    })
    .ToListAsync();
```

### AsNoTracking para queries de solo lectura
```csharp
// Para listados y consultas que no van a modificar entidades
var users = await _context.Users
    .AsNoTracking()
    .Where(u => u.IsActive)
    .ToListAsync();
```

---

## Revisión de seguridad básica

```
❌ Credenciales hardcodeadas en el código
❌ ConnectionString en appsettings sin variables de entorno
❌ Endpoints sin [Authorize] cuando deberían tenerlo
❌ Exponer stack trace en respuestas de error
❌ Sin validación de entrada en endpoints públicos
❌ IDs secuenciales (usar Guid para evitar enumeración)

✅ Secrets en variables de entorno o Azure Key Vault
✅ JWT validado en cada request protegido
✅ Solo el mensaje de error llega al cliente (no stack trace)
✅ FluentValidation en todos los DTOs de entrada
✅ Guid como identificadores primarios
```

---

## Preguntas de revisión para cada PR

1. ¿Cada clase tiene una sola responsabilidad?
2. ¿Las interfaces están en la capa correcta?
3. ¿Hay lógica de negocio fuera del service?
4. ¿Hay acceso a DbContext fuera del repository?
5. ¿Los errores son específicos y manejados correctamente?
6. ¿Hay logging en las operaciones críticas?
7. ¿El soft delete está implementado correctamente?
8. ¿Las queries tienen paginación cuando devuelven listas?
9. ¿Hay credenciales o valores sensibles hardcodeados?
10. ¿Los tests cubren el happy path y al menos un caso de error?
