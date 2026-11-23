# GUIDE — Cómo sacarle el máximo provecho al template

> Guía práctica de 5 pasos. Síguela en orden cada vez que arrancas o retomas un proyecto.
> Validada contra el código real del template — cada sección describe lo que el template realmente hace.

---

## Agentes soportados y cómo leen el contexto

| Agente                            | Archivo de instrucciones          | Lo lee automáticamente    | Skills y snapshots                                                                     |
| --------------------------------- | --------------------------------- | ------------------------- | -------------------------------------------------------------------------------------- |
| **Antigravity** (Google DeepMind) | AGENTS.md / .gemini/GEMINI.md     | ✅ Sí, automático         | Lectura bajo demanda con herramientas nativas vía IA_Skill/SKILL-instruction-router.md |
| **Claude Code**                   | `CLAUDE.md` → importa `AGENTS.md` | ✅ Sí, al abrir la sesión | El agente los lee con herramientas nativas                                             |
| **Gemini CLI**                    | `.gemini/GEMINI.md` → importa `AGENTS.md` | ✅ Sí, al iniciar | El agente los lee con herramientas nativas                                     |
| **OpenCode**                      | `AGENTS.md`                       | ✅ Sí, al iniciar         | El agente los lee con herramientas nativas                                             |
| **Codex CLI**                     | `AGENTS.md`                       | ✅ Sí, al iniciar         | El agente los lee con herramientas nativas                                             |
| **Cursor**                        | `AGENTS.md` + `.cursor/rules/project.mdc` (puntero) | ✅ Sí, automático | ⚠️ Skills y snapshots adjuntar con `@archivo` o arrastrar al contexto |
| **GitHub Copilot**                | `AGENTS.md` + `.github/copilot-instructions.md` (puntero) | ✅ Sí, automático | ⚠️ Requiere adjuntar cada archivo con `#file:` manualmente |

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
# Windows — snapshot completo (bootstrap: genera tambien IA_Memoria/modulos.json)
.\repomix-scan.ps1 -Target all

# Un modulo puntual: acepta cualquier ruta relativa a Codigo/, no solo los alias de abajo
.\repomix-scan.ps1 -Target "MiApp/src/Gateway" -Stack dotnet
.\repomix-scan.ps1 -Target backend-net      # alias de conveniencia (Codigo/backend-net/, stack dotnet)
.\repomix-scan.ps1 -Target backend-nestjs   # alias (Codigo/backend-nestjs/, stack nestjs)
.\repomix-scan.ps1 -Target frontend         # alias (Codigo/frontend-angular/, stack angular)
.\repomix-scan.ps1 -Full   # sin compresión, máxima fidelidad
```

```bash
# Linux / macOS
./repomix-scan.sh all
./repomix-scan.sh "MiApp/src/Gateway" --stack=dotnet
./repomix-scan.sh backend-net
./repomix-scan.sh backend-nestjs
./repomix-scan.sh frontend
./repomix-scan.sh --full
```

Stacks soportados en `-Stack`/`--stack`: `dotnet` · `nestjs` · `angular` · `react` · `python-fastapi`.
Cada uno trae su propio preset de ignore (bin/obj, node_modules, .venv, etc.) — sin `-Stack`, se usa un preset genérico que cubre todos.

El snapshot se guarda en `IA_Memoria/snapshots/snapshot-latest.md` (o `snapshot-<módulo>.md` para un target puntual).

**Cuándo regenerar completo (`-Target all`):** primera sesión, refactor amplio, o cuando cambió la estructura de módulos.
**Cuándo escanear un módulo puntual:** la tarea toca 1-2 módulos conocidos — evita empaquetar todo el monorepo por un cambio acotado.
**Cuándo omitir cualquier scan:** fix puntual en un archivo ya conocido, cambio de texto, ajuste de config aislado.

> Requisito: Node.js 18+ instalado. El primer escaneo puede hacer que `npx` descargue en su caché la versión fijada de Repomix; requiere acceso a npm y no modifica las dependencias de `Codigo/`.

### Escaneo dirigido por módulo (proyectos con varios servicios)

Si el proyecto tiene varios módulos/microservicios (ej. un monorepo `src/Gateway`, `src/Identity`, `src/Catalogo`...),
correr `-Target all` cada vez es desperdiciar contexto en módulos que la tarea actual no toca. Después del primer
bootstrap (`-Target all`), el agente deja un manifest en `IA_Memoria/modulos.json` con el nombre, ruta y stack de
cada módulo real detectado. A partir de ahí, usa el orquestador para escanear solo lo que necesitas:

```powershell
# Windows — todos los módulos del manifest, uno por uno (no un solo blob gigante)
.\repomix-scan-modules.ps1

# Solo los módulos relevantes para la tarea de hoy
.\repomix-scan-modules.ps1 -Modules Gateway,Identity
```

```bash
# Linux / macOS
./repomix-scan-modules.sh
./repomix-scan-modules.sh --modules=Gateway,Identity
```

El script genera un snapshot por módulo seleccionado y un solo prompt de inspección consolidado, con guía de
lectura específica según el stack de cada módulo. Si `IA_Memoria/modulos.json` no existe todavía, el script lo indica
y sugiere correr `-Target all` primero.

---

## Paso 3 — Pega el prompt de inspección en tu agente

Al terminar el scan, el script imprime un **prompt listo para copiar**.
Cópialo y pégalo en tu agente para que llene la memoria del proyecto.

El agente leerá el snapshot para llenar automáticamente:

| Archivo                       | Qué escribe el agente                                                         |
| ----------------------------- | ----------------------------------------------------------------------------- |
| `IA_Memoria/arquitectura.md`  | Tecnologías detectadas, módulos, puertos, variables de entorno                |
| `IA_Memoria/progreso.md`      | Qué módulos existen y cuáles están pendientes                                 |
| `IA_Memoria/convenciones.md`  | Patrones de naming encontrados en el código real                              |
| `IA_Memoria/deuda-tecnica.md` | Antipatrones reales detectados (solo si el proyecto ya tiene código)          |
| `IA_Memoria/modulos.json`     | Manifest de módulos (nombre, ruta, stack) — lo consume `repomix-scan-modules` |

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

4. IA_Memoria/deuda-tecnica.md (solo si el proyecto tiene codigo existente)
   - Registra antipatrones reales: IDs secuenciales, DELETE directo, credenciales hardcodeadas, etc.

5. IA_Memoria/modulos.json
   - { "generatedAt": "...", "modules": [{ "name", "path", "stack" }, ...] } — un entry por modulo/microservicio real
```

> Nota: el bloque de arriba es la versión resumida. El propio `repomix-scan.ps1`/`.sh` imprime el prompt completo
> y actualizado al terminar cada scan — cuando difieran, el que imprime el script es la fuente de verdad.

**Cursor**

Adjuntar el snapshot desde el chat (`@IA_Memoria/snapshots/snapshot-latest.md`) y pegar el mismo prompt de Claude Code / Gemini CLI:

```
@IA_Memoria/snapshots/snapshot-latest.md

Lee el snapshot adjunto.
Actualiza estos archivos con lo que encuentres en el snapshot.
No inventes ni asumas nada que no esté en el snapshot:

1. IA_Memoria/arquitectura.md
2. IA_Memoria/progreso.md
3. IA_Memoria/convenciones.md
4. IA_Memoria/deuda-tecnica.md
5. IA_Memoria/modulos.json
```

**GitHub Copilot**

Copilot no puede leer archivos por sí solo. Adjuntar manualmente:

```
#file:IA_Memoria/snapshots/snapshot-latest.md

Inspecciona el snapshot adjunto.
Actualiza los archivos de memoria con lo que encuentres en el snapshot.
No inventes ni asumas nada que no esté en el snapshot:

1. IA_Memoria/arquitectura.md — tecnologías, módulos, puertos, variables de entorno
2. IA_Memoria/progreso.md — marca solo lo que realmente exista en el snapshot
3. IA_Memoria/convenciones.md — patrones de naming detectados en el snapshot
4. IA_Memoria/deuda-tecnica.md — antipatrones reales (solo si hay código existente)
5. IA_Memoria/modulos.json — manifest {name, path, stack} por módulo/microservicio real
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
2. .\repomix-scan.ps1 -Target all  (o ./repomix-scan.sh all)  ← primera vez o refactor amplio
           ↓
3. Copiar prompt de inspección → pegar en el agente
   → agente llena IA_Memoria/ (arquitectura, progreso, convenciones, deuda-tecnica, modulos.json)
           ↓
   [tareas siguientes acotadas a 1-2 módulos → .\repomix-scan-modules.ps1 -Modules X,Y en vez de repetir el paso 2]
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

63 skills propias organizadas por dominio, más 30 skills oficiales de Microsoft para .NET en `IA_Skill/dotnet-official/` archify para diagramas en `IA_Skill/archify-official/`, y 210 guías oficiales de la plataforma web moderna (GoogleChrome) en `IA_Skill/web-official/`. El ruteo completo (cuándo leer cada una) está en `IA_Skill/README.md`. El agente lee solo la que corresponde a la tarea actual.

| Área | Skills |
|---|---|
| **Especificaciones** | `SKILL-spec-generator.md` (flujo completo Features/) · `SKILL-functional-spec-elicitation.md` (armar la HU desde insumos ambiguos) · `SKILL-technical-foundations-brief.md` (fundamentos técnicos no prescriptivos a partir de una HU + código) |
| **Implementación full stack** | `SKILL-implementation.md` · `SKILL-mvc-feature.md` · `SKILL-database-migrations.md` · `SKILL-aspire-orchestration.md` (orquestación local con Aspire) |
| **Testing E2E** | `SKILL-e2e-playwright.md` (Playwright por defecto; Cypress solo con autorización) |
| **Frontend — diseño visual** | `frontend-design/SKILL-component-patterns.md` · `frontend-design/SKILL-design-tokens.md` · `frontend-design/SKILL-typography-system.md` · `frontend-design/SKILL-layout-spacing-system.md` · `frontend-design/SKILL-visual-identity-override.md` · `frontend-design/SKILL-dark-mode-theming.md` · `frontend-design/SKILL-responsive-pwa-patterns.md` · `frontend-design/SKILL-animation-microinteractions.md` · `frontend-design/SKILL-accessibility-a11y.md` |
| **Frontend — plataforma web moderna (GoogleChrome)** | `web-official/` — 210 guías curadas de [GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance) (CSS moderno, `@layer`/`@scope`/`@container`/`subgrid`, `<dialog>`/`[popover]`, Anchor Positioning, formularios `:user-invalid`, `light-dark()`, Core Web Vitals LCP/INP/CLS, accesibilidad WCAG, seguridad/CSP/Trusted Types/Sanitizer API y JS moderno). Complementan a las propias; si chocan, gana la plantilla. Se actualizan con `web-official/sync-web-skills.ps1` / `.sh` (ver su `README.md`) |
| **Testing frontend** | `SKILL-angular-test-frameworks.md` · `SKILL-react-test-frameworks.md` |
| **Backend .NET** | `SKILL-dotnet-best-practices.md` · `SKILL-dotnet-design-pattern-review.md` · `SKILL-dotnet-test-frameworks.md` · `SKILL-dotnet-upgrade.md` |
| **.NET — oficiales de Microsoft** | `dotnet-official/` — 30 skills curadas de [dotnet/skills](https://github.com/dotnet/skills) (Web API, EF Core, upgrade 8→10, MSBuild, rendimiento, benchmarks, IA/ML, calidad de tests). Complementan a las propias; si chocan, gana la plantilla. Se actualizan con `dotnet-official/sync-dotnet-skills.ps1` / `.sh` (ver su `README.md`) |
| **Backend NestJS** | `SKILL-nestjs-best-practices.md` · `SKILL-nestjs-patterns.md` · `SKILL-nestjs-clean-typescript.md` · `SKILL-nestjs-test-frameworks.md` |
| **Seguridad** | `SKILL-auth-patterns.md` (perfiles de autenticación A/B) · `SKILL-security-angular.md` · `SKILL-security-dotnet.md` · `SKILL-security-nestjs.md` · `SKILL-security-owasp-checklist.md` · `SKILL-agent-owasp-compliance.md` · `SKILL-preprod-security-audit.md` (auditoría pre-productiva con los escáneres de `Tools/`) · `SKILL-secrets-scanning.md` · `SKILL-dependency-vulnerability-triage.md` |
| **Texto y docs / entregables** | `SKILL-humanizer.md` · `SKILL-docs-feature.md` · `SKILL-technical-memory.md` · `SKILL-user-manual.md` · `SKILL-visual-evidence.md` (diagramas archify + capturas Playwright) · `document-artifacts/SKILL.md` |
| **Soporte del agente** | `SKILL-web-search.md` · `SKILL-caveman.md` · `SKILL-pr-review-fixes.md` · `SKILL-execution-principles.md` (principios de ejecución basados en Karpathy; resumen siempre activo en `AGENTS.md`) |

Para invocar cualquier skill con Copilot: `#file:IA_Skill/SKILL-[nombre].md` antes del prompt.

---

## Entregables: memoria técnica y manual de usuario

El agente escribe el contenido en Markdown y la plantilla aplica el formato institucional; los
diagramas salen del código (archify) y las capturas de la app real (Playwright).

```powershell
# Una vez por máquina
npm install; npx playwright install chromium; npm install --prefix Tools/entregables
node Tools/entregables/archify.mjs doctor

# Por entregable (el agente lo hace siguiendo la skill)
$env:EVIDENCIAS_DIR = 'Entregables/<Proyecto>/evidencias'; $env:EVIDENCIAS_REPO = 'Codigo/<proyecto>'
npm run evidencias                                    # diagramas → PNG y capturas reales
node Tools/entregables/build-docx.mjs Entregables/<Proyecto>/memoria-tecnica/memoria-tecnica.md
```

| Pide al agente | Skill | Resultado |
|---|---|---|
| "Genera la memoria técnica de <Proyecto>" | `SKILL-technical-memory.md` | `Memoria_Tecnica_<Sistema>_v1.0.docx` con diagramas de arquitectura, ERD, secuencias y anexo de trazabilidad |
| "Genera el manual de usuario de <Proyecto>" | `SKILL-user-manual.md` | `Manual_de_Usuario_<Sistema>_v1.0.docx` con procedimientos paso a paso y capturas reales |

Al abrir el `.docx`, Word pide actualizar campos: aceptar para completar índice e índice de
figuras. Las capturas se toman solo contra local/QA con datos de prueba y datos sensibles
enmascarados. `Entregables/` no se versiona (contiene documentos de sistemas reales).

---

## Auditoría pre-productiva de seguridad

El agente corre escáneres reales en contenedores de `Tools/` (SonarQube, Semgrep, Trivy,
Dependency-Check, Gitleaks, ZAP y pa11y) sobre un proyecto de `Codigo/` y consolida los
hallazgos; no se limita a leer el código.

```powershell
# Una vez por máquina (Docker Desktop en modo contenedores Linux)
.\Tools\setup-tools.ps1      # Linux/macOS: ./Tools/setup-tools.sh — crea Tools/.env y levanta SonarQube, Trivy y ZAP
# Paso manual único: entrar a SonarQube (URL que imprime el script), cambiar el password de admin,
# generar un token en My Account > Security y pegarlo en Tools/.env como SONAR_TOKEN
```

| Pide al agente | Skill | Resultado |
|---|---|---|
| "Actúa como agente analista pre-productivo. Proyecto: <proyecto>. Corre el análisis pre-prod completo" | `SKILL-preprod-security-audit.md` | `hallazgos-preprod.md` y `hallazgos-preprod.html` en `Entregables/<Proyecto>/auditoria-preprod/<YYYYMMDD_HHmm>/` |

Para ZAP y pa11y la app debe estar corriendo en tu máquina (el agente verifica el puerto).
ZAP solo hace spider + escaneo pasivo; el Active Scan requiere autorización explícita. Los
reportes crudos quedan en `Insumos/` y no se versionan (Gitleaks los genera con `--redact`).
Puertos, comandos sueltos y apagado: `Tools/README.md`.

---

## Candado de comprobación ("Claro team")

`AGENTS.md` (y los punteros de Copilot y Cursor, que no soportan imports) obliga al agente a empezar
**cada respuesta** con `Claro team`. No es un saludo: es una señal de integridad.

**Si una respuesta del agente no empieza con `Claro team`, sospechar que algo se rompió:**
el archivo de instrucciones no se cargó, quedó truncado o con conflictos de merge, una ruta
cambió, o el contexto se compactó y el agente perdió las reglas. Qué hacer:

1. No aceptar los cambios de esa respuesta.
2. Correr la verificación de integridad:
   ```powershell
   .\IA_Skill\check-instruction-policy-sync.ps1
   ```
   Verifica la fuente única (`AGENTS.md`) y los imports de `CLAUDE.md`/`GEMINI.md`, el candado, el
   presupuesto de líneas, que no haya marcadores de conflicto de merge, que todas las skills citadas
   existan y la política de autonomía. `.\IA_Skill\test-antigravity-workflow.ps1` valida el ruteo.
3. Corregir lo que reporte y abrir una sesión nueva del agente.

El candado aplica solo a los mensajes del chat: el agente nunca lo escribe en archivos, código,
commits ni PRs. Si se cambia la frase, cambiarla en `AGENTS.md`, en los punteros de Copilot y
Cursor, y en el script.

## Estructura de las instrucciones (estándar AGENTS.md)

- **`AGENTS.md` es la fuente única** y se mantiene en ≤150 líneas (lo hace cumplir el script):
  contexto, candado, stack en una línea por capa, comandos de verificación, reglas críticas e índice.
- `CLAUDE.md` = `@AGENTS.md` + lo propio de Claude Code; `.gemini/GEMINI.md` = `@../AGENTS.md`;
  Copilot y Cursor tienen punteros cortos (≤40 líneas).
- Lo detallado se lee bajo demanda: política de autonomía (`IA_Skill/SKILL-autonomy-policy.md`),
  stack y reglas por tecnología (`IA_Skill/SKILL-stack-policy.md`), catálogo situación → skill
  (`IA_Skill/README.md`) y router (`IA_Skill/SKILL-instruction-router.md`).
- Cada proyecto puede tener su `Codigo/<proyecto>/AGENTS.md` (≤100 líneas, plantilla en
  `IA_Skill/templates/AGENTS.project.md`) con sus comandos de build/test y reglas locales.
- Preferencias personales: `CLAUDE.local.md` / `AGENTS.override.md`, ignorados por git.
- Regla para crecer: si algo nuevo es un procedimiento paso a paso, va a una skill, no a `AGENTS.md`.

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
