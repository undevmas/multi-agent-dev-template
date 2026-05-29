# SKILL — .NET Test Frameworks

## Cuándo usar esta skill
Al escribir, revisar o estructurar tests en el proyecto .NET.
Leer antes de crear cualquier archivo de test.

Framework principal: xUnit
Mocking: Moq o NSubstitute
Assertions: FluentAssertions
E2E/Integration: Cypress (frontend) + WebApplicationFactory (backend)

---

## Estructura de proyectos de test

```
Codigo/
└── backend-net/
    ├── src/
    │   ├── Api/
    │   ├── Application/
    │   ├── Domain/
    │   └── Infrastructure/
    └── tests/
        ├── Unit/                    # Tests unitarios (sin DB, sin HTTP)
        │   ├── Services/
        │   ├── Validators/
        │   └── Domain/
        ├── Integration/             # Tests con DB real o WebApplicationFactory
        │   ├── Controllers/
        │   └── Repositories/
        └── Architecture/            # Tests de reglas arquitectónicas (opcional)
```

Convención de nombres:
- Archivo: `[ClaseTesteada]Tests.cs`
- Método: `[Método]_[Escenario]_[ResultadoEsperado]`

Ejemplo: `CreateAsync_WithDuplicateEmail_ThrowsBusinessException`

---

## xUnit — configuración base

```xml
<!-- tests/Unit/Unit.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" Version="2.9.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.*" />
    <PackageReference Include="Moq" Version="4.20.*" />
    <PackageReference Include="FluentAssertions" Version="6.12.*" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.*" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="../../src/Application/Application.csproj" />
  </ItemGroup>
</Project>
```

---

## Tests unitarios — patrón AAA

Arrange: preparar datos y mocks
Act: ejecutar la acción bajo prueba
Assert: verificar el resultado

### Test de service — happy path
```csharp
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _userRepositoryMock;
    private readonly Mock<ILogger<UserService>> _loggerMock;
    private readonly UserService _sut; // System Under Test

    public UserServiceTests()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _loggerMock = new Mock<ILogger<UserService>>();
        _sut = new UserService(_userRepositoryMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task CreateAsync_WithValidData_ReturnsUserResponseDto()
    {
        // Arrange
        var dto = new CreateUserDto
        {
            Email = "test@example.com",
            Password = "Password123!",
            FullName = "Test User"
        };

        _userRepositoryMock
            .Setup(r => r.ExistsByEmailAsync(dto.Email))
            .ReturnsAsync(false);

        _userRepositoryMock
            .Setup(r => r.AddAsync(It.IsAny<User>()))
            .Returns(Task.CompletedTask);

        // Act
        var result = await _sut.CreateAsync(dto);

        // Assert
        result.Should().NotBeNull();
        result.Email.Should().Be(dto.Email);
        result.FullName.Should().Be(dto.FullName);
        result.Id.Should().NotBe(Guid.Empty);

        _userRepositoryMock.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_WithDuplicateEmail_ThrowsBusinessException()
    {
        // Arrange
        var dto = new CreateUserDto { Email = "existing@example.com" };

        _userRepositoryMock
            .Setup(r => r.ExistsByEmailAsync(dto.Email))
            .ReturnsAsync(true);

        // Act
        var act = async () => await _sut.CreateAsync(dto);

        // Assert
        await act.Should()
            .ThrowAsync<BusinessException>()
            .WithMessage("*correo*");

        _userRepositoryMock.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Never);
    }
}
```

### Test de validator
```csharp
public class CreateUserDtoValidatorTests
{
    private readonly CreateUserDtoValidator _validator = new();

    [Fact]
    public void Validate_WithValidData_PassesValidation()
    {
        // Arrange
        var dto = new CreateUserDto
        {
            Email = "valid@example.com",
            Password = "Password123!",
            FullName = "Valid Name"
        };

        // Act
        var result = _validator.Validate(dto);

        // Assert
        result.IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("", "Email es requerido")]
    [InlineData("not-an-email", "Email no válido")]
    [InlineData("a@b", "Email no válido")]
    public void Validate_WithInvalidEmail_FailsValidation(string email, string _)
    {
        // Arrange
        var dto = new CreateUserDto { Email = email, Password = "Pass123!", FullName = "Name" };

        // Act
        var result = _validator.Validate(dto);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "Email");
    }

    [Theory]
    [InlineData("short")]
    [InlineData("1234567")]
    public void Validate_WithShortPassword_FailsValidation(string password)
    {
        var dto = new CreateUserDto
        {
            Email = "valid@example.com",
            Password = password,
            FullName = "Name"
        };

        var result = _validator.Validate(dto);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "Password");
    }
}
```

### Test de dominio
```csharp
public class ContractTests
{
    [Fact]
    public void Approve_WhenPending_ChangesStatusToApproved()
    {
        // Arrange
        var contract = new Contract { Status = "Pending" };

        // Act
        contract.Approve("approver@example.com");

        // Assert
        contract.Status.Should().Be("Approved");
        contract.ApprovedBy.Should().Be("approver@example.com");
        contract.ApprovedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void Approve_WhenAlreadyApproved_ThrowsBusinessException()
    {
        // Arrange
        var contract = new Contract { Status = "Approved" };

        // Act
        var act = () => contract.Approve("another@example.com");

        // Assert
        act.Should().Throw<BusinessException>()
            .WithMessage("*pendiente*");
    }
}
```

---

## Tests parametrizados

```csharp
// Theory + InlineData — valores simples
[Theory]
[InlineData("admin@test.com", "Admin123!", true)]
[InlineData("", "Admin123!", false)]
[InlineData("admin@test.com", "", false)]
[InlineData("invalid-email", "Admin123!", false)]
public void Login_WithVariousInputs_ReturnsExpectedResult(
    string email, string password, bool expectedSuccess)
{
    // ...
}

// Theory + MemberData — objetos complejos
public static IEnumerable<object[]> InvalidContracts =>
[
    [new CreateContractDto { Title = "" }, "Title"],
    [new CreateContractDto { Title = "Valid", StartDate = DateTime.MinValue }, "StartDate"],
    [new CreateContractDto { Title = "Valid", StartDate = DateTime.Now, EndDate = DateTime.Now.AddDays(-1) }, "EndDate"],
];

[Theory]
[MemberData(nameof(InvalidContracts))]
public void Validate_WithInvalidContract_FailsOnExpectedField(
    CreateContractDto dto, string expectedField)
{
    var result = _validator.Validate(dto);
    result.IsValid.Should().BeFalse();
    result.Errors.Should().Contain(e => e.PropertyName == expectedField);
}
```

---

## Tests de integración con WebApplicationFactory

```csharp
public class UsersControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Reemplazar DbContext con base de datos en memoria
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);

                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb_" + Guid.NewGuid()));
            });
        }).CreateClient();
    }

    [Fact]
    public async Task GetAll_ReturnsOkWithUsers()
    {
        // Arrange
        var token = await GetAuthTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await _client.GetAsync("/api/v1/users");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<UserResponseDto>>>();
        content.Should().NotBeNull();
        content!.Success.Should().BeTrue();
    }

    [Fact]
    public async Task Create_WithValidData_Returns201()
    {
        // Arrange
        var token = await GetAuthTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var dto = new CreateUserDto
        {
            Email = $"test_{Guid.NewGuid()}@example.com",
            Password = "Password123!",
            FullName = "Test Integration User"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/users", dto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    private async Task<string> GetAuthTokenAsync()
    {
        var loginDto = new LoginDto { Email = "admin@test.com", Password = "Admin123!" };
        var response = await _client.PostAsJsonAsync("/api/v1/auth/login", loginDto);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        return result!.Data!.Token;
    }
}
```

---

## Mocking con Moq — patrones frecuentes

```csharp
// Setup de retorno simple
_mock.Setup(r => r.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync(user);

// Setup con valor específico
_mock.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);

// Setup que lanza excepción
_mock.Setup(r => r.GetByIdAsync(invalidId)).ThrowsAsync(new NotFoundException("..."));

// Verificar que fue llamado
_mock.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Once);
_mock.Verify(r => r.DeleteAsync(It.IsAny<Guid>()), Times.Never);

// Verificar con parámetros específicos
_mock.Verify(r => r.AddAsync(It.Is<User>(u => u.Email == "test@example.com")), Times.Once);

// Capturar argumento para verificar
User? capturedUser = null;
_mock.Setup(r => r.AddAsync(It.IsAny<User>()))
    .Callback<User>(u => capturedUser = u)
    .Returns(Task.CompletedTask);

await _sut.CreateAsync(dto);
capturedUser!.Email.Should().Be(dto.Email);
```

---

## FluentAssertions — assertions más legibles

```csharp
// Colecciones
result.Should().NotBeNull();
result.Should().NotBeEmpty();
result.Should().HaveCount(3);
result.Should().Contain(u => u.Email == "test@example.com");
result.Should().BeInAscendingOrder(u => u.CreatedAt);

// Strings
result.Email.Should().Be("test@example.com");
result.Email.Should().StartWith("test");
result.Email.Should().Contain("@");
result.Email.Should().NotBeNullOrEmpty();

// Números y fechas
result.Total.Should().BeGreaterThan(0);
result.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
result.CreatedAt.Should().BeBefore(DateTime.UtcNow.AddMinutes(1));

// Excepciones
var act = async () => await _sut.CreateAsync(dto);
await act.Should().ThrowAsync<BusinessException>();
await act.Should().ThrowAsync<BusinessException>().WithMessage("*correo*");
await act.Should().NotThrowAsync();
```

---

## Ejecutar tests

```bash
# Todos los tests
dotnet test

# Solo unitarios
dotnet test tests/Unit/

# Con reporte de cobertura
dotnet test --collect:"XPlat Code Coverage"

# Con detalle de cada test
dotnet test --logger "console;verbosity=detailed"

# Un test específico
dotnet test --filter "FullyQualifiedName~UserServiceTests.CreateAsync"
```

---

## Cobertura mínima requerida

- Services: 80% mínimo (happy path + principales casos de error)
- Validators: 100% (cada regla de validación)
- Domain entities con comportamiento: 90%
- Controllers: cubiertos por integration tests
- Repositories: cubiertos por integration tests o tests con InMemory DB
