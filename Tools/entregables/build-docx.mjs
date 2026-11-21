#!/usr/bin/env node
// Genera un .docx institucional (memoria técnica, manual de usuario) a partir de un Markdown acotado.
// El agente escribe el contenido; esta herramienta aplica siempre el mismo formato.
//
// Uso:
//   node Tools/entregables/build-docx.mjs <documento.md> [--out <archivo.docx>] [--check]
//
// Markdown soportado (ver Tools/entregables/README.md):
//   front matter (--- clave: valor ---), # a #### (numeración automática; sufijo {-} = sin número),
//   párrafos, **negrita**, *cursiva*, `código`, [texto](https://url), listas (- y 1.) con un nivel de anidación,
//   tablas con | y separador |---|, figuras ![Pie de figura](ruta.png|jpg) en línea propia,
//   bloques ``` de código, citas > (notas), <!-- pagebreak -->. Los marcadores [Pendiente …] y
//   [verificar …] se resaltan en amarillo y se listan en el reporte.
import fs from 'node:fs';
import path from 'node:path';
import {
  AlignmentType, BorderStyle, Document, ExternalHyperlink, Footer, Header, ImageRun, LevelFormat, Packer,
  PageBreak, PageNumber, Paragraph, SimpleField, ShadingType, Table, TableCell, TableOfContents, TableRow,
  TextRun, WidthType, HeadingLevel, TableLayoutType,
} from 'docx';

// Paleta, tipografía y tamaños institucionales (tamaños en medios puntos).
const COLORS = { primary: '1F3864', secondary: '2E75B6', accent: 'D6E4F7', text: '000000', subtle: '595959', code: 'F2F2F2', note: 'EAF1FB', border: 'BFBFBF' };
const FONTS = { heading: 'Arial', body: 'Arial', code: 'Courier New' };
const SIZES = { h1: 32, h2: 28, h3: 24, h4: 22, body: 22, code: 20, small: 18, coverTitle: 52, coverSub: 32 };
const MAX_IMG_WIDTH_PX = 605;  // ~16 cm a 96 dpi
const MAX_IMG_HEIGHT_PX = 800; // deja lugar al pie de figura en carta/A4
const PAPER = { carta: { width: 12240, height: 15840 }, a4: { width: 11906, height: 16838 } };
const TIPOS = {
  'memoria-tecnica': { titulo: 'Memoria Técnica', prefijo: 'Memoria_Tecnica' },
  'manual-usuario': { titulo: 'Manual de Usuario', prefijo: 'Manual_de_Usuario' },
};

const errors = [];
const warnings = [];
const pendientes = [];

// ---------- CLI ----------
const args = process.argv.slice(2);
const checkOnly = args.includes('--check');
const outIdx = args.indexOf('--out');
const outArg = outIdx >= 0 ? args[outIdx + 1] : null;
const input = args.find((a, i) => !a.startsWith('--') && (outIdx < 0 || i !== outIdx + 1));
if (!input) {
  console.error('Uso: node Tools/entregables/build-docx.mjs <documento.md> [--out <archivo.docx>] [--check]');
  process.exit(2);
}
const inputPath = path.resolve(input);
if (!fs.existsSync(inputPath)) {
  console.error(`No existe: ${inputPath}`);
  process.exit(2);
}
const baseDir = path.dirname(inputPath);

// ---------- Parser ----------
function parseFrontMatter(text) {
  const lines = text.replace(/^﻿/, '').replace(/\r\n/g, '\n').split('\n');
  const meta = {};
  if (lines[0]?.trim() !== '---') return { meta, body: lines, offset: 0 };
  let i = 1;
  for (; i < lines.length && lines[i].trim() !== '---'; i++) {
    const m = lines[i].match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (m) meta[m[1].toLowerCase()] = m[2].trim().replace(/^["']|["']$/g, '');
  }
  if (i >= lines.length) throw new Error('El front matter no tiene cierre (---).');
  return { meta, body: lines.slice(i + 1), offset: i + 1 };
}

const LIST_RE = /^(\s*)([-*+]|\d+[.)])\s+(.*)$/;

function splitRow(row) {
  let s = row.trim();
  if (s.startsWith('|')) s = s.slice(1);
  if (s.endsWith('|') && !s.endsWith('\\|')) s = s.slice(0, -1);
  return s.split(/(?<!\\)\|/).map((c) => c.trim().replace(/\\\|/g, '|'));
}

function parseTable(rows, lineNo) {
  if (rows.length < 2 || !/^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?$/.test(rows[1])) {
    errors.push(`Línea ${lineNo}: tabla sin fila separadora (|---|---|) bajo el encabezado.`);
    return null;
  }
  const header = splitRow(rows[0]);
  const align = splitRow(rows[1]).map((c) => (c.startsWith(':') && c.endsWith(':') ? AlignmentType.CENTER : c.endsWith(':') ? AlignmentType.RIGHT : AlignmentType.LEFT));
  const body = rows.slice(2).map(splitRow);
  body.forEach((r, k) => {
    if (r.length !== header.length) warnings.push(`Línea ${lineNo + 2 + k}: la fila tiene ${r.length} celdas y el encabezado ${header.length}.`);
  });
  return { type: 'table', header, align, rows: body };
}

function parseBlocks(lines, offset) {
  const blocks = [];
  let para = [];
  const flush = () => {
    if (para.length) blocks.push({ type: 'paragraph', text: para.join(' ') });
    para = [];
  };
  let i = 0;
  while (i < lines.length) {
    const raw = lines[i];
    const t = raw.trim();
    const lineNo = offset + i + 1;
    if (t.startsWith('```')) {
      flush();
      const code = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) code.push(lines[i++].replace(/\t/g, '    '));
      if (i >= lines.length) errors.push(`Línea ${lineNo}: bloque de código sin cierre.`);
      i++;
      blocks.push({ type: 'code', lines: code });
      continue;
    }
    if (/^<!--\s*pagebreak\s*-->$/i.test(t)) { flush(); blocks.push({ type: 'pagebreak' }); i++; continue; }
    if (t.startsWith('<!--')) { flush(); while (i < lines.length && !lines[i].includes('-->')) i++; i++; continue; }
    if (t === '') { flush(); i++; continue; }
    const h = t.match(/^(#{1,4})\s+(.+?)\s*$/);
    if (h) {
      flush();
      const un = h[2].match(/^(.*?)\s*\{(?:-|\.unnumbered)\}$/);
      blocks.push({ type: 'heading', level: h[1].length, text: un ? un[1] : h[2], numbered: !un, lineNo });
      i++;
      continue;
    }
    const fig = t.match(/^!\[(.*)\]\(\s*<?([^)>]+?)>?\s*\)$/);
    if (fig) { flush(); blocks.push({ type: 'figure', alt: fig[1].trim(), src: fig[2].trim(), lineNo }); i++; continue; }
    if (t.startsWith('|')) {
      flush();
      const rows = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) rows.push(lines[i++].trim());
      const table = parseTable(rows, lineNo);
      if (table) blocks.push(table);
      continue;
    }
    if (/^>\s?/.test(t)) {
      flush();
      const q = [];
      while (i < lines.length && /^>\s?/.test(lines[i].trim())) q.push(lines[i++].trim().replace(/^>\s?/, ''));
      blocks.push({ type: 'quote', text: q.join(' ') });
      continue;
    }
    if (LIST_RE.test(raw)) {
      flush();
      const items = [];
      while (i < lines.length) {
        const m = lines[i].match(LIST_RE);
        if (m) {
          items.push({ level: m[1].replace(/\t/g, '  ').length >= 2 ? 1 : 0, ordered: /\d/.test(m[2]), num: parseInt(m[2], 10) || 0, text: m[3] });
          i++;
        } else if (items.length && /^\s{2,}\S/.test(lines[i])) {
          items[items.length - 1].text += ` ${lines[i++].trim()}`;
        } else break;
      }
      blocks.push({ type: 'list', items });
      continue;
    }
    para.push(t);
    i++;
  }
  flush();
  return blocks;
}

// ---------- Inline ----------
const INLINE_RE = /(\*\*[^*]+\*\*)|(`[^`]+`)|(\[[^\]]+\]\([^)\s]+\))|(\*[^*\s][^*]*\*)/g;
const PENDING_RE = /\[(?:Pendiente|verificar)[^\]]*\]/gi;

function plainRuns(text, base) {
  const out = [];
  let last = 0;
  for (const m of text.matchAll(PENDING_RE)) {
    if (m.index > last) out.push(new TextRun({ ...base, text: text.slice(last, m.index) }));
    out.push(new TextRun({ ...base, text: m[0], highlight: 'yellow' }));
    pendientes.push(m[0]);
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(new TextRun({ ...base, text: text.slice(last) }));
  return out;
}

function inlineRuns(text, base = {}) {
  const out = [];
  let last = 0;
  for (const m of text.matchAll(INLINE_RE)) {
    if (m.index > last) out.push(...plainRuns(text.slice(last, m.index), base));
    const tok = m[0];
    if (tok.startsWith('**')) {
      out.push(...plainRuns(tok.slice(2, -2), { ...base, bold: true }));
    } else if (tok.startsWith('`')) {
      out.push(new TextRun({ ...base, text: tok.slice(1, -1), font: FONTS.code, size: (base.size ?? SIZES.body) - 2 }));
    } else if (tok.startsWith('[')) {
      const [, label, url] = tok.match(/^\[([^\]]+)\]\(([^)\s]+)\)$/);
      if (/^https?:\/\//i.test(url)) {
        out.push(new ExternalHyperlink({ link: url, children: [new TextRun({ ...base, text: label, color: COLORS.secondary, underline: {} })] }));
      } else {
        out.push(...plainRuns(label, base));
      }
    } else {
      out.push(...plainRuns(tok.slice(1, -1), { ...base, italics: true }));
    }
    last = m.index + tok.length;
  }
  if (last < text.length) out.push(...plainRuns(text.slice(last), base));
  return out;
}

// ---------- Imágenes ----------
function imageInfo(buf, file) {
  if (buf.length > 24 && buf.readUInt32BE(0) === 0x89504e47) return { type: 'png', w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
  if (buf[0] === 0xff && buf[1] === 0xd8) {
    let o = 2;
    while (o + 9 < buf.length && buf[o] === 0xff) {
      const marker = buf[o + 1];
      const len = buf.readUInt16BE(o + 2);
      if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) return { type: 'jpg', h: buf.readUInt16BE(o + 5), w: buf.readUInt16BE(o + 7) };
      o += 2 + len;
    }
  }
  errors.push(`Formato de imagen no soportado (usar PNG o JPEG): ${file}`);
  return null;
}

// ---------- Render ----------
function slug(s) {
  return String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^A-Za-z0-9]+/g, '_').replace(/^_|_$/g, '');
}

const { meta, body, offset } = parseFrontMatter(fs.readFileSync(inputPath, 'utf8'));
const tipo = TIPOS[meta.tipo];
const titulo = meta.titulo || tipo?.titulo;
const sistema = meta.sistema;
if (!sistema) errors.push('Front matter: falta "sistema" (nombre oficial del sistema).');
if (!titulo) errors.push('Front matter: falta "titulo" o un "tipo" conocido (memoria-tecnica | manual-usuario).');
const si = (v, def) => (v === undefined ? def : /^(si|sí|true|1|yes)$/i.test(v));
const numerar = si(meta.numerar, true);
const h1Mayus = si(meta['h1-mayusculas'], true);
const saltoCapitulo = si(meta['salto-por-capitulo'], true);
const anexoEvidencias = si(meta['anexo-evidencias'], false);
const paper = PAPER[(meta.papel || 'carta').toLowerCase()] ?? PAPER.carta;

const blocks = parseBlocks(body, offset);
const counters = [0, 0, 0, 0];
let lastLevel = 0;
let figureCount = 0;
let tableCount = 0;
let headingCount = 0;
let orderedInstance = 0;
const figures = [];

function headingParagraph(b) {
  if (b.level > lastLevel + 1 && lastLevel > 0) warnings.push(`Línea ${b.lineNo}: salto de nivel de título (H${lastLevel} → H${b.level}).`);
  lastLevel = b.level;
  headingCount++;
  let text = b.text;
  if (numerar && b.numbered) {
    counters[b.level - 1]++;
    for (let k = b.level; k < 4; k++) counters[k] = 0;
    const num = counters.slice(0, b.level).join('.');
    text = b.level === 1 ? `${num}. ${text}` : `${num} ${text}`;
  }
  if (b.level === 1 && h1Mayus) text = text.toLocaleUpperCase('es');
  const levels = [HeadingLevel.HEADING_1, HeadingLevel.HEADING_2, HeadingLevel.HEADING_3, HeadingLevel.HEADING_4];
  return new Paragraph({ heading: levels[b.level - 1], pageBreakBefore: b.level === 1 && saltoCapitulo, children: plainRuns(text, {}) });
}

function figureParagraphs(b) {
  const file = path.resolve(baseDir, b.src);
  if (!fs.existsSync(file)) {
    errors.push(`Línea ${b.lineNo}: no existe la imagen ${b.src}`);
    return [];
  }
  const buf = fs.readFileSync(file);
  const info = imageInfo(buf, b.src);
  if (!info) return [];
  if (!b.alt) warnings.push(`Línea ${b.lineNo}: la figura ${b.src} no tiene pie (texto entre corchetes).`);
  figureCount++;
  const scale = Math.min(1, MAX_IMG_WIDTH_PX / info.w, MAX_IMG_HEIGHT_PX / info.h);
  const sidecar = file.replace(/\.(png|jpe?g)$/i, '.json');
  figures.push({ n: figureCount, alt: b.alt, src: b.src, origen: fs.existsSync(sidecar) ? JSON.parse(fs.readFileSync(sidecar, 'utf8')) : null });
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER, keepNext: true, spacing: { before: 120, after: 60 },
      children: [new ImageRun({ type: info.type, data: buf, transformation: { width: Math.round(info.w * scale), height: Math.round(info.h * scale) }, altText: { name: `Figura ${figureCount}`, title: b.alt, description: b.alt } })],
    }),
    new Paragraph({
      style: 'Caption', alignment: AlignmentType.CENTER, spacing: { after: 240 },
      children: [new TextRun({ text: 'Figura ', bold: true }), new SimpleField('SEQ Figura \\* ARABIC', String(figureCount)), new TextRun({ text: '. ', bold: true }), ...inlineRuns(b.alt, {})],
    }),
  ];
}

function tableElement(b) {
  tableCount++;
  const cols = b.header.length;
  const border = { style: BorderStyle.SINGLE, size: 4, color: COLORS.border };
  const contentWidth = paper.width - 2 * 1418;
  const widths = b.widths?.map((pct) => Math.round((contentWidth * pct) / 100));
  const cell = (txt, header, align, k) => new TableCell({
    width: widths ? { size: widths[k], type: WidthType.DXA } : undefined,
    shading: header ? { type: ShadingType.CLEAR, fill: COLORS.accent, color: 'auto' } : undefined,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: [new Paragraph({ alignment: align, children: inlineRuns(txt ?? '', { size: SIZES.small, bold: header || undefined }) })],
  });
  const fit = (r) => Array.from({ length: cols }, (_, k) => r[k] ?? '');
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    columnWidths: widths,
    layout: widths ? TableLayoutType.FIXED : undefined,
    borders: { top: border, bottom: border, left: border, right: border, insideHorizontal: border, insideVertical: border },
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: b.header.map((c, k) => cell(c, true, b.align[k], k)) }),
      ...b.rows.map((r) => new TableRow({ cantSplit: true, children: fit(r).map((c, k) => cell(c, false, b.align[k], k)) })),
    ],
  });
}

function render(blocksToRender) {
  const out = [];
  for (const b of blocksToRender) {
    switch (b.type) {
      case 'heading': out.push(headingParagraph(b)); break;
      case 'paragraph': out.push(new Paragraph({ alignment: AlignmentType.JUSTIFIED, spacing: { after: 120 }, children: inlineRuns(b.text) })); break;
      case 'figure': out.push(...figureParagraphs(b)); break;
      case 'table': out.push(tableElement(b), new Paragraph({ spacing: { after: 120 }, children: [] })); break;
      case 'pagebreak': out.push(new Paragraph({ children: [new PageBreak()] })); break;
      case 'quote':
        out.push(new Paragraph({
          shading: { type: ShadingType.CLEAR, fill: COLORS.note, color: 'auto' }, indent: { left: 360 }, spacing: { before: 120, after: 120 },
          border: { left: { style: BorderStyle.SINGLE, size: 18, color: COLORS.secondary, space: 8 } },
          children: inlineRuns(b.text, { italics: true }),
        }));
        break;
      case 'code':
        for (const line of b.lines.length ? b.lines : ['']) {
          out.push(new Paragraph({ shading: { type: ShadingType.CLEAR, fill: COLORS.code, color: 'auto' }, indent: { left: 240 }, spacing: { after: 0 }, children: [new TextRun({ text: line, font: FONTS.code, size: SIZES.code })] }));
        }
        out.push(new Paragraph({ spacing: { after: 120 }, children: [] }));
        break;
      case 'list': {
        // Una lista que empieza en N > 1 continúa la anterior (pasos intercalados con figuras); si empieza en 1, reinicia.
        const continua = b.items[0].ordered && b.items[0].num > 1 && orderedInstance > 0;
        if (!continua) orderedInstance++;
        for (const it of b.items) {
          out.push(new Paragraph({
            numbering: it.ordered ? { reference: 'ordered', level: it.level, instance: orderedInstance } : { reference: 'bullets', level: it.level },
            spacing: { after: 60 }, children: inlineRuns(it.text),
          }));
        }
        out.push(new Paragraph({ spacing: { after: 60 }, children: [] }));
        break;
      }
      default: break;
    }
  }
  return out;
}

// Portada
function coverChildren() {
  const kids = [new Paragraph({ spacing: { before: 2400 }, children: [] })];
  if (meta.logo) {
    const logo = path.resolve(baseDir, meta.logo);
    if (fs.existsSync(logo)) {
      const buf = fs.readFileSync(logo);
      const info = imageInfo(buf, meta.logo);
      if (info) {
        const scale = Math.min(1, 240 / info.w, 120 / info.h);
        kids.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 }, children: [new ImageRun({ type: info.type, data: buf, transformation: { width: Math.round(info.w * scale), height: Math.round(info.h * scale) } })] }));
      }
    } else warnings.push(`Front matter: no existe el logo ${meta.logo}`);
  }
  kids.push(
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 240 }, children: [new TextRun({ text: sistema ?? '', bold: true, size: SIZES.coverTitle, color: COLORS.primary, font: FONTS.heading })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1200 }, children: [new TextRun({ text: titulo ?? '', size: SIZES.coverSub, color: COLORS.secondary, font: FONTS.heading })] }),
  );
  const field = (label, value, key) => {
    if (!value) warnings.push(`Portada: falta "${key}" en el front matter.`);
    return [label, value || `[Pendiente — ${label.toLowerCase()}]`];
  };
  const rows = [
    field('Versión del documento', meta.version, 'version'),
    field('Fecha', meta.fecha, 'fecha'),
    field('Organización', meta.organizacion, 'organizacion'),
    field('Elaboró', meta.elaboro, 'elaboro'),
    field('Clasificación', meta.clasificacion || 'Uso Interno', 'clasificacion'),
  ];
  const border = { style: BorderStyle.SINGLE, size: 4, color: COLORS.border };
  kids.push(new Table({
    width: { size: 70, type: WidthType.PERCENTAGE }, alignment: AlignmentType.CENTER,
    borders: { top: border, bottom: border, left: border, right: border, insideHorizontal: border, insideVertical: border },
    rows: rows.map(([k, v]) => new TableRow({
      children: [
        new TableCell({ shading: { type: ShadingType.CLEAR, fill: COLORS.accent, color: 'auto' }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: k, bold: true, size: SIZES.small })] })] }),
        new TableCell({ margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: plainRuns(v, { size: SIZES.small }) })] }),
      ],
    })),
  }));
  return kids;
}

const bodyChildren = render(blocks);

// Anexo de trazabilidad de figuras (origen, fecha y commit de cada evidencia)
if (anexoEvidencias && figures.length) {
  bodyChildren.push(headingParagraph({ level: 1, text: 'Anexo. Origen de las figuras', numbered: false, lineNo: 0 }));
  bodyChildren.push(tableElement({
    header: ['Figura', 'Descripción', 'Archivo', 'Origen', 'Fecha', 'Commit'],
    align: [AlignmentType.CENTER, AlignmentType.LEFT, AlignmentType.LEFT, AlignmentType.LEFT, AlignmentType.CENTER, AlignmentType.CENTER],
    widths: [9, 23, 24, 22, 12, 10],
    rows: figures.map((f) => [String(f.n), f.alt, f.src, f.origen?.url ?? f.origen?.origen ?? '—', (f.origen?.fecha ?? '—').slice(0, 10), f.origen?.commit ?? '—']),
  }));
}

if (blocks.length === 0) errors.push('El documento no tiene contenido después del front matter.');

const report = {
  archivo: null,
  titulos: headingCount,
  tablas: tableCount,
  figuras: figureCount,
  pendientes: [...new Set(pendientes)],
  advertencias: warnings,
  errores: errors,
};

if (errors.length) {
  console.log(JSON.stringify(report, null, 2));
  console.error(`\nERROR: ${errors.length} problema(s); no se generó el documento.`);
  process.exit(1);
}
if (checkOnly) {
  console.log(JSON.stringify(report, null, 2));
  process.exit(0);
}

const tocChildren = [
  new Paragraph({ spacing: { after: 240 }, children: [new TextRun({ text: 'CONTENIDO', bold: true, size: SIZES.h1, color: COLORS.primary, font: FONTS.heading })] }),
  new TableOfContents('Contenido', { hyperlink: true, headingStyleRange: '1-3' }),
];
if (figureCount > 0) {
  tocChildren.push(
    new Paragraph({ pageBreakBefore: true, spacing: { after: 240 }, children: [new TextRun({ text: 'ÍNDICE DE FIGURAS', bold: true, size: SIZES.h1, color: COLORS.primary, font: FONTS.heading })] }),
    new TableOfContents('Índice de figuras', { hyperlink: true, captionLabelIncludingNumbers: 'Figura' }),
  );
}
const firstIsH1 = blocks[0]?.type === 'heading' && blocks[0].level === 1;
if (!(saltoCapitulo && firstIsH1)) tocChildren.push(new Paragraph({ children: [new PageBreak()] }));

const headerText = `${[sistema, titulo].filter(Boolean).join(' · ')}  |  ${meta.clasificacion || 'Uso Interno'}`;
const pageProps = { size: paper, margin: { top: 1418, bottom: 1418, left: 1418, right: 1418, header: 708, footer: 708 } };
const doc = new Document({
  creator: meta.elaboro || 'multi-agent-dev-template',
  title: `${titulo} — ${sistema}`,
  description: titulo,
  features: { updateFields: true },
  styles: {
    default: {
      document: { run: { font: FONTS.body, size: SIZES.body, color: COLORS.text } },
      heading1: { run: { font: FONTS.heading, size: SIZES.h1, bold: true, color: COLORS.primary }, paragraph: { spacing: { before: 240, after: 160 }, keepNext: true } },
      heading2: { run: { font: FONTS.heading, size: SIZES.h2, bold: true, color: COLORS.secondary }, paragraph: { spacing: { before: 240, after: 120 }, keepNext: true } },
      heading3: { run: { font: FONTS.heading, size: SIZES.h3, bold: true, color: COLORS.text }, paragraph: { spacing: { before: 200, after: 100 }, keepNext: true } },
      heading4: { run: { font: FONTS.heading, size: SIZES.h4, bold: true, italics: true, color: COLORS.subtle }, paragraph: { spacing: { before: 160, after: 80 }, keepNext: true } },
    },
    paragraphStyles: [
      { id: 'Caption', name: 'Caption', basedOn: 'Normal', next: 'Normal', run: { size: SIZES.small, color: COLORS.subtle, italics: true } },
    ],
  },
  numbering: {
    config: [
      { reference: 'bullets', levels: [
        { level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.BULLET, text: '◦', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
      ] },
      { reference: 'ordered', levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.LOWER_LETTER, text: '%2)', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
      ] },
    ],
  },
  sections: [
    { properties: { page: pageProps }, children: coverChildren() },
    {
      properties: { page: { ...pageProps, pageNumbers: { start: 1 } } },
      headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: COLORS.border, space: 4 } }, children: [new TextRun({ text: headerText, size: SIZES.small, color: COLORS.subtle })] })] }) },
      footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['Página ', PageNumber.CURRENT, ' de ', PageNumber.TOTAL_PAGES_IN_SECTION], size: SIZES.small, color: COLORS.subtle })] })] }) },
      children: [...tocChildren, ...bodyChildren],
    },
  ],
});

const outName = outArg || meta.archivo || `${tipo?.prefijo ?? slug(titulo)}_${slug(sistema)}_v${meta.version || '1.0'}.docx`;
const outPath = path.resolve(baseDir, outName);
fs.writeFileSync(outPath, await Packer.toBuffer(doc));
report.archivo = path.relative(process.cwd(), outPath);
console.log(JSON.stringify(report, null, 2));
console.error(`\nOK: ${report.archivo} (${figureCount} figuras, ${tableCount} tablas, ${report.pendientes.length} pendientes). Al abrirlo, Word pedirá actualizar campos: aceptar para completar el índice.`);
