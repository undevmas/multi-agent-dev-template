# CLAUDE.md — Instrucciones para el agente IA

> Leer este archivo COMPLETO antes de cualquier acción en el proyecto.
> Este archivo es el contrato entre el equipo y el agente IA.

---

## Stack tecnológico — reglas duras

No sugerir, instalar ni implementar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa | Tecnología aprobada |
|---|---|
| **Frontend** | Angular 17+ · React 18+ |
| **Backend** | .NET 8+ (C#) · NestJS 10+ (TypeScript) · Python 3.11+ (FastAPI) — solo para tooling interno / scripts de reporting, no para apps de línea de negocio |
| **Base de datos** | SQL Server 2019+ · PostgreSQL 15+ |
| **ORM / acceso a datos** | Entity Framework Core · TypeORM · Prisma |
| **Autenticación** | JWT + Refresh Token · OAuth2 · ASP.NET Identity |
| **Contenedores** | Docker · Docker Compose |
| **CI/CD** | Azure DevOps Pipelines |
| **Testing unitario** | xUnit (.NET) · Jest (TS/JS) · pytest (Python) |
| **Testing E2E** | Cypress |
| **Documentación API** | Swagger / OpenAPI |

> **Python (FastAPI)** se aprobó el 2026-07-02 específicamente para el proyecto de
> `Codigo/Reportes/` (ReporteadorV2), que ya tenía lógica probada en Python
> (`ado_reporte.py`). Reutiliza esa base en vez de .NET/NestJS. No usar Python
> como backend de nuevas apps de negocio sin la misma aprobación explícita.

---

## Protocolo de inicio de sesión (ejecutar siempre)

Antes de cualquier tarea, leer en este orden:

1. IA_Memoria/progreso.md        → Saber qué está hecho y qué sigue
2. IA_Memoria/arquitectura.md    → Entender cada pieza del sistema
3. IA_Memoria/convenciones.md    → Respetar naming y estructura
4. Features/[feature].md         → Si la tarea involucra un módulo específico
   Features/[feature].spec.md    → Además, si existe y su Estado es `ready` o `in-progress`
5. IA_Skill/[skill].md           → Leer la skill relevante antes de codificar

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

Nunca empezar a codificar sin haber leído al menos 1, 2 y 3.

---

## Cuándo leer cada Skill

### Punto de entrada — Auditoría Pre-Productiva

| Situación | Skill a leer |
|---|---|
| "Actúa como agente analista pre-productivo", "corre el checklist pre-prod", "auditoría de seguridad antes de liberar" | IA_Skill/SKILL-preprod-security-audit.md — orquesta el resto, no leer las skills de seguridad sueltas directamente para este caso |

### Frontend

| Situación | Skill a leer |
|---|---|
| Crear o modificar componente reutilizable con variantes | IA_Skill/frontend-design/SKILL-component-patterns.md |
| Definir o aplicar tokens de diseño (color, espaciado, radio, sombras) | IA_Skill/frontend-design/SKILL-design-tokens.md |
| Configurar o ajustar sistema tipográfico del proyecto | IA_Skill/frontend-design/SKILL-typography-system.md |
| Diseñar layout, grid o sistema de espaciado | IA_Skill/frontend-design/SKILL-layout-spacing-system.md |
| Definir identidad visual (paleta de brand, radius, iconografía) | IA_Skill/frontend-design/SKILL-visual-identity-override.md |
| Librería de terceros a usar (componentes, iconos, gráficas, animación) — antes de instalar cualquier dependencia | IA_Skill/SKILL-approved-libraries.md |
| Tabla server-side/paginación/sort en Angular | IA_Skill/frontend-design/SKILL-angular-data-table-pattern.md |
| Botones/CTAs con gradiente premium, o hero de landing tipo mesh gradient | IA_Skill/frontend-design/SKILL-gradient-accents.md — el mesh gradient es SOLO para landing/marketing, nunca dashboard/admin |
| Implementar dark mode o theming (claro/oscuro, multi-tenant) | IA_Skill/frontend-design/SKILL-dark-mode-theming.md |
| Implementar diseño responsive o patrones PWA | IA_Skill/frontend-design/SKILL-responsive-pwa-patterns.md |
| Agregar animaciones o micro-interacciones a componentes | IA_Skill/frontend-design/SKILL-animation-microinteractions.md |
| Implementar accesibilidad (a11y / WCAG AA) en componentes o pantallas | IA_Skill/frontend-design/SKILL-accessibility-a11y.md |
| Escribir tests en Angular (TestBed, Jest) | IA_Skill/SKILL-angular-test-frameworks.md |
| Escribir tests en React (Jest + Testing Library) | IA_Skill/SKILL-react-test-frameworks.md |
| Diseño moderno en HTML/JS vanilla (sin framework, sin npm) | Leer en secuencia: IA_Skill/SKILL-frontend-design.md (tokens, tipografía, layout y componentes para HTML/CSS/JS puro) → IA_Skill/frontend-design/SKILL-animation-microinteractions.md → IA_Skill/frontend-design/SKILL-gradient-accents.md → IA_Skill/frontend-design/SKILL-accessibility-a11y.md. Sin Bootstrap en output final, sin npm, sin build step, sin frameworks JS (React, Vue, Alpine). Google Fonts vía `<link>` permitido. CSS en archivo propio, no inline. |

### Backend .NET

| Situación | Skill a leer |
|---|---|
| Crear o modificar cualquier archivo .NET (controller, service, repository) | IA_Skill/SKILL-dotnet-best-practices.md |
| Code review o refactorizar código .NET existente | IA_Skill/SKILL-dotnet-design-pattern-review.md |
| Escribir tests unitarios o de integración en .NET | IA_Skill/SKILL-dotnet-test-frameworks.md |
| Migrar el proyecto a una nueva versión de .NET | IA_Skill/SKILL-dotnet-upgrade.md |

### Backend NestJS

| Situación | Skill a leer |
|---|---|
| Crear o modificar módulo, controller, service o guard en NestJS | IA_Skill/SKILL-nestjs-best-practices.md |
| Implementar CQRS, eventos de dominio, colas o caching en NestJS | IA_Skill/SKILL-nestjs-patterns.md |
| Mejorar calidad o revisión de TypeScript en NestJS | IA_Skill/SKILL-nestjs-clean-typescript.md |
| Escribir tests unitarios o de integración en NestJS | IA_Skill/SKILL-nestjs-test-frameworks.md |

### Backend Python (FastAPI — solo tooling interno, ver nota de stack)

| Situación | Skill a leer |
|---|---|
| Crear o modificar cualquier archivo del backend Python de ReporteadorV2 (router, service, cliente HTTP) | IA_Skill/SKILL-python-fastapi-best-practices.md |
| Escribir tests unitarios o de integración en el backend Python | IA_Skill/SKILL-python-test-frameworks.md |
| Seguridad en el backend Python (manejo del PAT, subprocess/PDF, exposición del servicio) | IA_Skill/SKILL-security-python.md |

### Full Stack

| Situación | Skill a leer |
|---|---|
| Implementar una feature con `Features/[mod].spec.md` en estado `ready` | IA_Skill/SKILL-implementation.md |
| Implementar un módulo completo de principio a fin (sin spec previa) | IA_Skill/SKILL-mvc-feature.md |
| Crear, aplicar o revertir migraciones de BD (.NET/NestJS) | IA_Skill/SKILL-database-migrations.md |

### Seguridad

| Situación | Skill a leer |
|---|---|
| Crear guard, interceptor o manejar tokens en Angular | IA_Skill/SKILL-security-angular.md |
| Seguridad en cualquier endpoint o middleware .NET | IA_Skill/SKILL-security-dotnet.md |
| Seguridad en cualquier endpoint, guard o pipe NestJS | IA_Skill/SKILL-security-nestjs.md |
| Seguridad en el backend Python de ReporteadorV2 (manejo del PAT, subprocess/PDF, exposición del servicio) | IA_Skill/SKILL-security-python.md |
| Revisión OWASP (pre-producción o feature con datos sensibles) | IA_Skill/SKILL-security-owasp-checklist.md |
| Revisión OWASP adicional (compliance por agentes) | IA_Skill/SKILL-agent-owasp-compliance.md |
| Vulnerabilidad de dependencia/librería (npm audit, dotnet list package --vulnerable, pip-audit) — decidir qué parchar ahora vs. documentar | IA_Skill/SKILL-dependency-vulnerability-triage.md |
| Hallazgo de seguridad (SAST, código legado) en un stack que NO está en las filas de arriba (Angular/.NET/NestJS/Python-ReporteadorV2) — ej. Express, PHP, código de cliente heredado | IA_Skill/SKILL-legacy-stack-security-baseline.md — guía puntual, no modernización |
| Escaneo/sospecha de secreto expuesto (Gitleaks, .env trackeado, credencial en un commit) | IA_Skill/SKILL-secrets-scanning.md |
| Decidir si un fix (de cualquier tipo — PR, SAST, SCA, secreto, código legado) se aplica directo, se acota, o requiere ticket | IA_Skill/SKILL-risk-zone-policy.md — fuente única, todas las filas de arriba la referencian, no la redefinen |

### Texto y documentación

| Situación | Skill a leer |
|---|---|
| Escribir texto visible al usuario final (mensajes UI, emails, empty states) | IA_Skill/SKILL-humanizer.md |
| Documentar una feature terminada | IA_Skill/SKILL-docs-feature.md |

### Especificaciones

| Situación | Skill a leer |
|---|---|
| Generar o actualizar specs de features (sin tocar código) | IA_Skill/SKILL-spec-generator.md |

### Herramientas del agente

| Situación | Skill a leer |
|---|---|
| Necesitar información externa actualizada (versiones, CVEs, docs) | IA_Skill/SKILL-web-search.md |
| Activar respuestas ultra-concisas para sesiones largas | IA_Skill/SKILL-caveman.md |
| Resolver comentarios de revisión de un Pull Request en GitHub | IA_Skill/SKILL-pr-review-fixes.md |

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

## Estado del proyecto

El estado actual del proyecto vive únicamente en `IA_Memoria/`:
- `IA_Memoria/progreso.md` — qué módulos están completados, en progreso y pendientes
- `IA_Memoria/arquitectura.md` — servicios, puertos y decisiones técnicas vigentes
- `IA_Memoria/convenciones.md` — naming, commits y reglas del equipo

Al arrancar con un proyecto nuevo o existente: llenar esos tres archivos antes de iniciar cualquier sesión de desarrollo.
