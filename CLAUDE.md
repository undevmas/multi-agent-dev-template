# CLAUDE.md — Instrucciones para el agente IA

> Leer este archivo COMPLETO antes de cualquier acción en el proyecto.
> Este archivo es el contrato entre el equipo y el agente IA.

---

## Stack tecnológico — reglas duras

No sugerir, instalar ni implementar tecnologías fuera de esta tabla sin aprobación explícita.

| Capa | Tecnología aprobada |
|---|---|
| **Frontend** | Angular 17+ · React 18+ |
| **Backend** | .NET 8+ (C#) · NestJS 10+ (TypeScript) |
| **Base de datos** | SQL Server 2019+ · PostgreSQL 15+ |
| **ORM / acceso a datos** | Entity Framework Core · TypeORM · Prisma |
| **Autenticación** | JWT + Refresh Token · OAuth2 · ASP.NET Identity |
| **Contenedores** | Docker · Docker Compose |
| **CI/CD** | Azure DevOps Pipelines |
| **Testing unitario** | xUnit (.NET) · Jest (TS/JS) |
| **Testing E2E** | Cypress |
| **Documentación API** | Swagger / OpenAPI |

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

### Frontend

| Situación | Skill a leer |
|---|---|
| Crear o modificar componente reutilizable con variantes | IA_Skill/frontend-design/SKILL-component-patterns.md |
| Definir o aplicar tokens de diseño (color, espaciado, radio, sombras) | IA_Skill/frontend-design/SKILL-design-tokens.md |
| Configurar o ajustar sistema tipográfico del proyecto | IA_Skill/frontend-design/SKILL-typography-system.md |
| Diseñar layout, grid o sistema de espaciado | IA_Skill/frontend-design/SKILL-layout-spacing-system.md |
| Definir identidad visual (paleta de brand, radius, iconografía) | IA_Skill/frontend-design/SKILL-visual-identity-override.md |
| Implementar dark mode o theming (claro/oscuro, multi-tenant) | IA_Skill/frontend-design/SKILL-dark-mode-theming.md |
| Implementar diseño responsive o patrones PWA | IA_Skill/frontend-design/SKILL-responsive-pwa-patterns.md |
| Agregar animaciones o micro-interacciones a componentes | IA_Skill/frontend-design/SKILL-animation-microinteractions.md |
| Implementar accesibilidad (a11y / WCAG AA) en componentes o pantallas | IA_Skill/frontend-design/SKILL-accessibility-a11y.md |
| Escribir tests en Angular (TestBed, Jest) | IA_Skill/SKILL-angular-test-frameworks.md |
| Escribir tests en React (Jest + Testing Library) | IA_Skill/SKILL-react-test-frameworks.md |

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
| Revisión OWASP (pre-producción o feature con datos sensibles) | IA_Skill/SKILL-security-owasp-checklist.md |
| Revisión OWASP adicional (compliance por agentes) | IA_Skill/SKILL-agent-owasp-compliance.md |

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

---

## Estructura del workspace

workspace-proyecto/
├── Codigo/              ← ÚNICO que se versiona en GitHub / Azure DevOps
│   └── [nombre-proyecto]/   ← estructura interna libre; rutas reales en IA_Memoria/arquitectura.md
├── IA_Skill/            ← Skills permanentes del proyecto
├── IA_Memoria/          ← Estado y contexto del proyecto
├── Insumos/             ← Mockups, specs, datos de prueba
├── Features/            ← Definición detallada de cada módulo
├── Issues/              ← Bugs y problemas registrados
└── CLAUDE.md            ← Este archivo

No asumir estructura interna de Codigo/ — leer IA_Memoria/arquitectura.md.
Las carpetas IA_Skill, IA_Memoria, Insumos, Features e Issues
NO se suben al repositorio de código.

---

## Política de trabajo con código legado

Aplica cuando el proyecto tiene código existente que no sigue al 100% las convenciones
del template. Las convenciones del template no se bajan para acomodar el legado —
se aplican donde es posible sin romper lo que funciona.

### Zona verde — código nuevo (estándar completo siempre)
Archivos que no existían antes. Seguir las convenciones del template al 100%
aunque estén en un módulo legado. No heredar antipatrones del código de al lado.
- UUID/GUID siempre, aunque la tabla vecina use int secuencial
- Soft delete, response estandarizada, guards en todos los endpoints nuevos
- Naming en inglés, estructura de carpetas según convenciones

### Zona ámbar — código existente que hay que modificar
Tocar solo lo mínimo necesario para la tarea. No aprovechar para "mejorar" lo que no pidieron.
- Agregar el nuevo método siguiendo convenciones, sin cambiar los métodos existentes
- Si el archivo tiene DELETE directo en BD, el nuevo código usa soft delete — el viejo queda igual
- Si un cambio rompería la interfaz existente — PARAR y consultar al dev antes de continuar
- No refactorizar oportunistamente sin ticket explícito

### Zona roja — código que no se toca sin ticket explícito
Código legado que funciona pero no sigue convenciones. Detectar, documentar, dejar como está.
- No modificar migraciones ya aplicadas en producción
- No cambiar IDs de int a UUID en tablas existentes con datos
- No renombrar endpoints que ya consumen clientes externos
- Registrar en `IA_Memoria/deuda-tecnica.md` con impacto y condición de salida

### Regla de desempate
Cuando spec y código real se contradicen en un módulo legado:
el código real gana. La contradicción va a `IA_Memoria/deuda-tecnica.md`.
No modificar el código existente, no falsificar la spec — consultar al dev.

---

## Lo que NUNCA hacer sin confirmación explícita

- Modificar .env, appsettings.json o cualquier archivo de entorno
- Ejecutar DROP TABLE, DELETE FROM o borrar migraciones
- Cambiar tecnologías o instalar librerías fuera del stack aprobado
- Modificar pipelines de CI/CD
- Subir archivos de las carpetas IA al repositorio git

---

## Estado del proyecto

El estado actual del proyecto vive únicamente en `IA_Memoria/`:
- `IA_Memoria/progreso.md` — qué módulos están completados, en progreso y pendientes
- `IA_Memoria/arquitectura.md` — servicios, puertos y decisiones técnicas vigentes
- `IA_Memoria/convenciones.md` — naming, commits y reglas del equipo

Al arrancar con un proyecto nuevo o existente: llenar esos tres archivos antes de iniciar cualquier sesión de desarrollo.
