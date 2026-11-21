# Tools/entregables — herramientas para entregables

| Herramienta | Qué hace |
|---|---|
| `build-docx.mjs` | Convierte un Markdown acotado en un `.docx` institucional: portada, índice, índice de figuras, títulos numerados, tablas, figuras con pie, encabezado y "Página X de Y" |
| `archify.mjs` | Ejecuta archify (`IA_Skill/archify-official`) sin red y con el Chromium de Playwright |

El agente escribe el **contenido**; la herramienta aplica el **formato**. Así todos los agentes
producen el mismo documento. Procedimientos: `IA_Skill/SKILL-technical-memory.md`,
`IA_Skill/SKILL-user-manual.md`, `IA_Skill/SKILL-visual-evidence.md`.

## Preparación (una vez por máquina)

```bash
npm install --prefix Tools/entregables   # docx (fijado en package.json)
npm install                              # raíz: @playwright/test (capturas y diagramas a PNG)
npx playwright install chromium
```

## Uso

```bash
node Tools/entregables/build-docx.mjs Entregables/<Proyecto>/memoria-tecnica/memoria-tecnica.md --check
node Tools/entregables/build-docx.mjs Entregables/<Proyecto>/memoria-tecnica/memoria-tecnica.md
node Tools/entregables/build-docx.mjs <doc.md> --out <ruta/archivo.docx>
```

`--check` valida sin escribir. La salida es un JSON con títulos, tablas, figuras, pendientes,
advertencias y errores; el proceso termina con error (sin generar nada) si falta una imagen, una
tabla no tiene separador o falta un dato obligatorio. Al abrir el `.docx`, Word pide actualizar
campos: aceptar para completar los índices.

## Front matter

```markdown
---
tipo: memoria-tecnica          # memoria-tecnica | manual-usuario (define título y nombre del archivo)
sistema: Sistema de Indicadores # obligatorio: nombre oficial
version: 1.0
fecha: 2026-11-20
organizacion: <dependencia o cliente>
elaboro: <autor o área>
clasificacion: Uso Interno     # Público | Uso Interno | Confidencial
---
```

| Clave opcional | Default | Efecto |
|---|---|---|
| `titulo` | según `tipo` | Título del documento en portada y encabezado (obligatorio si no hay `tipo`) |
| `logo` | — | Ruta a PNG/JPEG para la portada |
| `papel` | `carta` | `carta` o `a4` |
| `numerar` | `si` | Numera los títulos (1., 1.1, 1.1.1, 1.1.1.1) |
| `h1-mayusculas` | `si` | Capítulos en mayúsculas |
| `salto-por-capitulo` | `si` | Cada capítulo empieza en página nueva |
| `anexo-evidencias` | `no` | Agrega "Anexo. Origen de las figuras" con origen, fecha y commit (lee el `.json` junto a cada imagen) |
| `archivo` | `<Memoria_Tecnica\|Manual_de_Usuario>_<Sistema>_v<version>.docx` | Nombre del `.docx` (junto al `.md`) |

Los datos de portada que falten se rellenan con `[Pendiente — …]` y se reportan como advertencia.

## Markdown soportado

| Elemento | Sintaxis | Resultado |
|---|---|---|
| Títulos | `#` a `####` (sin número; la herramienta numera) | Estilos Heading 1–4, entran al índice H1–H3 |
| Título sin número | `# Glosario {-}` | Igual, sin numeración |
| Párrafo | Líneas seguidas; línea en blanco separa | Justificado |
| Énfasis | `**negrita**`, `*cursiva*`, `` `código` `` | — (no usar `_guion_bajo_` para cursiva) |
| Enlace | `[texto](https://…)` | Hipervínculo |
| Listas | `- ítem` / `1. ítem`; anidación con 2 espacios (un nivel) | Viñetas o numeración (cada lista reinicia en 1) |
| Tabla | `\| a \| b \|` + separador `\|---\|---\|` (`:---:` centra, `---:` alinea a la derecha) | Encabezado azul claro que se repite por página |
| Figura | `![Pie de figura](ruta.png)` en su propia línea (PNG o JPEG) | Imagen centrada (máx. 16 cm) + "Figura N. Pie" e índice de figuras |
| Código | Bloque con ` ``` ` | Courier New sombreado |
| Nota | `> texto` | Recuadro con barra lateral |
| Salto de página | `<!-- pagebreak -->` | — |
| Pendientes | `[Pendiente — …]`, `[verificar …]` | Resaltado amarillo + listado en el reporte |

Otros comentarios HTML se ignoran. Las rutas de imágenes son relativas al `.md`.
