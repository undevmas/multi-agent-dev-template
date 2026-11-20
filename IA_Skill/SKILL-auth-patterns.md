# SKILL — Patrones de Autenticación y Autorización

## Cuándo usar esta skill
Antes de diseñar, implementar o revisar autenticación/autorización en un proyecto
nuevo o al agregar auth a uno existente (.NET 10 o NestJS, con SPA Angular/React).
Complementa — no reemplaza — a `SKILL-security-dotnet.md`, `SKILL-security-nestjs.md`
y `SKILL-security-angular.md`.

**Regla 1:** elegir UN perfil por proyecto y registrarlo en `IA_Memoria/arquitectura.md`
(campo **Autenticación**, ej. `Perfil A — OIDC + BFF (IdP: Keycloak)`). Si el campo
está vacío o en `[COMPLETAR]`, **preguntar al dev antes de implementar auth**.

### Tabla de decisión

| Pregunta | Si la respuesta es "sí" |
|---|---|
| ¿Hay SSO corporativo (Entra ID, Keycloak existente)? | Perfil A |
| ¿Más de una API o microservicio consume la identidad del usuario? | Perfil A |
| ¿Es multi-tenant? | Perfil A |
| ¿Clientes de terceros o apps móviles deben validar los tokens? | Perfil A |
| Ninguna de las anteriores: una API + una SPA, desarrollo rápido | Perfil B |

| Perfil | Stack |
|---|---|
| **A — Empresarial / microservicios / multi-tenant** | OAuth 2.1 / OpenID Connect (Authorization Code + PKCE) · access tokens JWT validados en cada API (Authority/JWKS) · patrón BFF para la SPA · IdP: Entra ID / Keycloak / OpenIddict |
| **B — API monolítica / desarrollo rápido .NET 10** | ASP.NET Core Identity con Identity API endpoints · cookie HttpOnly (SPA mismo sitio) o bearer token (clientes no-navegador) · autorización por políticas |

### Reglas transversales (ambos perfiles)
- Nunca guardar tokens en `localStorage` ni `sessionStorage`. Nunca tokens en query string.
- OAuth 2.1: PKCE obligatorio; **prohibidos** implicit flow y password grant (ROPC);
  redirect URIs registradas con coincidencia exacta; rotación de refresh tokens.
- Denegar por defecto: fallback policy `RequireAuthenticatedUser`. Solo login,
  callbacks OIDC y health checks llevan `AllowAnonymous`.
- Autorización por políticas/permisos, no por roles hardcodeados dispersos.
- Secretos (`ClientSecret`, cadenas de conexión) en variables de entorno / user-secrets /
  Key Vault — nunca en `appsettings.json` comiteado. Modificar `appsettings*.json` o
  `.env` requiere confirmación explícita del dev.

---

## Perfil A — OIDC + BFF en .NET 10

Arquitectura: `SPA ──cookie──▶ BFF (.NET) ──Bearer JWT──▶ APIs`. La SPA nunca ve un token;
el BFF hace el Authorization Code + PKCE, guarda los tokens del lado servidor (en el
ticket de la cookie cifrada o en un `ITicketStore`) y los adjunta al proxy hacia las APIs.
SPA y BFF deben compartir origen: el BFF sirve el build de la SPA (`MapFallbackToFile`)
o ambos van detrás del mismo reverse proxy. En dev, usar el proxy de Angular/Vite hacia el BFF.

### (a) BFF: cookie + OpenID Connect + YARP

```csharp
// Paquetes: Microsoft.AspNetCore.Authentication.OpenIdConnect, Yarp.ReverseProxy
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    // Challenge por cookie → 401 para fetch; el login OIDC es explícito en /bff/login
    options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie(options =>
{
    options.Cookie.Name = "__Host-bff";               // __Host- exige Secure + Path=/ + sin Domain
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;    // Lax solo si hay deep links externos que requieren sesión
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;
    options.Events.OnRedirectToLogin = ctx => { ctx.Response.StatusCode = 401; return Task.CompletedTask; };
    options.Events.OnRedirectToAccessDenied = ctx => { ctx.Response.StatusCode = 403; return Task.CompletedTask; };
})
.AddOpenIdConnect(OpenIdConnectDefaults.AuthenticationScheme, options =>
{
    options.Authority = builder.Configuration["Auth:Authority"];   // Keycloak: https://<host>/realms/<realm>
    options.ClientId = builder.Configuration["Auth:ClientId"];
    options.ClientSecret = builder.Configuration["Auth:ClientSecret"]; // variable de entorno, nunca en appsettings
    options.ResponseType = OpenIdConnectResponseType.Code;
    options.UsePkce = true;
    options.SaveTokens = true;                 // tokens en el ticket del servidor, no en la SPA
    options.MapInboundClaims = false;          // conservar "sub", "roles", "tid" sin renombrar
    options.GetClaimsFromUserInfoEndpoint = true;
    options.Scope.Clear();
    foreach (var scope in new[] { "openid", "profile", "offline_access", builder.Configuration["Auth:ApiScope"]! })
        options.Scope.Add(scope);
    options.TokenValidationParameters.NameClaimType = "name";
    options.TokenValidationParameters.RoleClaimType = "roles";
});

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy")) // rutas /api/** → APIs internas
    .AddTransforms(ctx => ctx.AddRequestTransform(async transform =>
    {
        transform.ProxyRequest.Headers.Remove("Cookie"); // la cookie del BFF no viaja a las APIs
        var token = await transform.HttpContext.GetTokenAsync("access_token");
        if (token is not null)
            transform.ProxyRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }));
```

```csharp
// Anti-CSRF: header custom obligatorio en /api y /bff (fuerza preflight CORS en cross-site)
app.UseAuthentication();
app.UseAuthorization();
app.Use(async (ctx, next) =>
{
    var path = ctx.Request.Path;
    var needsHeader = path.StartsWithSegments("/api") || path.StartsWithSegments("/bff/user")
                      || path.StartsWithSegments("/bff/logout");
    if (needsHeader && ctx.Request.Headers["X-CSRF"] != "1")
    {
        ctx.Response.StatusCode = StatusCodes.Status403Forbidden;
        return;
    }
    await next();
});

var bff = app.MapGroup("/bff");

bff.MapGet("/login", (string? returnUrl) =>
    Results.Challenge(new AuthenticationProperties { RedirectUri = SafeReturnUrl(returnUrl) },
                      [OpenIdConnectDefaults.AuthenticationScheme]))
   .AllowAnonymous();

// Respuesta: envolver en el formato estándar del proyecto (IA_Memoria/convenciones.md)
bff.MapGet("/user", (ClaimsPrincipal user) => user.Identity?.IsAuthenticated == true
    ? Results.Ok(new { isAuthenticated = true, sub = user.FindFirstValue("sub"),
                       name = user.FindFirstValue("name"),
                       permissions = user.FindAll("permission").Select(c => c.Value) })
    : Results.Ok(new { isAuthenticated = false }))
   .AllowAnonymous();

// POST + X-CSRF: cierra la sesión local y devuelve la URL de logout del IdP
bff.MapPost("/logout", async (HttpContext ctx, IConfiguration config,
                              IOptionsMonitor<OpenIdConnectOptions> oidcOptions) =>
{
    var idToken = await ctx.GetTokenAsync("id_token");
    await ctx.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

    var oidc = oidcOptions.Get(OpenIdConnectDefaults.AuthenticationScheme);
    var discovery = await oidc.ConfigurationManager!.GetConfigurationAsync(ctx.RequestAborted); // (verificar contra la versión instalada)
    var logoutUrl = QueryHelpers.AddQueryString(discovery.EndSessionEndpoint, new Dictionary<string, string?>
    {
        ["id_token_hint"] = idToken,
        ["post_logout_redirect_uri"] = config["Auth:PostLogoutRedirectUri"], // de config, nunca del Host header
    });
    return Results.Ok(new { logoutUrl });
});

app.MapReverseProxy().RequireAuthorization();

// Evitar open redirect: solo rutas locales
static string SafeReturnUrl(string? url) =>
    !string.IsNullOrEmpty(url) && url.StartsWith('/') && !url.StartsWith("//") && !url.StartsWith("/\\")
        ? url : "/";
```

**Refresco de tokens:** el access token expira antes que la cookie. Opciones:
- `Duende.AccessTokenManagement.OpenIdConnect` — refresca y rota automáticamente
  (`AddOpenIdConnectAccessTokenManagement()` + `GetUserAccessTokenAsync()`, verificar contra
  la versión instalada). Licencia OSS a la fecha — confirmar licencia y pasar por
  `SKILL-approved-libraries.md` antes de instalar.
- **`Duende.BFF` requiere licencia comercial → no usar sin aprobación explícita.**
- Para Entra ID: `AddMicrosoftIdentityWebApp(...).EnableTokenAcquisitionToCallDownstreamApi()`
  + caché de tokens distribuida resuelve login y refresco sin código manual.
- Si la cookie crece demasiado (tokens grandes de Entra), usar `options.SessionStore`
  (`ITicketStore`) respaldado por caché distribuida.

### (b) API como resource server

```csharp
// Keycloak / OpenIddict / cualquier IdP OIDC
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"]; // JWKS se descubre vía .well-known
        options.Audience = builder.Configuration["Auth:Audience"];   // la API rechaza tokens de otra audiencia
        options.MapInboundClaims = false;
        options.TokenValidationParameters.ValidateIssuer = true;
        options.TokenValidationParameters.ValidateLifetime = true;
        options.TokenValidationParameters.ValidAlgorithms = [SecurityAlgorithms.RsaSha256];
        options.TokenValidationParameters.ClockSkew = TimeSpan.FromSeconds(30);
        options.TokenValidationParameters.RoleClaimType = "roles";
    });

// Entra ID (Microsoft.Identity.Web) — valida issuer/audiencia/firma con la sección "AzureAd"
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));
```

Nunca `IssuerSigningKey = new SymmetricSecurityKey(...)` con secreto compartido entre servicios:
las APIs validan con las claves públicas del IdP.

### (c) Elección de IdP

| IdP | Cuándo | Notas |
|---|---|---|
| **Entra ID** | Organización en Microsoft 365 / Azure | Dos app registrations (BFF web + API que expone `api://<id>/access_as_user`). App roles → claim `roles`. Usar `Microsoft.Identity.Web`. |
| **Keycloak** | Self-hosted, multi-cliente, sin Microsoft 365 | Authority `https://<host>/realms/<realm>`. Cliente confidencial para el BFF con PKCE S256 requerido. Agregar *audience mapper* (por defecto `aud` = `account`). Los roles vienen anidados en `realm_access.roles` → mapper "User Realm Role" a claim plano `roles` o `IClaimsTransformation`. |
| **OpenIddict** | Solo si no hay IdP corporativo y se necesita servidor OIDC propio en .NET | Habilitar solo code + PKCE + refresh (`AllowAuthorizationCodeFlow().RequireProofKeyForCodeExchange()`, `AllowRefreshTokenFlow()` — verificar contra la versión instalada). Stores en EF Core. Es un componente crítico: requiere aprobación de arquitectura. |

### (d) Multi-tenant

- Fuente del tenant: claim del token (`tid` en Entra; claim `tenant_id` vía mapper en Keycloak,
  o un realm por tenant). **Nunca** tomar el tenant de un header/query enviado por el cliente.
- Issuer por tenant: Entra multi-tenant (`/organizations/v2.0`) → `Microsoft.Identity.Web` valida
  el issuer por tenant; además restringir a una lista blanca de `tid` permitidos (política).
  Keycloak con realm por tenant → `ValidIssuers` con la lista blanca de realms (verificar
  resolución de claves por issuer); un solo realm + claim `tenant_id` es más simple.
- Aislamiento de datos: filtro global de EF Core por `TenantId`.

```csharp
public sealed class ClaimsTenantProvider(IHttpContextAccessor accessor) : ITenantProvider
{
    public Guid TenantId =>
        Guid.TryParse(accessor.HttpContext?.User.FindFirstValue("tid"), out var id)
            ? id : throw new UnauthorizedAccessException("Token sin tenant");
}

public class AppDbContext(DbContextOptions<AppDbContext> options, ITenantProvider tenant) : DbContext(options)
{
    private readonly Guid _tenantId = tenant.TenantId;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // EF Core 10: filtros con nombre — permiten combinar tenant + soft delete (verificar contra la versión instalada).
        // En EF Core < 10 un segundo HasQueryFilter REEMPLAZA al primero: combinar ambas condiciones en uno solo.
        modelBuilder.Entity<Contract>()
            .HasQueryFilter("Tenant", c => c.TenantId == _tenantId)
            .HasQueryFilter("SoftDelete", c => c.IsActive);
    }
}
```

---

## SPA con BFF (Angular y React)

- Sin interceptor de `Authorization: Bearer` — la cookie viaja sola (mismo origen).
- Todas las llamadas a `/api` y `/bff` llevan el header `X-CSRF: 1`, solo hacia el propio origen.
- Login = navegación completa a `/bff/login?returnUrl=...`. Logout = `POST /bff/logout` con
  `X-CSRF` y luego navegar a la `logoutUrl` devuelta. Estado del usuario desde `/bff/user`.
- 401 en cualquier llamada → sesión expirada → redirigir a `/bff/login`.

```typescript
// Angular — app.config.ts: provideHttpClient(withInterceptors([bffCsrfInterceptor]))
export const bffCsrfInterceptor: HttpInterceptorFn = (req, next) =>
  req.url.startsWith('/') // solo mismo origen; nunca a terceros
    ? next(req.clone({ setHeaders: { 'X-CSRF': '1' } }))
    : next(req);

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  readonly user = signal<BffUser | null>(null);

  async loadUser(): Promise<void> {
    const res = await firstValueFrom(this.http.get<BffUser>('/bff/user'));
    this.user.set(res.isAuthenticated ? res : null);
  }

  login(returnUrl = location.pathname): void {
    location.href = `/bff/login?returnUrl=${encodeURIComponent(returnUrl)}`;
  }

  async logout(): Promise<void> {
    const { logoutUrl } = await firstValueFrom(this.http.post<{ logoutUrl: string }>('/bff/logout', null));
    location.href = logoutUrl;
  }
}
```

```typescript
// React — wrapper de fetch
export async function bffFetch(input: string, init: RequestInit = {}): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set('X-CSRF', '1');
  const res = await fetch(input, { ...init, headers, credentials: 'same-origin' });
  if (res.status === 401) {
    window.location.href = `/bff/login?returnUrl=${encodeURIComponent(window.location.pathname)}`;
  }
  return res;
}
```

---

## Perfil B — ASP.NET Core Identity API endpoints (.NET 10)

```csharp
// IDs GUID por regla del proyecto
public class AppUser : IdentityUser<Guid> { }
public class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>(options) { }

builder.Services.AddIdentityApiEndpoints<AppUser>(options =>
{
    options.Password.RequiredLength = 12;
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = true;
    options.Lockout.AllowedForNewUsers = true;
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
})
.AddRoles<IdentityRole<Guid>>()
.AddEntityFrameworkStores<AppDbContext>();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;
});

// Bearer (clientes no-navegador): expiraciones cortas (verificar contra la versión instalada)
builder.Services.Configure<BearerTokenOptions>(IdentityConstants.BearerScheme, o =>
{
    o.BearerTokenExpiration = TimeSpan.FromMinutes(15);
    o.RefreshTokenExpiration = TimeSpan.FromDays(7);
});

builder.Services.AddTransient<IEmailSender<AppUser>, SmtpIdentityEmailSender>(); // sin esto, no se envían correos

app.MapGroup("/api/auth").MapIdentityApi<AppUser>();
```

Endpoints que expone `MapIdentityApi`: `POST /register`, `POST /login`
(`?useCookies=true` para SPA mismo sitio), `POST /refresh`, `GET /confirmEmail`,
`POST /resendConfirmationEmail`, `POST /forgotPassword`, `POST /resetPassword`,
`POST /manage/2fa`, `GET|POST /manage/info`.

**Advertencias:**
- **`MapIdentityApi` expone `/register` públicamente.** Si el negocio no permite
  auto-registro, no mapearlo tal cual: escribir endpoints propios con `UserManager`/
  `SignInManager`, o bloquear la ruta con un endpoint filter en el grupo (devolver 404).
- Los bearer tokens de Identity son **opacos/propietarios (no JWT)**: solo los valida la
  misma app. Si terceros o microservicios deben validarlos → es Perfil A.
- Identity ya hace hashing (PBKDF2) y lockout (`options.Lockout`). La regla BCrypt de
  `SKILL-security-dotnet.md` aplica solo a auth propia heredada, no a Identity.
- Con cookies, la protección CSRF sigue siendo obligatoria: `SameSite=Strict` + header
  custom o antiforgery en requests que cambian estado.
- Rate limiting en `/api/auth/*` (ver `SKILL-security-dotnet.md`).

---

## Autorización por políticas (común a A y B)

```csharp
public static class Permissions
{
    public const string ContractsRead = "contracts:read";
    public const string ContractsWrite = "contracts:write";
    public const string ContractsAdmin = "contracts:admin";
}

builder.Services.AddAuthorizationBuilder()
    .AddPolicy(Permissions.ContractsRead, p => p.RequireClaim("permission", Permissions.ContractsRead))
    .AddPolicy(Permissions.ContractsWrite, p => p.RequireClaim("permission", Permissions.ContractsWrite))
    .SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build());

builder.Services.AddSingleton<IAuthorizationHandler, ContractOwnerHandler>();

// Minimal APIs
app.MapGroup("/api/v1/contracts").RequireAuthorization(Permissions.ContractsRead);
app.MapHealthChecks("/health").AllowAnonymous();

// Controllers
[HttpPost]
[Authorize(Policy = Permissions.ContractsWrite)]
public async Task<IActionResult> Create([FromBody] CreateContractDto dto) { /* ... */ }
```

Resource-based (pertenencia del recurso):

```csharp
public sealed class ContractOwnerRequirement : IAuthorizationRequirement;

public sealed class ContractOwnerHandler : AuthorizationHandler<ContractOwnerRequirement, Contract>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context, ContractOwnerRequirement requirement, Contract resource)
    {
        // Perfil A: "sub" (MapInboundClaims = false). Perfil B: ClaimTypes.NameIdentifier.
        var userId = context.User.FindFirstValue("sub") ?? context.User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (resource.UserId.ToString() == userId || context.User.HasClaim("permission", Permissions.ContractsAdmin))
            context.Succeed(requirement);
        return Task.CompletedTask;
    }
}

// En el service
var result = await _authorizationService.AuthorizeAsync(user, contract, new ContractOwnerRequirement());
if (!result.Succeeded)
    throw new NotFoundException("Contrato no encontrado"); // 404: no revelar que existe
```

---

## NestJS

- **Perfil B:** JWT propio, access token en memoria + refresh token en cookie HttpOnly →
  seguir `SKILL-security-nestjs.md` (no se duplica aquí).
- **Perfil A:** la API valida el JWT del IdP contra su JWKS. Instalar `passport-jwt` +
  `jwks-rsa` (o `jose`) **requiere confirmación del dev**.

```typescript
@Injectable()
export class OidcJwtStrategy extends PassportStrategy(Strategy, 'oidc-jwt') {
  constructor(config: ConfigService) {
    const issuer = config.getOrThrow<string>('AUTH_ISSUER'); // https://<host>/realms/<realm>
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 10,
        jwksUri: config.getOrThrow<string>('AUTH_JWKS_URI'), // jwks_uri del .well-known/openid-configuration
      }),
      issuer,
      audience: config.getOrThrow<string>('AUTH_AUDIENCE'),
      algorithms: ['RS256'],
    });
  }

  validate(payload: OidcPayload): AuthUser {
    return { userId: payload.sub, tenantId: payload.tenant_id, permissions: payload.permissions ?? [] };
  }
}
```

Registrar el guard como `APP_GUARD` global con decorador `@Public()` para las excepciones
(mismo patrón deny-by-default de `SKILL-security-nestjs.md`).

---

## Antipatrones

| Antipatrón | Por qué | Correcto |
|---|---|---|
| Tokens en `localStorage`/`sessionStorage` | Cualquier XSS los roba | BFF (A) o cookie HttpOnly (B) |
| Implicit flow / password grant (ROPC) | Eliminados en OAuth 2.1 | Authorization Code + PKCE |
| JWT HS256 con secreto compartido entre microservicios | Cualquier servicio puede emitir tokens válidos | RS256/ES256 firmados por el IdP, validación vía JWKS |
| Validar solo la firma, sin `aud`/`iss`/`exp` | Tokens de otra app o expirados pasan | `Authority` + `Audience` + `ValidateLifetime` |
| Roles hardcodeados dispersos (`[Authorize(Roles = "Admin")]` en todos lados) | Cambiar permisos exige tocar código en N lugares | Políticas por permiso centralizadas |
| Tenant leído de header o query del cliente | Escalamiento entre tenants | Tenant desde el claim del token + filtro global |
| `returnUrl` sin validar en login | Open redirect | Solo rutas locales (`SafeReturnUrl`) |
| Scalar / Swagger UI / Redoc sin auth en producción | Expone el contrato completo de la API | Deshabilitar en prod o proteger con política |

---

## Checklist de autenticación antes de PR

- [ ] Perfil (A o B) registrado en `IA_Memoria/arquitectura.md` → campo Autenticación
- [ ] Ningún token en `localStorage`/`sessionStorage` ni en query string
- [ ] Perfil A: Authorization Code + PKCE; sin implicit ni ROPC; redirect URIs exactas en el IdP
- [ ] Perfil A: cada API valida `Authority`/JWKS + `Audience` + lifetime; sin clave simétrica
- [ ] Perfil A: cookie del BFF `__Host-`, HttpOnly, Secure, SameSite; header `X-CSRF` exigido
- [ ] Perfil A: refresh tokens con rotación; logout cierra sesión local y en el IdP
- [ ] Perfil B: `/register` deshabilitado si no hay auto-registro; lockout y confirmación de email configurados
- [ ] Fallback policy `RequireAuthenticatedUser`; `AllowAnonymous` solo en login, callbacks OIDC y health
- [ ] Autorización por políticas/permisos; pertenencia de recursos con `AuthorizationHandler` (404 al denegar)
- [ ] Multi-tenant: tenant desde el token, lista blanca de tenants/issuers, filtro global por `TenantId`
- [ ] `ClientSecret` y demás secretos fuera de `appsettings.json` comiteado
- [ ] Rate limiting en endpoints de login/refresh
- [ ] UI de documentación de API (Scalar/Swagger UI/Redoc) deshabilitada o protegida en producción
