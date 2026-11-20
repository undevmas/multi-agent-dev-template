# SKILL — E2E con Playwright

## Cuándo usar esta skill
Al escribir, revisar o ejecutar tests end-to-end (E2E) del frontend Angular o React, al
validar un flujo desde la UI o al reproducir un bug visual/funcional en el navegador.
Leer antes de crear cualquier archivo en `tests/e2e/` o tocar `playwright.config.ts`.
Complementa — no reemplaza — los tests unitarios del stack.

Framework E2E aprobado (default): **Playwright** — `@playwright/test` con TypeScript, más
`playwright-cli` para automatización interactiva del navegador.
Cypress: solo con autorización explícita del dev. Si el proyecto ya usa Cypress, se
conserva y **no se migra sin ticket** (zona roja según `SKILL-risk-zone-policy.md` →
registrar la propuesta en `IA_Memoria/deuda-tecnica.md`). Ver tabla al final.

Skills relacionadas: `SKILL-auth-patterns.md` (perfil de auth del proyecto) ·
`SKILL-aspire-orchestration.md` (levantar el entorno local) ·
`SKILL-approved-libraries.md` (antes de agregar plugins, ej. `@axe-core/playwright`) ·
`.claude/skills/playwright-cli/SKILL.md` (automatización interactiva).

---

## Mapa operativo del template

El tooling de Playwright vive en la **raíz del workspace**, no dentro de cada frontend.

| Recurso | Ruta / comando |
|---|---|
| Paquete local | `package.json` en la raíz (`@playwright/test`) |
| Configuración | `playwright.config.ts` en la raíz |
| Pruebas persistentes | `tests/e2e/**/*.spec.ts` |
| Ejecución local por defecto | `npm run test:e2e` (Chromium) |
| Todos los navegadores | `npm run test:e2e:all` |
| Depuración interactiva | `npm run test:e2e:debug` o `npm run test:e2e:ui` |
| Reporte de la última ejecución | `npm run test:e2e:report` |
| Automatización por consola | `playwright-cli` — ver `.claude/skills/playwright-cli/SKILL.md` |
| Artefactos efímeros | `test-results/`, `playwright-report/`, `blob-report/`, `playwright/.auth/` (ignorados por Git) |

Primera vez en el workspace:

```bash
npm install                      # instala @playwright/test desde el lockfile
npx playwright install chromium  # navegadores (agregar firefox/webkit si se necesitan)
```

Antes de ejecutar, leer `IA_Memoria/arquitectura.md` para confirmar la URL y el comando de
arranque del proyecto afectado.

Estructura sugerida dentro de `tests/e2e/`:

```
tests/e2e/
├── setup/
│   └── auth.setup.ts          ← login real una vez, guarda storageState
├── fixtures/
│   ├── test.ts                ← test.extend con page objects y helpers
│   └── data/                  ← JSON estáticos para mocks
├── pages/
│   └── contracts.page.ts      ← Page Objects ligeros
└── contracts/
    └── create-contract.spec.ts   ← tests/e2e/<modulo>/<escenario>.spec.ts
```

Variables de entorno (nunca hardcodear URLs ni credenciales — documentarlas en `.env.e2e.example`):
`E2E_BASE_URL`, `E2E_USER`, `E2E_PASSWORD`.

---

## playwright.config.ts

La configuración de la raíz es la fuente de verdad:

- `testDir: './tests/e2e'`.
- `baseURL` desde `E2E_BASE_URL`; si no se define, `http://localhost:4200` (puerto por defecto de Angular).
- Proyectos `chromium`, `firefox` y `webkit`; los scripts `npm run test:e2e*` usan Chromium salvo `test:e2e:all`.
- `trace`, `video` en `retain-on-failure` y `screenshot` en `only-on-failure`.
- En CI: `forbidOnly`, 2 reintentos y 1 worker.
- **Sin `webServer` global:** cada proyecto puede requerir dependencias y variables de
  desarrollo distintas. La app se arranca con su mecanismo documentado antes de lanzar los tests.

Cuando la app requiere login, agregar un proyecto `setup` y hacer que los navegadores
dependan de él (ver "Autenticación reutilizable"):

```typescript
// playwright.config.ts — fragmento de `projects`
const authFile = 'playwright/.auth/user.json';

projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  {
    name: 'chromium',
    use: { ...devices['Desktop Chrome'], storageState: authFile },
    dependencies: ['setup'],
  },
  // firefox / webkit con el mismo storageState y dependencies
],
```

**Con Aspire:** levantar el AppHost (`aspire run` o `dotnet run --project src/AppHost`),
tomar la URL del frontend desde el dashboard y exportarla en `E2E_BASE_URL`. Detalle en
`SKILL-aspire-orchestration.md`.

---

## Flujo de trabajo

1. Leer la spec de la feature cuando exista y ubicar los datos de prueba ya declarados;
   no inventar credenciales ni hardcodearlas en un `.spec.ts`.
2. Iniciar el proyecto con su mecanismo documentado y comprobar que la UI está disponible
   antes de diagnosticar una falla de test.
3. Para un comportamiento que debe mantenerse, crear o actualizar una prueba en
   `tests/e2e/<modulo>/<escenario>.spec.ts`.
4. Para exploración o reproducción puntual, usar `playwright-cli`: abrir una sesión, tomar
   `snapshot`, operar mediante refs/locators y revisar `console` y `requests` si el resultado
   es inesperado. Si el flujo corrige una regresión con frontend, convertirlo en prueba persistente.
5. Ejecutar primero Chromium. Ejecutar Firefox/WebKit cuando la tarea pida compatibilidad
   entre navegadores, responsividad crítica o un bug específico de navegador.
6. Reportar qué escenario se validó, navegador, URL base usada, resultado y cualquier dato
   de desarrollo creado. Cerrar la sesión de `playwright-cli` al terminar.

---

## Locators y aserciones

Prioridad de locators (de más a menos robusto):

1. `getByRole('button', { name: 'Guardar' })` — refleja lo que percibe el usuario y lectores de pantalla
2. `getByLabel('Correo electrónico')` — inputs de formulario
3. `getByText('Aún no hay contratos')` — contenido no interactivo
4. `getByTestId('contracts-table')` — último recurso (`data-testid` explícito en el componente)

```typescript
// MAL — selectores CSS frágiles y esperas fijas
await page.locator('div.mat-mdc-card > button.btn-primary:nth-child(2)').click();
await page.waitForTimeout(3000);
expect(await page.locator('.toast').isVisible()).toBe(true);   // no reintenta

// BIEN — locators semánticos + web-first assertions (reintentan solas hasta el timeout)
await page.getByRole('button', { name: 'Guardar' }).click();
await expect(page.getByRole('status')).toHaveText(/guardado/i);
await expect(page.getByRole('row', { name: /Contrato-e2e/ })).toBeVisible();
```

Si `getByRole` no encuentra el elemento, casi siempre es un problema de accesibilidad
del componente (botón sin nombre accesible, input sin `<label>`) — corregir el componente
(`frontend-design/SKILL-accessibility-a11y.md`), no bajar a selectores CSS.

---

## Autenticación reutilizable (storageState)

El login real se ejecuta **una vez** en el proyecto `setup`; el resto de los tests reutiliza
la sesión guardada en `playwright/.auth/user.json`. Usar siempre usuarios de prueba del
ambiente de QA — **nunca** cuentas reales ni de producción.

### Perfil A — OIDC + PKCE + BFF (Keycloak / Entra ID)
La SPA no maneja tokens: el BFF redirige al IdP y al volver deja una cookie HttpOnly.

```typescript
// tests/e2e/setup/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('autenticar usuario de prueba (IdP)', async ({ page }) => {
  const user = process.env.E2E_USER;
  const password = process.env.E2E_PASSWORD;
  if (!user || !password) throw new Error('E2E_USER / E2E_PASSWORD no definidas');

  await page.goto('/');   // el BFF redirige al IdP (realm/tenant de QA)
  await page.getByLabel(/usuario|username|email/i).fill(user);
  await page.getByLabel(/contraseña|password/i).fill(password);
  await page.getByRole('button', { name: /iniciar sesión|sign in/i }).click();

  await page.waitForURL('**/dashboard');          // de vuelta en la app
  await expect(page.getByRole('navigation')).toBeVisible();

  await page.context().storageState({ path: authFile });  // guarda la cookie del BFF
});
```

- Entra ID tiene login en varios pasos (email → Siguiente → contraseña): ajustar el flujo con `codegen`.
- MFA no es automatizable: pedir al admin una cuenta de prueba exenta de MFA **solo en el tenant/realm de QA**. Nunca desactivar MFA en producción ni usar ROPC (password grant) como atajo — OAuth 2.1 lo prohíbe.

### Perfil B — ASP.NET Core Identity API endpoints
Login directo por API con cookie (ruta según el `MapGroup` del proyecto):

```typescript
// tests/e2e/setup/auth.setup.ts
setup('autenticar vía Identity API', async ({ page }) => {
  const response = await page.request.post('/api/auth/login?useCookies=true', {
    data: { email: process.env.E2E_USER, password: process.env.E2E_PASSWORD },
  });
  expect(response.ok()).toBeTruthy();
  await page.context().storageState({ path: authFile });
});
```

Si la app usa formulario propio de login, hacer el flujo por UI igual que en el Perfil A.
El modo bearer de Identity es para clientes no-browser; en E2E de la SPA usar cookie.

---

## Page Object Model ligero + fixtures

```typescript
// tests/e2e/pages/contracts.page.ts
import { type Page, type Locator } from '@playwright/test';

export class ContractsPage {
  readonly newButton: Locator;
  readonly titleInput: Locator;
  readonly saveButton: Locator;

  constructor(private readonly page: Page) {
    this.newButton = page.getByRole('button', { name: 'Nuevo contrato' });
    this.titleInput = page.getByLabel('Título');
    this.saveButton = page.getByRole('button', { name: 'Guardar' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/contracts');
  }

  async create(title: string): Promise<void> {
    await this.newButton.click();
    await this.titleInput.fill(title);
    await this.saveButton.click();
  }

  row(title: string): Locator {
    return this.page.getByRole('row', { name: new RegExp(title) });
  }
}
```

```typescript
// tests/e2e/fixtures/test.ts
import { test as base } from '@playwright/test';
import { ContractsPage } from '../pages/contracts.page';

type Fixtures = {
  contractsPage: ContractsPage;
  uniqueName: (prefix: string) => string;
};

export const test = base.extend<Fixtures>({
  contractsPage: async ({ page }, use) => {
    await use(new ContractsPage(page));
  },
  // Identificador único por test — evita colisiones entre workers y corridas
  uniqueName: async ({}, use, testInfo) => {
    await use((prefix) => `${prefix}-e2e-${testInfo.workerIndex}-${Date.now()}`);
  },
});

export { expect } from '@playwright/test';
```

```typescript
// tests/e2e/contracts/create-contract.spec.ts
import { test, expect } from '../fixtures/test';

test.describe('Contratos — alta', () => {
  test('crea un contrato y lo muestra en la tabla', { tag: '@smoke' }, async ({ contractsPage, uniqueName }) => {
    const title = uniqueName('Contrato');
    await contractsPage.goto();
    await contractsPage.create(title);
    await expect(contractsPage.row(title)).toBeVisible();
  });
});
```

Los Page Objects exponen locators y acciones; las **aserciones viven en el test**.

---

## Mock de red (estados de error / vacío)

```typescript
test('muestra empty state cuando no hay contratos', async ({ page, contractsPage }) => {
  await page.route('**/api/v1/contracts*', (route) =>
    route.fulfill({ status: 200, json: { success: true, data: [], message: '', errors: [] } }),
  );
  await contractsPage.goto();
  await expect(page.getByText('Aún no hay contratos')).toBeVisible();
});

test('muestra error amigable si la API falla', async ({ page, contractsPage }) => {
  await page.route('**/api/v1/contracts*', (route) =>
    route.fulfill({ status: 500, json: { success: false, data: null, message: 'Error interno', errors: [] } }),
  );
  await contractsPage.goto();
  await expect(page.getByRole('alert')).toContainText(/no pudimos cargar/i);
});
```

- La forma del JSON mockeado debe ser la respuesta estandarizada de `IA_Memoria/convenciones.md`.
- **Mockear:** estados difíciles de reproducir (500, timeout, lista vacía, paginación extrema).
- **No mockear:** flujos críticos (login, alta/edición de negocio, permisos) — van contra el backend real.

---

## Datos de prueba y seguridad

- Usar únicamente entornos locales o autorizados. No automatizar producción.
- Las credenciales y secretos se inyectan por variables de entorno; nunca se escriben en
  tests, snapshots, traces, videos ni reportes.
- Crear datos vía API (`page.request`, que comparte las cookies de la sesión) con identificadores únicos (`uniqueName`).
  Cada test crea/aísla sus propios datos o usa seeds idempotentes; no depender del orden de ejecución.
- **Nunca** limpiar con `DELETE` ni `DELETE FROM` (soft delete obligatorio). Si hace falta limpieza, usar el endpoint de baja lógica de la propia API o recrear la BD efímera de QA (contenedor Aspire/Docker).
- Si el BFF exige header anti-CSRF en mutaciones (ej. `X-CSRF: 1`), agregarlo en la llamada o en `use.extraHTTPHeaders`.
- Al fallar, conservar trace, captura y video; no desactivar aserciones ni convertir una
  regresión en `skip` sin una decisión explícita del dev.

```typescript
test('edita un contrato existente', async ({ page, contractsPage, uniqueName }) => {
  const title = uniqueName('Contrato');
  const created = await page.request.post('/api/v1/contracts', { data: { title } });
  expect(created.ok()).toBeTruthy();

  await contractsPage.goto();
  await expect(contractsPage.row(title)).toBeVisible();
  // ... flujo de edición por UI
});
```

---

## Comandos

```bash
npm run test:e2e                             # Chromium (default local)
npm run test:e2e:all                         # todos los navegadores configurados
npm run test:e2e:ui                          # modo UI interactivo (time-travel)
npm run test:e2e:debug                       # inspector paso a paso
npm run test:e2e:report                      # abrir reporte HTML
npx playwright test --grep "@smoke"          # por tag o texto del título
npx playwright test tests/e2e/contracts      # por carpeta/archivo
npx playwright codegen "$E2E_BASE_URL"       # grabar flujo y obtener locators sugeridos
```

---

## CI en Azure DevOps (PROPUESTA)

> Modificar pipelines requiere confirmación explícita del dev (`AGENTS.md`).
> Este YAML se **propone** en la respuesta o en un archivo aparte; no se aplica al pipeline real.
> El template no incluye workflows de GitHub Actions: el CI/CD aprobado es Azure DevOps.

Para publicar resultados en CI, agregar el reporter JUnit en `playwright.config.ts`
(`['junit', { outputFile: 'results/e2e-junit.xml' }]`) y `results/` al `.gitignore`.

```yaml
# Pasos a agregar al job del frontend — PROPUESTA, no aplicar sin confirmación
- task: NodeTool@0                          # (verificar contra la versión instalada; alternativa: UseNode@1)
  inputs:
    versionSpec: '$(NodeLtsVersion)'        # Node.js LTS vigente del proyecto
- script: npm ci
  displayName: Instalar dependencias
- script: npx playwright install --with-deps
  displayName: Instalar navegadores Playwright
- script: npx playwright test
  displayName: Ejecutar E2E
  env:
    CI: 'true'
    E2E_BASE_URL: $(E2E_BASE_URL)
    E2E_USER: $(E2E_USER)
    E2E_PASSWORD: $(E2E_PASSWORD)           # variable secreta / variable group — mapear explícito
- task: PublishTestResults@2
  condition: succeededOrFailed()
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'results/e2e-junit.xml'
    testRunTitle: 'E2E Playwright'
- task: PublishPipelineArtifact@1
  condition: succeededOrFailed()
  inputs:
    targetPath: 'playwright-report'
    artifact: 'playwright-report'
```

---

## Si el proyecto ya usa Cypress

No migrar sin ticket: es zona roja (`SKILL-risk-zone-policy.md`). Registrar la propuesta
de migración en `IA_Memoria/deuda-tecnica.md` y seguir escribiendo tests en Cypress
mientras tanto. Si hay ticket aprobado, equivalencias:

| Cypress | Playwright |
|---|---|
| `cy.get('selector')` | `page.getByRole(...)` / `page.getByLabel(...)` / `page.locator(...)` |
| `cy.contains('texto')` | `page.getByText('texto')` |
| `cy.intercept(...)` | `page.route(...)` |
| `cy.session(...)` | proyecto `setup` + `storageState` |
| `cy.fixture('x.json')` | `import data from './data/x.json'` |
| `.should('be.visible')` | `await expect(locator).toBeVisible()` |
| `cy.request(...)` | `page.request.get/post(...)` |

---

## Checklist E2E antes de PR

- [ ] Tests en `tests/e2e/<modulo>/`, Page Objects en `tests/e2e/pages/`, fixtures en `tests/e2e/fixtures/`
- [ ] Locators semánticos (`getByRole` / `getByLabel` / `getByText`); `getByTestId` solo como último recurso
- [ ] Sin `waitForTimeout` ni selectores CSS frágiles; solo web-first assertions
- [ ] Login vía proyecto `setup` + `storageState`; `playwright/.auth/` ignorado por Git
- [ ] `baseURL` y credenciales de prueba desde variables de entorno (nada hardcodeado)
- [ ] Usuarios de prueba del ambiente de QA, nunca de producción
- [ ] Datos creados vía API con identificadores únicos; sin `DELETE` para limpieza
- [ ] Mocks (`page.route`) solo para estados de error/vacío; flujos críticos contra backend real
- [ ] JSON mockeado respeta la respuesta estandarizada de `IA_Memoria/convenciones.md`
- [ ] Tag `@smoke` en los flujos críticos
- [ ] Cambios al pipeline de Azure DevOps propuestos, no aplicados sin confirmación
- [ ] Plugins adicionales (ej. `@axe-core/playwright`) aprobados vía `SKILL-approved-libraries.md`
