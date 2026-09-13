# CLAUDE.md — Instrucciones para el agente IA

> Leer este archivo COMPLETO antes de cualquier acción en el proyecto.
> Este archivo es el contrato entre el equipo y el agente IA.

---

## Stack tecnológico — reglas duras

No sugerir, instalar ni implementar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa                     | Tecnología aprobada                                                                                                                                  |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Frontend**             | Angular 17+ · React 18+                                                                                                                              |
| **Backend**              | .NET 8+ (C#) · NestJS 10+ (TypeScript) · Python 3.11+ (FastAPI) — solo para tooling interno / scripts de reporting, no para apps de línea de negocio |
| **Base de datos**        | SQL Server 2019+ · PostgreSQL 15+                                                                                                                    |
| **ORM / acceso a datos** | Entity Framework Core · TypeORM · Prisma                                                                                                             |
| **Autenticación**        | JWT + Refresh Token · OAuth2 · ASP.NET Identity                                                                                                      |
| **Contenedores**         | Docker · Docker Compose                                                                                                                              |
| **CI/CD**                | Azure DevOps Pipelines                                                                                                                               |
| **Testing unitario**     | xUnit (.NET) · Jest (TS/JS) · pytest (Python)                                                                                                        |
| **Testing E2E**          | Playwright Test + playwright-cli                                                                                                                     |
| **Documentación API**    | Swagger / OpenAPI                                                                                                                                    |

> **Python (FastAPI)** se aprobó el 2026-07-02 específicamente para el proyecto de
> `Codigo/Reportes/` (ReporteadorV2), que ya tenía lógica probada en Python
> (`ado_reporte.py`). Reutiliza esa base en vez de .NET/NestJS. No usar Python
> como backend de nuevas apps de negocio sin la misma aprobación explícita.

> **Excepción de stack para PersonalCripto — `jmh_trading`:** módulo Python
> analítico versionado en `Codigo/personal-cripto/jmh_trading/` (fuera del
> `.sln`, pero verificado en el repositorio — ver `IA_Memoria/arquitectura.md`).
> Se permite crear, modificar y validar este módulo siguiendo
> `IA_Skill/SKILL-jmh-trading.md`. Esta excepción NO autoriza crear una nueva
> aplicación de negocio Python fuera de este módulo. Una Spec aprobada y
> evidencia explícita son necesarias pero nunca suficientes para habilitar
> ejecución real, paper trading o adapters live: se requiere autorización
> humana separada, actual y específica justo antes de habilitar u operar.
> Tampoco autoriza ejecutar el deploy en la VM; eso lo hace el dev manualmente
> (ver regla de Python/FastAPI más abajo en este documento).

---

## Protocolo de inicio de sesión (contextualizado y eficiente)

Antes de cualquier acción, consultar `IA_Skill/SKILL-instruction-router.md` para determinar la **Skill Primaria**, las **Skills Auxiliares** y las lecturas estrictamente requeridas para el tipo de tarea.

### Lecturas según tipo de tarea:

1. **Implementar SPEC `ready` o reanudar `in-progress`:**
   - Leer `Features/[feature].spec.md`, `[feature].checks.md` y `[feature].md`.
   - Consultar `IA_Memoria/arquitectura.md` y `convenciones.md` únicamente antes de generar código nuevo o navegar entre servicios.
2. **Corregir un bug puntual o refactor acotado:**
   - Ir directamente al archivo afectado y su suite de tests. NO leer `progreso.md` ni snapshots globales.
3. **Generar una SPEC o Spike técnico:**
   - Leer insumos del dev y `[feature]-epic.md` (si aplica); no cargar skills de backend, frontend ni frameworks.
4. **Tareas de investigación pura o consultas de usuario:**
   - No cargar memoria global; buscar evidencia quirúrgica con herramientas dirigidas (`find_by_name`, `grep_search`, `view_file` acotado).

Regla de snapshot (Repomix) — leer solo cuando la tarea lo justifica:
Leer `IA_Memoria/snapshots/snapshot-latest.md` ÚNICAMENTE si se cumple alguna de estas condiciones:

- La tarea afecta más de un módulo o capa (ej. frontend + backend, backend + BD).
- Es la primera sesión en el proyecto o no hay contexto previo del código.
- Se toma una decisión de arquitectura o un refactor amplio.
- Se depura un bug cuya causa no es evidente en un solo archivo.

NO leer el snapshot si la tarea es: fix puntual en un archivo conocido, cambio de texto/estilo, modificación de config aislada.

Si el snapshot no existe o tiene más de 7 días, sugerir al usuario ejecutar:

- Windows: `.\repomix-scan.ps1`
- Linux/macOS: `./repomix-scan.sh`

Protocolo post-snapshot (obligatorio al leer el snapshot):
Después de leer el snapshot, ANTES de codificar:

1. Comparar lo que muestra el snapshot contra `IA_Memoria/arquitectura.md` — actualizar módulos, dependencias o estructura que hayan cambiado.
2. Comparar contra `IA_Memoria/progreso.md` — marcar como hecho lo que ya existe en el código aunque no estuviera registrado.
3. Si el proyecto tiene código existente, actualizar `IA_Memoria/convenciones.md` con los patrones arquitectónicos detectados en el snapshot — solo agregar lo que no esté ya documentado, nunca reemplazar entradas ya completas:
   - Estructura de capas detectada (Clean Architecture, N-capas, Vertical Slice, etc.)
   - Patrón de acceso a datos (Repository, DbContext directo, CQRS + MediatR, etc.)
   - Estructura de carpetas dentro de cada capa
   - Patrón de manejo de excepciones y validaciones
   - Formato de responses detectado en controllers existentes
4. Solo después de actualizar los tres archivos, proceder con la tarea solicitada.

Nunca empezar a codificar lógica de negocio sin verificar las convenciones y arquitectura del módulo correspondiente.

---

## Cuándo leer cada Skill

### Punto de entrada — Auditoría Pre-Productiva

| Situación                                                                                                             | Skill a leer                                                                                                                      |
| --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| "Actúa como agente analista pre-productivo", "corre el checklist pre-prod", "auditoría de seguridad antes de liberar" | IA_Skill/SKILL-preprod-security-audit.md — orquesta el resto, no leer las skills de seguridad sueltas directamente para este caso |

### Frontend

| Situación                                                                                                        | Skill a leer                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Crear o modificar componente reutilizable con variantes                                                          | IA_Skill/frontend-design/SKILL-component-patterns.md                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Definir o aplicar tokens de diseño (color, espaciado, radio, sombras)                                            | IA_Skill/frontend-design/SKILL-design-tokens.md                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Configurar o ajustar sistema tipográfico del proyecto                                                            | IA_Skill/frontend-design/SKILL-typography-system.md                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Diseñar layout, grid o sistema de espaciado                                                                      | IA_Skill/frontend-design/SKILL-layout-spacing-system.md                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Definir identidad visual (paleta de brand, radius, iconografía)                                                  | IA_Skill/frontend-design/SKILL-visual-identity-override.md                                                                                                                                                                                                                                                                                                                                                                                                                |
| Librería de terceros a usar (componentes, iconos, gráficas, animación) — antes de instalar cualquier dependencia | IA_Skill/SKILL-approved-libraries.md                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Tabla server-side/paginación/sort en Angular                                                                     | IA_Skill/frontend-design/SKILL-angular-data-table-pattern.md                                                                                                                                                                                                                                                                                                                                                                                                              |
| Botones/CTAs con gradiente premium, o hero de landing tipo mesh gradient                                         | IA_Skill/frontend-design/SKILL-gradient-accents.md — el mesh gradient es SOLO para landing/marketing, nunca dashboard/admin                                                                                                                                                                                                                                                                                                                                               |
| Implementar dark mode o theming (claro/oscuro, multi-tenant)                                                     | IA_Skill/frontend-design/SKILL-dark-mode-theming.md                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Implementar diseño responsive o patrones PWA                                                                     | IA_Skill/frontend-design/SKILL-responsive-pwa-patterns.md                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Agregar animaciones o micro-interacciones a componentes                                                          | IA_Skill/frontend-design/SKILL-animation-microinteractions.md                                                                                                                                                                                                                                                                                                                                                                                                             |
| Implementar accesibilidad (a11y / WCAG AA) en componentes o pantallas                                            | IA_Skill/frontend-design/SKILL-accessibility-a11y.md                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Escribir tests en Angular (TestBed, Jest)                                                                        | IA_Skill/SKILL-angular-test-frameworks.md                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Escribir tests en React (Jest + Testing Library)                                                                 | IA_Skill/SKILL-react-test-frameworks.md                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Validar un flujo UI, reproducir un bug visual/funcional o crear/ejecutar pruebas E2E                             | IA_Skill/SKILL-playwright-e2e.md; para automatización interactiva, `.claude/skills/playwright-cli/SKILL.md`                                                                                                                                                                                                                                                                                                                                                               |
| Diseño moderno en HTML/JS vanilla (sin framework, sin npm)                                                       | Leer en secuencia: IA_Skill/SKILL-frontend-design.md (tokens, tipografía, layout y componentes para HTML/CSS/JS puro) → IA_Skill/frontend-design/SKILL-animation-microinteractions.md → IA_Skill/frontend-design/SKILL-gradient-accents.md → IA_Skill/frontend-design/SKILL-accessibility-a11y.md. Sin Bootstrap en output final, sin npm, sin build step, sin frameworks JS (React, Vue, Alpine). Google Fonts vía `<link>` permitido. CSS en archivo propio, no inline. |

> Corrección de mapeo para HTML/JS vanilla: usar `IA_Skill/SKILL-frontend-design.md` → `IA_Skill/SKILL-animation-microinteractions.md` → `IA_Skill/SKILL-gradient-accents.md` → `IA_Skill/frontend-design/SKILL-accessibility-a11y.md`. Esta secuencia reemplaza cualquier referencia de la tabla anterior a las skills de animación o gradientes dentro de `frontend-design/`.

### Backend .NET

| Situación                                                                  | Skill a leer                                   |
| -------------------------------------------------------------------------- | ---------------------------------------------- |
| Crear o modificar cualquier archivo .NET (controller, service, repository) | IA_Skill/SKILL-dotnet-best-practices.md        |
| Code review o refactorizar código .NET existente                           | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Escribir tests unitarios o de integración en .NET                          | IA_Skill/SKILL-dotnet-test-frameworks.md       |
| Migrar el proyecto a una nueva versión de .NET                             | IA_Skill/SKILL-dotnet-upgrade.md               |

### Backend NestJS

| Situación                                                       | Skill a leer                              |
| --------------------------------------------------------------- | ----------------------------------------- |
| Crear o modificar módulo, controller, service o guard en NestJS | IA_Skill/SKILL-nestjs-best-practices.md   |
| Implementar CQRS, eventos de dominio, colas o caching en NestJS | IA_Skill/SKILL-nestjs-patterns.md         |
| Mejorar calidad o revisión de TypeScript en NestJS              | IA_Skill/SKILL-nestjs-clean-typescript.md |
| Escribir tests unitarios o de integración en NestJS             | IA_Skill/SKILL-nestjs-test-frameworks.md  |

### Backend Python (FastAPI — solo tooling interno, ver nota de stack)

| Situación                                                                                                                                     | Skill a leer                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Crear o modificar cualquier archivo del backend Python de ReporteadorV2 (router, service, cliente HTTP)                                       | IA_Skill/SKILL-python-fastapi-best-practices.md |
| Escribir tests unitarios o de integración en el backend Python                                                                                | IA_Skill/SKILL-python-test-frameworks.md        |
| Seguridad en el backend Python (manejo del PAT, subprocess/PDF, exposición del servicio)                                                      | IA_Skill/SKILL-security-python.md               |
| Crear, modificar o validar `Codigo/personal-cripto/jmh_trading/` (FastAPI interna, analítica, Redis Streams, TimescaleDB, contratos o pytest) | IA_Skill/SKILL-jmh-trading.md                   |

### Full Stack

| Situación                                                              | Skill a leer                          |
| ---------------------------------------------------------------------- | ------------------------------------- |
| Implementar una feature con `Features/[mod].spec.md` en estado `ready` | IA_Skill/SKILL-implementation.md      |
| Implementar un módulo completo de principio a fin (sin spec previa)    | IA_Skill/SKILL-mvc-feature.md         |
| Crear, aplicar o revertir migraciones de BD (.NET/NestJS)              | IA_Skill/SKILL-database-migrations.md |

### Seguridad

| Situación                                                                                                                                                                            | Skill a leer                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| Crear guard, interceptor o manejar tokens en Angular                                                                                                                                 | IA_Skill/SKILL-security-angular.md                                                                           |
| Seguridad en cualquier endpoint o middleware .NET                                                                                                                                    | IA_Skill/SKILL-security-dotnet.md                                                                            |
| Seguridad en cualquier endpoint, guard o pipe NestJS                                                                                                                                 | IA_Skill/SKILL-security-nestjs.md                                                                            |
| Seguridad en el backend Python de ReporteadorV2 (manejo del PAT, subprocess/PDF, exposición del servicio)                                                                            | IA_Skill/SKILL-security-python.md                                                                            |
| Revisión OWASP (pre-producción o feature con datos sensibles)                                                                                                                        | IA_Skill/SKILL-security-owasp-checklist.md                                                                   |
| Revisión OWASP adicional (compliance por agentes)                                                                                                                                    | IA_Skill/SKILL-agent-owasp-compliance.md                                                                     |
| Vulnerabilidad de dependencia/librería (npm audit, dotnet list package --vulnerable, pip-audit) — decidir qué parchar ahora vs. documentar                                           | IA_Skill/SKILL-dependency-vulnerability-triage.md                                                            |
| Hallazgo de seguridad (SAST, código legado) en un stack que NO está en las filas de arriba (Angular/.NET/NestJS/Python-ReporteadorV2) — ej. Express, PHP, código de cliente heredado | IA_Skill/SKILL-legacy-stack-security-baseline.md — guía puntual, no modernización                            |
| Escaneo/sospecha de secreto expuesto (Gitleaks, .env trackeado, credencial en un commit)                                                                                             | IA_Skill/SKILL-secrets-scanning.md                                                                           |
| Decidir si un fix (de cualquier tipo — PR, SAST, SCA, secreto, código legado) se aplica directo, se acota, o requiere ticket                                                         | IA_Skill/SKILL-risk-zone-policy.md — fuente única, todas las filas de arriba la referencian, no la redefinen |

### Texto y documentación

| Situación                                                                    | Skill a leer                             |
| ---------------------------------------------------------------------------- | ---------------------------------------- |
| Escribir texto visible al usuario final (mensajes UI, emails, empty states)  | IA_Skill/SKILL-humanizer.md              |
| Documentar una feature terminada                                             | IA_Skill/SKILL-docs-feature.md           |
| Crear o editar memoria técnica formal en Word (.docx) para clientes/gobierno | IA_Skill/technical-memory.md             |
| Generar especificaciones técnicas formales en Word (.docx) para auditorías   | IA_Skill/technical-audit-spec-generic.md |
| Crear, editar o inspeccionar entregables en Word o PDF                       | IA_Skill/document-artifacts/SKILL.md     |

### Especificaciones

| Situación                                                 | Skill a leer                     |
| --------------------------------------------------------- | -------------------------------- |
| Generar o actualizar specs de features (sin tocar código) | IA_Skill/SKILL-spec-generator.md |

### Herramientas del agente

| Situación                                                         | Skill a leer                      |
| ----------------------------------------------------------------- | --------------------------------- |
| Necesitar información externa actualizada (versiones, CVEs, docs) | IA_Skill/SKILL-web-search.md      |
| Activar respuestas ultra-concisas para sesiones largas            | IA_Skill/SKILL-caveman.md         |
| Resolver comentarios de revisión de un Pull Request en GitHub     | IA_Skill/SKILL-pr-review-fixes.md |

---

## Reglas de codificación

### General

- Código en inglés (variables, funciones, clases, tablas)
- Comentarios y documentación en español
- Nunca hardcodear credenciales, URLs base ni valores de entorno
- Toda configuración sensible va en variables de entorno
- Todo cambio de base de datos debe tener su migración versionada
- IDs siempre UUID/GUID (nunca int secuencial)

### Soft delete obligatorio

Nunca ejecutar DELETE en tablas de negocio.
Siempre actualizar IsActive = 0 (SQL Server) o is_active = false (PostgreSQL).

### Respuesta estandarizada

Todos los endpoints deben retornar la misma estructura de respuesta — sin excepciones y sin inventar formatos nuevos por endpoint.
La forma concreta (campos, anidamiento, errores, paginación) la define el proyecto en `IA_Memoria/convenciones.md`.
Si el proyecto aún no tiene convención definida, usar como punto de partida:
`{ "success": true/false, "data": {}, "message": "texto", "errors": [] }`
Si el código existente ya usa otra forma, registrarla en convenciones.md y usarla consistentemente — no mezclar formas dentro del mismo proyecto.

### Autenticación

- Token JWT en header: Authorization: Bearer [token]
- Refresh token en cookie HttpOnly
- Proteger con guard/middleware TODOS los endpoints excepto login

### Python (FastAPI — tooling interno)

- El Dockerfile y docker-compose.yml son entregable obligatorio en todo proyecto FastAPI
- Documentar los pasos de deploy en un README.md dentro de la carpeta del proyecto
- El deploy real en la VM lo ejecuta el dev manualmente — el agente no hace push ni accede a servidores remotos
- Frontend servido por FastAPI: HTML/JS vanilla únicamente — sin npm, sin build step, sin frameworks JS

---

## Estructura del workspace

```
workspace-proyecto/
├── Codigo/              ← ÚNICO que se versiona en GitHub / Azure DevOps
│   └── [nombre-proyecto]/   ← estructura interna libre; rutas reales en IA_Memoria/arquitectura.md
├── IA_Skill/            ← Skills permanentes del proyecto
├── IA_Memoria/          ← Estado y contexto del proyecto
├── Insumos/             ← Mockups, specs, datos de prueba
├── Features/            ← Definición detallada de cada módulo
├── Issues/              ← Bugs y problemas registrados
└── CLAUDE.md            ← Este archivo
```

No asumir estructura interna de Codigo/ — leer IA_Memoria/arquitectura.md.
Las carpetas IA_Skill, IA_Memoria, Insumos, Features e Issues
NO se suben al repositorio de código.

---

## Política de autonomía y ambigüedades

**AUTONOMY_POLICY_VERSION: 1**

Esta política aplica a generación de Specs, implementación, revisión, corrección
de bugs y mantenimiento. Las restricciones de seguridad, capital real,
credenciales, producción, acciones destructivas, despliegues remotos y
tecnologías no aprobadas conservan plena vigencia.

### 1. Investigar antes de preguntar

Una pregunta al usuario nunca sustituye la investigación técnica.

Antes de declarar un bloqueo o solicitar una decisión, el agente debe revisar,
según corresponda:

1. Feature, Spec, checks, prompt de ejecución y Specs anteriores/posteriores.
2. `IA_Memoria/progreso.md`, `arquitectura.md` y `convenciones.md`.
3. Código, contratos, modelos, migraciones, configuración no sensible y pruebas.
4. Skills aplicables y cualquier skill que estas referencien para el caso.
5. Implementaciones equivalentes, catálogos versionados y patrones ya usados.

El reporte debe identificar qué fuentes se inspeccionaron y qué evidencia se
encontró o no se encontró. Está prohibido preguntar de qué tabla, DTO, interfaz
o patrón obtener un dato sin haber agotado primero estas fuentes.

### 2. Clasificación obligatoria de incógnitas

Toda ambigüedad se clasifica antes de decidir si bloquea:

- `T1 — Detalle técnico reversible`: nombres internos, DTOs, mappers, ubicación
  de código, interfaces, representación nullable, estrategia de consulta y
  decisiones equivalentes de bajo costo. El agente decide e implementa.
- `T2 — Decisión arquitectónica de impacto acotado`: elección entre patrones
  existentes, evolución compatible de contratos internos o persistencia
  adicional no destructiva. El agente investiga, elige la opción más coherente,
  documenta la decisión y continúa si es reversible.
- `B1 — Regla de negocio faltante`: umbral, fórmula, peso o criterio no aprobado.
  El agente no inventa el valor; implementa contrato, configuración,
  observabilidad y estados seguros, manteniendo la regla desactivada.
- `B2 — Decisión de negocio material`: cambia de forma importante el alcance,
  significado del producto, experiencia principal o resultado financiero.
  Puede requerir confirmación, pero primero se debe intentar aislarla.
- `S1 — Seguridad, datos o acción destructiva`: credenciales, producción,
  dinero real, integridad de datos, permisos, borrados o cambios irreversibles.
  Se aplican las políticas de confirmación explícita.
- `X1 — Bloqueo externo real`: falta acceso, infraestructura, credenciales o una
  dependencia que no puede sustituirse ni simularse de manera segura.

Una Spec aprobada o evidencia técnica nunca conceden por sí mismas autorización
operativa sobre dinero real, paper trading, adapters live, credenciales o
producción. Esas acciones requieren autorización humana separada, actual y
específica inmediatamente antes de ejecutarlas.

### 3. Definición estricta de NEEDS CLARIFICATION

`NEEDS CLARIFICATION` solo procede cuando, después de investigar:

1. la decisión es `B2`, `S1` o `X1`, o cambia materialmente alcance, seguridad
   o experiencia principal;
2. no puede aislarse detrás de configuración, interfaz, feature flag, estado
   explícito o comportamiento degradado; y
3. es irreversible, costosa de revertir, afecta dinero real, seguridad o
   integridad de datos, o impide objetivamente una implementación segura.

No constituye `NEEDS CLARIFICATION` por sí solo:

- que la Spec no nombre una tabla, DTO, clase, método u operador;
- que haya varias implementaciones técnicas reversibles;
- que falte un campo en un contrato interno extensible;
- que una dependencia SOFT esté ausente o degradada;
- que falte un umbral que puede permanecer sin configurar;
- que un componente independiente pueda marcarse no disponible.

Una feature cuyo propósito único dependa de una regla de negocio ausente puede
permanecer en `needs-clarification`. Un gap parcial no convierte automáticamente
toda la Spec en bloqueada.

### 4. Regla de negocio ausente

La falta de una regla de negocio puede impedir activar esa regla, pero no
necesariamente impide implementar su contrato, persistencia, configuración,
estados, observabilidad, pruebas estructurales y flujo de integración.

Cuando falte una regla de negocio:

- no inventar umbrales, pesos, fórmulas ni equivalencias semánticas;
- usar configuración nullable/no establecida;
- mantener la regla deshabilitada;
- exponer `PENDING_CONFIGURATION` o `NOT_EVALUATED`;
- probar que la regla no produce efectos mientras no esté aprobada;
- indicar la condición exacta necesaria para activarla.

### 5. Estados seguros y ausencia de datos

Usar, según el contexto: `UNKNOWN`, `UNAVAILABLE`, `NOT_EVALUATED`,
`PENDING_CONFIGURATION` o `SOURCE_UNAVAILABLE`.

La ausencia o incertidumbre nunca se convierte silenciosamente en:

- `PASS`, `APPROVED`, `ELIGIBLE` o equivalente;
- cero;
- colección vacía que parezca una evaluación válida;
- valor por defecto cuantitativo;
- transición, promoción u orden.

Si un filtro activo requiere un dato ausente, el contrato debe aplicar una
semántica explícita y probada: exclusión fail-closed con razón observable, o
error/degradación según la Spec. Nunca debe incluir el elemento como aprobado.

### 6. Implementación provisional segura

Una implementación provisional debe:

1. desacoplar proveedor y consumidor mediante una interfaz o contrato estable;
2. exponer disponibilidad, fuente, freshness y versión;
3. mantener desactivado cualquier comportamiento sin definición aprobada;
4. preservar `null`/estado explícito en vez de fabricar datos;
5. incluir pruebas del caso configurado, no configurado y fuente degradada;
6. poder reemplazarse sin migración destructiva ni cambio breaking;
7. no exagerar la evidencia ni declararse funcionalmente completa.

### 7. Continuidad del trabajo

El agente debe continuar con todas las partes no bloqueadas.

Una ambigüedad localizada puede dejar un componente provisional, pero no detiene
backend, persistencia, UI, observabilidad, contratos o pruebas independientes.
La entrega queda como máximo en `in-review`, indicando qué está operativo, qué
es provisional y qué decisión sigue pendiente.

### 7.1 Propiedad del gap y trazabilidad entre Specs

Antes de registrar una ambigüedad o deuda, identificar qué Spec es propietaria
del contrato, dato o comportamiento faltante.

- **Gap propiedad de otra Spec:** si la Spec actual consume una capacidad que
  otra Spec debía producir y su contrato o evidencia está incompleto, registrar
  deuda técnica vinculada a la **Spec propietaria**. La deuda debe indicar la
  Spec donde se detectó, el alcance afectado, evidencia, comportamiento
  provisional, criterio de salida y `Retomar en: SPEC-[propietaria]`. El agente
  que retome la Spec propietaria debe revisar y resolver sus deudas vinculadas.
- Si la Spec propietaria ya está `done`, la Spec consumidora no la modifica ni
  cambia su estado silenciosamente. La deuda abre una pasada correctiva bajo la
  Spec propietaria; el agente asignado la mueve por `in-progress` → `in-review`
  y el dev conserva la decisión final de volver a marcarla `done`.
- **Gap propiedad de la Spec actual:** el agente no lo difiere como deuda de
  otra Spec ni pregunta por una decisión técnica. Investiga, elige la mejor
  opción T1/T2 reversible, la implementa, la prueba y registra la decisión en
  `[mod].checks.md`; si cambia una convención o frontera transversal, actualiza
  también `convenciones.md` o `arquitectura.md` según corresponda.
- Para B1 propia, implementar soporte seguro deshabilitado y documentar la
  condición de activación. Para B2/S1/X1, aplicar la definición estricta de
  `NEEDS CLARIFICATION`, sin detener el trabajo independiente.
- La deuda técnica no sustituye implementar una decisión T1/T2 propia ni
  permite declarar operativo o completo un comportamiento pendiente.

Formato mínimo de deuda cross-Spec:

- `Spec propietaria`:
- `Detectada desde`:
- `Clasificación`:
- `Evidencia`:
- `Alcance afectado`:
- `Comportamiento provisional`:
- `Decisión técnica recomendada`:
- `Condición de salida`:
- `Retomar en`:

### 8. Evolución de contratos

Una extensión aditiva, backward-compatible y autorizada por una Spec `ready`
no es automáticamente zona roja, especialmente en APIs internas.

Debe:

- conservar campos y semántica existentes;
- actualizar productor, consumidor y documentación;
- agregar pruebas de contrato en ambos lados;
- revisar consumidores conocidos;
- versionar cuando la compatibilidad no pueda conservarse.

Los cambios breaking, externos, no autorizados o de impacto incierto mantienen
las reglas de zona roja y confirmación.

### 9. Registro de supuestos

Registrar cada supuesto con este formato:

- `ID`:
- `Categoría`: T1 | T2 | B1 | B2 | S1 | X1
- `Pregunta o gap`:
- `Evidencia revisada`:
- `Decisión aplicada`:
- `Impacto`:
- `Reversibilidad`:
- `Comportamiento provisional`:
- `Decisión pendiente`:
- `Condición de activación`:
- `Pruebas`:

### 10. Escalamiento al usuario

Cuando una aclaración sea realmente necesaria, reportar:

- `DECISIÓN REQUERIDA`:
- `Clasificación`:
- `Evidencia agotada`:
- `Por qué no puede aislarse`:
- `Opciones viables`:
- `Opción recomendada y razón`:
- `Impacto de cada opción`:
- `Riesgo de continuar sin decisión`:
- `Trabajo no bloqueado ya completado`:

No pedir al usuario que diseñe DTOs, tablas, interfaces, mappers, queries o
patrones internos salvo que su elección cambie materialmente el contrato de
negocio o un sistema externo bajo su responsabilidad.

### 11. Presupuesto operativo y gestión eficiente de contexto

Para garantizar que toda tarea alcance implementación y validación sin agotar prematuramente la ventana de contexto:

- **Distribución de esfuerzo recomendada:** 20% descubrimiento y lectura mínima indispensable; 20% diagnóstico y diseño del cambio; 30% aplicación de correcciones; 25% validación y pruebas; 5% entrega final.
- **Eficiencia en lecturas:** Investigar primero con `find_by_name` y `grep_search`. Abrir archivos con `view_file` de forma acotada (usando `StartLine` y `EndLine`). No volcar documentos completos en la narrativa ni releer archivos que no han sufrido modificaciones.
- **Prioridad de validación:** Iniciar la validación antes de consumir el 75% del contexto disponible. Si el presupuesto de tokens es bajo, detener la exploración adicional, aplicar los cambios mínimos necesarios y priorizar la ejecución de pruebas sobre la prosa extensa.
- **Cierre de ciclo:** El resultado estándar de una tarea completada por el agente es `in-review`, nunca `done` (salvo autorización explícita del desarrollador).

### 12. Jerarquía de instrucciones y ruteo central

La selección de skills, resolución de conflictos entre instrucciones y reglas de carga progresiva se rigen por `IA_Skill/SKILL-instruction-router.md`:

1. Existe exactamente **una skill primaria** por tarea que conduce el ciclo de vida.
2. Las **skills auxiliares** se cargan exclusivamente bajo demanda demostrable por capa.
3. Se prohíbe la lectura indiscriminada de todo el catálogo de skills o la carga de skills de frontend para procesos de backend/worker sin interfaz de usuario.
4. En caso de contradicción, la precedencia es: Reglas de plataforma > Solicitud actual del usuario > `CLAUDE.md` > `SKILL-instruction-router.md` > Skill primaria > Skills auxiliares > Contrato específico de feature > Evidencia en código.

## Política de trabajo con código legado

Ver `IA_Skill/SKILL-risk-zone-policy.md` — fuente única de la política de zonas
(verde/ámbar/roja). No se redefine aquí para evitar que las 4 copias (esta,
AGENTS.md, GEMINI.md, copilot-instructions.md) diverjan entre sí.

---

## Lo que NUNCA hacer sin confirmación explícita

- Modificar .env, appsettings.json o cualquier archivo de entorno
- Ejecutar DROP TABLE, DELETE FROM o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado
- Modificar pipelines de CI/CD
- Subir archivos de las carpetas IA al repositorio git
- Ejecutar docker build, docker push ni acceder a servidores remotos

---

## Compatibilidad verificada de PersonalCripto

Para mantener `Codigo/personal-cripto/` están aprobados .NET 10, Angular 22, .NET Aspire y Vitest, además de las dependencias registradas en `IA_Skill/SKILL-approved-libraries.md`. Para tests del frontend de ese proyecto usar `IA_Skill/SKILL-angular-test-vitest.md`, no la skill genérica de Jest. Esta excepción es exclusiva de ese proyecto: no autoriza instalaciones nuevas en otros proyectos sin confirmación.

Playwright Test y `playwright-cli` están aprobados en este template para validación E2E y automatización de navegador. Su mapa operativo vive en `IA_Skill/SKILL-playwright-e2e.md`; no sustituye los tests unitarios de cada stack.

## Estado del proyecto

El estado actual del proyecto vive únicamente en `IA_Memoria/`:

- `IA_Memoria/progreso.md` — qué módulos están completados, en progreso y pendientes
- `IA_Memoria/arquitectura.md` — servicios, puertos y decisiones técnicas vigentes
- `IA_Memoria/convenciones.md` — naming, commits y reglas del equipo

Al arrancar con un proyecto nuevo o existente: llenar esos tres archivos antes de iniciar cualquier sesión de desarrollo.

## Regla de módulo completo

Cuando una tarea construya un módulo funcional, el módulo incluye por defecto:

- Backend/API, persistencia y reglas de negocio que correspondan.
- Frontend/pantalla/flujo de usuario cuando el módulo tenga interacción visual.
- Validación directa del flujo completo mediante Playwright, ejecutando la aplicación y comprobando el comportamiento desde la UI.

La única excepción es un servicio o módulo explícitamente sin frontend (por ejemplo, un worker, una API interna, un proceso de integración o un servicio de infraestructura). En ese caso, documentar en la entrega que no aplica UI/Playwright y validar mediante pruebas de contrato, integración o smoke tests apropiados.

No considerar terminado un módulo con frontend si solo compila o tiene tests unitarios: debe existir al menos una validación Playwright del happy path y de los errores principales del flujo.
Para ejecutar esta validación, el agente debe verificar de forma autónoma que los servicios locales (AppHost/Angular en localhost:4200) estén activos (o arrancarlos en segundo plano sin bloquear la terminal) y ejecutar la prueba en modo visual/encabezado (--headed en desarrollo local contra Chromium, o interactivamente con playwright-cli open). No asumir ejecución headless silenciosa ni esperar a que el operador tenga que indicarlo en el prompt.

## Regla para librerías y plugins recomendados

Si una librería o plugin recomendado no aparece en el stack aprobado, no descartarlo automáticamente por ese único motivo. Antes de decidir no usarlo, detener la implementación y consultar al usuario presentando brevemente:

1. Qué problema resuelve y qué ventajas aporta frente a la opción aprobada o a no incorporar dependencia.
2. Evidencia de seguridad, mantenimiento, comunidad, licencia y compatibilidad con el proyecto.
3. Por qué puede ser la mejor opción para esta tarea y cuáles son las alternativas consideradas.
4. Impacto de adoptarlo: instalación, mantenimiento, lockfile, CI/CD, superficie de ataque y migración futura.

Solo después de la confirmación explícita del usuario se puede instalar o implementar una tecnología fuera del stack. Si el usuario decide no adoptarla, registrar la decisión y su razón en la memoria o spec correspondiente.
