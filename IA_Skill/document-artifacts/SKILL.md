---
name: document-artifacts
description: Create, edit, or inspect Word and PDF deliverables. New documents are written in Markdown and built with the template's own generator (Tools/entregables/build-docx.mjs) so every agent produces the same institutional .docx; the agent's native document capability is only for editing or inspecting existing Word/PDF files.
---

# Entregables de documentos

Úsala al crear, editar o revisar archivos Word o PDF.

## Crear un documento nuevo (memoria técnica, manual de usuario, especificación formal)

1. Escribir el contenido en Markdown con front matter (formato y sintaxis soportada en
   `Tools/entregables/README.md`). Las imágenes salen de `IA_Skill/SKILL-visual-evidence.md`.
2. Validar: `node Tools/entregables/build-docx.mjs <documento.md> --check`.
3. Generar: el mismo comando sin `--check`. Guardar en `Entregables/<Proyecto>/…`.
4. Reportar el resultado de la herramienta (figuras, tablas, `[Pendiente …]`) y avisar que Word
   pide actualizar campos al abrir el archivo (aceptar para completar los índices).

No escribir scripts `docx` propios ni instalar paquetes adicionales: el formato institucional
(portada, índices, numeración, estilos) vive en la herramienta para que todos los agentes
produzcan el mismo documento. Si el documento necesita algo que la herramienta no soporta,
proponer el cambio a `Tools/entregables/build-docx.mjs` en vez de resolverlo por fuera.

## Editar o revisar un Word/PDF existente

1. Identificar la capacidad nativa de documentos disponible en el agente y leer sus instrucciones.
2. Si no existe esa capacidad, informar el bloqueo y pedir al usuario que habilite una herramienta
   compatible; no instalar dependencias ni inventar una ruta local.
3. Cuando el formato importe, renderizar o inspeccionar el resultado antes de entregarlo.

## PDF

El PDF se obtiene desde Word ("Guardar como → PDF") después de actualizar campos, para que el
índice y la numeración de figuras queden completos.

No copiar instrucciones de rutas como `/mnt/skills/...`; esas rutas son específicas de un entorno y
no forman parte de este template.
