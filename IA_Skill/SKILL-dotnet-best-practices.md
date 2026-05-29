# SKILL — .NET Best Practices

## Cuándo usar esta skill
Antes de crear o modificar cualquier archivo de backend en .NET 8+.
Leer antes de implementar controllers, services, repositories, DTOs o middleware.

---

## Arquitectura en capas (obligatorio)

```
API Layer          → Controllers, Middleware, Filters
Application Layer  → Services, DTOs, Validators, Interfaces
Domain Layer       → Entities, Domain Models, Business Rules
Infrastructure     → Repositories, DbContext, External Services
```

Reglas de dependencia:
- API → Application → Domain (sentido único)
- Infrastructure implementa interfaces de Application/Domain
- NUNCA el Domain depende de Infrastructure o API

---

## Controllers

### Responsabilidades del controller
- Recibir la request HTTP
- Validar que el modelo llegó correctamente (ModelState)
- Llamar al service correspondiente
- Retornar la respuesta estandarizada
- NADA de lógica de negocio en el controller

### Estructura base
```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Authorize] // en todos excepto login
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] UserFilterDto filter)
    {
        var result = await _userService.GetAllAsync(filter);
        return Ok(ApiResponse<PagedResult<UserResponseDto>>.Success(result));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var result = await _userService.GetByIdAsync(id);
        if (result == null) return NotFound(ApiResponse.Error("Usuario no encontrado"));
        return Ok(ApiResponse<UserResponseDto>.Success(result));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateUserDto dto)
    {
        var result = await _userService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<UserResponseDto>.Success(result));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateUserDto dto)
    {
        var result = await _userService.UpdateAsync(id, dto);
        return Ok(ApiResponse<UserResponseDto>.Success(result));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _userService.DeleteAsync(id); // soft delete
        return Ok(ApiResponse.Success("Usuario eliminado correctamente"));
    }
}
```

---

## Respuesta estandarizada (ApiResponse)

```csharp
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string Message { get; set; } = string.Empty;
    public List<string> Errors { get; set; } = new();
    public PaginationInfo? Pagination { get; set; }

    public static ApiResponse<T> Success(T data, string message = "Operación exitosa")
        => new() { Success = true, Data = data, Message = message };

    public static ApiResponse<T> Error(string message, List<string>? errors = null)
        => new() { Success = false, Message = message, Errors = errors ?? new() };
}

public class ApiResponse
{
    public static ApiResponse<object> Success(string message)
        => ApiResponse<object>.Success(null!, message);

    public static ApiResponse<object> Error(string message)
        => ApiResponse<object>.Error(message);
}

public class PaginationInfo
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)Total / PageSize);
}
```

---

## Services

### Responsabilidades
- Contener TODA la lógica de negocio
- Llamar al repository para acceso a datos
- Mapear entre entidades y DTOs
- Lanzar excepciones de dominio cuando corresponda
- Nunca acceder a DbContext directamente

### Estructura base
```csharp
public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<UserService> _logger;

    public UserService(IUserRepository userRepository, ILogger<UserService> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task<PagedResult<UserResponseDto>> GetAllAsync(UserFilterDto filter)
    {
        var (users, total) = await _userRepository.GetAllAsync(filter);
        return new PagedResult<UserResponseDto>
        {
            Items = users.Select(MapToDto).ToList(),
            Total = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<UserResponseDto> CreateAsync(CreateUserDto dto)
    {
        // validar unicidad
        if (await _userRepository.ExistsByEmailAsync(dto.Email))
            throw new BusinessException("El correo ya está registrado");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email,
            PasswordHash = BCrypt.HashPassword(dto.Password),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            IsActive = true
        };

        await _userRepository.AddAsync(user);
        _logger.LogInformation("Usuario creado: {UserId}", user.Id);
        return MapToDto(user);
    }

    private static UserResponseDto MapToDto(User user) => new()
    {
        Id = user.Id,
        Email = user.Email,
        CreatedAt = user.CreatedAt
    };
}
```

---

## Repositories

### Responsabilidades
- Acceso a base de datos ÚNICAMENTE
- Sin lógica de negocio
- Implementar interfaz definida en Application layer

### Interfaz base genérica
```csharp
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(Guid id); // soft delete
    Task<bool> ExistsAsync(Guid id);
}
```

### Implementación con EF Core
```csharp
public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(Guid id)
        => await _context.Users
            .Where(u => u.IsActive && u.Id == id)
            .FirstOrDefaultAsync();

    public async Task<(IEnumerable<User>, int)> GetAllAsync(UserFilterDto filter)
    {
        var query = _context.Users.Where(u => u.IsActive);

        if (!string.IsNullOrEmpty(filter.Search))
            query = query.Where(u => u.Email.Contains(filter.Search));

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(u => u.CreatedAt)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(User user)
    {
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
    }

    // Soft delete — NUNCA eliminar físicamente
    public async Task DeleteAsync(Guid id)
    {
        var user = await GetByIdAsync(id);
        if (user == null) throw new NotFoundException("Usuario no encontrado");
        user.IsActive = false;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
}
```

---

## DTOs — reglas

- Nunca exponer entidades directamente en la API
- Un DTO por dirección: Request (entrada) y Response (salida)
- Usar FluentValidation para validar DTOs de entrada

```csharp
// Request DTO
public class CreateUserDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
}

// Validador
public class CreateUserDtoValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserDtoValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress()
            .WithMessage("El correo electrónico no es válido");
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8)
            .WithMessage("La contraseña debe tener al menos 8 caracteres");
        RuleFor(x => x.FullName).NotEmpty().MaximumLength(200)
            .WithMessage("El nombre completo es requerido");
    }
}

// Response DTO
public class UserResponseDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
```

---

## Manejo de errores global

```csharp
// Middleware de excepciones globales
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (NotFoundException ex)
        {
            context.Response.StatusCode = 404;
            await WriteErrorResponse(context, ex.Message);
        }
        catch (BusinessException ex)
        {
            context.Response.StatusCode = 422;
            await WriteErrorResponse(context, ex.Message);
        }
        catch (UnauthorizedException ex)
        {
            context.Response.StatusCode = 401;
            await WriteErrorResponse(context, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado");
            context.Response.StatusCode = 500;
            await WriteErrorResponse(context, "Error interno del servidor");
        }
    }

    private static async Task WriteErrorResponse(HttpContext context, string message)
    {
        context.Response.ContentType = "application/json";
        var response = ApiResponse.Error(message);
        await context.Response.WriteAsJsonAsync(response);
    }
}
```

---

## Logging con Serilog

```csharp
// Program.cs
builder.Host.UseSerilog((context, config) =>
{
    config
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .WriteTo.Console()
        .WriteTo.File("logs/app-.log", rollingInterval: RollingInterval.Day);
});

// En services — usar siempre contexto
_logger.LogInformation("Usuario {UserId} actualizó su perfil", userId);
_logger.LogWarning("Intento de login fallido para {Email}", email);
_logger.LogError(ex, "Error al procesar pago para orden {OrderId}", orderId);
```

---

## Inyección de dependencias — registro

```csharp
// Program.cs — extensión por capa
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IAuthService, AuthService>();
        // agregar nuevos services aquí
        return services;
    }

    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services)
    {
        services.AddScoped<IUserRepository, UserRepository>();
        // agregar nuevos repositories aquí
        return services;
    }
}
```

---

## Convenciones de nomenclatura .NET

- Clases: PascalCase → UserService, ContractRepository
- Interfaces: I + PascalCase → IUserService, IContractRepository
- Métodos: PascalCase → GetAllAsync, CreateAsync
- Variables locales: camelCase → userId, contractList
- Constantes: PascalCase → MaxLoginAttempts
- Campos privados: _camelCase → _userRepository, _logger
- Async: siempre sufijo Async → GetByIdAsync, SaveAsync

---

## Checklist antes de hacer PR

- [ ] Controller sin lógica de negocio
- [ ] Service con lógica encapsulada y testeada
- [ ] Repository sin lógica de negocio
- [ ] DTOs validados con FluentValidation
- [ ] Soft delete implementado (no DELETE físico)
- [ ] Logging en puntos críticos
- [ ] Manejo de excepciones (no try-catch genérico en controllers)
- [ ] Respuesta estandarizada en todos los endpoints
- [ ] Migración de BD si hay cambios en entidades
