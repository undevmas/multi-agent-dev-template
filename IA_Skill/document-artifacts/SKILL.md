---
name: document-artifacts
description: Create, edit, or inspect Word and PDF deliverables using the document capability available in the current agent environment.
---

# Entregables de documentos

Úsala al crear, editar o revisar archivos Word o PDF. No presupone rutas internas de otro entorno, una skill con nombre fijo ni paquetes npm.

## Flujo

1. Identificar la capacidad nativa de documentos disponible en el agente y leer sus instrucciones antes de generar o editar el archivo.
2. Si no existe esa capacidad, informar el bloqueo y pedir al usuario que habilite una herramienta compatible; no instalar dependencias ni inventar una ruta local.
3. Guardar el entregable en la ruta autorizada por la tarea, normalmente `Entregables/`.
4. Cuando el formato importe, renderizar o inspeccionar el resultado antes de entregarlo.

No copiar instrucciones de rutas como `/mnt/skills/...`; esas rutas son específicas de un entorno y no forman parte de este template.
