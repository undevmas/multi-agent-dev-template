# Arquitectura del Proyecto

> Snapshot verificado el 2026-09-04 mediante lectura estratégica de `IA_Memoria/snapshots/snapshot-latest.md` y comprobación de los archivos fuente.

## Visión general del sistema

PersonalCripto es un monorepo .NET 10 + Angular 22 para gestión multi-tenant, identidad y autorización, catálogo, trading de pares de criptomonedas, reportes y jobs en segundo plano. El Gateway YARP centraliza routing y seguridad; los servicios comparten contratos, DTOs, dominio e infraestructura reutilizable. El pipeline de trading delega ingesta histórica, backtesting y activación a un servicio Python llamado `jmh_trading`; su código fuente no está incluido en este workspace ni en el snapshot vigente, por lo que actualmente se trata como dependencia externa no verificable.

## Ruta raíz del proyecto

```text
Codigo/personal-cripto/
```

Ruta completa al código fuente: `Codigo/personal-cripto/src/`.

## Mapa de rutas por capa

| Capa | Ruta desde Codigo/ | Notas |
|---|---|---|
| Frontend | `personal-cripto/src/Frontend/gestion-pwa/` | Angular 22 standalone, zoneless, signals y PWA |
| Gateway/API edge | `personal-cripto/src/Gateway/` | ASP.NET Core, YARP, JWT, middlewares de seguridad |
| Identity | `personal-cripto/src/Identity/` | ASP.NET Core Identity, MFA, SSO, multi-tenant |
| Servicios de negocio | `personal-cripto/src/Services/Business/` | Servicio scaffold con WeatherForecast |
| Catálogo | `personal-cripto/src/Services/Catalogo/` | Módulo Productos + EF Core |
| Reportes | `personal-cripto/src/Services/Reportes/` | Servicio scaffold; no hay controller funcional detectado |
| Trading | `personal-cripto/src/Services/Trading/` | Pares, pares internos y preparación de pares |
| Analítica Python externa | No incluida en `Codigo/personal-cripto/` | `jmh_trading`: histórico, backtesting, re-scoring y activación; solo se observan sus contratos/clientes desde .NET |
| Worker | `personal-cripto/src/Services/Worker/` | Jobs, Quartz y mensajería |
| Dominio compartido | `personal-cripto/src/Shared/Domain/` | Entidades, abstracciones e IDs GUID |
| DTOs compartidos | `personal-cripto/src/Shared/Dtos/` | `ApiResponse`, `ApiError`, paginación |
| Contratos compartidos | `personal-cripto/src/Shared/Contracts/` | Interfaces, eventos y contratos de integración |
| Datos | `personal-cripto/src/Infrastructure/Data/` | EF Core, repositorio genérico, unidad de trabajo y Dapper |
| Cache | `personal-cripto/src/Infrastructure/Cache/` | MemoryCache y Redis |
| Messaging | `personal-cripto/src/Infrastructure/Messaging/` | Azure Service Bus, RabbitMQ y AWS SQS/SNS |
| Seguridad/secretos | `personal-cripto/src/Infrastructure/Security/`, `Secrets/` | interceptores, JWT auxiliar y Azure Key Vault |
| Observabilidad | `personal-cripto/src/Observability/` | OpenTelemetry, Serilog y health checks |
| Orquestación | `personal-cripto/src/Orchestration/` | .NET Aspire AppHost y ServiceDefaults |
| Tests | `personal-cripto/tests/` | Gateway, Trading y Worker |

## Estructura de Codigo/

| Carpeta en Codigo/ | Contenido | Tecnología detectada |
|---|---|---|
| `personal-cripto/` | Monorepo de servicios, frontend, documentación y pruebas | .NET 10, Angular 22, Aspire |
| `personal-cripto/src/` | Aplicaciones, librerías compartidas e infraestructura | C#, TypeScript |
| `personal-cripto/tests/` | Tests de Gateway, Trading y Worker | Microsoft Testing Platform, EF InMemory |

## Tecnologías y versiones reales

- .NET `net10.0`, C# nullable e implicit usings.
- ASP.NET Core, YARP `2.3.0`, OpenAPI `10.0.11`/`Microsoft.OpenApi 2.11.0`.
- EF Core `10.0.11`; PostgreSQL vía Npgsql `10.0.3`; SQL Server e InMemory en Identity.
- Dapper `2.1.79`; MediatR `14.2.0`; Redis `StackExchange.Redis 2.8.41`.
- Angular `22.1.0`, npm `10.9.8`, TypeScript `~6.0.2`, Vitest `4.0.8`, RxJS `~7.8.0`.
- Playwright Test `1.63.0` y `playwright-cli` para validación E2E y automatización local de navegador; configuración en la raíz del workspace.
- Quartz `3.19.1`; Polly `8.6.6`; Fido2 `4.0.1`; OpenIddict `7.6.0`; Otp.NET `1.4.1`.
- .NET Aspire para orquestación local; OpenTelemetry y Serilog para observabilidad.

## Módulos y estado

### Frontend

Ruta: `Codigo/personal-cripto/src/Frontend/gestion-pwa/`. Puerto de desarrollo no fijado en `angular.json`; `ng serve` usa el valor predeterminado de Angular si no se sobreescribe.

Validación E2E: desde la raíz del workspace, `npm run test:e2e` ejecuta las pruebas de `tests/e2e/` en Chromium. `E2E_BASE_URL` permite indicar otra URL; su valor local predeterminado es `http://localhost:4200`. La guía operativa es `IA_Skill/SKILL-playwright-e2e.md`.

Módulos implementados: autenticación (login, registro, MFA, SSO, recuperación y verificación), dashboard, perfil, configuración de cuenta, administración de usuarios/tenants/permisos/invitaciones/jobs/auditoría, pares, preparación de pares y provisioning.

### Backend

| Componente | Puerto HTTP | Estado |
|---|---:|---|
| Gateway | 5032 | Implementado |
| Identity | 5028 | Implementado |
| Business | 5001 | Scaffold WeatherForecast |
| Catalogo | 5008 | Implementado: Productos |
| Reportes | 5150 | Scaffold; sin endpoints de negocio detectados |
| Trading | 5190 | Implementado: Pares, InternalPares, PreparacionPares |
| jmh_trading | No documentado | Dependencia Python externa; fuente y runtime no presentes en el workspace |
| Worker | 5170 | Implementado: Jobs/Quartz |
| Aspire AppHost | 15159 | Orquestación local |

Los perfiles HTTPS también existen: Gateway 7199, Identity 7069, Business 7262, Catalogo 7286, Reportes 7033, Trading 7190 y Worker 7170.

Autenticación: JWT Bearer en servicios/Gateway, refresh token y ASP.NET Identity/OpenIddict en Identity. Documentación API: OpenAPI/Swagger en los proyectos web.

### Base de datos

| Motor | Uso |
|---|---|
| PostgreSQL 15+ | Persistencia principal de Identity, Catalogo, Trading y Worker cuando el provider es PostgreSQL |
| SQL Server 2019+ | Provider alternativo de Identity |
| EF Core InMemory | Desarrollo/pruebas; provider configurado por defecto en varios `appsettings.json` |
| Redis | Cache y soporte de Trading |

Migraciones: EF Core Migrations por bounded context. Los IDs de entidades de negocio son GUID; Trading también usa claves compuestas técnicas (`Exchange/Par` y `Par/Exchange/Ventana`).

## Infraestructura

| Componente | Tecnología | Notas |
|---|---|---|
| Contenedores | No detectado | No existe `docker-compose.yml` ni `.env.example` en el snapshot/proyecto |
| Orquestación local | .NET Aspire | AppHost en `src/Orchestration/Aspire.Orchestration.AppHost/` |
| Mensajería | Azure Service Bus, RabbitMQ, AWS SQS/SNS | Infraestructura reusable |
| Secretos | Azure Key Vault, User Secrets, variables de entorno | No hardcodear valores sensibles |
| CI/CD | No detectado en el snapshot | No documentar pipeline inexistente |

## Flujo principal

```text
Angular gestion-pwa
  └── HTTPS/JWT → Gateway (YARP, seguridad y routing)
                    ├── Identity
                    ├── Catalogo
                    ├── Trading
                    │     └── API interna/Redis Streams ↔ jmh_trading (externo al workspace)
                    ├── Reportes
                    ├── Business
                    └── Worker
                          ├── PostgreSQL/SQL Server/Redis
                          ├── Quartz
                          └── Service Bus/RabbitMQ/AWS messaging
```

## Variables de entorno y configuración requerida

- `ASPNETCORE_ENVIRONMENT`.
- `ConnectionStrings__IdentityPostgres`, `ConnectionStrings__IdentitySqlServer`, `ConnectionStrings__CatalogoPostgres`, `ConnectionStrings__TradingPostgres`, `ConnectionStrings__WorkerPostgres`.
- `Jwt__SecretKey`, `Jwt__MfaChallengeSecretKey`, `Jwt__Issuer`, `Jwt__Audience`.
- `Azure__ApplicationInsightsConnectionString`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `Otel__CollectorEndpoint`.
- `KeyVault__Uri` y credenciales/configuración de Azure Key Vault.
- `Trading__Redis__ConnectionString`.
- `Trading__JmhTrading__BaseUrl`, `Trading__JmhTrading__ApiKey`, `Worker__JmhTrading__BaseUrl`, `Worker__JmhTrading__ApiKey`.
- SSO: `Sso__CallbackBaseUrl`, `Sso__Google__ClientId`, `Sso__Google__ClientSecret`, `Sso__Microsoft__ClientId`, `Sso__Microsoft__ClientSecret`.
- Mail: `Mail__Provider`, SMTP/SendGrid/MailHog.
