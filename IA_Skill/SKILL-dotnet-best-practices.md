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
        if (result == null) return NotFound(ApiResponse.Error("Recurso no encontrado"));
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
        return Ok(ApiResponse.Success("Recurso eliminado correctamente"));
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
        _logger.LogInformation("Entidad creada: {EntityId}", user.Id);
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
        if (user == null) throw new NotFoundException("Recurso no encontrado");
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

### Herencia en DTOs — evitar property hiding

Antes de agregar una propiedad a una clase derivada, verificar que la clase base (y sus bases) no la declare ya.
Redeclarar produce *property hiding*: el compilador no avisa, el valor se silencia en serialización y los
analizadores estáticos lo marcan como defecto.

```csharp
// MAL — hiding silencioso
public class AdminResponseDto : BaseResponseDto
{
    public string? Name { get; set; } // ya existe en BaseResponseDto
}

// BIEN — solo propiedades genuinamente nuevas
public class AdminResponseDto : BaseResponseDto { }
```

Regla: hacer `grep` del nombre de la propiedad en la jerarquía completa antes de declararla.

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
_logger.LogInformation("Entidad {EntityId} actualizada", entityId);
_logger.LogWarning("Intento de login fallido para {Email}", email);
_logger.LogError(ex, "Error al procesar la operación para {ResourceId}", resourceId);
```

### Reglas de logging estructurado (obligatorio)

- **Sin interpolación de strings** en llamadas de log. Usar siempre parámetros nombrados.
- **La excepción va como primer argumento** en `Log.Error`/`Log.Warning`: `Log.Error(ex, "Mensaje {Param}", valor)`.
  Pasarla al final o dentro del mensaje hace que Serilog no la registre como `Exception` en el sink.
- **Nivel correcto**: usar `Error` (no `Information`) para excepciones capturadas. `Warning` para condiciones anómalas
  pero recuperables.

```csharp
// MAL
Log.Information($"Error al parsear {ex.Message}");   // interpolación + nivel incorrecto
Log.Error("Falló la operación. Ex: {Ex}", ex);        // excepción como parámetro final

// BIEN
Log.Error(ex, "Error al parsear el archivo.");
Log.Error(ex, "Falló la operación para {ResourceId}.", resourceId);
```

### Logging seguro — inputs externos y payloads grandes

**Log Forging**: nunca pasar directamente a un log un valor que venga de fuente externa
(claims JWT, nombres de archivo, respuestas HTTP, campos de API).
Un atacante puede inyectar saltos de línea o secuencias que falsifican entradas de log.
Sanear el valor antes del log eliminando caracteres de control:

```csharp
// Función de saneamiento inline (o extraer a un helper del proyecto)
var safeValue = value?.Replace("\r", " ").Replace("\n", " ").Trim() ?? string.Empty;
```

**Payloads grandes**: nunca loguear un string de Base64, body HTTP completo ni payload
de tamaño indeterminado. En su lugar, loguear `Length` + un `Preview` truncado y saneado.

```csharp
// MAL — Log Forging + payload gigante
Log.Information("Archivo: {Name}", entry.FullName);           // nombre viene de fuente externa
Log.Warning("Body={Body}", await response.ReadAsStringAsync()); // body puede ser MB

// BIEN
var safeName = entry.FullName?.Replace("\r", " ").Replace("\n", " ").Trim() ?? string.Empty;
Log.Information("Archivo: {Name}", safeName);

var body = await response.Content.ReadAsStringAsync();
var preview = (body.Length <= 512 ? body : body[..512])
    .Replace("\r", " ").Replace("\n", " ");
Log.Warning("Error HTTP. BodyLength={BodyLength} BodyPreview={BodyPreview}", body.Length, preview);
```

---

## Manejo de excepciones en services y handlers

El middleware global (`GlobalExceptionMiddleware`) puede atrapar `Exception` porque es el último recurso.
En services, handlers y repositories **no** usar `catch (Exception ex)` salvo que sea absolutamente
imposible identificar el tipo específico. El análisis estático (Checkmarx, SonarQube) lo marca como
*Declaration Of Catch For Generic Exception*.

### Jerarquía de catches recomendada

```csharp
// Operación de BD
try { ... }
catch (OperationCanceledException) { throw; }                 // siempre rethrow — no suprimir cancelación
catch (System.Data.Common.DbException ex)
    { Log.Warning(ex, "Error de BD en {Operacion}.", nameof(GetDataAsync)); resultado = []; }
catch (InvalidOperationException ex)
    { Log.Warning(ex, "Estado inválido en {Operacion}.", nameof(GetDataAsync)); resultado = []; }

// Deserialización JSON (Newtonsoft)
catch (Newtonsoft.Json.JsonException ex)
    { Log.Warning(ex, "JSON inválido. RawLength={Len}", raw?.Length ?? 0); }

// Llamadas HTTP
catch (HttpRequestException ex)
    { Log.Warning(ex, "Fallo HTTP hacia {Servicio}.", "ExternalService"); }

// Procesamiento de archivos
catch (System.IO.IOException ex)
    { Log.Warning(ex, "Error de I/O procesando archivo."); }
```

### Variables usadas después de try/catch (Unchecked Error Condition)

Toda variable que se inicializa dentro de un `try` y se usa fuera **debe** tener un valor
por defecto seguro antes del bloque para que el compilador y los analizadores no reporten
condición sin verificar.

```csharp
// MAL — si el try falla, bytes no tiene valor
byte[] bytes;
try { bytes = Convert.FromBase64String(encoded); }
catch (FormatException ex) { Log.Warning(ex, "Base64 inválido."); continue; }
// aquí bytes puede estar sin asignar

// BIEN
byte[] bytes = Array.Empty<byte>();
try { bytes = Convert.FromBase64String(encoded); }
catch (FormatException ex) { Log.Warning(ex, "Base64 inválido."); continue; }
if (bytes.Length == 0) continue;  // guardia explícita
```

Del mismo modo, verificar el retorno de métodos que pueden devolver null/vacío antes de usarlos:

```csharp
var raw = await response.Content.ReadAsStringAsync();
if (string.IsNullOrWhiteSpace(raw)) return null;   // no asumir que siempre tiene contenido
```

---

## Inputs externos — validación y saneamiento

### Cache keys

Construir la clave de caché solo cuando los identificadores tengan valor.
Una clave con identificador vacío colapsa múltiples entidades en la misma entrada de caché.

```csharp
// MAL — cache key con identificador vacío posible
var cacheKey = $"entity_{data.Id}_{data.Code}";

// BIEN
if (string.IsNullOrWhiteSpace(data.Id) && string.IsNullOrWhiteSpace(data.Code))
    return null;
var cacheKey = $"entity_{data.Id}_{data.Code}";
```

### Saneamiento de nombres de archivo externos

Nunca usar directamente el nombre de un archivo proveniente de un ZIP, FTP o API como
argumento en operaciones de escritura o subida. Sanitizar primero:

```csharp
var safeFileName = entry.Name?.Replace("\r", " ").Replace("\n", " ").Trim() ?? string.Empty;
await storage.UploadFileAsync(safeFileName, bytes);
Log.Information("Archivo subido: {FileName}", safeFileName);
```

### URL encoding en query strings HTTP

Nunca interpolar directamente valores en query strings. Usar `Uri.EscapeDataString` por cada valor
para evitar que caracteres como `&`, `=`, `+` rompan la URL o permitan inyección de parámetros.

```csharp
// MAL — un valor con "&" rompe el querystring
var query = $"type=entity&id={entityId}&code={code}";

// BIEN
var query = $"type=entity&id={Uri.EscapeDataString(entityId)}&code={Uri.EscapeDataString(code)}";
```

Aplica a todos los métodos del mismo cliente aunque el tipo esperado sea GUID o valor de config:
el encoding es barato y elimina una superficie de ataque sin costo en mantenimiento.

### Límite de tamaño al streamear contenido externo

Al copiar streams de fuentes externas (ZIPs de terceros, descargas de APIs) siempre validar
el tamaño antes de iniciar la copia. Sin límite, un archivo malicioso o corrupto puede agotar
CPU/memoria y funcionar como vector de DoS. Definir el límite máximo según el dominio del proyecto.

```csharp
// MAL — sin límite: un ZIP malicioso agota recursos
await using var innerStream = entry.Open();
await innerStream.CopyToAsync(outStream, ct);

// BIEN — guard antes de abrir el stream
const long MaxEntryBytes = 20L * 1024 * 1024; // ajustar según dominio del proyecto
if (entry.Length == 0) continue;
if (entry.Length > MaxEntryBytes)
{
    var safeName = entry.FullName?.Replace("\r", " ").Replace("\n", " ").Trim() ?? string.Empty;
    _logger.LogWarning("Entrada excede límite. Entry={Entry} Length={Length}", safeName, entry.Length);
    continue;
}
await using var innerStream = entry.Open();
await innerStream.CopyToAsync(outStream, ct);
```

Usar `ZipArchiveEntry.Length` (tamaño sin comprimir) para el guard — está disponible
sin abrir el stream y es la métrica relevante para el impacto en memoria de salida.

### Orden en LINQ: normalizar antes de filtrar

Cuando se aplica una normalización y luego un filtro de vacíos, el orden importa.
`.Where(not empty).Select(normalize)` permite que strings con solo espacios pasen el
`Where` y se conviertan en `""` después, contaminando el conjunto.

```csharp
// MAL — " " pasa el Where, luego normaliza a ""
var codeSet = codes.Where(c => !string.IsNullOrEmpty(c))
                   .Select(Normalize)
                   .ToHashSet();

// BIEN — normalizar primero, luego filtrar vacíos resultantes
var codeSet = codes.Select(Normalize)
                   .Where(c => !string.IsNullOrEmpty(c))
                   .ToHashSet();
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

- Clases: PascalCase → `UserService`, `ContractRepository`
- Interfaces: I + PascalCase → `IUserService`, `IContractRepository`
- Métodos: PascalCase → `GetAllAsync`, `CreateAsync`
- Variables locales: camelCase → `userId`, `itemList`
- Constantes de dominio (`const string`, `public static readonly`): **UPPER_SNAKE_CASE**
  → `MAX_LOGIN_ATTEMPTS`, `DEFAULT_PAGE_SIZE`, `ORDER_STATUS_PENDING`
- Constantes de configuración técnica (límites, timeouts): PascalCase → `MaxLoginAttempts`
- Campos privados: _camelCase → `_userRepository`, `_logger`
- Async: siempre sufijo Async → `GetByIdAsync`, `SaveAsync`

---

## Checklist antes de hacer PR

### Arquitectura y diseño
- [ ] Controller sin lógica de negocio
- [ ] Service con lógica encapsulada y testeada
- [ ] Repository sin lógica de negocio
- [ ] DTOs validados con FluentValidation
- [ ] Soft delete implementado (no DELETE físico)
- [ ] Respuesta estandarizada en todos los endpoints
- [ ] Migración de BD si hay cambios en entidades
- [ ] DTOs derivados no redeclaran propiedades de la clase base (no property hiding)
- [ ] Constantes de dominio en UPPER_SNAKE_CASE con nombre que refleje el concepto de negocio

### Logging
- [ ] Sin interpolación de strings en llamadas de log (usar parámetros nombrados)
- [ ] Excepción como primer argumento en `Log.Error(ex, ...)`/`Log.Warning(ex, ...)`
- [ ] Nivel correcto: `Error` para excepciones, `Warning` para anomalías recuperables
- [ ] Strings de fuente externa saneados antes del log (sin CR/LF ni caracteres de control)
- [ ] Payloads grandes (Base64, HTTP bodies) logueados como Length + Preview ≤ 512 chars

### Manejo de excepciones
- [ ] Sin `catch (Exception ex)` en services/handlers (usar tipos específicos)
- [ ] `OperationCanceledException` siempre re-lanzado (`throw;`)
- [ ] Variables inicializadas antes del try-block si se usan fuera de él
- [ ] Retornos de métodos async verificados antes de usar (null/empty guard)

### Inputs externos
- [ ] Cache keys construidas solo cuando los identificadores tienen valor
- [ ] Nombres de archivo de fuentes externas saneados antes de log y antes de operaciones de escritura
- [ ] Query strings con valores externos usando `Uri.EscapeDataString`
- [ ] Streams externos con guard de tamaño máximo antes de la copia
- [ ] LINQ sobre colecciones externas: normalizar primero, luego filtrar vacíos
