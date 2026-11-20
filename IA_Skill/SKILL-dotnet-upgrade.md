# SKILL — .NET Upgrade

## Cuándo usar esta skill
Solo cuando se necesita migrar el proyecto de una versión anterior de .NET
a una versión más reciente. No usar en desarrollo normal.

Versión actual del proyecto: la registrada en `IA_Memoria/arquitectura.md`.
Versión objetivo: **siempre el último LTS** (hoy .NET 10, soporte hasta 2028-11-10).
Verificar el LTS vigente en dotnet.microsoft.com/platform/support/policy antes de iniciar.

- Saltar de LTS a LTS (ej. .NET 8 → .NET 10). No detenerse en una STS (versiones impares).
- **.NET 8 y .NET 9 terminaron soporte el 2026-11-10** — ya no reciben parches de seguridad.
  Un proyecto en esas versiones se registra en `IA_Memoria/deuda-tecnica.md` y su upgrade
  es prioritario, pero se ejecuta como tarea propia con confirmación del equipo, nunca como
  efecto colateral de otra tarea.

---

## Antes de iniciar cualquier upgrade

Checklist previo obligatorio:
- [ ] Backup completo del código en rama dedicada: `chore/upgrade-dotnet-[version]`
- [ ] Verificar que todos los tests pasan en la versión actual
- [ ] Documentar las dependencias de terceros y sus versiones actuales
- [ ] Revisar el roadmap de soporte de la versión objetivo en dotnet.microsoft.com
- [ ] Confirmar con el equipo antes de iniciar (cambio estructural)

---

## Proceso de upgrade paso a paso

### Paso 1 — Actualizar el target framework

En cada archivo .csproj:
```xml
<!-- Antes (ejemplo desde .NET 8) -->
<TargetFramework>net8.0</TargetFramework>

<!-- Después (último LTS) -->
<TargetFramework>net10.0</TargetFramework>
```

Si existe `global.json`, actualizar también el SDK (`"version": "10.0.xxx"`).
Si existe `Directory.Packages.props` (Central Package Management), actualizar ahí las versiones.

### Paso 2 — Actualizar paquetes NuGet

Listar paquetes desactualizados:
```bash
dotnet list package --outdated
```

Actualizar uno por uno (no todos a la vez):
```bash
dotnet add package [NombrePaquete] --version [version]
```

Paquetes críticos a revisar en orden:
```
1. Microsoft.EntityFrameworkCore y extensiones
2. Microsoft.AspNetCore.* packages
3. Serilog y sinks
4. FluentValidation
5. AutoMapper (si se usa)
6. Paquetes de autenticación (JWT, Identity, Microsoft.Identity.Web)
7. Swashbuckle.AspNetCore → reemplazar por Microsoft.AspNetCore.OpenApi + Scalar.AspNetCore
   (ver SKILL-dotnet-best-practices.md, sección "Documentación API")
8. Paquetes de terceros restantes
```

> Revisar también la licencia de cada paquete al subir de versión mayor: algunas librerías
> populares cambiaron a licencia comercial en versiones recientes. Si la nueva versión mayor
> exige licencia, no actualizar sin confirmación — quedarse en la última versión con
> licencia compatible y registrarlo en `IA_Memoria/deuda-tecnica.md`.

### Paso 3 — Compilar y revisar breaking changes

```bash
dotnet build --no-restore
```

Revisar cada error/warning antes de continuar.
No suprimir warnings sin entender su causa.

### Paso 4 — Ejecutar tests

```bash
dotnet test
```

Si hay tests fallando, corregir antes de continuar.
No comentar tests para que pasen.

### Paso 5 — Revisar cambios de comportamiento en runtime

Probar manualmente los flujos críticos:
- [ ] Login y generación de JWT
- [ ] Endpoints principales de cada módulo
- [ ] Migraciones de base de datos
- [ ] Middleware personalizado

---

## Breaking changes más comunes por versión

> **Detalle por área (oficial de Microsoft):** para el inventario completo de breaking changes
> usar `IA_Skill/dotnet-official/dotnet-upgrade/migrate-dotnet8-to-dotnet9/SKILL.md` y después
> `migrate-dotnet9-to-dotnet10/SKILL.md`, en el mismo upgrade con destino `net10.0` (nunca liberar
> en .NET 9). Si el upgrade también activa nullable, `migrate-nullable-references/SKILL.md`, en un
> PR aparte. Precedencia: si chocan con esta skill o con CLAUDE.md, gana la plantilla.

### De .NET 6 a .NET 7
- Minimal APIs recibieron actualizaciones de routing
- Rate limiting nativo agregado (Microsoft.AspNetCore.RateLimiting)
- Output caching nativo
- IFormFile cambios en manejo de archivos grandes

### De .NET 7 a .NET 8
- Keyed services en DI: `services.AddKeyedScoped<IService, Impl>("key")`
- Frozen collections para mejor performance (FrozenDictionary, FrozenSet)
- TimeProvider abstraction (importante para testing de tiempo)
- Primary constructors en C# 12
- Collection expressions en C# 12
- Cambios en serialización System.Text.Json

### De .NET 8 a .NET 10 (LTS → LTS — incluye los cambios de .NET 9)
- Verificar breaking changes en: learn.microsoft.com/dotnet/core/compatibility/9.0 y /10.0
- Swashbuckle ya no viene en las plantillas (desde .NET 9): migrar a `Microsoft.AspNetCore.OpenApi`
  + Scalar; en .NET 10 el documento se genera en OpenAPI 3.1
- LINQ nuevos métodos (CountBy, AggregateBy, Index); HybridCache
- C# 13/14 (`params` collections, `field` keyword, extension members)
- EF Core 10: revisar breaking changes del proveedor (SQL Server / Npgsql) y regenerar el
  snapshot de migraciones si cambia el modelo (ver sección EF Core abajo)
- Imágenes de contenedor: revisar la distro base por defecto de las imágenes 10.0 y los
  paquetes del sistema que asuma el Dockerfile (verificar contra mcr.microsoft.com)
- Autenticación: revisar cambios de ASP.NET Core Identity y del pipeline de auth si el
  proyecto migra a perfil A/B (ver SKILL-auth-patterns.md) — no mezclarlo con el upgrade,
  hacerlo en un PR aparte

---

## Actualizar Entity Framework Core

EF Core sigue su propio ciclo de versiones alineado con .NET.

```bash
# Actualizar paquetes EF Core
dotnet add package Microsoft.EntityFrameworkCore --version [version]
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version [version]
dotnet add package Microsoft.EntityFrameworkCore.Tools --version [version]
```

Después de actualizar EF Core, siempre:
```bash
# Verificar que las migraciones existentes siguen siendo válidas
dotnet ef migrations list

# Crear migración de prueba para verificar el modelo
dotnet ef migrations add TestUpgrade --no-build

# Si todo está bien, eliminar la migración de prueba
dotnet ef migrations remove
```

---

## Actualizar Docker

Si el proyecto usa Docker, actualizar el Dockerfile:

```dockerfile
# Antes (ejemplo .NET 8)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Después (.NET 10 — último LTS)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
```

El agente edita el Dockerfile, pero no ejecuta `docker build` ni `docker push` sin confirmación.

Imágenes disponibles en: mcr.microsoft.com/dotnet/aspnet

---

## Actualizar Azure DevOps pipeline

Modificar pipelines requiere confirmación explícita: proponer el cambio al dev, no aplicarlo.

```yaml
# Antes
- task: UseDotNet@2
  inputs:
    version: '8.x'

# Después
- task: UseDotNet@2
  inputs:
    version: '10.x'
```

---

## Aprovechar nuevas features del upgrade

### .NET 8+ — features a adoptar gradualmente (disponibles en .NET 10)

Primary constructors (C# 12):
```csharp
// Antes
public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    public UserService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }
}

// Con primary constructor
public class UserService(IUserRepository userRepository) : IUserService
{
    // userRepository disponible directamente
    public async Task<User?> GetByIdAsync(Guid id)
        => await userRepository.GetByIdAsync(id);
}
```

Keyed services para múltiples implementaciones:
```csharp
// Registro
services.AddKeyedScoped<INotificationService, EmailNotificationService>("email");
services.AddKeyedScoped<INotificationService, SmsNotificationService>("sms");

// Uso
public class NotificationDispatcher(
    [FromKeyedServices("email")] INotificationService emailService,
    [FromKeyedServices("sms")] INotificationService smsService)
{ }
```

TimeProvider para tests más fáciles:
```csharp
// En lugar de DateTime.UtcNow directamente
public class ContractService(TimeProvider timeProvider)
{
    public Contract Create(CreateContractDto dto)
    {
        return new Contract
        {
            CreatedAt = timeProvider.GetUtcNow().DateTime
        };
    }
}

// En tests — tiempo controlable
var fakeTime = new FakeTimeProvider();
fakeTime.SetUtcNow(new DateTimeOffset(2025, 1, 15, 10, 0, 0, TimeSpan.Zero));
```

---

## Rollback si algo falla

Si el upgrade genera problemas en producción:

```bash
# Volver a la rama anterior
git checkout main
git revert [commits del upgrade]

# O simplemente usar la rama de backup
git checkout chore/backup-before-upgrade-dotnet-[version]
```

Nunca hacer upgrade directamente en main sin rama de feature/chore separada.

---

## Recursos oficiales

- Guía de migración oficial: learn.microsoft.com/dotnet/core/migration
- Breaking changes por versión: aka.ms/dotnet-breaking-changes
- Compatibilidad de paquetes: nuget.org
- Roadmap de soporte LTS: dotnet.microsoft.com/platform/support/policy
