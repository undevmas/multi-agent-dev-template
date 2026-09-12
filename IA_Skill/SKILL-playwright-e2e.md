# SKILL — Playwright E2E y validación de navegador

## Cuándo usar esta skill

Usar para crear o ejecutar pruebas E2E, reproducir un bug desde la interfaz,
o validar una corrección en un flujo con frontend. Complementa — no reemplaza —
los tests unitarios del stack.

## Mapa operativo del template

| Recurso | Ruta / comando |
|---|---|
| Paquete local | `package.json` en la raíz del workspace (`@playwright/test`) |
| Configuración | `playwright.config.ts` |
| Pruebas persistentes | `tests/e2e/**/*.spec.ts` |
| Ejecución local por defecto | `npm run test:e2e` (Chromium) |
| Todos los navegadores instalados | `npm run test:e2e:all` |
| Depuración interactiva | `npm run test:e2e:debug` o `npm run test:e2e:ui` |
| Reporte de la última ejecución | `npm run test:e2e:report` |
| Automatización por consola | `.claude/skills/playwright-cli/SKILL.md` y `playwright-cli` |
| Artefactos efímeros | `test-results/`, `playwright-report/`, `blob-report/` (ignorados por Git) |

La URL se toma de `E2E_BASE_URL`; si no se define, la configuración usa
`http://localhost:4200`. Antes de ejecutar, leer `IA_Memoria/arquitectura.md`
para confirmar la URL y el comando de arranque del proyecto afectado.

### PersonalCripto

| Necesidad | Referencia concreta |
|---|---|
| Frontend | `Codigo/personal-cripto/src/Frontend/gestion-pwa/` |
| URL local | `http://localhost:4200` |
| Orquestación local | `dotnet run --project Codigo/personal-cripto/src/Orchestration/Aspire.Orchestration.AppHost/Aspire.Orchestration.AppHost.csproj -c Debug` |
| Prueba | `npm run test:e2e` desde la raíz del workspace |

Aspire o el frontend deben estar disponibles antes de lanzar la prueba. No
configurar `webServer` globalmente: cada módulo puede requerir dependencias y
variables de desarrollo distintas.

## Flujo de trabajo

1. Leer la spec de la feature cuando exista y ubicar los datos de prueba ya
   declarados; no inventar credenciales ni hardcodearlas en un `.spec.ts`.
2. Iniciar el proyecto con su mecanismo documentado y comprobar que la UI está
   disponible antes de diagnosticar una falla de test.
3. Para un comportamiento que debe mantenerse, crear o actualizar una prueba
   en `tests/e2e/<modulo>/<escenario>.spec.ts`. Usar locators por rol, label o
   `data-testid`; evitar selectores estructurales frágiles y esperas fijas.
4. Para exploración o reproducción puntual, usar `playwright-cli`: abrir una
   sesión con Chrome, tomar `snapshot`, operar mediante refs/locators, y revisar
   `console` y `requests` si el resultado es inesperado. Convertir el flujo a
   una prueba persistente si corrige una regresión con frontend.
5. Ejecutar primero Chromium. Ejecutar Firefox/WebKit cuando la tarea pida
   compatibilidad entre navegadores, responsividad crítica o un bug específico.
6. Reportar qué escenario se validó, navegador, URL/base usada, resultado y
   cualquier dato de desarrollo creado. Cerrar la sesión de CLI al terminar.

## Seguridad y datos de prueba

- Usar únicamente entornos locales o autorizados. No automatizar producción.
- Las credenciales y secretos se inyectan por variables de entorno o por el
  mecanismo seguro ya documentado; nunca se escriben en tests, snapshots,
  traces, videos ni reportes.
- Cada test debe crear/aislar sus propios datos o usar seeds idempotentes.
  No depender del orden de ejecución ni de datos compartidos de otros tests.
- Al fallar, conservar trace, captura y video generados por la configuración;
  no desactivar las aserciones ni convertir una regresión en `skip` sin una
  decisión explícita del usuario/equipo.

