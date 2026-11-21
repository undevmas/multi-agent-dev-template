import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { expect, test } from '@playwright/test';
import { escribirMetadatos, evidenciasDir } from './support/evidencia';

// Exporta cada diagrama de archify (EVIDENCIAS_DIR/diagramas/**/*.html) a PNG usando el propio
// menú Exportar → PNG del visor, en tema claro, para insertarlo en memorias técnicas y manuales.
// Se omiten las carpetas de revisión que archify crea al reintentar (review-*, visual-check).
const diagramasDir = evidenciasDir ? path.join(evidenciasDir, 'diagramas') : '';

function buscarHtml(dir: string): string[] {
  if (!dir || !fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const ruta = path.join(dir, e.name);
    if (e.isDirectory()) return /^(review-|visual-check)/.test(e.name) ? [] : buscarHtml(ruta);
    return e.isFile() && e.name.endsWith('.html') ? [ruta] : [];
  });
}

const archivos = buscarHtml(diagramasDir);

test.describe('Diagramas archify → PNG', () => {
  test.skip(!evidenciasDir, 'Definir EVIDENCIAS_DIR (Entregables/<Proyecto>/evidencias).');

  if (archivos.length === 0) {
    test('sin diagramas para exportar', () => {
      test.skip(true, `No hay .html en ${diagramasDir || 'EVIDENCIAS_DIR/diagramas'}`);
    });
  }

  for (const html of archivos) {
    test(path.relative(diagramasDir, html).replace(/\\/g, '/'), async ({ page }) => {
      await page.goto(`${pathToFileURL(html).href}?theme=light`);
      const exportar = page.locator('#btn-export');
      await expect(exportar).toBeVisible();
      await exportar.click();
      const descarga = page.waitForEvent('download');
      await page.locator('#export-menu button[data-format="png"]').click();
      const destino = html.replace(/\.html$/i, '.png');
      await (await descarga).saveAs(destino);
      escribirMetadatos(destino, { tipo: 'diagrama', origen: path.relative(process.cwd(), html).replace(/\\/g, '/') });
    });
  }
});
