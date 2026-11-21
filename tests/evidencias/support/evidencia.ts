import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import type { Locator, Page } from '@playwright/test';

/** Carpeta de evidencias del entregable: Entregables/<Proyecto>/evidencias (variable EVIDENCIAS_DIR). */
export const evidenciasDir = process.env.EVIDENCIAS_DIR ? path.resolve(process.env.EVIDENCIAS_DIR) : '';

let commitCache: string | null | undefined;

/** Commit corto del código evidenciado (EVIDENCIAS_REPO = Codigo/<proyecto>), para el anexo de trazabilidad. */
export function commitEvidenciado(): string | null {
  if (commitCache !== undefined) return commitCache;
  const repo = process.env.EVIDENCIAS_REPO;
  try {
    commitCache = repo
      ? execFileSync('git', ['-C', path.resolve(repo), 'rev-parse', '--short', 'HEAD'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim()
      : null;
  } catch {
    commitCache = null;
  }
  return commitCache;
}

/** Guarda junto a la imagen un .json con su origen, fecha y commit (lo usa el anexo de evidencias del .docx). */
export function escribirMetadatos(imagen: string, datos: Record<string, unknown>): void {
  const sidecar = imagen.replace(/\.(png|jpe?g)$/i, '.json');
  fs.writeFileSync(sidecar, JSON.stringify({ ...datos, fecha: new Date().toISOString(), commit: commitEvidenciado() }, null, 2));
}

export interface OpcionesCaptura {
  /** Carpeta del módulo funcional en kebab-case, ej. "contratos". */
  modulo: string;
  /** Identificador ordenable del paso en kebab-case, ej. "01-listado". */
  id: string;
  /** Pie de figura que usará el documento. */
  pie: string;
  /** Elementos con datos personales o sensibles que se tapan en la imagen. */
  mascaras?: Locator[];
  /** Capturar solo este elemento en lugar de la ventana. */
  elemento?: Locator;
  /** Capturar la página completa, incluido el scroll. */
  paginaCompleta?: boolean;
}

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** Captura determinista para entregables: sin animaciones ni cursor, con máscaras y metadatos (URL sin query string). */
export async function capturar(page: Page, o: OpcionesCaptura): Promise<string> {
  if (!evidenciasDir) throw new Error('Definir EVIDENCIAS_DIR (Entregables/<Proyecto>/evidencias).');
  if (!SLUG.test(o.modulo) || !SLUG.test(o.id)) throw new Error(`modulo e id deben ser kebab-case: ${o.modulo}/${o.id}`);
  const dir = path.join(evidenciasDir, 'capturas', o.modulo);
  fs.mkdirSync(dir, { recursive: true });
  const archivo = path.join(dir, `${o.id}.png`);
  await page.evaluate(() => document.fonts?.ready);
  const opciones = { path: archivo, animations: 'disabled' as const, caret: 'hide' as const, mask: o.mascaras ?? [], maskColor: '#1F3864' };
  if (o.elemento) await o.elemento.screenshot(opciones);
  else await page.screenshot({ ...opciones, fullPage: o.paginaCompleta ?? false });
  const url = new URL(page.url());
  const origen = url.protocol === 'file:' ? path.basename(url.pathname) : `${url.origin}${url.pathname}`;
  escribirMetadatos(archivo, { tipo: 'captura', modulo: o.modulo, id: o.id, pie: o.pie, url: origen, viewport: page.viewportSize() });
  return archivo;
}
