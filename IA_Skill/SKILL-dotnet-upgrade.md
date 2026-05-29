# SKILL — .NET Upgrade

## Cuándo usar esta skill
Solo cuando se necesita migrar el proyecto de una versión anterior de .NET
a una versión más reciente. No usar en desarrollo normal.

Versión actual del proyecto: .NET 8
Próxima versión objetivo cuando aplique: .NET 9 / .NET 10

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
<!-- Antes (ejemplo desde .NET 7) -->
<TargetFramework>net7.0</TargetFramework>

<!-- Después -->
<TargetFramework>net8.0</TargetFramework>
```

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
6. Paquetes de autenticación (JWT, Identity)
7. Paquetes de terceros restantes
```

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

### De .NET 8 a .NET 9 (referencia futura)
- Verificar breaking changes en: aka.ms/dotnet9-breaking-changes
- LINQ nuevos métodos (CountBy, AggregateBy, Index)
- Mejoras en HybridCache
- OpenAPI integrado nativamente

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
# Antes (ejemplo .NET 7)
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

# Después (.NET 8)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
```

Imágenes disponibles en: mcr.microsoft.com/dotnet/aspnet

---

## Actualizar Azure DevOps pipeline

En los archivos de workflow de CI/CD:

```yaml
# Antes
- task: UseDotNet@2
  inputs:
    version: '7.x'

# Después
- task: UseDotNet@2
  inputs:
    version: '8.x'
```

---

## Aprovechar nuevas features del upgrade

### .NET 8 — features a adoptar gradualmente

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
