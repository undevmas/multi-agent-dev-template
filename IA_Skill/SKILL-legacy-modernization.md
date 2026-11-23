# SKILL — Modernización de proyectos legados (reescritura al stack aprobado)

Esta skill especializa, pero no reemplaza, la `Política de autonomía y ambigüedades`
de `IA_Skill/SKILL-autonomy-policy.md` (**AUTONOMY_POLICY_VERSION: 1**).

## Cuándo usar esta skill

- Un proyecto de `Codigo/` usa tecnología fuera del stack o sin soporte (p. ej. .NET Framework 4.x
  con ASP.NET Web API 2 / MVC 5, WebJobs, Angular 8, log4net, TFVC) y la decisión es
  **reescribirlo completo** en el stack aprobado: .NET último LTS (hoy 10) + Angular última versión
  mayor estable.
- **No** usar para mantener o corregir el legado: eso se hace con su tecnología actual (regla de
  proyecto legado en `AGENTS.md`). Para subir de versión un .NET moderno: `SKILL-dotnet-upgrade.md`.

## Principios

1. **El legado es la especificación ejecutable.** Reglas de negocio, validaciones, contratos y datos
   se extraen del código, la BD y el comportamiento real. No se inventan ni se "mejoran" en silencio.
2. **Paridad primero, mejoras después.** Toda diferencia deseada se registra como decisión del dev o
   como backlog; no entra de forma implícita en la reescritura.
3. **El legado es de solo lectura** durante la reescritura. Excepción: una corrección urgente de
   seguridad mientras siga en producción, hecha con su tecnología actual.
4. **Se reimplementa, no se traduce.** Copiar clases o traducir línea por línea arrastra
   vulnerabilidades y antipatrones; se construye con los patrones del stack.
5. **Nada se apaga ni se borra sin el dev.** El legado sigue operando hasta que el sistema nuevo se
   acepta; el corte a producción es clase `S1`.

## Dónde vive cada cosa

| Qué | Dónde |
|---|---|
| Legado (referencia, solo lectura) | `Codigo/<legado>/`, tal como se copió |
| Sistema nuevo | `Codigo/<sistema>/`, repo git propio creado con el stack aprobado |
| Inventario, decisiones y matriz de paridad | `IA_Memoria/modernizacion.md` (estructura al final) |
| Specs del sistema nuevo | `Features/<mod>.md` · `<mod>.spec.md` · `<mod>.checks.md` (`SKILL-spec-generator.md`); cada regla cita su fuente en el legado |
| Pruebas de paridad | Repo nuevo, `tests/paridad/` (Playwright) |

Registrar ambos sistemas en `IA_Memoria/arquitectura.md` y el legado en `IA_Memoria/deuda-tecnica.md`.

---

## Fase 0 — Inventario (solo lectura)

| Elemento | Dónde buscarlo en el legado |
|---|---|
| Endpoints: ruta, verbo, request, response, auth | Web API 2: clases `ApiController`, `[Route]`, `App_Start/WebApiConfig.cs` · MVC: `Controller`, `RouteConfig.cs` |
| Pantallas y flujos | Angular: módulos de rutas (`*-routing.module.ts`), componentes, servicios HTTP |
| Procesos en segundo plano | WebJobs: `Program.cs`, funciones con disparadores, `settings.job` (cron) |
| Base de datos | Scripts SQL: tablas, procedimientos almacenados, vistas, funciones, triggers; qué SP usa cada endpoint |
| Integraciones externas | `Service References` (SOAP), `HttpClient`/`WebClient`, colas, correo, archivos |
| Configuración | Claves de `Web.config` / `App.config` (`appSettings`, `connectionStrings`): **solo nombres, nunca valores** |
| Autenticación y autorización | `[Authorize]`, filtros, OWIN, emisión y validación de tokens, roles |
| Consumidores del API | Apps móviles, jobs u otros sistemas que lo llaman: definen si el contrato debe conservarse |

Apoyos: snapshot de Repomix (`GUIDE.md`, Paso 2) para cruzar capas y archify
(`SKILL-visual-evidence.md`) para el diagrama de la arquitectura actual.

## Fase 1 — Línea base del legado

1. **Auditoría** con `SKILL-preprod-security-audit.md`: vulnerabilidades y secretos que el sistema
   nuevo no debe heredar. Un secreto real en `Web.config` se reporta para rotación (clase `S1`).
2. **Pruebas de caracterización** con Playwright (`request` para el API, navegador para la UI)
   contra el legado en local o QA con datos de prueba. Capturan las respuestas y los flujos reales;
   las mismas pruebas, cambiando `baseURL` al sistema nuevo, son el criterio de paridad.
3. **Capturas** de las pantallas clave (`SKILL-visual-evidence.md`) como referencia de UX.

Nunca ejecutar pruebas contra producción ni con datos reales.

## Fase 2 — Decisiones del dev (clase B2: preguntar y registrar)

| Decisión | Opciones | Choque con reglas de la plantilla |
|---|---|---|
| Base de datos | (a) Conservar esquema y SP, acceso con Dapper · (b) Esquema nuevo con EF Core y migración de datos | (a) choca con IDs UUID, soft delete y migraciones por ORM: excepción documentada en `convenciones.md` · (b) exige migrar y conciliar datos |
| Contrato del API | (a) Idéntico para los consumidores actuales · (b) Contrato nuevo `{ success, data, message, errors }` con plan de transición | (a) se registra la forma existente en `convenciones.md` y se sigue sin mezclar |
| Autenticación | Perfil A o B (`SKILL-auth-patterns.md`) | Sin perfil no se implementa (regla crítica) |
| Procesos en segundo plano | Worker Service .NET (`BackgroundService`) · consola .NET con el SDK de WebJobs si el hosting sigue en Azure App Service | Decisión de infraestructura |
| Orden de construcción | Por módulo de negocio, según dependencias y riesgo | — |

## Fase 3 — Construcción por módulo

Por módulo: spec desde el inventario → implementación (`SKILL-implementation.md`) → pruebas de
paridad + E2E Playwright → auditoría → tarea en `in-review`.

### Backend: .NET Framework → .NET 10

| Legado | Destino |
|---|---|
| ASP.NET Web API 2 / MVC 5 (`System.Web`) | ASP.NET Core: `dotnet-official/dotnet-aspnetcore/dotnet-webapi/SKILL.md` + `SKILL-dotnet-best-practices.md` |
| `Global.asax`, `WebApiConfig`, HTTP modules y handlers | `Program.cs`, middleware y filtros de ASP.NET Core |
| `Web.config` (`appSettings`, `connectionStrings`) | `appsettings.json` + variables de entorno o secretos; ningún valor sensible en el código |
| `packages.config` | `PackageReference` con Central Package Management (`dotnet-official/dotnet-nuget/convert-to-cpm/SKILL.md`) |
| log4net | `ILogger` (Microsoft.Extensions.Logging) |
| Newtonsoft.Json | System.Text.Json; mayúsculas, fechas y nulos cambian: las pruebas de paridad lo detectan |
| ADO.NET / EF6 / procedimientos almacenados | EF Core o Dapper según el perfil de datos (`SKILL-stack-policy.md`) |
| OWIN, Forms o autenticación propia | Perfil A o B (`SKILL-auth-patterns.md`) |
| WebJobs | Según la decisión de la Fase 2 |
| Help Page o Swashbuckle | `Microsoft.AspNetCore.OpenApi` + Scalar |
| `HttpContext.Current`, `Session` | Inyección de dependencias; sin estado en sesión |
| Pruebas legadas (MSTest, NUnit) | xUnit (`SKILL-dotnet-test-frameworks.md`) |

### Frontend: Angular 8 → Angular actual

| Legado | Destino |
|---|---|
| Workspace Angular 8 | Workspace nuevo (`ng new`) en la última versión mayor estable; **no** `ng update` versión por versión: en una reescritura no conviene arrastrar más de diez migraciones |
| `NgModule` | Componentes standalone |
| `*ngIf`, `*ngFor` | Control flow (`@if`, `@for`) |
| Estado local con RxJS | Signals; RxJS para HTTP y flujos asíncronos |
| Protractor | Playwright (`SKILL-e2e-playwright.md`) |
| Karma / Jasmine | El runner por defecto del Angular actual (`SKILL-angular-test-frameworks.md`) |
| TSLint | ESLint (`ng lint`) |
| jQuery, ng-bootstrap, Bootstrap 4 | Librerías de `SKILL-approved-libraries.md`; jQuery no se migra |
| Tokens en `localStorage` | Nunca: cookie HttpOnly o BFF según el perfil de auth (`SKILL-security-angular.md`) |

## Fase 4 — Datos y corte (clase S1)

- BD nueva: scripts de migración idempotentes, conciliación por tabla (conteos y sumas de control)
  y ensayo completo en QA.
- Plan de corte: congelamiento, migración, pruebas de humo y criterio de vuelta atrás (el legado
  sigue listo para retomar).
- Tocar producción o datos reales lo ejecuta o autoriza el dev, siempre.

## Fase 5 — Retiro del legado

Solo cuando el dev acepta el sistema nuevo en producción. El agente propone el checklist
(consumidores migrados, jobs desactivados, BD archivada) pero no borra `Codigo/<legado>/` ni apaga
servicios.

## Un módulo está terminado cuando

- Las pruebas de paridad pasan contra el sistema nuevo (diferencias aceptadas, documentadas).
- Hay E2E Playwright del happy path y de los errores principales.
- La auditoría no tiene hallazgos críticos o altos nuevos.
- La spec y `IA_Memoria/modernizacion.md` están al día y la tarea queda en `in-review`.

## Estructura de `IA_Memoria/modernizacion.md`

```markdown
# Modernización — <sistema legado> → <sistema nuevo>
## Inventario            (tablas de la Fase 0, con ruta de archivo como fuente)
## Decisiones            (Fase 2: decisión · opción elegida · quién · fecha)
## Matriz de paridad
| Módulo | Elementos del legado | Spec | Paridad | Diferencias aceptadas |
|---|---|---|---|---|
## Pendientes y riesgos
```

## Qué NO hacer

- Traducir línea por línea o copiar clases del legado.
- Cambiar una regla de negocio "porque se ve mal" sin decisión del dev.
- Llevar valores de `Web.config` (cadenas de conexión, claves) al repo nuevo.
- Agregar funcionalidad nueva mientras se construye la paridad.
- Probar contra producción o con datos reales.
- Borrar, apagar o reemplazar el legado sin confirmación.
