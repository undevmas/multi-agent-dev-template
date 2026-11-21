#!/usr/bin/env node
// Ejecuta archify (copia fijada en IA_Skill/archify-official/archify) con la configuración de la plantilla:
//   - ARCHIFY_UPDATE_CHECK_DISABLED=1 → sin llamadas de red (no consulta actualizaciones).
//   - ARCHIFY_CHROME → el Chromium de Playwright del workspace (un solo navegador para todo).
//
// Uso (reemplaza a `node bin/archify.mjs` de la skill):
//   node Tools/entregables/archify.mjs <comando> [argumentos]
//   node Tools/entregables/archify.mjs doctor
//   node Tools/entregables/archify.mjs finalize architecture <candidate.json> <salida.html> --repo-root Codigo/<proyecto> --quality showcase --json
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const bin = path.join(root, 'IA_Skill', 'archify-official', 'archify', 'bin', 'archify.mjs');
if (!fs.existsSync(bin)) {
  console.error(`No se encontró archify en ${bin}. Sincronizar con IA_Skill/archify-official/sync-archify.ps1 (o .sh).`);
  process.exit(1);
}

const env = { ...process.env, ARCHIFY_UPDATE_CHECK_DISABLED: '1' };
if (!env.ARCHIFY_CHROME) {
  try {
    const require = createRequire(path.join(root, 'package.json'));
    const exe = require('@playwright/test').chromium.executablePath();
    if (exe && fs.existsSync(exe)) env.ARCHIFY_CHROME = exe;
    else console.error('Aviso: falta el Chromium de Playwright (npx playwright install chromium); archify buscará Chrome/Edge del sistema.');
  } catch {
    console.error('Aviso: @playwright/test no está instalado en la raíz (npm install); archify buscará Chrome/Edge del sistema.');
  }
}

const result = spawnSync(process.execPath, [bin, ...process.argv.slice(2)], { stdio: 'inherit', env, cwd: process.cwd() });
process.exit(result.status ?? 1);
