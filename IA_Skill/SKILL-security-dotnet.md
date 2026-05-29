# SKILL — Security .NET

## Cuándo usar esta skill
Al crear o revisar cualquier endpoint, service, middleware o configuración
en el proyecto .NET 8 que maneje autenticación, autorización, datos del
usuario, archivos, o información sensible.

---

## SQL Injection — Entity Framework Core

EF Core usa consultas parametrizadas por defecto, lo que previene SQL injection:

```csharp
// SEGURO — EF Core parametriza automáticamente
var user = await _context.Users
    .Where(u => u.Email == email && u.IsActive)
    .FirstOrDefaultAsync();

// SEGURO — LINQ to Entities
var contracts = await _context.Contracts
    .Where(c => c.Status == status && c.UserId == userId)
    .ToListAsync();
```

El riesgo aparece con raw queries:
```csharp
// MAL — concatenación directa en raw query
var query = $"SELECT * FROM Users WHERE Email = '{email}'";
var users = await _context.Users.FromSqlRaw(query).ToListAsync();

// MAL — también vulnerable
var users = await _context.Database.ExecuteSqlRawAsync(
    $"UPDATE Users SET IsActive = 0 WHERE Id = '{userId}'"
);

// BIEN — FromSqlRaw con parámetros
var users = await _context.Users
    .FromSqlRaw("SELECT * FROM Users WHERE Email = {0}", email)
    .ToListAsync();

// BIEN — FromSqlInterpolated (más legible, igualmente seguro)
var users = await _context.Users
    .FromSqlInterpolated($"SELECT * FROM Users WHERE Email = {email}")
    .ToListAsync();

// BIEN — ExecuteSqlInterpolated para comandos
await _context.Database.ExecuteSqlInterpolatedAsync(
    $"UPDATE Users SET IsActive = 0 WHERE Id = {userId}"
);

// BIEN — SqlParameter explícito para stored procedures
var emailParam = new SqlParameter("@email", email);
var users = await _context.Users
    .FromSqlRaw("EXEC GetUsersByEmail @email", emailParam)
    .ToListAsync();
```

---

## Contraseñas — BCrypt obligatorio

```csharp
// Instalar: dotnet add package BCrypt.Net-Next

// MAL — texto plano o algoritmos débiles
user.Password = password;
user.Password = Convert.ToBase64String(Encoding.UTF8.GetBytes(password));
user.Password = MD5.HashData(Encoding.UTF8.GetBytes(password)).ToString(); // inseguro

// BIEN — BCrypt con work factor adecuado
public class PasswordService
{
    private const int WorkFactor = 12; // mínimo 10, recomendado 12

    public string Hash(string password)
        => BCrypt.Net.BCrypt.HashPassword(password, WorkFactor);

    public bool Verify(string password, string hash)
        => BCrypt.Net.BCrypt.Verify(password, hash);
}

// Uso en AuthService
public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
{
    var user = await _userRepository.GetByEmailAsync(dto.Email);

    // Mensaje genérico — no revelar si el email existe
    if (user == null || !_passwordService.Verify(dto.Password, user.PasswordHash))
        throw new UnauthorizedException("Credenciales inválidas");

    return GenerateTokens(user);
}
```

---

## JWT — configuración segura

```csharp
// Program.cs — configuración JWT
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]!)
            ),
            ClockSkew = TimeSpan.Zero, // sin margen de gracia al expirar
        };

        // Manejo de errores de autenticación
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                if (context.Exception is SecurityTokenExpiredException)
                    context.Response.Headers.Append("Token-Expired", "true");
                return Task.CompletedTask;
            },
        };
    });

// Generación de token
public class JwtService
{
    private readonly IConfiguration _config;

    public string GenerateAccessToken(User user)
    {
        // Payload mínimo — solo lo necesario
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Secret"]!)
        );
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8), // access token: 8 horas
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        // Refresh token: bytes aleatorios seguros
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }
}
```

---

## Rate Limiting — limitar intentos

```csharp
// Program.cs — .NET 8 tiene rate limiting nativo
builder.Services.AddRateLimiter(options =>
{
    // Política para login — 5 intentos por minuto por IP
    options.AddFixedWindowLimiter("login", limiterOptions =>
    {
        limiterOptions.PermitLimit = 5;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiterOptions.QueueLimit = 0;
    });

    // Política general — 100 requests por minuto por IP
    options.AddFixedWindowLimiter("general", limiterOptions =>
    {
        limiterOptions.PermitLimit = 100;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
    });

    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = 429;
        await context.HttpContext.Response.WriteAsJsonAsync(
            ApiResponse.Error("Demasiadas solicitudes. Intenta más tarde."), token
        );
    };
});

app.UseRateLimiter();

// En el controller de auth
[HttpPost("login")]
[EnableRateLimiting("login")]
public async Task<IActionResult> Login([FromBody] LoginDto dto) { }
```

---

## Bloqueo por intentos fallidos

```csharp
public class AuthService : IAuthService
{
    private const int MaxFailedAttempts = 5;
    private const int LockoutMinutes = 15;

    public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
    {
        var user = await _userRepository.GetByEmailAsync(dto.Email);

        if (user == null)
        {
            // No revelar si el email existe — mismo mensaje siempre
            throw new UnauthorizedException("Credenciales inválidas");
        }

        // Verificar bloqueo
        if (user.LockedUntil.HasValue && user.LockedUntil > DateTime.UtcNow)
        {
            var minutesLeft = (int)Math.Ceiling(
                (user.LockedUntil.Value - DateTime.UtcNow).TotalMinutes
            );
            throw new UnauthorizedException(
                $"Cuenta bloqueada. Intenta en {minutesLeft} minutos."
            );
        }

        var isValid = _passwordService.Verify(dto.Password, user.PasswordHash);

        if (!isValid)
        {
            await HandleFailedAttemptAsync(user);
            throw new UnauthorizedException("Credenciales inválidas");
        }

        // Reset intentos fallidos en login exitoso
        await _userRepository.ResetFailedAttemptsAsync(user.Id);
        _logger.LogInformation("Login exitoso: {UserId}", user.Id);

        return GenerateTokens(user);
    }

    private async Task HandleFailedAttemptAsync(User user)
    {
        var newAttempts = user.FailedAttempts + 1;

        if (newAttempts >= MaxFailedAttempts)
        {
            var lockedUntil = DateTime.UtcNow.AddMinutes(LockoutMinutes);
            await _userRepository.LockUserAsync(user.Id, lockedUntil);
            _logger.LogWarning("Usuario bloqueado por intentos fallidos: {UserId}", user.Id);
        }
        else
        {
            await _userRepository.IncrementFailedAttemptsAsync(user.Id, newAttempts);
        }
    }
}
```

---

## Headers de seguridad — middleware

```csharp
// Instalar: dotnet add package NWebsec.AspNetCore.Middleware
// O usar configuración manual

// Program.cs — headers de seguridad
app.Use(async (context, next) =>
{
    // Prevenir clickjacking
    context.Response.Headers.Append("X-Frame-Options", "DENY");

    // Prevenir MIME sniffing
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");

    // Forzar HTTPS
    context.Response.Headers.Append(
        "Strict-Transport-Security",
        "max-age=31536000; includeSubDomains"
    );

    // Content Security Policy
    context.Response.Headers.Append(
        "Content-Security-Policy",
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';"
    );

    // Referrer Policy
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");

    // Permissions Policy
    context.Response.Headers.Append(
        "Permissions-Policy",
        "geolocation=(), microphone=(), camera=()"
    );

    await next();
});

// CORS — solo orígenes permitidos
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
                builder.Configuration["AllowedOrigins"]?.Split(',') ?? Array.Empty<string>()
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials(); // para cookies HttpOnly
    });
});

app.UseCors("AllowFrontend");
```

---

## Manejo de secretos — variables de entorno

```csharp
// appsettings.json — solo estructura, SIN valores sensibles
{
  "Jwt": {
    "Issuer": "",
    "Audience": "",
    "Secret": ""   // valor en variable de entorno
  },
  "ConnectionStrings": {
    "DefaultConnection": ""   // valor en variable de entorno
  }
}

// appsettings.Development.json — valores de desarrollo (no subir a git)
// Agregar a .gitignore: appsettings.Development.json

// Program.cs — validar que los secretos están configurados
var jwtSecret = builder.Configuration["Jwt:Secret"];
if (string.IsNullOrEmpty(jwtSecret) || jwtSecret.Length < 32)
    throw new InvalidOperationException("Jwt:Secret no configurado o demasiado corto (mínimo 32 caracteres)");

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrEmpty(connectionString))
    throw new InvalidOperationException("ConnectionStrings:DefaultConnection no configurado");

// User Secrets para desarrollo local (no se sube a git)
// dotnet user-secrets init
// dotnet user-secrets set "Jwt:Secret" "mi-secreto-de-desarrollo-32-chars"
// dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=..."

// En producción — variables de entorno del sistema o Azure Key Vault
// Azure Key Vault (producción):
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/"),
    new DefaultAzureCredential()
);
```

---

## Autorización basada en roles

```csharp
// Definir política de autorización
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole(UserRole.Admin.ToString()));

    options.AddPolicy("ManagerOrAdmin", policy =>
        policy.RequireRole(UserRole.Admin.ToString(), UserRole.Manager.ToString()));

    options.AddPolicy("AnyAuthenticatedUser", policy =>
        policy.RequireAuthenticatedUser());
});

// En controllers — aplicar por acción o por clase
[ApiController]
[Route("api/v1/[controller]")]
[Authorize] // requiere autenticación en todo el controller
public class ContractsController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() { } // cualquier usuario autenticado

    [HttpPost]
    [Authorize(Policy = "ManagerOrAdmin")] // solo managers y admins
    public async Task<IActionResult> Create([FromBody] CreateContractDto dto) { }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "AdminOnly")] // solo admins
    public async Task<IActionResult> Delete(Guid id) { }
}

// Verificar pertenencia del recurso en el service
public async Task<ContractResponseDto> GetByIdAsync(Guid id, Guid requestingUserId, string requestingUserRole)
{
    var contract = await _contractRepository.GetByIdAsync(id);
    if (contract == null)
        throw new NotFoundException("Contrato no encontrado");

    // Verificar pertenencia — no solo autenticación
    var isOwner = contract.UserId == requestingUserId;
    var isAdminOrManager = requestingUserRole is "Admin" or "Manager";

    if (!isOwner && !isAdminOrManager)
        throw new NotFoundException("Contrato no encontrado"); // no revelar que existe
}
```

---

## Logging de seguridad con Serilog

```csharp
// Instalar: dotnet add package Serilog.AspNetCore

// Program.cs
builder.Host.UseSerilog((context, config) =>
{
    config
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithEnvironmentName()
        .WriteTo.Console(outputTemplate:
            "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
        .WriteTo.File(
            "logs/security-.log",
            rollingInterval: RollingInterval.Day,
            retainedFileCountLimit: 30
        );
});

// SecurityAuditService — eventos de seguridad obligatorios
public class SecurityAuditService
{
    private readonly ILogger<SecurityAuditService> _logger;

    public void LogLoginSuccess(Guid userId, string ip)
        => _logger.LogInformation(
            "SECURITY|LOGIN_SUCCESS UserId={UserId} IP={IP}", userId, ip);

    public void LogLoginFailure(string email, string ip, string reason)
        => _logger.LogWarning(
            "SECURITY|LOGIN_FAILURE Email={Email} IP={IP} Reason={Reason}",
            email, ip, reason);
        // NUNCA loggear la contraseña

    public void LogUserLocked(Guid userId, string ip)
        => _logger.LogWarning(
            "SECURITY|ACCOUNT_LOCKED UserId={UserId} IP={IP}", userId, ip);

    public void LogPermissionDenied(Guid userId, string resource, string action)
        => _logger.LogWarning(
            "SECURITY|PERMISSION_DENIED UserId={UserId} Resource={Resource} Action={Action}",
            userId, resource, action);

    public void LogPasswordChanged(Guid userId)
        => _logger.LogInformation(
            "SECURITY|PASSWORD_CHANGED UserId={UserId}", userId);

    public void LogTokenExpired(Guid userId)
        => _logger.LogInformation(
            "SECURITY|TOKEN_EXPIRED UserId={UserId}", userId);
}
```

---

## Manejo seguro de archivos

```csharp
[HttpPost("upload")]
public async Task<IActionResult> Upload(IFormFile file)
{
    // Validar tamaño
    const long MaxFileSize = 5 * 1024 * 1024; // 5MB
    if (file.Length > MaxFileSize)
        return BadRequest(ApiResponse.Error("El archivo no puede superar 5MB"));

    // Validar tipo por extensión Y por contenido (MIME sniffing)
    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".pdf" };
    var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

    if (!allowedExtensions.Contains(extension))
        return BadRequest(ApiResponse.Error("Tipo de archivo no permitido"));

    // Validar contenido real del archivo (no confiar solo en la extensión)
    var allowedMimeTypes = new[] { "image/jpeg", "image/png", "application/pdf" };
    if (!allowedMimeTypes.Contains(file.ContentType))
        return BadRequest(ApiResponse.Error("Tipo de archivo no válido"));

    // Generar nombre seguro — NUNCA usar el nombre original del usuario
    var safeFilename = $"{Guid.NewGuid()}{extension}";
    var uploadPath = Path.Combine(_config["UploadPath"]!, safeFilename);

    // Verificar que el path no sale del directorio permitido (path traversal)
    var fullPath = Path.GetFullPath(uploadPath);
    var basePath = Path.GetFullPath(_config["UploadPath"]!);
    if (!fullPath.StartsWith(basePath))
        return BadRequest(ApiResponse.Error("Ruta de archivo inválida"));

    using var stream = new FileStream(fullPath, FileMode.Create);
    await file.CopyToAsync(stream);

    return Ok(ApiResponse<string>.Success(safeFilename));
}
```

---

## Checklist seguridad .NET antes de PR

### SQL y datos
- [ ] Sin concatenación en queries raw (usar FromSqlInterpolated o parámetros)
- [ ] EF Core usado correctamente (no raw strings con variables)
- [ ] Soft delete implementado (no DELETE físico)

### Autenticación
- [ ] Contraseñas con BCrypt (work factor >= 12)
- [ ] JWT con expiración (8h access, 30d refresh)
- [ ] Secreto JWT en variables de entorno (mínimo 32 caracteres)
- [ ] Rate limiting en endpoints de auth con [EnableRateLimiting]
- [ ] Bloqueo por intentos fallidos implementado

### Autorización
- [ ] [Authorize] en todos los controllers/acciones que lo requieren
- [ ] Pertenencia de recursos verificada en el service (no solo autenticación)
- [ ] Mensajes de error genéricos cuando se deniega acceso (no revelar existencia)

### Configuración
- [ ] Headers de seguridad configurados (X-Frame-Options, CSP, HSTS)
- [ ] CORS con origins específicos (no AllowAnyOrigin)
- [ ] Secretos en variables de entorno o Azure Key Vault
- [ ] Sin secretos en appsettings.json comiteado

### Archivos
- [ ] Validación de tamaño máximo
- [ ] Validación de tipo por extensión Y ContentType
- [ ] Nombre de archivo generado internamente (UUID + extensión)
- [ ] Verificación de path traversal

### Logging
- [ ] Eventos de seguridad loggeados (login, permisos denegados, bloqueos)
- [ ] Sin datos sensibles en logs (no passwords, no tokens completos)
- [ ] Stack traces solo en logs (nunca en respuestas al cliente)
