# AI Dev Workspace Template

> Capa de contexto y gobierno para sesiones de desarrollo con IA en proyectos enterprise.

Estandariza cómo trabajan **Claude Code**, **GitHub Copilot**, **Gemini CLI**, **OpenCode** y **Codex CLI** en un mismo proyecto — sin depender de un solo proveedor y sin perder convenciones entre sesiones.

---

## ¿Qué problema resuelve?

Cada sesión con un agente IA empieza desde cero: el agente no sabe qué está hecho, qué convenciones usa el equipo ni qué tecnologías están aprobadas. Este template instala una capa de memoria y gobierno que:

- Da contexto persistente al agente antes de que toque código
- Bloquea el stack tecnológico aprobado (no más sugerencias fuera de convención)
- Separa el código productivo de los archivos de IA (solo `Codigo/` va a git)
- Funciona con cualquier agente del ecosistema actual

---

## Agentes soportados

| Agente | Archivo de instrucciones | Acceso al filesystem |
|---|---|---|
| Claude Code | `CLAUDE.md` | ✅ Nativo |
| Gemini CLI | `.gemini/GEMINI.md` | ✅ Nativo |
| OpenCode | `AGENTS.md` | ✅ Nativo |
| Codex CLI (OpenAI) | `AGENTS.md` | ✅ Nativo |
| GitHub Copilot | `.github/copilot-instructions.md` | ⚠️ Requiere adjuntar con `#file:` |

---

## Stack aprobado

No usar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa | Tecnología |
|---|---|
| Frontend | Angular 17+ · React 18+ |
| Backend | .NET 8+ (C#) · NestJS 10+ (TypeScript) |
| Base de datos | SQL Server 2019+ · PostgreSQL 15+ |
| ORM | Entity Framework Core · TypeORM · Prisma |
| Autenticación | JWT + Refresh Token · OAuth2 · ASP.NET Identity |
| Contenedores | Docker · Docker Compose |
| CI/CD | Azure DevOps Pipelines |
| Testing unitario | xUnit (.NET) · Jest (TS/JS) |
| Testing E2E | Cypress |
| Documentación API | Swagger / OpenAPI |

---

## Estructura del template

```text
workspace-proyecto/
├── CLAUDE.md                          ← Claude Code (fuente de verdad)
├── AGENTS.md                          ← OpenCode + Codex CLI
├── .github/
│   └── copilot-instructions.md        ← GitHub Copilot
├── .gemini/
│   └── GEMINI.md                      ← Gemini CLI
│
├── IA_Skill/                          ← Guías técnicas por dominio (no va a git)
│   ├── SKILL-frontend-design.md
│   ├── SKILL-dotnet-best-practices.md
│   ├── SKILL-nestjs-best-practices.md
│   ├── SKILL-database-migrations.md
│   └── ... (24 skills en total)
│
├── IA_Memoria/                        ← Estado del proyecto (no va a git)
│   ├── progreso.md                    ← Qué está hecho y qué sigue
│   ├── arquitectura.md                ← Decisiones técnicas y estructura
│   ├── convenciones.md                ← Naming, commits, reglas
│   └── snapshots/                     ← Snapshots de Repomix (no va a git)
│
├── Features/                          ← Definición de cada módulo (no va a git)
├── Issues/                            ← Bugs registrados (no va a git)
├── Insumos/                           ← Mockups y specs (no va a git)
│
├── Codigo/                            ← ÚNICO que se versiona en git
│   ├── frontend-angular/
│   ├── backend-net/
│   ├── backend-nestjs/
│   ├── database/
│   ├── docs/
│   └── .gitignore
│
├── repomix-scan.ps1                   ← Genera snapshot (Windows)
└── repomix-scan.sh                    ← Genera snapshot (Linux / macOS)
```

---

## Cómo funciona

El template opera en tres capas de contexto que el agente consume antes de tocar código:

```
Capa 1 — IA_Memoria/
  Contexto narrativo del proyecto: qué está hecho, convenciones,
  decisiones de arquitectura. Lo escriben humanos; el agente lo actualiza.

Capa 2 — IA_Skill/
  24 guías técnicas especializadas: testing, seguridad, migraciones, UX...
  El agente lee solo la que corresponde a la tarea del momento.

Capa 3 — Snapshots Repomix
  Dump comprimido del codebase real, generado bajo demanda.
  El agente lo lee únicamente cuando la tarea abarca múltiples módulos.
```

---

## Quick start

### Requisitos previos

- Node.js 18+ (para ejecutar Repomix)
- Un agente IA instalado (Claude Code, Gemini CLI, OpenCode, etc.)

### 1. Clona el template

```bash
git clone <este-repo> workspace-mi-proyecto
cd workspace-mi-proyecto
```

### 2. Mueve tu código a `Codigo/`

```
Codigo/
├── frontend-angular/   ← Angular o React
├── backend-net/        ← API .NET
├── backend-nestjs/     ← API NestJS
└── database/           ← Migraciones SQL
```

### 3. Genera el snapshot inicial

```powershell
# Windows
.\repomix-scan.ps1
```

```bash
# Linux / macOS
./repomix-scan.sh
```

Al terminar, el script imprime un **prompt de inspección** listo para copiar y pegar en tu agente IA.

### 4. Pega el prompt en tu agente y deja que inspeccione

El agente leerá el snapshot e inspeccionará el código real para llenar automáticamente los tres archivos de memoria:

| Archivo | Qué escribe el agente |
|---|---|
| `IA_Memoria/arquitectura.md` | Tecnologías detectadas, módulos, puertos, variables de entorno |
| `IA_Memoria/progreso.md` | Módulos existentes marcados, pendientes reales del proyecto |
| `IA_Memoria/convenciones.md` | Patrones de naming encontrados en el código |

Funciona igual para **proyectos nuevos** (Codigo/ vacío → el agente lo indica) y para **proyectos legacy** (el agente documenta lo que encuentra sin asumir nada).

### 5. Abre tu sesión de desarrollo

A partir de aquí el agente arranca con contexto real del proyecto — sin preguntas de arranque, sin suposiciones.

---

## Sistema de Skills

Las Skills son guías técnicas que el agente consulta según la tarea. No las lee todas — solo la que corresponde al trabajo del momento, reduciendo el consumo de tokens innecesario.

| Área | Skills disponibles |
|---|---|
| **Frontend** | Componentes visuales · UX y formularios · Code review · SEO · Tests Angular · Tests React |
| **Backend .NET** | Best practices · Design patterns · Tests unitarios e integración · Upgrade de versión |
| **Backend NestJS** | Best practices · CQRS / eventos / colas · TypeScript estricto · Tests |
| **Full Stack** | Módulo MVC completo · Migraciones de BD (EF Core, TypeORM, Prisma, Sequelize) |
| **Seguridad** | Angular · .NET · NestJS · Checklist OWASP pre-producción |
| **Texto y docs** | Mensajes UI / emails para usuario final · Documentar features terminadas |
| **Herramientas** | Búsqueda web para versiones y CVEs · Modo ultra-conciso en sesiones largas |

---

## Snapshots con Repomix

Los snapshots le dan al agente una visión comprimida de todo el código sin que tenga que abrir archivos uno por uno.

**Cuándo generarlos:**
- Primera sesión del proyecto
- La tarea afecta más de un módulo o capa
- El snapshot tiene más de 7 días sin regenerar

**Cuándo omitirlos:** fixes en un archivo conocido, cambios de texto, ajustes de config aislados.

### Comandos

```powershell
# Windows
.\repomix-scan.ps1                        # Snapshot completo
.\repomix-scan.ps1 -Target backend-net    # Solo .NET
.\repomix-scan.ps1 -Target backend-nestjs # Solo NestJS
.\repomix-scan.ps1 -Target frontend       # Solo frontend
.\repomix-scan.ps1 -Full                  # Sin compresión (máxima fidelidad)
```

```bash
# Linux / macOS
./repomix-scan.sh                         # Snapshot completo
./repomix-scan.sh backend-net             # Solo .NET
./repomix-scan.sh backend-nestjs          # Solo NestJS
./repomix-scan.sh frontend                # Solo frontend
./repomix-scan.sh --full                  # Sin compresión
```

> Los snapshots no se versionan. La configuración de Repomix vive en `Codigo/repomix.config.json`.

---

## Flujo de sesión recomendado

```
1. Regenerar snapshot (si hay cambios desde la última sesión)
        ↓
2. El agente lee: progreso → arquitectura → convenciones
        ↓
3. Si aplica: leer Features/[feature].md del módulo involucrado
        ↓
4. El agente consulta la Skill técnica relevante
        ↓
5. Implementación dentro de Codigo/ únicamente
        ↓
6. Al cerrar: el agente actualiza IA_Memoria/progreso.md
```

---

## Reglas críticas

Estas reglas están declaradas en todos los archivos de instrucciones y el agente no puede ignorarlas sin confirmación explícita:

| Regla | Detalle |
|---|---|
| **Soft delete obligatorio** | Nunca `DELETE FROM` en tablas de negocio — usar `is_active = false` |
| **IDs UUID/GUID** | Nunca enteros secuenciales |
| **Respuesta de API estandarizada** | `{ success, data, message, errors }` en todos los endpoints |
| **Endpoints protegidos** | Guard/middleware en todo excepto login |
| **Sin hardcodeo** | Credenciales y URLs siempre en variables de entorno |
| **Migraciones versionadas** | Todo cambio de BD requiere su migración |
| **Requieren confirmación** | Modificar `.env`, ejecutar `DROP TABLE`, cambiar el stack aprobado |

---

## Qué versionar

| Qué | ¿Va a git? | Motivo |
|---|---|---|
| `Codigo/` | ✅ Siempre | Es el producto |
| `CLAUDE.md`, `AGENTS.md`, bridges | ✅ Recomendado | El equipo comparte instrucciones coherentes |
| `IA_Memoria/` | 🔶 Opcional | Útil para equipos; prescindible en repos individuales |
| `Features/`, `Issues/` | 🔶 Opcional | Depende de si el equipo los usa como documentación |
| `IA_Skill/` | ❌ No recomendado | Son prompts del agente, mejor fuera del repo de producto |
| `IA_Memoria/snapshots/` | ❌ Nunca | Archivos temporales, potencialmente pesados |

---

## Checklist para publicar como template

- [ ] Sin secretos en ningún archivo (keys, tokens, passwords)
- [ ] `IA_Memoria/` sin datos internos de clientes
- [ ] Descripciones genéricas en `arquitectura.md` y `progreso.md`
- [ ] `Codigo/.gitignore` actualizado
- [ ] Licencia incluida (ej. MIT)

---

## Roadmap

- [x] Soporte para Claude Code, Copilot, Gemini CLI, OpenCode, Codex CLI
- [x] 24 Skills técnicas por dominio
- [x] Sistema de snapshots con Repomix (condicional, por módulo)
- [x] Protocolo post-snapshot para mantener memoria sincronizada
- [ ] Integración con MCP servers (ej. CodeGraph para navegación semántica del código)
- [ ] CLI / script de setup automatizado
- [ ] Skills adicionales: Docker, Azure DevOps Pipelines
