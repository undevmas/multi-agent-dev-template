# SKILL — Database Migrations

## Cuándo usar esta skill
Al crear, modificar o revertir migraciones de base de datos en cualquier capa del stack.
Leer antes de tocar el esquema de BD en .NET o NestJS.

| Backend | Herramienta de esquema/migraciones | Notas |
|---|---|---|
| .NET (LTS vigente — hoy .NET 10) | Entity Framework Core Migrations (obligatorio) | Dapper solo lee — nunca crea ni altera esquema |
| NestJS — proyecto nuevo | Prisma · Drizzle ORM (`drizzle-kit`) · Kysely (`Migrator`) — uno por proyecto | Según el perfil de acceso a datos registrado en `IA_Memoria/arquitectura.md` |
| NestJS — proyecto existente | TypeORM | Solo mantenimiento; no se elige para proyectos nuevos |

Motores soportados: SQL Server 2019+ · PostgreSQL 15+

> **SQL Server + TypeScript:** Prisma y Kysely (`MssqlDialect`) lo soportan. El soporte
> de SQL Server en Drizzle era reciente/beta — verificar contra la versión instalada
> antes de elegir Drizzle para SQL Server.

---

## Reglas generales (aplican a todos los ORM)

- Toda migración tiene `up` (aplicar) Y `down` (revertir) — sin excepciones. En herramientas sin `down` nativo (Prisma, `drizzle-kit`), el `down` es un script de rollback versionado en `database/scripts/rollback/` con el mismo nombre que la migración
- El esquema lo gestiona solo la herramienta del ORM principal — nunca DDL desde Dapper, Kysely queries de aplicación ni scripts sueltos
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

# Paquetes del proyecto (según motor de BD) — misma versión mayor que el runtime .NET (EF Core 10 ↔ .NET 10)
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer   # SQL Server
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL     # PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Tools
```

> Con Aspire, la connection string llega inyectada desde el AppHost — ver
> `IA_Skill/SKILL-aspire-orchestration.md` para correr migraciones contra la BD que levanta.

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

## Dapper (.NET — lado de lectura, perfil Alto rendimiento / CQRS)

Dapper no tiene migraciones ni modelo de esquema: lee tablas que crea y versiona EF Core.

```csharp
// Infrastructure/Queries/ContractQueries.cs — lado de lectura
public sealed class ContractQueries(IDbConnectionFactory connectionFactory)
{
    public async Task<IReadOnlyList<ContractListItem>> GetActiveByUserAsync(Guid userId, CancellationToken ct)
    {
        // Filtro IsActive explícito: los query filters globales de EF Core NO aplican a Dapper
        const string sql = """
            SELECT Id, Title, Status, CreatedAt
            FROM Contracts
            WHERE UserId = @UserId AND IsActive = 1
            ORDER BY CreatedAt DESC
            """;

        using var connection = await connectionFactory.OpenAsync(ct);
        var rows = await connection.QueryAsync<ContractListItem>(
            new CommandDefinition(sql, new { UserId = userId }, cancellationToken: ct));
        return rows.AsList();
    }
}
```

- Misma connection string que el `DbContext` (inyectada por configuración/Aspire, nunca literal).
- Solo `SELECT`. Escrituras por EF Core para conservar validaciones, auditoría (`UpdatedAt`) y soft delete.
- Parametrización obligatoria — ver `SKILL-security-dotnet.md` (sección Dapper).

---

## TypeORM (NestJS — solo proyectos existentes)

> No elegir TypeORM para proyectos nuevos: usar Prisma, Drizzle ORM o Kysely según el
> perfil de acceso a datos. Migrar un proyecto existente de TypeORM a otro ORM es zona
> roja (`SKILL-risk-zone-policy.md`) — requiere ticket.

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

> **Prisma 7+:** el generador recomendado pasó a `prisma-client` (con `output` explícito)
> y la URL de conexión se configura en `prisma.config.ts` en lugar del `schema.prisma`.
> Verificar contra la versión instalada antes de copiar el bloque de abajo.

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

### Soft delete con Prisma (Client Extensions)

```typescript
// Prisma no tiene soft delete nativo. El middleware $use fue eliminado en versiones
// recientes — usar Client Extensions ($extends).
// $allModels asume que todos los modelos son de negocio (tienen isActive); si hay modelos
// sin isActive, declarar la extensión por modelo en lugar de $allModels.
export const prisma = new PrismaClient().$extends({
  name: 'soft-delete',
  query: {
    $allModels: {
      // Bloquear borrado físico — desactivar con update({ data: { isActive: false } })
      async delete() {
        throw new Error('DELETE físico prohibido: usar update con isActive = false');
      },
      async deleteMany() {
        throw new Error('DELETE físico prohibido: usar updateMany con isActive = false');
      },
      // Filtrar automáticamente registros inactivos
      async findMany({ args, query }) {
        args.where = { ...args.where, isActive: true };
        return query(args);
      },
      async findFirst({ args, query }) {
        args.where = { ...args.where, isActive: true };
        return query(args);
      },
    },
  },
});
```

---

## Drizzle ORM (NestJS — perfiles Equilibrado y Alto rendimiento)

### Setup inicial

```bash
npm install drizzle-orm pg
npm install -D drizzle-kit @types/pg
```

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/database/schema/*.ts',
  out: './src/database/migrations',
  dbCredentials: { url: process.env.DATABASE_URL! }, // nunca literal
});
```

### Schema con columnas obligatorias

```typescript
// src/database/schema/columns.ts — columnas de auditoría reutilizables
import { boolean, timestamp, uuid } from 'drizzle-orm/pg-core';

export const auditColumns = {
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow().$onUpdate(() => new Date()),
  createdBy: uuid('created_by'),
  updatedBy: uuid('updated_by'),
};

// src/database/schema/contracts.ts
import { index, pgTable, uuid, varchar } from 'drizzle-orm/pg-core';

export const contracts = pgTable('contracts', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: varchar('title', { length: 300 }).notNull(),
  status: varchar('status', { length: 50 }).notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  ...auditColumns,
}, (t) => [index('ix_contracts_user_id').on(t.userId)]);
```

### Comandos del ciclo de vida

```bash
# Generar migración SQL desde los cambios en el schema
npx drizzle-kit generate --name=add_contracts_table

# Aplicar migraciones pendientes
npx drizzle-kit migrate

# Verificar consistencia de las migraciones generadas
npx drizzle-kit check

# PROHIBIDO fuera de prototipos locales: aplica cambios sin generar migración versionada
# npx drizzle-kit push
```

- `drizzle-kit` no genera `down`: crear el script de rollback en `database/scripts/rollback/` con el mismo nombre.
- Soft delete: desactivar con `db.update(contracts).set({ isActive: false }).where(eq(contracts.id, id))`; toda lectura filtra `eq(contracts.isActive, true)`.
- Queries con el builder o con el template `sql\`...\`` (parametrizado). Nunca `sql.raw()` con input del usuario.

---

## Kysely (NestJS — perfil Alto rendimiento / SQL type-safe)

Kysely es un query builder type-safe con migraciones propias (`Migrator`). Funciona con
PostgreSQL (`PostgresDialect`) y SQL Server (`MssqlDialect`).

### Estructura de una migración

```typescript
// src/database/migrations/2026_11_20_001_add_contracts_table.ts
import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema
    .createTable('contracts')
    .addColumn('id', 'uuid', (col) => col.primaryKey().defaultTo(sql`gen_random_uuid()`))
    .addColumn('title', 'varchar(300)', (col) => col.notNull())
    .addColumn('status', 'varchar(50)', (col) => col.notNull())
    .addColumn('user_id', 'uuid', (col) => col.notNull().references('users.id').onDelete('restrict'))
    .addColumn('is_active', 'boolean', (col) => col.notNull().defaultTo(true))
    .addColumn('created_at', 'timestamp', (col) => col.notNull().defaultTo(sql`now()`))
    .addColumn('updated_at', 'timestamp', (col) => col.notNull().defaultTo(sql`now()`))
    .addColumn('created_by', 'uuid')
    .addColumn('updated_by', 'uuid')
    .execute();

  await db.schema.createIndex('ix_contracts_user_id').on('contracts').column('user_id').execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.dropTable('contracts').execute();
}
```

### Runner de migraciones

```typescript
// src/database/migrate.ts — ejecutar con: node dist/database/migrate.js [latest|down]
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { FileMigrationProvider, Migrator } from 'kysely';
import { db } from './db';

async function main(): Promise<void> {
  const migrator = new Migrator({
    db,
    provider: new FileMigrationProvider({ fs, path, migrationFolder: path.join(__dirname, 'migrations') }),
  });

  const { error, results } = process.argv[2] === 'down'
    ? await migrator.migrateDown()
    : await migrator.migrateToLatest();

  results?.forEach((r) => console.log(`${r.status}: ${r.migrationName}`));
  await db.destroy();
  if (error) {
    console.error(error);
    process.exit(1);
  }
}

void main();
```

- Tipos de la BD: definirlos a mano o generarlos con `kysely-codegen` (paquete adicional — confirmar con el dev antes de instalar).
- Valores siempre por el builder o `sql\`...\`` (parametrizado). Nunca `sql.raw()` con input del usuario.
- Soft delete: `updateTable('contracts').set({ is_active: false })`; toda lectura con `.where('is_active', '=', true)`.

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

- [ ] La migración tiene `up` Y `down` implementados (o script de rollback versionado si la herramienta no genera `down`)
- [ ] El `down` fue probado localmente (revertir y volver a aplicar)
- [ ] La migración la generó la herramienta del ORM principal (sin `drizzle-kit push`, sin DDL desde Dapper ni scripts sueltos)
- [ ] Se incluyen las columnas obligatorias: `id`, `created_at`, `updated_at`, `is_active`, `created_by`, `updated_by`
- [ ] Las claves foráneas usan `ON DELETE RESTRICT` (no CASCADE en tablas de negocio)
- [ ] Sin `DROP TABLE` ni `DELETE FROM` en tablas de negocio
- [ ] Migraciones de esquema y seeds son archivos separados
- [ ] Sin credenciales ni valores de entorno hardcodeados en la migración
- [ ] El nombre de la migración describe el cambio: `AddContractsTable`, `AddIndexToUsersEmail`
- [ ] `IA_Memoria/progreso.md` actualizado si la migración corresponde a una nueva feature
