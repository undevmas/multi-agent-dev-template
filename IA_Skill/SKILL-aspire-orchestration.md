# SKILL — Orquestación con Aspire

## Cuándo usar esta skill
Al crear, modificar o revisar el entorno de desarrollo local de una solución con
**2 o más servicios** (API + front + BD, varias APIs, microservicios, cache, IdP).
Leer antes de tocar el `AppHost`, el proyecto `ServiceDefaults` o la forma en que
los servicios se descubren entre sí.

Aspire (antes ".NET Aspire"; desde la versión 13 se llama solo **Aspire** y es
políglota) es el **orquestador de desarrollo local** del stack aprobado
(`Contenedores y orquestación: Docker · Docker Compose · Aspire`):
- `AppHost`: levanta API(s) .NET, front Angular/React (Node), BD (SQL Server /
  PostgreSQL), cache e IdP (Keycloak) en contenedores, en el orden correcto.
- Service discovery e inyección de connection strings / URLs — nada hardcodeado.
- Dashboard con OpenTelemetry (logs estructurados, trazas distribuidas, métricas).
- `ServiceDefaults`: health checks, resiliencia HTTP y OTel en una sola llamada.

### Cuándo NO usarla
- Servicio único (una sola API sin dependencias levantables) — no aporta, no forzarlo.
- Tooling Python de ReporteadorV2 (`Codigo/Reportes/`): sigue con `Dockerfile` +
  `docker-compose.yml` obligatorios (ver CLAUDE.md, sección Python).
- Despliegue a producción: **Docker Compose sigue siendo el artefacto de despliegue
  en VM** (y el de `Tools/`). Aspire no lo reemplaza en producción salvo decisión
  registrada en `IA_Memoria/arquitectura.md`.

---

## Estructura en Codigo/

```
Codigo/[Proyecto]/
└── src/
    ├── [Proyecto].AppHost/          ← orquestación (solo desarrollo local)
    ├── [Proyecto].ServiceDefaults/  ← health checks, resiliencia, OTel compartidos
    ├── [Proyecto].Api/              ← referencia a ServiceDefaults
    ├── [Proyecto].MigrationService/ ← opcional, ver "Migraciones"
    └── [proyecto]-web/              ← Angular / React
```

Al crear o detectar estos proyectos, registrar sus rutas en la sección
"Mapa de rutas por capa" de `IA_Memoria/arquitectura.md` y marcar en
"Infraestructura" que la orquestación local es Aspire.

---

## Setup

Requisitos: SDK de .NET en el **LTS vigente** (hoy .NET 10) y un runtime de
contenedores (Docker Desktop o Podman) corriendo.

```bash
# CLI de Aspire (verificar el método de instalación vigente en la doc oficial)
dotnet tool install -g Aspire.Cli

aspire new                 # plantilla interactiva (AppHost + ServiceDefaults)
aspire add                 # agrega una integración de hosting (sqlserver, postgres, redis, keycloak...)
aspire run                 # levanta todo y abre el dashboard (URL con token en consola)
```

- `AppHost` y paquetes `Aspire.*` en la **última versión estable**, todos en la
  misma versión. Verificar contra la fuente oficial antes de fijar versión
  (`SKILL-web-search.md`), no asumir de memoria.
- Agregar integraciones nuevas (`aspire add`, paquetes `Aspire.Hosting.*` /
  `Aspire.*`) que impliquen tecnología fuera del stack requiere confirmación
  explícita del dev (`SKILL-approved-libraries.md`).

---

## AppHost de ejemplo

```csharp
// [Proyecto].AppHost/AppHost.cs
var builder = DistributedApplication.CreateBuilder(args);

// Secretos como parámetros — se resuelven desde user-secrets del AppHost
// o variables de entorno (Parameters__sql-password). NUNCA literales aquí.
var sqlPassword = builder.AddParameter("sql-password", secret: true);

// Base de datos (SQL Server). Para PostgreSQL: builder.AddPostgres("pg")
var sql = builder.AddSqlServer("sql", password: sqlPassword)
    .WithDataVolume();                 // persiste datos entre reinicios
var db = sql.AddDatabase("appdb");     // nombre lógico = nombre de la connection string

// Cache opcional
var cache = builder.AddRedis("cache");

// IdP local opcional — solo si el proyecto es Perfil A (ver SKILL-auth-patterns.md)
var keycloak = builder.AddKeycloak("keycloak", port: 8080) // puerto fijo: el issuer y los redirect URIs deben ser estables
    .WithDataVolume()
    .WithRealmImport("./realms");      // realm exportado y versionado, sin secretos reales

// API .NET
var api = builder.AddProject<Projects.MiProyecto_Api>("api")
    .WithReference(db).WaitFor(db)
    .WithReference(cache)
    .WithReference(keycloak).WaitFor(keycloak)
    .WithHttpHealthCheck("/health");

// Front JS (Angular / React)
// Aspire 13: integración Aspire.Hosting.JavaScript → AddJavaScriptApp / AddViteApp
// Aspire 9.x: Aspire.Hosting.NodeJs → AddNpmApp
// (verificar contra la versión instalada)
builder.AddJavaScriptApp("web", "../miproyecto-web", "start")
    .WithReference(api).WaitFor(api)
    .WithEnvironment("API_URL", api.GetEndpoint("https")) // la consume el proxy del dev server
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints();

builder.Build().Run();
```

Valores de parámetros en desarrollo (no se versionan):

```bash
cd src/MiProyecto.AppHost
dotnet user-secrets set "Parameters:sql-password" "<valor-local>"
```

Reglas del AppHost:
- Sin connection strings, contraseñas ni URLs absolutas literales — todo vía
  `WithReference`, `GetEndpoint` o `AddParameter(..., secret: true)`.
- Usar `WaitFor` en toda dependencia que deba estar lista antes de arrancar.
- Para React con Vite, `AddViteApp("web", "../miproyecto-web")` ya configura el
  endpoint (verificar contra la versión instalada). Para Angular, el script
  `start` debe respetar el puerto inyectado (`PORT`) o usar
  `WithHttpEndpoint(targetPort: 4200)` y dejar que Aspire haga de proxy.

---

## Consumo desde la API

```csharp
// [Proyecto].Api/Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults(); // OTel, health checks, service discovery, resiliencia HTTP

// Integración cliente de EF Core — toma la connection string "appdb" inyectada por el AppHost
builder.AddSqlServerDbContext<AppDbContext>("appdb");    // Aspire.Microsoft.EntityFrameworkCore.SqlServer
// builder.AddNpgsqlDbContext<AppDbContext>("appdb");    // Aspire.Npgsql.EntityFrameworkCore.PostgreSQL

builder.AddRedisDistributedCache("cache");               // si se usa cache

var app = builder.Build();

app.MapDefaultEndpoints(); // /health y /alive
// ... resto del pipeline (auth, endpoints, OpenAPI)
app.Run();
```

- Alternativa sin integración cliente: `builder.Configuration.GetConnectionString("appdb")`
  con el `AddDbContext` habitual — la cadena la inyecta igual el AppHost.
- La plantilla de `ServiceDefaults` mapea los health endpoints **solo en
  Development**. Exponerlos en producción es una decisión explícita (y deben ir
  protegidos o limitados a la red interna).
- Fuera de Aspire (VM con Docker Compose), la API recibe las mismas claves
  (`ConnectionStrings__appdb`, etc.) desde variables de entorno — no cambia el código.

### Front: URL de la API sin hardcodear
El front llama a rutas relativas (`/api/...`) y el dev server hace proxy hacia la
URL que inyecta el AppHost en `API_URL`. Mismo origen en desarrollo, coherente con
el patrón BFF.

```js
// Angular — proxy.conf.js (referenciado en angular.json → serve.options.proxyConfig)
module.exports = {
  '/api': { target: process.env.API_URL, secure: false, changeOrigin: true },
};
```

```ts
// React + Vite — vite.config.ts
export default defineConfig({
  server: {
    proxy: { '/api': { target: process.env.API_URL, secure: false, changeOrigin: true } },
  },
});
```

---

## Dashboard y observabilidad

`aspire run` imprime la URL del dashboard (con token de login). Revisar ahí:
- **Resources**: estado de cada recurso, endpoints, variables de entorno inyectadas
  (útil para depurar connection strings sin abrir archivos de entorno).
- **Console / Structured logs**: logs por servicio con sus propiedades.
- **Traces**: la llamada front → API → BD como una sola traza; primer lugar donde
  buscar latencias o errores entre servicios.
- **Metrics**: requests, errores, GC, pool de conexiones.

OTel ya viene configurado por `ServiceDefaults` — no agregar otro exporter ni
instrumentación duplicada. Respetar las reglas de logging de las skills de
seguridad: sin contraseñas, tokens ni PII en logs ni en atributos de trazas.

---

## Migraciones de EF Core con Aspire

Las reglas de migraciones no cambian — ver `SKILL-database-migrations.md`.
Dos formas válidas de aplicarlas en local:

1. **Servicio de migraciones (recomendado en soluciones multi-servicio):** un
   worker que aplica `Database.MigrateAsync()` al arrancar y termina.
   ```csharp
   var migrations = builder.AddProject<Projects.MiProyecto_MigrationService>("migrations")
       .WithReference(db).WaitFor(db);

   api.WaitForCompletion(migrations); // la API arranca cuando las migraciones terminaron
   ```
2. **`dotnet ef` contra la BD levantada:** copiar la connection string desde el
   dashboard (Resources → appdb) y ejecutar los comandos de
   `SKILL-database-migrations.md`.

El servicio de migraciones es solo para desarrollo/local. En producción las
migraciones se aplican con el script idempotente revisado, como siempre.

---

## Tests de integración y E2E

```csharp
// tests/MiProyecto.IntegrationTests — paquete Aspire.Hosting.Testing + xUnit
public class ApiIntegrationTests
{
    [Fact]
    public async Task GetHealth_ReturnsOk()
    {
        var appHost = await DistributedApplicationTestingBuilder
            .CreateAsync<Projects.MiProyecto_AppHost>();
        await using var app = await appHost.BuildAsync();
        await app.StartAsync();

        // Esperar a que la API esté sana (verificar contra la versión instalada)
        await app.ResourceNotifications.WaitForResourceHealthyAsync("api");

        using var client = app.CreateHttpClient("api");
        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

- Estos tests levantan contenedores reales — son lentos; separarlos de los
  unitarios (`SKILL-dotnet-test-frameworks.md`).
- **E2E con Playwright** (`SKILL-e2e-playwright.md`): correr la suite contra el
  entorno que levanta `aspire run`, tomando la URL del front desde el dashboard y
  exportándola en `E2E_BASE_URL` (con `E2E_SKIP_WEBSERVER=1`), nunca hardcodeada en los specs.

---

## Despliegue

- Destino por defecto: **VM con Docker Compose**. Aspire puede generar ese
  `docker-compose` a partir del AppHost con la integración Docker Compose:
  ```csharp
  builder.AddDockerComposeEnvironment("compose"); // Aspire.Hosting.Docker (verificar contra la versión instalada)
  ```
  ```bash
  aspire publish -o ./deploy   # genera docker-compose.yaml + .env de plantilla
  ```
  El dev revisa el resultado, lo ajusta y lo versiona. El `.env` generado nunca
  se versiona con valores reales.
- **Requiere confirmación explícita del dev** (reglas de CLAUDE.md):
  - `aspire deploy` o cualquier publicación hacia un entorno remoto.
  - `docker build` / `docker push` (si `aspire publish` va a construir imágenes, avisar antes).
  - Modificar `.env`, `appsettings*.json` o archivos de entorno.
  - Modificar pipelines de CI/CD (Azure DevOps) para incluir Aspire.
  - Agregar integraciones o paquetes fuera del stack aprobado.
- El deploy real lo ejecuta el dev — el agente no accede a servidores remotos.

---

## Checklist Aspire antes de PR

### Estructura
- [ ] `AppHost` y `ServiceDefaults` en `Codigo/[Proyecto]/src/`, rutas registradas en `IA_Memoria/arquitectura.md`
- [ ] Paquetes `Aspire.*` en la misma versión estable; runtime .NET en el LTS vigente
- [ ] Cada servicio .NET llama `AddServiceDefaults()` y `MapDefaultEndpoints()`

### Configuración y secretos
- [ ] Sin connection strings, contraseñas ni URLs absolutas literales en AppHost, API o front
- [ ] Secretos como `AddParameter(..., secret: true)` con valores en user-secrets / variables de entorno
- [ ] El front llama rutas relativas; la URL de la API llega por `API_URL` al proxy del dev server
- [ ] Realm de Keycloak versionado sin secretos reales (solo Perfil A)

### Orquestación
- [ ] `WaitFor` en toda dependencia que deba estar lista antes de arrancar
- [ ] Migraciones vía servicio de migraciones o `dotnet ef` — nunca `EnsureCreated` en lugar de migraciones
- [ ] Health endpoints no expuestos públicamente en producción sin decisión explícita

### Despliegue
- [ ] Docker Compose de despliegue revisado y versionado (sin `.env` con valores reales)
- [ ] Ningún `aspire deploy`, `docker build/push` ni cambio de pipeline ejecutado sin confirmación del dev
