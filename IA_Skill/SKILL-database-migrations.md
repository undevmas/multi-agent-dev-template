# SKILL — Database Migrations

## Cuándo usar esta skill
Al crear, modificar o revertir migraciones de base de datos en cualquier capa del stack.
Leer antes de tocar el esquema de BD en .NET o NestJS.

| Backend | ORM estándar del proyecto |
|---|---|
| .NET 8 | Entity Framework Core (obligatorio) |
| NestJS | TypeORM · Prisma (elegir uno por proyecto) |

Motores soportados: SQL Server 2019+ · PostgreSQL 15+

---

## Reglas generales (aplican a todos los ORM)

- Toda migración tiene `up` (aplicar) Y `down` (revertir) — sin excepciones
- Nunca eliminar una migración que ya fue aplicada a cualquier entorno
- Nunca ejecutar `DROP TABLE` ni `DELETE FROM` en tablas de negocio
- El soft delete se implementa con `IsActive`/`is_active` — no con borrado físico
- Separar migraciones de esquema (DDL) de migraciones de datos (DML seeds)
- Una migración = un cambio cohesivo. No mezclar varias features en una sola
- Nombres descriptivos: `AddContractsTable`, `AddIndexToUsersEmail`, `AddRoleColumnToUsers`
- Probar siempre el `down` antes de subir a staging

---

## Columnas obligatorias en toda tabla de negocio

```sql
-- SQL Server
Id          UNIQUEIDENTIFIER  NOT NULL PRIMARY KEY DEFAULT NEWID()
CreatedAt   DATETIME          NOT NULL DEFAULT GETDATE()
UpdatedAt   DATETIME          NOT NULL DEFAULT GETDATE()
IsActive    BIT               NOT NULL DEFAULT 1
CreatedBy   UNIQUEIDENTIFIER  NULL REFERENCES Users(Id)
UpdatedBy   UNIQUEIDENTIFIER  NULL REFERENCES Users(Id)

-- PostgreSQL
id          UUID              NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()
created_at  TIMESTAMP         NOT NULL DEFAULT NOW()
updated_at  TIMESTAMP         NOT NULL DEFAULT NOW()
is_active   BOOLEAN           NOT NULL DEFAULT TRUE
created_by  UUID              NULL REFERENCES users(id)
updated_by  UUID              NULL REFERENCES users(id)
```

---

## Entity Framework Core (.NET — estándar del proyecto)

### Setup inicial

```bash
# Instalar herramientas EF Core
dotnet tool install --global dotnet-ef

# Paquetes del proyecto (según motor de BD)
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer   # SQL Server
dotnet add package Microsoft.EntityFrameworkCore.Npgsql      # PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Tools
```

### Entidad base reutilizable

```csharp
// Domain/Entities/BaseEntity.cs
public abstract class BaseEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
    public Guid? CreatedBy { get; set; }
    public Guid? UpdatedBy { get; set; }
}

// Toda entidad de negocio hereda de BaseEntity
public class Contract : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
}
```

### Configuración en DbContext

```csharp
// Infrastructure/Data/AppDbContext.cs
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Contract> Contracts => Set<Contract>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Aplicar todas las configuraciones del ensamblado automáticamente
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

        // Filtro global de soft delete — aplica a todas las consultas
        modelBuilder.Entity<User>().HasQueryFilter(u => u.IsActive);
        modelBuilder.Entity<Contract>().HasQueryFilter(c => c.IsActive);
    }

    // Actualizar UpdatedAt automáticamente al guardar
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Modified)
                entry.Entity.UpdatedAt = DateTime.UtcNow;
        }
        return base.SaveChangesAsync(cancellationToken);
    }
}

// Infrastructure/Data/Configurations/ContractConfiguration.cs
public class ContractConfiguration : IEntityTypeConfiguration<Contract>
{
    public void Configure(EntityTypeBuilder<Contract> builder)
    {
        builder.ToTable("Contracts");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Title)
            .IsRequired()
            .HasMaxLength(300);

        builder.Property(c => c.Status)
            .IsRequired()
            .HasMaxLength(50);

        // Índice para búsquedas frecuentes
        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => c.Status);

        // Relación con Users
        builder.HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
```

### Comandos del ciclo de vida

```bash
# Crear nueva migración
dotnet ef migrations add AddContractsTable --project src/Infrastructure --startup-project src/Api

# Aplicar migraciones pendientes
dotnet ef database update --project src/Infrastructure --startup-project src/Api

# Ver lista de migraciones (aplicadas y pendientes)
dotnet ef migrations list --project src/Infrastructure --startup-project src/Api

# Revertir a una migración específica
dotnet ef database update NombreMigracionAnterior --project src/Infrastructure --startup-project src/Api

# Revertir TODAS las migraciones (estado vacío)
dotnet ef database update 0 --project src/Infrastructure --startup-project src/Api

# Generar script SQL (para revisión manual o aplicar en producción)
dotnet ef migrations script --idempotent --output migrations.sql \
  --project src/Infrastructure --startup-project src/Api

# Eliminar la última migración (solo si NO fue aplicada a ningún entorno)
dotnet ef migrations remove --project src/Infrastructure --startup-project src/Api
```

### Migración de datos (seed) separada del esquema

```csharp
// Migrations/[timestamp]_SeedInitialRoles.cs
public partial class SeedInitialRoles : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Insertar datos iniciales — usar SQL directo para control total
        migrationBuilder.Sql(@"
            INSERT INTO Roles (Id, Name, IsActive, CreatedAt, UpdatedAt)
            VALUES
              (NEWID(), 'Admin',    1, GETDATE(), GETDATE()),
              (NEWID(), 'Manager',  1, GETDATE(), GETDATE()),
              (NEWID(), 'Analyst',  1, GETDATE(), GETDATE()),
              (NEWID(), 'ReadOnly', 1, GETDATE(), GETDATE())
        ");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Soft delete de los seeds — nunca DELETE físico
        migrationBuilder.Sql(@"
            UPDATE Roles SET IsActive = 0
            WHERE Name IN ('Admin', 'Manager', 'Analyst', 'ReadOnly')
        ");
    }
}
```

### Agregar columna sin romper producción

```csharp
// Patrón para agregar columna nullable primero, luego hacerla requerida
// Migración 1 — agregar nullable
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.AddColumn<string>(
        name: "PhoneNumber",
        table: "Users",
        type: "nvarchar(20)",
        nullable: true);  // nullable para no romper registros existentes
}

// Migración 2 (después de poblar los datos) — hacer requerida
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.AlterColumn<string>(
        name: "PhoneNumber",
        table: "Users",
        type: "nvarchar(20)",
        nullable: false,
        defaultValue: "");
}
```

---

## TypeORM (NestJS)

### Setup inicial

```bash
npm install typeorm @nestjs/typeorm
npm install pg          # PostgreSQL
npm install mssql       # SQL Server

# CLI de migraciones
npm install -D ts-node
```

```typescript
// data-source.ts — fuente de datos para CLI (separada del AppModule)
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
  type: process.env.DB_TYPE as 'postgres' | 'mssql',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT ?? '5432'),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/database/migrations/*.ts'],
  synchronize: false, // NUNCA true en producción
});

// package.json — scripts de migración
{
  "scripts": {
    "migration:create": "typeorm migration:create src/database/migrations/$npm_config_name",
    "migration:generate": "typeorm-ts-node-commonjs migration:generate src/database/migrations/$npm_config_name -d src/database/data-source.ts",
    "migration:run": "typeorm-ts-node-commonjs migration:run -d src/database/data-source.ts",
    "migration:revert": "typeorm-ts-node-commonjs migration:revert -d src/database/data-source.ts",
    "migration:show": "typeorm-ts-node-commonjs migration:show -d src/database/data-source.ts"
  }
}
```

### Entidad base reutilizable

```typescript
// database/base.entity.ts
import { PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export abstract class BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'created_by', type: 'uuid', nullable: true })
  createdBy: string | null;

  @Column({ name: 'updated_by', type: 'uuid', nullable: true })
  updatedBy: string | null;
}

// modules/contracts/entities/contract.entity.ts
@Entity('contracts')
export class Contract extends BaseEntity {
  @Column({ length: 300 })
  title: string;

  @Column({ length: 50 })
  status: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;
}
```

### Comandos del ciclo de vida

```bash
# Generar migración automática desde diferencias en entidades
npm run migration:generate -- --name=AddContractsTable

# Crear migración vacía (para seeds o cambios manuales)
npm run migration:create -- --name=SeedInitialRoles

# Aplicar migraciones pendientes
npm run migration:run

# Revertir la última migración
npm run migration:revert

# Ver estado de migraciones
npm run migration:show
```

### Estructura de una migración TypeORM

```typescript
// src/database/migrations/1716800000000-AddContractsTable.ts
import { MigrationInterface, QueryRunner, Table, TableIndex, TableForeignKey } from 'typeorm';

export class AddContractsTable1716800000000 implements MigrationInterface {
  name = 'AddContractsTable1716800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(new Table({
      name: 'contracts',
      columns: [
        { name: 'id',         type: 'uuid',      isPrimary: true, default: 'gen_random_uuid()' },
        { name: 'title',      type: 'varchar',   length: '300',   isNullable: false },
        { name: 'status',     type: 'varchar',   length: '50',    isNullable: false },
        { name: 'user_id',    type: 'uuid',      isNullable: false },
        { name: 'is_active',  type: 'boolean',   default: true },
        { name: 'created_at', type: 'timestamp', default: 'NOW()' },
        { name: 'updated_at', type: 'timestamp', default: 'NOW()' },
        { name: 'created_by', type: 'uuid',      isNullable: true },
        { name: 'updated_by', type: 'uuid',      isNullable: true },
      ],
    }), true);

    await queryRunner.createIndex('contracts', new TableIndex({
      name: 'IX_contracts_user_id',
      columnNames: ['user_id'],
    }));

    await queryRunner.createForeignKey('contracts', new TableForeignKey({
      columnNames: ['user_id'],
      referencedTableName: 'users',
      referencedColumnNames: ['id'],
      onDelete: 'RESTRICT',
    }));
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('contracts', true);
  }
}
```

---

## Prisma (NestJS)

### Setup inicial

```bash
npm install prisma @prisma/client
npx prisma init --datasource-provider postgresql   # o sqlserver
```

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"   // o "sqlserver"
  url      = env("DATABASE_URL")
}

// Modelo base embebido en cada modelo de negocio
model Contract {
  id        String   @id @default(uuid()) @db.Uuid
  title     String   @db.VarChar(300)
  status    String   @db.VarChar(50)
  isActive  Boolean  @default(true) @map("is_active")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  createdBy String?  @map("created_by") @db.Uuid
  updatedBy String?  @map("updated_by") @db.Uuid

  userId    String   @map("user_id") @db.Uuid
  user      User     @relation(fields: [userId], references: [id])

  @@index([userId])
  @@map("contracts")
}
```

### Comandos del ciclo de vida

```bash
# Crear y aplicar migración en desarrollo (genera SQL + aplica)
npx prisma migrate dev --name AddContractsTable

# Aplicar migraciones en staging/producción (sin generar nuevas)
npx prisma migrate deploy

# Ver estado de migraciones
npx prisma migrate status

# Revertir: Prisma no tiene revert nativo
# Estrategia: crear una nueva migración que deshaga el cambio
# Para emergencias en dev:
npx prisma migrate reset   # PELIGROSO — borra toda la BD y re-aplica desde cero

# Formatear y validar el schema
npx prisma format
npx prisma validate

# Generar/regenerar el cliente después de cambios en el schema
npx prisma generate

# Seed de datos
npx prisma db seed
```

### Seed con Prisma

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // upsert evita duplicados si el seed se ejecuta más de una vez
  await prisma.role.upsert({
    where: { name: 'Admin' },
    update: {},
    create: { name: 'Admin', isActive: true },
  });

  await prisma.role.upsert({
    where: { name: 'Manager' },
    update: {},
    create: { name: 'Manager', isActive: true },
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

// package.json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

### Soft delete con Prisma (middleware)

```typescript
// Prisma no tiene soft delete nativo — implementar con middleware
prisma.$use(async (params, next) => {
  // Interceptar delete → convertir a update de is_active
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { isActive: false };
  }
  if (params.action === 'deleteMany') {
    params.action = 'updateMany';
    params.args.data = { isActive: false };
  }
  // Filtrar automáticamente registros inactivos en findMany/findFirst
  if (params.action === 'findMany' || params.action === 'findFirst') {
    params.args.where = { ...params.args.where, isActive: true };
  }
  return next(params);
});
```

---

## Estructura de carpetas de BD (compartida)

```
Codigo/
└── database/
    ├── migrations/            ← scripts versionados (subir a git)
    ├── seeders/               ← datos iniciales (subir a git)
    └── scripts/
        ├── rollback/          ← scripts manuales de emergencia
        └── indexes/           ← índices que no van en migraciones
```

---

## Checklist antes de hacer PR con migración

- [ ] La migración tiene `up` Y `down` implementados
- [ ] El `down` fue probado localmente (revertir y volver a aplicar)
- [ ] Se incluyen las columnas obligatorias: `id`, `created_at`, `updated_at`, `is_active`, `created_by`, `updated_by`
- [ ] Las claves foráneas usan `ON DELETE RESTRICT` (no CASCADE en tablas de negocio)
- [ ] Sin `DROP TABLE` ni `DELETE FROM` en tablas de negocio
- [ ] Migraciones de esquema y seeds son archivos separados
- [ ] Sin credenciales ni valores de entorno hardcodeados en la migración
- [ ] El nombre de la migración describe el cambio: `AddContractsTable`, `AddIndexToUsersEmail`
- [ ] `IA_Memoria/progreso.md` actualizado si la migración corresponde a una nueva feature
