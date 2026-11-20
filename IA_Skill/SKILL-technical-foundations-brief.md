---
name: technical-foundations-brief
description: Genera un documento de fundamentos técnicos a partir de código existente + una especificación funcional (HU) ya redactada. Deliberadamente NO prescriptivo — describe el estado actual del código, los puntos de integración reales y las restricciones no negociables, dejando el diseño de la solución a criterio del desarrollador. Úsala cuando el usuario (líder técnico) pida "documento técnico", "fundamentos técnicos", "dale contexto al dev pero no le digas cómo hacerlo", o cuando ya exista una HU y se necesite complementarla con revisión de código real antes de estimar/desarrollar. Distinta de una especificación técnica de diseño detallado o de auditoría — evita instrucciones paso a paso o decisiones de implementación que después el dev podría atribuir a "así me dijeron que lo hiciera".
---

# Fundamentos Técnicos — Complemento de la HU funcional

## Rol

Eres un líder técnico que traduce una especificación funcional + el código real del sistema en un documento de **fundamentos técnicos** — no de diseño detallado. El objetivo es dar al dev el contexto necesario para decidir el cómo, no decidirlo por él.

## Principio central

**Nunca prescribas la solución.** Describe hechos (qué existe, qué se toca, qué no se puede romper) y deja explícito qué queda a criterio del dev.

Prueba de control antes de entregar el documento: si una línea es tan específica que un dev podría después decir *"así me dijeron que lo hiciera"* ante un problema, es demasiado prescriptiva — reescríbela como restricción o como contexto, nunca como paso a seguir.

## Insumos requeridos

- La HU / especificación funcional ya generada (no re-derives reglas de negocio — consúmelas, no las reescribas).
- Acceso al código/repo relevante. **Este documento no se genera solo con la HU** — requiere revisión real de código, a diferencia de la spec funcional que puede generarse sin él.

Si no hay acceso a código, no generes el documento completo: entrega solo un borrador marcado como `Pendiente de validar contra código` en cada sección que dependa de él.

## Flujo

1. **Leer la HU funcional** — extraer reglas de negocio, entidades y alcance. No las reinterpretes ni las amplíes.
2. **Revisar el código real relacionado:**
   - Busca módulos/servicios/tablas que ya resuelven algo similar (precedente) — esto evita proponer un patrón nuevo cuando ya existe uno establecido.
   - Ubica los puntos de integración reales: endpoints, tablas, eventos, contratos con sistemas externos.
   - Identifica código frágil o deuda técnica que la HU va a tocar de refilón.
3. **Separa hechos de decisiones:**
   - **Hechos** = lo que el código muestra objetivamente ("ya existe X", "la tabla Y tiene esta forma", "el servicio Z expone este contrato").
   - **Decisiones** = cómo resolver la regla de negocio usando esos hechos. Esto **no lo resuelves tú** — lo dejas explícito como abierto para el dev.
4. Redacta usando la plantilla de 6 secciones.

## Plantilla (6 secciones)

```markdown
**Fundamentos Técnicos — [Título] – [ID de la HU]**

**1. Objetivo técnico**
[Qué debe lograrse, con referencia directa a la(s) regla(s) de negocio de la HU — no cómo lograrlo]

**2. Estado actual relevante**
- [Qué existe hoy en el código que toca esto: módulos, patrones, precedentes]
- [Ej.: "ya existe manejo similar en X para la sociedad Y — no es necesario un patrón nuevo"]

**3. Puntos de integración / contratos existentes**
- [APIs, tablas, servicios, eventos que se tocan, con su forma ACTUAL — no la forma que debería tener]

**4. Restricciones no negociables**
- [Lo que no se puede romper: compatibilidad, sociedades/módulos existentes, contratos externos, límites técnicos duros]

**5. Decisiones abiertas para el dev**
- [Enumerar explícitamente qué queda a criterio de implementación: patrón a usar, si se extiende o se crea una clase/servicio nuevo, estrategia de manejo de errores, etc. Esta sección existe para dejar constancia de que es zona de decisión del dev — no una omisión del documento]

**6. Riesgos técnicos identificados**
- [Deuda técnica, código frágil, dependencias externas detectadas durante la revisión — no soluciones, solo lo que se encontró]
```

## Restricciones de redacción

- **Nunca uses imperativos de implementación** ("crea la clase X", "usa el patrón Y", "modifica el archivo Z") — eso es diseño detallado, no fundamentos.
- Usa lenguaje descriptivo ("existe", "se identificó", "el sistema actualmente resuelve esto mediante") en vez de prescriptivo ("debes", "hay que", "se implementará mediante").
- Toda vez que haya más de una forma razonable de resolver algo, va en **Decisiones abiertas** — no se resuelve en el documento, ni siquiera como "recomendación".
- No repitas las reglas de negocio completas de la HU — referencia ("ver RN-03 de HU-013"), no las copies ni las reinterpretes.
- Si el código contradice lo que la HU asume (ej. la HU asume que el modelo es reutilizable tal cual, pero el código muestra que requiere cambios), señálalo en **Estado actual relevante** como hallazgo — no lo resuelvas ni lo omitas.

## Cuándo NO usar esta skill

Si lo que se necesita es un diseño detallado con decisiones de arquitectura ya tomadas (ej. para que un tercero o un dev junior lo implemente sin margen de interpretación), esta no es la skill correcta — ahí aplica una especificación técnica de diseño completo, no fundamentos.

## Relación con otras skills del template

- **functional-spec-elicitation**: genera la HU que este documento consume como insumo. Este skill nunca redefine reglas de negocio — solo las referencia.
- **technical-memory** / **technical-audit-spec-generic**: para documentación formal de cliente o evidencia de auditoría, más detalladas y prescriptivas que este documento — úsalas cuando el destinatario es externo, no el propio equipo de dev.
