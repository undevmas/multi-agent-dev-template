# GUIDE — Cómo sacarle el máximo provecho al template

> Guía práctica de 5 pasos. Síguela en orden cada vez que arrancas o retomas un proyecto.
> Validada contra el código real del template — cada sección describe lo que el template realmente hace.

---

## Agentes soportados y cómo leen el contexto

| Agente | Archivo de instrucciones | Lo lee automáticamente | Skills y snapshots |
|---|---|---|---|
| **Claude Code** | `CLAUDE.md` | ✅ Sí, al abrir la sesión | El agente los lee con herramientas nativas |
| **Gemini CLI** | `.gemini/GEMINI.md` | ✅ Sí, al iniciar | El agente los lee con herramientas nativas |
| **OpenCode** | `AGENTS.md` | ✅ Sí, al iniciar | El agente los lee con herramientas nativas |
| **Codex CLI** | `AGENTS.md` | ✅ Sí, al iniciar | El agente los lee con herramientas nativas |
| **Cursor** | `.cursor/rules/project.mdc` | ✅ Sí, automático | ⚠️ Skills y snapshots adjuntar con `@archivo` o arrastrar al contexto |
| **GitHub Copilot** | `.github/copilot-instructions.md` | ✅ Sí, automático | ⚠️ Requiere adjuntar cada archivo con `#file:` manualmente |

> **Nota Cursor:** las instrucciones base (`.cursor/rules/project.mdc`) se cargan automáticamente. Skills, specs y snapshots se adjuntan arrastrando el archivo al chat o usando `@archivo` en el prompt.
>
> **Nota Copilot:** las instrucciones base se cargan solas, pero todo archivo adicional (skills, specs, snapshots) debe adjuntarse explícitamente con `#file:ruta/archivo`. Los prompts de Copilot en esta guía ya incluyen los `#file:` necesarios.

---

## Paso 1 — El código siempre vive en `Codigo/`

Mueve o clona tu proyecto dentro de las subcarpetas correspondientes.
Los archivos fuera de `Codigo/` son contexto del agente — no se versionan en git.

```
Codigo/
├── frontend-angular/   ← Angular o React
├── backend-net/        ← API .NET
├── backend-nestjs/     ← API NestJS
├── database/           ← Migraciones SQL
└── docs/               ← Documentación técnica generada
```

**Regla:** si no está en `Codigo/`, no va al repositorio. Si está en `Codigo/`, sí va.

Los insumos de trabajo (mockups, HU, datos de prueba) van en `Insumos/` con esta estructura:

```
Insumos/
├── mockups/            ← PNG, PDF, exportaciones de Figma
├── especificaciones/   ← Word, PDF, MD con reglas de negocio
└── datos/              ← Seeds y escenarios de prueba (CSV, JSON)
```

---

## Paso 2 — Genera el snapshot con Repomix

El snapshot le da al agente una foto comprimida de todo el código.
Sin él, el agente adivina. Con él, parte de lo que realmente existe.

```powershell
# Windows — snapshot completo
.\repomix-scan.ps1

# Solo un módulo (más rápido si la tarea es acotada)
.\repomix-scan.ps1 -Target backend-net
.\repomix-scan.ps1 -Target backend-nestjs
.\repomix-scan.ps1 -Target frontend
.\repomix-scan.ps1 -Full   # sin compresión, máxima fidelidad
```

```bash
# Linux / macOS
./repomix-scan.sh
./repomix-scan.sh backend-net
./repomix-scan.sh backend-nestjs
./repomix-scan.sh frontend
./repomix-scan.sh --full
```

El snapshot se guarda en `IA_Memoria/snapshots/snapshot-latest.md`.

**Cuándo regenerar:** primera sesión, tarea que toca más de un módulo, snapshot con más de 7 días.
**Cuándo omitir:** fix puntual en un archivo conocido, cambio de texto, ajuste de config aislado.

> Requisito: Node.js 18+ instalado (Repomix corre vía `npx` sin instalación previa).

---

## Paso 3 — Pega el prompt de inspección en tu agente

Al terminar el scan, el script imprime un **prompt listo para copiar**.
Cópialo y pégalo en tu agente para que llene la memoria del proyecto.

El agente leerá el snapshot para llenar automáticamente:

| Archivo | Qué escribe el agente |
|---|---|
| `IA_Memoria/arquitectura.md` | Tecnologías detectadas, módulos, puertos, variables de entorno |
| `IA_Memoria/progreso.md` | Qué módulos existen y cuáles están pendientes |
| `IA_Memoria/convenciones.md` | Patrones de naming encontrados en el código real |

Esto evita que el agente te haga preguntas de arranque en cada sesión.
Si el proyecto está vacío, el agente lo indica — no inventa estructura.

### Prompts de inspección por agente

**Claude Code / Gemini CLI / OpenCode / Codex CLI**

El script ya imprime el prompt. Copiarlo y pegarlo es suficiente:

```
Lee IA_Memoria/snapshots/snapshot-latest.md.
Actualiza estos tres archivos con lo que encuentres en el snapshot.
No inventes ni asumas nada que no este en el snapshot:

1. IA_Memoria/arquitectura.md
   - Tecnologias y versiones reales detectadas
   - Modulos y servicios existentes con su estado actual
   - Puertos en docker-compose o archivos de configuracion
   - Variables de entorno en .env.example o en el snapshot

2. IA_Memoria/progreso.md
   - Marca [x] solo los modulos/features que realmente existan en el snapshot
   - Deja [ ] los que no esten implementados
   - Si el proyecto esta vacio: escribe "Proyecto nuevo, sin modulos implementados"

3. IA_Memoria/convenciones.md
   - Confirma o corrige los patrones de naming detectados en el snapshot
   - Deja [COMPLETAR] donde no puedas inferirlo del snapshot
```

**Cursor**

Adjuntar el snapshot desde el chat (`@IA_Memoria/snapshots/snapshot-latest.md`) y pegar el mismo prompt de Claude Code / Gemini CLI:

```
@IA_Memoria/snapshots/snapshot-latest.md

Lee el snapshot adjunto.
Actualiza estos tres archivos con lo que encuentres en el snapshot.
No inventes ni asumas nada que no esté en el snapshot:

1. IA_Memoria/arquitectura.md
2. IA_Memoria/progreso.md
3. IA_Memoria/convenciones.md
```

**GitHub Copilot**

Copilot no puede leer archivos por sí solo. Adjuntar manualmente:

```
#file:IA_Memoria/snapshots/snapshot-latest.md

Inspecciona el snapshot adjunto.
Actualiza los tres archivos de memoria con lo que encuentres en el snapshot.
No inventes ni asumas nada que no esté en el snapshot:

1. IA_Memoria/arquitectura.md — tecnologías, módulos, puertos, variables de entorno
2. IA_Memoria/progreso.md — marca solo lo que realmente exista en el snapshot
3. IA_Memoria/convenciones.md — patrones de naming detectados en el snapshot
```

---

## Paso 4 — Invoca al agente spec para definir qué construir

Antes de codificar, el agente spec convierte cualquier insumo en una especificación ejecutable.
No toca código — solo genera archivos `.md` en `Features/`.

### Qué puedes entregarle como insumo

- Documento Word / PDF con historia de usuario o PRD → extrae actores, flujos y reglas
- Imágenes o mockups de pantallas → lee pantallas e infiere comportamiento
- Notas informales o ideas sueltas → estructura, hace preguntas y genera la spec
- Código existente o snapshot → documenta lo que ya existe y especifica solo lo nuevo

### Qué produce (tres archivos por feature)

```
Features/
├── [mod].md          ← Requisitos de negocio, actores, User Stories, criterios de éxito
├── [mod].spec.md     ← Contrato técnico: entidades, endpoints, reglas de negocio
└── [mod].checks.md   ← Checklist de verificación post-implementación
```

Para features grandes, el agente detecta automáticamente el Epic y presenta una propuesta de descomposición **antes** de generar specs. No arranca a especificar por su cuenta.

### Ciclo de vida de la spec (validado en SKILL-spec-generator.md y Features/README.md)

```
draft → needs-clarification → ready → in-progress → in-review → done
```

Solo cuando el estado es `ready` el agente de implementación puede arrancar.
Si quedan ambigüedades críticas, el agente entrega en `needs-clarification` con las preguntas listadas.

### Prompts del agente spec por agente

**Claude Code**

```
Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [nombre del módulo].
Insumo: [adjunta el archivo o pega el texto aquí]
```

**Gemini CLI**

```
Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [nombre del módulo].
Insumo: [adjunta el archivo o pega el texto aquí]
```

**OpenCode**

```
Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [nombre del módulo].
Insumo: [adjunta el archivo o pega el texto aquí]
```

**Codex CLI**

```
Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [nombre del módulo].
Insumo: [adjunta el archivo o pega el texto aquí]
```

**Cursor**

Adjuntar la skill arrastrándola al contexto o con `@`:

```
@IA_Skill/SKILL-spec-generator.md

Genera la spec de [nombre del módulo] siguiendo SKILL-spec-generator.md.
Insumo: [adjunta el archivo con @ o pega el texto aquí]
```

**GitHub Copilot**

Adjuntar la skill y el insumo manualmente:

```
#file:IA_Skill/SKILL-spec-generator.md
#file:Insumos/especificaciones/[mi-insumo].md

Genera la spec de [nombre del módulo] siguiendo SKILL-spec-generator.md.
Produce los tres archivos: Features/[mod].md, Features/[mod].spec.md, Features/[mod].checks.md
```

Si el insumo es una imagen o mockup, adjuntarlo también con `#file:Insumos/mockups/[archivo].png`.

---

## Paso 5 — El agente de implementación codifica desde la spec

Con la spec en estado `ready`, el agente sabe exactamente qué construir.
Lee solo lo que necesita — memoria, spec y la Skill técnica del stack — sin abrir archivos innecesarios.

**Bloqueo confirmado:** si `[mod].spec.md` no existe o su estado no es `ready`, el agente de implementación se detiene y lo informa. No implementa con especificación incompleta.

### Qué hace internamente (validado en SKILL-implementation.md)

1. Lee `Features/[mod].md` + `Features/[mod].spec.md` + `Features/[mod].checks.md`
2. Lee `IA_Memoria/arquitectura.md` → `convenciones.md` → `deuda-tecnica.md`
3. Consulta la Skill técnica del stack declarado en la spec (`.NET`, `NestJS`, `Angular`, etc.)
4. Implementa dentro de `Codigo/` únicamente
5. Completa `Features/[mod].checks.md` con el reporte de verificación
6. Marca la feature como `in-review` en `Features/[mod].md` y sincroniza `IA_Memoria/progreso.md`

El estado `done` solo lo puede asignar el dev — nunca el agente.

### Prompts de implementación por agente

**Claude Code**

```
Lee IA_Skill/SKILL-implementation.md e implementa Features/[mod]
```

**Gemini CLI**

```
Lee IA_Skill/SKILL-implementation.md e implementa Features/[mod]
```

**OpenCode**

```
Lee IA_Skill/SKILL-implementation.md e implementa Features/[mod]
```

**Codex CLI**

```
Lee IA_Skill/SKILL-implementation.md e implementa Features/[mod]
```

**Cursor**

```
@IA_Skill/SKILL-implementation.md
@Features/[mod].md
@Features/[mod].spec.md
@Features/[mod].checks.md

Implementa Features/[mod] siguiendo SKILL-implementation.md.
```

**GitHub Copilot**

Adjuntar la skill, la spec y los checks:

```
#file:IA_Skill/SKILL-implementation.md
#file:Features/[mod].md
#file:Features/[mod].spec.md
#file:Features/[mod].checks.md
#file:IA_Memoria/arquitectura.md
#file:IA_Memoria/convenciones.md

Implementa Features/[mod] siguiendo SKILL-implementation.md.
El contrato técnico está en [mod].spec.md. No inventar comportamiento no declarado en la spec.
```

Si el módulo tiene deuda técnica registrada, agregar también:

```
#file:IA_Memoria/deuda-tecnica.md
```

### Alternativa sin spec previa

Si el módulo es simple y no requiere el flujo spec-driven completo, existe `SKILL-mvc-feature.md` para implementar un módulo full-stack de principio a fin en una sola sesión. Para Claude Code / Gemini / OpenCode / Codex:

```
Lee IA_Skill/SKILL-mvc-feature.md e implementa el módulo [nombre]
```

Para Copilot: `#file:IA_Skill/SKILL-mvc-feature.md` + prompt equivalente.

---

## Flujo completo en resumen

```
1. Código en Codigo/
           ↓
2. .\repomix-scan.ps1  (o ./repomix-scan.sh)
           ↓
3. Copiar prompt de inspección → pegar en el agente
   → agente llena IA_Memoria/ (arquitectura, progreso, convenciones)
           ↓
4. Entregar insumo al agente spec
   → "Lee IA_Skill/SKILL-spec-generator.md y genera la spec de [módulo]"
   → agente genera Features/[mod].md + .spec.md + .checks.md → estado: ready
   → dev revisa y aprueba
           ↓
5. Agente implementa
   → "Lee IA_Skill/SKILL-implementation.md e implementa Features/[mod]"
   → agente implementa en Codigo/ y completa checks → estado: in-review
   → dev revisa → estado: done (solo el dev lo asigna)
```

---

## Skills disponibles (validadas en el template)

33 skills organizadas por dominio. El agente lee solo la que corresponde a la tarea actual.

| Área | Skills |
|---|---|
| **Especificaciones** | `SKILL-spec-generator.md` |
| **Implementación full stack** | `SKILL-implementation.md` · `SKILL-mvc-feature.md` · `SKILL-database-migrations.md` |
| **Frontend — diseño visual** | `frontend-design/SKILL-component-patterns.md` · `frontend-design/SKILL-design-tokens.md` · `frontend-design/SKILL-typography-system.md` · `frontend-design/SKILL-layout-spacing-system.md` · `frontend-design/SKILL-visual-identity-override.md` · `frontend-design/SKILL-dark-mode-theming.md` · `frontend-design/SKILL-responsive-pwa-patterns.md` · `frontend-design/SKILL-animation-microinteractions.md` · `frontend-design/SKILL-accessibility-a11y.md` |
| **Testing frontend** | `SKILL-angular-test-frameworks.md` · `SKILL-react-test-frameworks.md` |
| **Backend .NET** | `SKILL-dotnet-best-practices.md` · `SKILL-dotnet-design-pattern-review.md` · `SKILL-dotnet-test-frameworks.md` · `SKILL-dotnet-upgrade.md` |
| **Backend NestJS** | `SKILL-nestjs-best-practices.md` · `SKILL-nestjs-patterns.md` · `SKILL-nestjs-clean-typescript.md` · `SKILL-nestjs-test-frameworks.md` |
| **Seguridad** | `SKILL-security-angular.md` · `SKILL-security-dotnet.md` · `SKILL-security-nestjs.md` · `SKILL-security-owasp-checklist.md` · `SKILL-agent-owasp-compliance.md` |
| **Texto y docs** | `SKILL-humanizer.md` · `SKILL-docs-feature.md` |
| **Soporte del agente** | `SKILL-web-search.md` · `SKILL-caveman.md` · `SKILL-pr-review-fixes.md` |

Para invocar cualquier skill con Copilot: `#file:IA_Skill/SKILL-[nombre].md` antes del prompt.

---

## Preguntas frecuentes

**¿Qué pasa si el agente pide leer el snapshot y no existe?**
Ejecuta `.\repomix-scan.ps1` primero. El agente no puede adivinar el estado real del código.

**¿El agente spec puede trabajar con código que ya existe?**
Sí. Entregale el snapshot o el código directamente. Documentará lo que existe y especificará solo lo nuevo — sin reinventar lo que ya funciona.

**¿Puedo saltarme la spec y pedir al agente que codifique directamente?**
Puedes usar `SKILL-mvc-feature.md` para módulos simples. Para features con reglas de negocio, el flujo spec-driven evita ambigüedades que después cuestan horas de corrección.

**¿Qué pasa si la spec tiene `[NEEDS CLARIFICATION]`?**
El agente de implementación usa el default documentado en ese ítem y lo reporta. No inventa comportamiento ni bloquea la implementación — solo informa qué defaults aplicó.

**¿Por qué Copilot requiere `#file:` para todo?**
Copilot no tiene acceso nativo al filesystem del workspace como Claude Code, Gemini CLI u OpenCode. El `#file:` es la forma de adjuntar archivos al contexto de la conversación. Para sesiones largas con Copilot, adjuntar solo los archivos relevantes a la tarea actual — no todos a la vez.

**¿Cuándo leer el snapshot vs. no leerlo?**
Solo si la tarea afecta más de un módulo, es la primera sesión, o hay una decisión de arquitectura involucrada.
Para fixes en un archivo conocido, cambios de texto o config: omitirlo.

**¿Cómo reportar un bug encontrado durante el desarrollo?**
Usar `Issues/TEMPLATE_BUG.md` como base. Los bugs van en `Issues/` — no en `Features/`.
