# Memoria de Sesión — Multi-Agent Dev Template

> Este archivo es para Claude, no para los agentes del template.
> Pégalo al inicio de una sesión nueva para continuar sin perder contexto.
> Última actualización: Junio 2026

---

## Qué es este proyecto

Estás ayudando a desarrollar un **template de workspace para equipos enterprise**
que estandariza cómo trabajan múltiples agentes IA (Claude Code, Copilot, Gemini CLI,
OpenCode, Codex CLI) en un mismo proyecto. El template resuelve que cada sesión IA
empieza desde cero sin contexto del proyecto, stack ni convenciones del equipo.

El dueño del proyecto es desarrollador, trabaja con un equipo de devs,
y quiere que el template acelere el onboarding de cualquier dev con cualquier agente.

---

## Repositorio

**GitHub:** `multi-agent-dev-template` (en c:\devops\IA\multi-agent-dev-template)
**Estado actual:** v3, funcional de punta a punta — Codigo/ es ahora completamente genérico

### Estructura del template (estado actual)

```
workspace/
├── CLAUDE.md              ← Fuente de verdad (Claude Code)
├── AGENTS.md              ← OpenCode + Codex CLI (paridad con CLAUDE.md)
├── .gemini/GEMINI.md      ← Gemini CLI (versión media)
├── .github/copilot-instructions.md  ← Copilot (versión compacta, límite contexto)
├── IA_Skill/              ← 27 skills técnicas
├── IA_Memoria/            ← Estado del proyecto (templates vacíos)
│   ├── arquitectura.md    ← Reescrito: genérico con [COMPLETAR], nueva sección "Estructura de Codigo/"
│   ├── progreso.md
│   ├── convenciones.md
│   └── deuda-tecnica.md
├── Features/              ← Specs de features (patrón 3 archivos)
├── Issues/                ← Template de bug report
├── Insumos/               ← Mockups y HUs del dev
├── Codigo/                ← ÚNICO que va a git
│   ├── .gitignore         ← Cubre .NET + Node/TS + Angular + Docker + OS
│   └── repomix.config.json ← Config del scanner (genérico)
├── repomix-scan.ps1/.sh   ← Genera snapshot + prompt de inspección (genérico)
├── README.md
├── GUIDE.md
└── CLAUDE-session-memory.md ← Este archivo
```

**Nota:** `Codigo/` ya no tiene subcarpetas hardcodeadas. El dev pega su proyecto
directamente dentro con el nombre que quiera.

---

## Lo que se construyó en estas sesiones (cronológico)

### Fase 1 — Limpieza y flujo base
- Se limpió `IA_Memoria/progreso.md` de contenido específico del proyecto original
- Se mejoró el prompt de inspección en `repomix-scan.ps1/.sh`

### Fase 2 — Política de código legado
**Decisión de diseño clave:** las convenciones del template nunca se bajan
para acomodar código legado. Se aplican donde es posible sin romper lo que funciona.

Tres zonas definidas en `CLAUDE.md` y replicadas a todos los bridges:
- **Zona verde:** código nuevo → estándar completo siempre
- **Zona ámbar:** código existente a modificar → mínimo necesario, sin refactorizar sin ticket
- **Zona roja:** código intocable sin ticket → detectar, documentar, no tocar

Se creó `IA_Memoria/deuda-tecnica.md`.

### Fase 3 — Spec-Driven Development (inspirado en spec-kit de GitHub)
Se analizó el repo `github/spec-kit`. Decisión: absorber principios, no el sistema.

**Lo adoptado:** separación spec/plan técnico/tasks, marcadores `[NEEDS CLARIFICATION]`,
Given/When/Then por User Story, criterios de éxito medibles, constitution gates.

**Lo descartado:** CLI `specify`, estructura de carpetas `specs/NNN-feature/`,
constitución incompatible con stack enterprise.

### Fase 4 — Patrón de 3 artefactos por feature
Cada módulo tiene exactamente 3 archivos en `Features/`:

| Archivo | Quién lo escribe | Quién lo lee |
|---|---|---|
| `[mod].md` | Dev + agente spec | Todos — requisitos y estado |
| `[mod].spec.md` | Agente spec | Agente implementación — contrato técnico |
| `[mod].checks.md` | Agente spec | Agente implementación — verificación |

**Ciclo de vida:** `draft` → `needs-clarification` → `ready` → `in-progress` → `in-review` → `done`

### Fase 5 — SKILL-spec-generator.md
Skill para agente especializado en specs. No toca código nunca. 7 pasos.
4 tipos de insumo: Word/HU, imágenes/mockups, notas sueltas, código existente.
Protocolo para epics (espera confirmación), protocolo para spikes.

### Fase 6 — SKILL-implementation.md
Skill para el agente de implementación. 8 pasos. Regla de bloqueo explícita:
si no existe `[mod].spec.md` con estado `ready` → PARA, no implementa.
Nunca marca `done` (solo el dev puede).

### Fase 7 — Ejemplo canónico: auth
`Features/auth.md` + `auth.spec.md` + `auth.checks.md`
3 User Stories, 3 tablas en BD, 3 endpoints con contratos completos,
8 reglas de negocio (RN-01 a RN-08), 30 checks verificables.

### Fase 8 — README y GUIDE
Ambos validados contra el repo real.
**GUIDE:** 5 pasos con prompts listos para copiar/pegar por cada agente.

### Fase 9 — Genericidad de Codigo/ (Junio 2026)

**Contexto:** el dev tiene un proyecto con Angular + NestJS en una sola carpeta
(`gestion-de-proyectos`), Docker sirve el Angular como static desde NestJS.
La pregunta era si conviene separar en subcarpetas o mantener todo junto.

**Decisiones tomadas:**

1. **Workspace = un sistema cohesionado** (un producto o microservicios relacionados).
   Múltiples productos sin relación → workspaces separados, no uno combinado.

2. **Codigo/ es ahora completamente genérico** — el dev pega su proyecto con el nombre
   que quiera, sin convención forzada. La fuente de verdad de rutas es `IA_Memoria/arquitectura.md`.

**Cambios aplicados (7 archivos):**

| Archivo | Cambio |
|---|---|
| `CLAUDE.md` | Sección "Estructura del workspace": 4 subcarpetas → `[nombre-proyecto]/` genérico + nota |
| `AGENTS.md` | Mismo cambio |
| `.gemini/GEMINI.md` | Mismo cambio |
| `.github/copilot-instructions.md` | Removido path hardcodeado `(Codigo/workflows/)` en regla NUNCA |
| `IA_Memoria/arquitectura.md` | Reescritura completa: rutas/puertos/techs → `[COMPLETAR]`, nueva sección "Estructura de Codigo/" |
| `repomix-scan.ps1` | Eliminado `ValidateSet` fijo; `$Target` libre; `$args` → `$npxArgs` (fix PS warning); prompt actualizado |
| `repomix-scan.sh` | `case` hardcodeado → lógica genérica; uso actualizado; prompt actualizado |

**Limpieza adicional:** eliminadas de `Codigo/` las carpetas vacías `backend-nestjs/`,
`backend-net/`, `database/`, `frontend-angular/`, `docs/`.

**Flujo resultante para cualquier proyecto:**
```
1. Copiar template
2. Pegar código en Codigo/<nombre-que-quieras>/
3. .\repomix-scan.ps1                      ← escanea todo
   .\repomix-scan.ps1 -Target mi-proyecto  ← escanea solo esa carpeta
4. Copiar el prompt → agente llena IA_Memoria/
5. Listo para trabajar features
```

---

## Decisiones de diseño importantes (para no repetir discusiones)

**Por qué 3 archivos separados en vez de un .md con secciones:**
Conflictos de propiedad, estado y scope. Los checks de legado bloquearían features nuevas.

**Por qué no adoptar spec-kit completo:**
Diseñado para proyectos de librería/CLI greenfield. Asume "Library-First, CLI-Mandate"
que rompe el stack enterprise. No tiene concepto de legado ni convenciones de equipo.

**Por qué el agente spec no toca código nunca:**
Separación limpia. Permite que un PM o analista itere la spec sin un dev.
El dev aprueba antes de que cualquier código se toque.

**Por qué `done` solo lo asigna el dev:**
El agente puede declarar `in-review` pero no puede saber si cumple expectativas de negocio.
Ese juicio siempre es humano.

**Por qué la política de legado no negocia las convenciones:**
El código nuevo es el ejemplo de cómo debería ser el viejo.
Si el agente adoptara los antipatrones del entorno, la deuda se perpetuaría.

**Por qué Codigo/ es genérico y no tiene subcarpetas fijas:**
El agente no navega por nombres de carpeta hardcodeados — navega por `IA_Memoria/arquitectura.md`.
Forzar nombres como `frontend-angular/` crea fricción cuando el proyecto se llama distinto
o tiene una estructura compuesta. La genericidad no sacrifica funcionalidad.

**Por qué un workspace = un sistema cohesionado:**
`IA_Memoria/` está diseñado para un sistema: arquitectura.md describe "el" sistema,
progreso.md trackea "el" avance, el snapshot repomix es coherente. Mezclar productos
no relacionados rompe esa coherencia y hace el contexto del agente inútil.

---

## Gaps pendientes (lo que falta al template hoy)

- [ ] **Integración MCP servers** — en roadmap, no especificado aún
- [ ] **CLI / script de setup automatizado** — en roadmap
- [ ] **Skills faltantes:** Docker, Azure DevOps Pipelines
- [ ] **Segundo ejemplo canónico** — `auth` está hecho, podría añadirse uno
      con Epic descompuesto en slices para mostrar ese flujo
- [x] **README y GUIDE** — actualizados: Codigo/ es genérico, prompts de inspección apuntan solo al snapshot (sin inspección directa de Codigo/), conteo de skills corregido a 27

---

## Cómo continuar una sesión

El repo está en `c:\devops\IA\multi-agent-dev-template`.
No hace falta compartir .zip — leer directamente del repo.

Preguntas útiles para arrancar:
- ¿Qué gap o feature quiere atacar hoy?
- ¿Hay feedback de devs que usaron el template?
- ¿Va a probar el template con su proyecto `gestion-de-proyectos`?

El dev trabaja de forma iterativa: analiza → diseña → valida → genera archivos.
Prefiere entender el "por qué" antes de generar código/archivos.
Le interesa que el template funcione para los 3 escenarios:
proyecto nuevo, proyecto con baseline, y proyecto legado.
