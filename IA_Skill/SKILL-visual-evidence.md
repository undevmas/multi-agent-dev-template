# SKILL — Evidencias visuales para entregables (diagramas archify + capturas Playwright)

## Cuándo usar esta skill

Al producir las imágenes de un entregable: memoria técnica (`SKILL-technical-memory.md`), manual de
usuario (`SKILL-user-manual.md`) o documentación de feature (`SKILL-docs-feature.md`). Cubre:

- **Diagramas desde el código** con archify (arquitectura, secuencia, ERD, flujo de datos, ciclo de
  vida, clases, workflow, timeline) y su exportación a PNG.
- **Capturas reales de pantallas** con Playwright, deterministas y con datos sensibles enmascarados.
- **Trazabilidad**: cada imagen guarda su origen, fecha y commit para el anexo de auditoría.

No usarla para tests E2E (eso es `SKILL-e2e-playwright.md`): los specs de evidencias no validan
comportamiento, producen imágenes.

---

## Estructura

```
Entregables/<Proyecto>/
├── evidencias/
│   ├── diagramas/<id>/candidate.json      ← fuente del diagrama (se conserva para regenerar)
│   ├── diagramas/<id>/<id>.html           ← diagrama interactivo validado por archify
│   ├── diagramas/<id>/<id>.png  + .json   ← PNG para Word + metadatos (origen, fecha, commit)
│   └── capturas/<modulo>/<NN-paso>.png + .json
├── memoria-tecnica/memoria-tecnica.md → Memoria_Tecnica_<Sistema>_v<ver>.docx
└── manual-usuario/manual-usuario.md   → Manual_de_Usuario_<Sistema>_v<ver>.docx
tests/evidencias/<modulo>.capture.ts      ← guiones de captura (se versionan en el workspace)
```

`Entregables/` no se sube al repositorio de código del proyecto. Los guiones de captura sí se
conservan: permiten regenerar el manual cuando cambie la UI.

## Preparación (una vez por máquina)

```bash
npm install                               # raíz: @playwright/test
npx playwright install chromium           # navegador de Playwright (archify también lo usa)
npm install --prefix Tools/entregables    # generador .docx (docx)
node Tools/entregables/archify.mjs doctor # debe terminar en "Archify is ready."
```

---

## 1. Diagramas con archify

archify está copiado y fijado en `IA_Skill/archify-official/` (ver su `README.md`). Para escribir
el `candidate.json`, leer `IA_Skill/archify-official/archify/SKILL.md` y sus `references/`, con un
cambio obligatorio: **donde archify dice `node bin/archify.mjs`, usar
`node Tools/entregables/archify.mjs`** (corre sin red y con el Chromium de Playwright).

| Necesito mostrar | Tipo archify |
|---|---|
| Capas, servicios, BD, integraciones, despliegue | `architecture` |
| Una llamada entre componentes (login, integración, pago) | `sequence` |
| Esquema de base de datos | `erd` |
| Movimiento de datos entre sistemas (ETL, colas) | `dataflow` |
| Estados de una entidad (solicitud, contrato) | `lifecycle` |
| Modelo de clases/DTOs de un módulo | `class` |
| Proceso de negocio con decisiones | `workflow` |

Si el tipo no es obvio: `node Tools/entregables/archify.mjs guide "<escenario>" --json`.

```bash
# Una carpeta por diagrama; id en kebab-case
node Tools/entregables/archify.mjs finalize architecture \
  Entregables/<Proyecto>/evidencias/diagramas/arquitectura-general/candidate.json \
  Entregables/<Proyecto>/evidencias/diagramas/arquitectura-general/arquitectura-general.html \
  --repo-root Codigo/<proyecto> --quality showcase --json
```

Reglas:
- **Solo evidencia real:** con `--repo-root`, cada nodo y relación cita su fuente en el código
  (archify lo valida). Lo que no tiene evidencia no se dibuja; en el documento se marca `[Pendiente — …]`.
- **Salida exitosa** = exit 0 y `"status":"pass"` en las cuatro compuertas (validate, deliver, check,
  browser-check). Si falla, reparar según `references/delivery-contract.md` y reintentar con
  `--out-dir <carpeta>/review-<n>`.
- Si el recibo trae `visualReviewRecommendation`, aplicar la corrección de posiciones que indica una
  sola vez y revisar el PNG antes de usarlo.
- Títulos y etiquetas en el idioma del entregable (español); nombres de componentes tal como
  aparecen en el código.
- Nunca hosts, IPs internas, cadenas de conexión ni credenciales en nodos o etiquetas.

## 2. Exportar los diagramas a PNG

`tests/evidencias/diagramas.capture.ts` abre cada `.html` de `diagramas/` en tema claro y usa el
propio menú **Exportar → PNG** de archify (sin la interfaz del visor), alta resolución.

```powershell
# PowerShell
$env:EVIDENCIAS_DIR = 'Entregables/<Proyecto>/evidencias'; $env:EVIDENCIAS_REPO = 'Codigo/<proyecto>'
npm run evidencias -- diagramas.capture.ts
```

```bash
# bash
EVIDENCIAS_DIR=Entregables/<Proyecto>/evidencias EVIDENCIAS_REPO=Codigo/<proyecto> npm run evidencias -- diagramas.capture.ts
```

Revisar visualmente cada PNG antes de citarlo en un documento.

## 3. Capturas reales de pantallas

Un spec por módulo funcional en `tests/evidencias/<modulo>.capture.ts`. El proyecto Playwright
`evidencias` fija la ventana (1440×900, escala 2), tema claro, locale `es-MX` y zona horaria
(`EVIDENCIAS_LOCALE` / `EVIDENCIAS_TZ` para cambiarlos); `E2E_BASE_URL` indica la app.

```typescript
import { test } from '@playwright/test';
import { capturar } from './support/evidencia';

// Guion de capturas del módulo Contratos para el manual de usuario.
test.describe('Contratos — capturas', () => {
  // Sesión de un usuario de prueba de QA, generada por el setup de E2E (SKILL-e2e-playwright.md)
  test.use({ storageState: 'playwright/.auth/usuario-qa.json' });

  test('registro de contrato', async ({ page }) => {
    await page.goto('/contratos');
    await capturar(page, {
      modulo: 'contratos', id: '01-listado', pie: 'Listado de contratos activos',
      mascaras: [page.getByTestId('usuario-actual')],
    });

    await page.getByRole('button', { name: 'Nuevo contrato' }).click();
    await page.getByLabel('Título').fill('Contrato de servicios de prueba');
    await capturar(page, {
      modulo: 'contratos', id: '02-formulario', pie: 'Formulario de registro de contrato',
      elemento: page.getByRole('dialog'),
    });

    await page.getByRole('button', { name: 'Guardar' }).click();
    await capturar(page, { modulo: 'contratos', id: '03-confirmacion', pie: 'Mensaje de confirmación del registro' });
  });
});
```

```powershell
$env:EVIDENCIAS_DIR = 'Entregables/<Proyecto>/evidencias'; $env:EVIDENCIAS_REPO = 'Codigo/<proyecto>'
$env:E2E_BASE_URL = 'http://localhost:4200'
npm run evidencias -- contratos.capture.ts
```

`capturar(page, { modulo, id, pie, mascaras?, elemento?, paginaCompleta? })` desactiva
animaciones y cursor, espera las fuentes, guarda `capturas/<modulo>/<id>.png` y su `.json`
(URL **sin** query string, viewport, fecha, commit).

Reglas de capturas:
- **Solo entorno local o de QA con datos de prueba.** Nunca producción ni datos reales de usuarios.
- **Enmascarar** todo dato personal o sensible que pueda aparecer (nombres, RFC, CURP, correos,
  teléfonos, montos reales, tokens) con `mascaras`.
- Credenciales de usuarios de prueba por variables de entorno o `storageState`; nunca en el spec.
- Datos de prueba creados por API con valores ficticios realistas; sin `DELETE` para limpiar.
- Capturar cuando la pantalla cambia o muestra un resultado relevante, no en cada clic.
- `id` ordenable (`01-…`, `02-…`) para que el orden del documento sea el del flujo.

## 4. Usar las imágenes en el documento

En el Markdown del entregable, cada imagen en su propia línea con su pie:

```markdown
![Vista general de la arquitectura del sistema](../evidencias/diagramas/arquitectura-general/arquitectura-general.png)
![Formulario de registro de contrato](../evidencias/capturas/contratos/02-formulario.png)
```

`Tools/entregables/build-docx.mjs` numera las figuras, arma el índice de figuras y, con
`anexo-evidencias: si`, agrega la tabla de trazabilidad usando los `.json` de cada imagen.

---

## Checklist

- [ ] `node Tools/entregables/archify.mjs doctor` en verde
- [ ] Cada diagrama pasó `finalize` con las 4 compuertas y su contenido tiene evidencia en `Codigo/`
- [ ] PNG de diagramas exportados con `diagramas.capture.ts` y revisados visualmente
- [ ] Capturas tomadas contra local/QA, con datos de prueba y máscaras sobre datos sensibles
- [ ] Ninguna imagen muestra credenciales, hosts internos de producción ni datos reales
- [ ] Cada imagen tiene su `.json` de trazabilidad (EVIDENCIAS_REPO definido para el commit)
- [ ] Los guiones `tests/evidencias/<modulo>.capture.ts` quedaron guardados para regenerar
