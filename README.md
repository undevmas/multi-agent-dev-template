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
│   ├── SKILL-spec-generator.md        ← Genera specs desde cualquier insumo
│   ├── SKILL-implementation.md        ← Implementa features desde spec
│   ├── SKILL-frontend-design.md
│   ├── SKILL-dotnet-best-practices.md
│   ├── SKILL-nestjs-best-practices.md
│   ├── SKILL-database-migrations.md
│   └── ... (27 skills en total)
│
├── IA_Memoria/                        ← Estado del proyecto (no va a git)
│   ├── progreso.md                    ← Vista agregada: qué está hecho y qué sigue
│   ├── arquitectura.md                ← Decisiones técnicas y estructura
│   ├── convenciones.md                ← Naming, commits, reglas
│   ├── deuda-tecnica.md               ← Inventario de código legado con antipatrones
│   └── snapshots/                     ← Snapshots de Repomix (no va a git)
│
├── Features/                          ← Especificaciones de módulos (no va a git)
│   ├── README.md                      ← Ciclo de vida y patrón de 3 archivos (leer primero)
│   ├── auth.md / auth.spec.md / auth.checks.md  ← Ejemplo canónico del formato
│   ├── [mod].md                       ← Tu feature: requisitos de negocio + estado del ciclo
│   ├── [mod].spec.md                  ← Tu feature: contrato técnico: API, entidades, reglas
│   └── [mod].checks.md                ← Tu feature: verificación post-implementación
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

El template opera en cuatro capas de contexto que el agente consume antes de tocar código:

```
Capa 1 — IA_Memoria/
  Contexto narrativo del proyecto: qué está hecho, convenciones,
  decisiones de arquitectura. Lo escriben humanos; el agente lo actualiza.

Capa 2 — Features/
  Especificaciones de cada módulo: requisitos de negocio, contratos técnicos
  y listas de verificación. El agente spec las genera; el agente de
  implementación las consume. Ninguno toca código sin leerlas.

Capa 3 — IA_Skill/
  26 guías técnicas especializadas: specs, implementación, testing, seguridad,
  migraciones, UX... El agente lee solo la que corresponde a la tarea.

Capa 4 — Snapshots Repomix
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

El agente leerá el snapshot para llenar automáticamente los tres archivos de memoria:

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
| **Especificaciones** | Generar specs desde cualquier insumo (Word, mockups, notas, código) |
| **Full Stack** | Implementar desde spec · Módulo MVC completo · Migraciones de BD |
| **Frontend** | Componentes visuales · UX y formularios · Code review · SEO · Tests Angular · Tests React |
| **Backend .NET** | Best practices · Design patterns · Tests unitarios e integración · Upgrade de versión |
| **Backend NestJS** | Best practices · CQRS / eventos / colas · TypeScript estricto · Tests |
| **Seguridad** | Angular · .NET · NestJS · Checklist OWASP pre-producción · Compliance agentes |
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

### Flujo spec-driven (recomendado para features nuevas)

```
1. Dev entrega insumo al agente spec (Word, mockup, notas, código)
        ↓
2. Agente spec lee SKILL-spec-generator → genera Features/[mod].md
   + Features/[mod].spec.md + Features/[mod].checks.md
        ↓
3. Dev revisa y aprueba la spec (estado pasa a ready)
        ↓
4. Agente de implementación lee SKILL-implementation → implementa
   siguiendo Features/[mod].spec.md como contrato
        ↓
5. Agente completa Features/[mod].checks.md → marca in-review
        ↓
6. Dev revisa → marca done en Features/[mod].md
```

### Flujo de sesión estándar

```
1. Regenerar snapshot (si hay cambios desde la última sesión)
        ↓
2. El agente lee: progreso → arquitectura → convenciones
        ↓
3. Si aplica: leer Features/[mod].md + Features/[mod].spec.md (si existe en ready/in-progress)
        ↓
4. El agente consulta la Skill técnica relevante
        ↓
5. Implementación dentro de Codigo/ únicamente
        ↓
6. Al cerrar: actualizar Features/[mod].md (estado) → sincronizar IA_Memoria/progreso.md
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

## Checklist antes de versionar tu workspace

Cuando tu equipo decida subir el workspace a un repositorio compartido o público,
verificar que no se filtre contexto del proyecto:

- [ ] Ningún archivo contiene secretos (API keys, tokens, passwords)
- [ ] `IA_Memoria/` no tiene datos internos de clientes o información sensible del negocio
- [ ] `arquitectura.md` y `progreso.md` no exponen detalles confidenciales si el repo es público
- [ ] `Codigo/.gitignore` excluye snapshots, archivos generados y variables de entorno
- [ ] Si el repo es público, incluir una licencia (ej. MIT)

---

## Roadmap

- [x] Soporte para Claude Code, Copilot, Gemini CLI, OpenCode, Codex CLI
- [x] 26 Skills técnicas por dominio
- [x] Sistema de snapshots con Repomix (condicional, por módulo)
- [x] Protocolo post-snapshot para mantener memoria sincronizada
- [x] Flujo spec-driven completo: SKILL-spec-generator → SKILL-implementation → checks
- [x] Política de trabajo con código legado (zonas verde / ámbar / roja)
- [x] Inventario de deuda técnica (`IA_Memoria/deuda-tecnica.md`)
- [ ] Integración con MCP servers (ej. CodeGraph para navegación semántica del código)
- [ ] CLI / script de setup automatizado
- [ ] Skills adicionales: Docker, Azure DevOps Pipelines
