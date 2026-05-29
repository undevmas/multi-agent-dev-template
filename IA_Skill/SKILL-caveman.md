# SKILL — Caveman (Respuestas compactas)

## Qué hace esta skill
Instruye al agente a responder de forma ultra-concisa, como "hombre de las cavernas".
Reduce tokens de salida ~75% manteniendo precisión técnica.
Útil en sesiones largas donde el contexto se llena rápido.

## Cuándo activar
Escribir al inicio del prompt: "caveman mode" o "responde en modo caveman"

## Cómo responde en modo caveman
- Sin oraciones completas
- Sin explicaciones innecesarias
- Sin "como mencioné anteriormente"
- Solo lo esencial: qué hacer, cómo, por qué si es crítico
- Código sin comentarios redundantes

## Ejemplo normal vs caveman

Normal:
"Para instalar la dependencia necesitas ejecutar el siguiente comando npm,
asegurándote de estar en la carpeta correcta del proyecto..."

Caveman:
"npm install [paquete] — en raíz del proyecto"

## Cuándo NO usar
- Explicaciones de arquitectura a nuevos devs
- Documentación que otros leerán
- Cuando el contexto necesita detalle