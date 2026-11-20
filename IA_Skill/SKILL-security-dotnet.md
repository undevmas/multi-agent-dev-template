# SKILL — Security .NET

## Cuándo usar esta skill
Al crear o revisar cualquier endpoint, service, middleware o configuración
en el proyecto .NET (LTS vigente — hoy .NET 10) que maneje autenticación,
autorización, datos del usuario, archivos, o información sensible.

> **Autenticación:** el patrón (perfil A — OIDC + PKCE + BFF, o perfil B —
> ASP.NET Core Identity API endpoints) se decide y se implementa con
> `IA_Skill/SKILL-auth-patterns.md`. Esta skill cubre el endurecimiento
> transversal (inyección, secretos, headers, rate limiting, archivos, logging)
> y el mantenimiento de auth propia heredada.

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

### Dapper (lado de lectura en perfil CQRS)

Dapper ejecuta el SQL tal cual lo recibe — la parametrización es responsabilidad del código:

```csharp
// MAL — interpolación directa: SQL injection
var sql = $"SELECT Id, Title FROM Contracts WHERE Status = '{status}' AND IsActive = 1";
var rows = await connection.QueryAsync<ContractListItem>(sql);

// BIEN — parámetros con objeto anónimo
const string sql = """
    SELECT Id, Title, Status
    FROM Contracts
    WHERE Status = @Status AND UserId = @UserId AND IsActive = 1
    """;
var rows = await connection.QueryAsync<ContractListItem>(sql, new { Status = status, UserId = userId });

// BIEN — ORDER BY dinámico solo contra lista blanca (los parámetros no aplican a nombres de columna)
var allowedSort = new Dictionary<string, string> { ["title"] = "Title", ["created"] = "CreatedAt" };
var orderBy = allowedSort.GetValueOrDefault(sortKey, "CreatedAt");
```

- Toda consulta Dapper filtra `IsActive = 1` explícitamente — los query filters globales de EF Core no aplican aquí.
- Dapper solo lee: escrituras y esquema van por EF Core (ver "Perfiles de acceso a datos" en `IA_Skill/SKILL-stack-policy.md`).

---

## Contraseñas — solo en auth propia heredada

> Con ASP.NET Core Identity (perfil B) el hashing (PBKDF2 vía `PasswordHasher`) y
> el lockout ya vienen incluidos — no reimplementarlos. Con perfil A las
> contraseñas viven en el IdP. Esta sección aplica solo a proyectos existentes
> que ya tienen su propia tabla de usuarios y login.

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

## JWT — validación y emisión

**Proyectos nuevos no emiten JWT propios con clave simétrica.**
- Perfil A: la API es *resource server* y valida los tokens del IdP por discovery/JWKS:

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"]; // Entra ID / Keycloak / OpenIddict
        options.Audience = builder.Configuration["Auth:Audience"];
        options.MapInboundClaims = false;
        options.TokenValidationParameters.ClockSkew = TimeSpan.FromSeconds(30);
    });
```

- Perfil B: Identity API endpoints emiten y validan sus propios tokens — ver `SKILL-auth-patterns.md`.

El bloque siguiente (clave simétrica + emisión propia) aplica **solo a proyectos
existentes** que ya funcionan así. No replicarlo en código nuevo; si hay que
evolucionarlo, registrar la migración a perfil A/B en `IA_Memoria/deuda-tecnica.md`.

```csharp
// Program.cs — configuración JWT (auth propia heredada)
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
// Program.cs — rate limiting nativo de ASP.NET Core (Microsoft.AspNetCore.RateLimiting)
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

## Autorización basada en políticas (Policy-Based)

```csharp
// Políticas por permiso + denegar por defecto (fallback policy)
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("contracts:read", policy => policy.RequireClaim("permission", "contracts:read"))
    .AddPolicy("contracts:write", policy => policy.RequireClaim("permission", "contracts:write"))
    .AddPolicy("contracts:deactivate", policy => policy.RequireRole("Admin"))
    // Todo endpoint sin [Authorize]/[AllowAnonymous] explícito exige usuario autenticado
    .SetFallbackPolicy(new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build());

// En controllers — la política nombra el permiso, no el rol
[ApiController]
[Route("api/v1/[controller]")]
[Authorize(Policy = "contracts:read")]
public class ContractsController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() { }

    [HttpPost]
    [Authorize(Policy = "contracts:write")]
    public async Task<IActionResult> Create([FromBody] CreateContractDto dto) { }

    [HttpDelete("{id:guid}")] // soft delete — IsActive = 0
    [Authorize(Policy = "contracts:deactivate")]
    public async Task<IActionResult> Deactivate(Guid id) { }
}

// Minimal APIs — mismo criterio
app.MapGroup("/api/v1/contracts")
   .RequireAuthorization("contracts:read");

// Solo login, callbacks OIDC y health checks son anónimos — explícito
app.MapHealthChecks("/health").AllowAnonymous();

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
- [ ] Consultas Dapper 100% parametrizadas, ORDER BY dinámico solo por lista blanca, filtro `IsActive = 1` explícito
- [ ] Soft delete implementado (no DELETE físico)

### Autenticación
- [ ] Perfil de auth (A o B) registrado en `IA_Memoria/arquitectura.md` e implementado según `SKILL-auth-patterns.md`
- [ ] Perfil A: API valida tokens con Authority + Audience del IdP (sin clave simétrica)
- [ ] Perfil B: Identity API endpoints con lockout configurado; `/register` no expuesto si el negocio no permite auto-registro
- [ ] Solo auth propia heredada: contraseñas con BCrypt (work factor >= 12), secreto JWT en variables de entorno (mínimo 32 caracteres), bloqueo por intentos fallidos
- [ ] Rate limiting en endpoints de auth con [EnableRateLimiting]

### Autorización
- [ ] Fallback policy activa (denegar por defecto); `[AllowAnonymous]` solo en login, callbacks OIDC y health checks
- [ ] Políticas por permiso (`[Authorize(Policy = ...)]` / `RequireAuthorization`), no chequeos de rol dispersos
- [ ] Pertenencia de recursos verificada en el service (no solo autenticación)
- [ ] Mensajes de error genéricos cuando se deniega acceso (no revelar existencia)

### Configuración
- [ ] Headers de seguridad configurados (X-Frame-Options, CSP, HSTS)
- [ ] CORS con origins específicos (no AllowAnyOrigin)
- [ ] Secretos en variables de entorno o Azure Key Vault
- [ ] Sin secretos en appsettings.json comiteado
- [ ] Documento OpenAPI y UI (Scalar / Swagger UI / Redoc) solo en Development o protegidos con auth

### Archivos
- [ ] Validación de tamaño máximo
- [ ] Validación de tipo por extensión Y ContentType
- [ ] Nombre de archivo generado internamente (UUID + extensión)
- [ ] Verificación de path traversal

### Logging
- [ ] Eventos de seguridad loggeados (login, permisos denegados, bloqueos)
- [ ] Sin datos sensibles en logs (no passwords, no tokens completos)
- [ ] Stack traces solo en logs (nunca en respuestas al cliente)
