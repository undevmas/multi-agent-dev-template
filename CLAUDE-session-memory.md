# Memoria de Sesión — Multi-Agent Dev Template

> Este archivo es para Claude, no para los agentes del template.
> Pégalo al inicio de una sesión nueva para continuar sin perder contexto.
> Última actualización: Mayo 2025

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

**GitHub:** `multi-agent-dev-template-main` (compartido como .zip en sesiones)
**Estado actual:** v2, funcional de punta a punta

### Estructura del template (lo que existe hoy)

```
workspace/
├── CLAUDE.md              ← Fuente de verdad (Claude Code)
├── AGENTS.md              ← OpenCode + Codex CLI (paridad con CLAUDE.md)
├── .gemini/GEMINI.md      ← Gemini CLI (versión media)
├── .github/copilot-instructions.md  ← Copilot (versión compacta, límite contexto)
├── IA_Skill/              ← 27 skills técnicas
├── IA_Memoria/            ← Estado del proyecto (templates vacíos)
├── Features/              ← Specs de features (patrón 3 archivos)
├── Issues/                ← Template de bug report
├── Insumos/               ← Mockups y HUs del dev
├── Codigo/                ← ÚNICO que va a git
├── repomix-scan.ps1/.sh   ← Genera snapshot + prompt de inspección
├── README.md              ← Documentación pública
└── GUIDE.md               ← Guía práctica de 5 pasos con prompts por agente
```

---

## Lo que se construyó en estas sesiones (cronológico)

### Fase 1 — Limpieza y flujo base
- Se limpió `IA_Memoria/progreso.md` de contenido específico del proyecto original
- Se mejoró el prompt de inspección en `repomix-scan.ps1/.sh` — el agente ahora
  sabe exactamente qué escribir en cada archivo de memoria y cómo manejar
  proyectos vacíos vs proyectos con código existente

### Fase 2 — Política de código legado
**Decisión de diseño clave:** las convenciones del template nunca se bajan
para acomodar código legado. Se aplican donde es posible sin romper lo que funciona.

Tres zonas definidas en `CLAUDE.md` y replicadas a todos los bridges:
- **Zona verde:** código nuevo → estándar completo siempre
- **Zona ámbar:** código existente a modificar → mínimo necesario, sin refactorizar sin ticket
- **Zona roja:** código intocable sin ticket → detectar, documentar, no tocar

Se creó `IA_Memoria/deuda-tecnica.md` — inventario separado de `progreso.md`.
Cada entrada tiene: descripción, ubicación, impacto, riesgo, política aplicada,
y **condición de salida obligatoria** (sin esto no es deuda, es queja).

### Fase 3 — Spec-Driven Development (inspirado en spec-kit de GitHub)
Se analizó el repo `github/spec-kit`. Decisión: absorber principios, no el sistema.

**Lo adoptado de spec-kit:**
- Separación spec (qué) / plan técnico (cómo) / tasks
- Marcadores `[NEEDS CLARIFICATION]` — el agente declara sus suposiciones
- Given/When/Then por User Story como criterios de aceptación ejecutables
- Criterios de éxito medibles y tech-agnósticos
- Constitution gates antes de implementar (ahora en CLAUDE.md)

**Lo descartado:** CLI `specify`, estructura de carpetas `specs/NNN-feature/`,
constitution articles incompatibles con stack enterprise (Library-First, CLI-Mandate).

### Fase 4 — Patrón de 3 artefactos por feature
Cada módulo tiene exactamente 3 archivos en `Features/`:

| Archivo | Quién lo escribe | Quién lo lee |
|---|---|---|
| `[mod].md` | Dev + agente spec | Todos — requisitos y estado |
| `[mod].spec.md` | Agente spec | Agente implementación — contrato técnico |
| `[mod].checks.md` | Agente spec | Agente implementación — verificación |

**Ciclo de vida de la spec:**
`draft` → `needs-clarification` → `ready` → `in-progress` → `in-review` → `done`
+ estados especiales: `epic`, `spike`, `legacy-debt`

**Fuente de verdad del estado:** `[mod].md` manda. `progreso.md` es el espejo.
El agente actualiza primero `[mod].md`, luego sincroniza `progreso.md`.

### Fase 5 — SKILL-spec-generator.md (698 líneas)
Skill para agente especializado en specs. **No toca código nunca.**

7 pasos: leer contexto → identificar insumo → detectar tamaño → preguntar (máx 3) →
generar 3 artefactos → registrar en memoria → reportar al dev

4 tipos de insumo que acepta: Word/HU, imágenes/mockups, notas sueltas, código existente

Protocolo para features grandes:
- Detecta señales (>5 US, >5 días estimados, dependencias internas, etc.)
- Genera `[mod]-epic.md` con propuesta de descomposición
- **Espera confirmación del dev** — nunca descompone en silencio

Protocolo para spikes:
- Si hay incertidumbre técnica que bloquea la spec → genera `[mod]-spike.md`
- La spec real espera el resultado del spike

El agente spec puede correr en un **chat separado del agente de implementación**:
acepta cualquier insumo, hace máx 3 preguntas con opciones, produce archivos `.md`.

### Fase 6 — SKILL-implementation.md
Skill para el agente de implementación. Cierra el ciclo que spec-generator abre.

8 pasos con regla de bloqueo explícita:
- Si no existe `[mod].spec.md` con estado `ready` → **PARA, no implementa**
- Lee los 3 artefactos ANTES de tocar código (checks.md como guía de trabajo, no cierre)
- Marca `in-progress` en `[mod].md` antes de escribir código
- Selecciona skill técnica del stack declarado en spec
- Implementa como traducción directa del contrato — no interpreta, no mejora
- Corre todos los checks — los de legado van a deuda-tecnica.md, no bloquean
- Marca `in-review` — nunca `done` (ese estado solo lo asigna el dev)

### Fase 7 — Ejemplo canónico: auth
`Features/auth.md` + `auth.spec.md` + `auth.checks.md`

Módulo de autenticación elegido por ser universal en cualquier proyecto enterprise.
Muestra en la práctica:
- 3 User Stories con todos sus escenarios de aceptación
- 3 tablas en BD (Users, RefreshTokens, RevokedTokens) con columnas completas
- 3 endpoints con contratos exactos de request/response/cookies/errores
- 8 reglas de negocio numeradas (RN-01 a RN-08) con casos no obvios
- 30 checks verificables en código organizados por categoría
- Bloque de reporte que el agente completa antes de marcar in-review

### Fase 8 — README y GUIDE
Ambos escritos y validados contra el repo real (no documentación inventada).

**README:** problema, agentes soportados, stack, estructura, cómo funciona en 4 capas,
quick start, flujos spec-driven y estándar, reglas críticas, qué versionar, roadmap.

**GUIDE:** guía de 5 pasos con prompts listos para copiar/pegar por cada agente.
Incluye variantes para Copilot (con `#file:`) para cada paso.

---

## Decisiones de diseño importantes (para no repetir discusiones)

**Por qué 3 archivos separados en vez de un .md con secciones:**
Un `.md` que hace 3 roles (requisitos, técnico, checks) crea conflictos de
propiedad (¿quién lo modifica?), de estado (¿cuál es la fuente de verdad?)
y de scope (los checks de legado bloquearían features nuevas).

**Por qué no adoptar spec-kit completo:**
Está diseñado para proyectos de librería/CLI greenfield. Su constitución asume
"Library-First, CLI-Mandate" que rompe el stack enterprise del template.
No tiene concepto de legado, deuda técnica ni convenciones de equipo.

**Por qué el agente spec no toca código nunca:**
Separación limpia de responsabilidades. Permite que un PM o analista
itere sobre la spec sin necesidad de un dev. El dev aprueba antes de
que cualquier código se toque.

**Por qué `done` solo lo asigna el dev:**
El agente de implementación puede declarar que está listo (`in-review`)
pero no puede saber si el resultado cumple las expectativas del negocio.
Ese juicio siempre es humano.

**Por qué la política de legado no negocia las convenciones:**
El código nuevo es el ejemplo de cómo debería ser el viejo.
La inconsistencia entre módulos legados y nuevos es intencional y temporal.
Si el agente adoptara los antipatrones del entorno para "ser consistente",
la deuda se perpetuaría indefinidamente.

---

## Gaps pendientes (lo que falta al template hoy)

- [ ] **Integración MCP servers** — en roadmap, no especificado aún
- [ ] **CLI / script de setup automatizado** — en roadmap
- [ ] **Skills faltantes:** Docker, Azure DevOps Pipelines
- [ ] **Segundo ejemplo canónico** — `auth` está hecho, podría añadirse uno
      con Epic descompuesto en slices para mostrar ese flujo

---

## Cómo continuar una sesión

Si el dev comparte el .zip del repo actualizado, leerlo antes de proponer cambios.
El repo cambia entre sesiones — no asumir que el último estado analizado aquí es el actual.

Preguntas útiles para arrancar:
- ¿Hay un .zip nuevo del repo?
- ¿Qué gap o feature quiere atacar hoy?
- ¿Hay feedback de devs que usaron el template?

El dev trabaja de forma iterativa: analiza → diseña → valida → genera archivos.
Prefiere entender el "por qué" antes de generar código/archivos.
Le interesa que el template funcione para los 3 escenarios:
proyecto nuevo, proyecto con baseline, y proyecto legado.
