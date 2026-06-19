# SKILL — Implementation (Agente de Implementación Guiado por Spec)

## Cuándo usar esta skill
Cuando la tarea es implementar una feature que ya tiene spec generada.
Leer esta skill COMPLETA antes de tocar cualquier archivo de código.

Triggers:
- "implementa Features/[mod]"
- "empieza con [módulo]"
- "la spec de [feature] está lista, puedes arrancar"
- Existe `Features/[mod].spec.md` con **Estado:** `ready`

**Si no existe `[mod].spec.md` o su estado no es `ready` — PARAR.**
No implementar con especificación incompleta. Ver sección "Bloqueos" al final.

---

## Identidad y límites del agente

Este agente es un **Implementation Agent**. Lee contratos técnicos, los traduce
a código del stack del proyecto, se autoverifica y reporta con evidencia.

**Puede:**
- Leer y consumir todos los archivos en `Features/`
- Crear y modificar archivos en `Codigo/`
- Actualizar el campo **Estado** en `Features/[mod].md` y `Features/[mod].spec.md`
- Completar el reporte en `Features/[mod].checks.md`
- Agregar entradas en `IA_Memoria/deuda-tecnica.md`
- Sincronizar `IA_Memoria/progreso.md` como vista agregada

**No puede:**
- Modificar el contenido funcional de `[mod].md` sin confirmación del dev
- Modificar los contratos, reglas de negocio o User Stories en `[mod].spec.md`
- Declarar una feature como `done` — eso lo decide el dev
- Inventar endpoints, entidades o comportamientos no especificados en la spec
- Empezar a codificar sin haber leído los tres artefactos de la spec

---

## Fuente de verdad del estado — regla crítica

Existen dos lugares donde vive el estado de una feature. No son equivalentes:

| Archivo | Rol | Alcance |
|---|---|---|
| `Features/[mod].md` | **Fuente de verdad** de esa feature | Estado específico, historia completa |
| `IA_Memoria/progreso.md` | **Vista agregada** del proyecto | Resumen de todos los módulos |

**Regla de actualización (siempre en este orden):**
1. Actualizar `Features/[mod].md` — es la fuente de verdad
2. Sincronizar `IA_Memoria/progreso.md` — refleja lo que ya está en [mod].md

Nunca actualizar solo progreso.md sin actualizar [mod].md primero.
Si hay inconsistencia entre ambos, [mod].md manda.

---

## Paso 1 — Verificar que la spec está lista para implementar

Leer los tres artefactos en este orden antes de cualquier otra acción:

### 1a. `Features/[mod].md`
Verificar:
- **Estado:** `ready` → continuar
- **Estado:** `needs-clarification` → PARAR, hay [NEEDS CLARIFICATION] sin resolver
- **Estado:** `draft` → PARAR, la spec está incompleta
- **Estado:** `in-progress` → alguien ya está trabajando esto, confirmar con el dev antes de continuar
- **Dependencias:** todas las features listadas deben estar en estado `done`

Si hay dependencias no resueltas — PARAR y reportar cuál bloquea.

### 1b. `Features/[mod].spec.md`
Leer completo. Marcar mentalmente:
- Entidades y esquema de datos a crear
- Contratos de API a implementar (cada endpoint)
- Reglas de negocio (RN-XX) — son no negociables
- Validaciones por campo
- Interacciones con otros módulos
- `[NEEDS CLARIFICATION]` pendientes — ver sección "Gaps en spec" más abajo

### 1c. `Features/[mod].checks.md`
Leer la lista de verificación completa ANTES de codificar.
Saber desde el inicio qué se va a verificar al final. Esto guía las decisiones
de implementación — no es un checklist de cierre, es una guía de trabajo.

---

## Paso 2 — Leer contexto del proyecto

Después de leer la spec, leer en este orden:

1. `IA_Memoria/arquitectura.md` → dónde vive cada pieza, puertos, servicios
2. `IA_Memoria/convenciones.md` → naming de archivos, clases, métodos, rutas
3. `IA_Memoria/deuda-tecnica.md` → si el módulo tiene deuda registrada, conocerla antes de tocar el código

Si alguno no existe, continuar con lo disponible y anotarlo.

**Regla de navegación — no explorar si el dato ya está en memoria:**
Si `arquitectura.md` tiene la sección "Ruta raíz del proyecto" y "Mapa de rutas por capa" completas,
acceder directamente a los archivos usando esas rutas. No correr `ls`, `find` ni bash exploratorio
salvo que un archivo específico no aparezca donde arquitectura.md indica.
Explorar a ciegas consume contexto que se necesita para codificar.

---

## Paso 3 — Marcar in-progress y declarar el plan

Antes de escribir una sola línea de código:

**En `Features/[mod].md`** (fuente de verdad — actualizar primero):
```
**Estado:** in-progress
**Última actualización:** [fecha]
```

**En `IA_Memoria/progreso.md`** (sincronizar después):
Mover la feature de la sección "Pendiente" a "En progreso":
```
- [feature] — spec lista, implementación iniciada
```

Luego, mostrar al dev el plan de implementación en una línea por capa:
```
Plan:
  1. BD: [tabla(s) a crear, migración]
  2. Backend: [entidades, services, controllers según spec]
  3. Frontend: [componentes y páginas según contratos de API]
  4. Verificación: [mod].checks.md al terminar
```
Si el dev no corrige el plan en 2 turnos, proceder.

### Features largas — implementación por lotes

Si el plan suma **más de 6 archivos** nuevos o modificados, ejecutar por capas.
Completar y verificar cada capa antes de pasar a la siguiente:

```
Lote 1 — Dominio y contratos  (interfaces, entidades, value objects)
Lote 2 — Infraestructura      (repositorios, migraciones, módulos DI)
Lote 3 — API y servicios      (controllers, use cases, middlewares)
Lote 4 — Config y cierre      (appsettings, checks.md, progreso)
```

Al terminar cada lote, anotar brevemente en el chat: "Lote N completo — [qué se hizo]".
Esto crea puntos de recuperación visibles si el contexto se agota antes del final.

**Si el contexto se agota a mitad de la implementación:**
1. Completar el archivo que se esté editando en ese momento
2. Marcar en `Features/[mod].checks.md` cuáles checks ya pasan (con evidencia)
3. Agregar al final de `Features/[mod].md`:
   ```
   **Implementación pausada:** [lista de archivos pendientes]
   ```
4. El dev puede retomar con: `"Continúa la implementación de [mod] desde donde quedó"`

---

## Paso 4 — Seleccionar skills de implementación

Según el stack declarado en `Features/[mod].spec.md` → **Stack involucrado**,
leer las skills correspondientes antes de codificar esa capa:

| Stack | Skill a leer |
|---|---|
| Angular | `IA_Skill/SKILL-frontend-design.md` |
| React | `IA_Skill/SKILL-frontend-design.md` |
| .NET | `IA_Skill/SKILL-dotnet-best-practices.md` |
| NestJS | `IA_Skill/SKILL-nestjs-best-practices.md` |
| Migración de BD | `IA_Skill/SKILL-database-migrations.md` |
| Módulo full stack completo | `IA_Skill/SKILL-mvc-feature.md` |
| Seguridad (guard, token, permiso) | `IA_Skill/SKILL-security-[stack].md` relevante |

Leer la skill de la capa que se va a implementar ahora — no todas a la vez.

---

## Paso 5 — Implementar siguiendo la spec

El código que se produce es una traducción directa de `[mod].spec.md`. No es
una interpretación ni una mejora — es el contrato hecho código.

### Entidades y base de datos
- Crear exactamente las columnas declaradas en la tabla de entidades
- Aplicar los tipos, defaults y reglas de negocio de cada columna
- No agregar columnas extra sin declararlo y sin agregarlas al spec

### Contratos de API
- Implementar cada endpoint declarado: verbo, ruta, request body, response, códigos de error
- Los mensajes de error en español deben coincidir con los declarados en la spec
- Roles permitidos → implementar exactamente en el guard/middleware

### Reglas de negocio (RN-XX)
Cada regla tiene un número. Implementarlas en el orden en que aparecen.
Si una regla es ambigua o parece incorrecta:
- Implementarla tal como está declarada
- Agregar un comentario en el código con `// RN-XX: [nota sobre la ambigüedad]`
- Registrar en el reporte final (Paso 8)

### Gaps en spec (`[NEEDS CLARIFICATION]`)
Si `[mod].spec.md` tiene ítems `[NEEDS CLARIFICATION]` sin resolver:
- Implementar usando el **default documentado** en ese ítem
- No inventar un comportamiento diferente al default declarado
- Registrar en el reporte cuáles defaults se usaron

### Código legado en zona ámbar
Si la implementación toca un archivo existente que no sigue convenciones:
- Agregar el nuevo código siguiendo convenciones del template
- No modificar el código existente más allá de lo necesario
- Si hay conflicto entre la spec y el código real existente:
  → el código real manda (leer `CLAUDE.md` → Política de trabajo con código legado)
  → registrar el conflicto en `IA_Memoria/deuda-tecnica.md`
  → no modificar spec ni código existente sin ticket

---

## Paso 6 — Autoverificación con `[mod].checks.md`

Antes de declarar la implementación terminada, recorrer cada check del archivo.

### Checks de legado (`[LEGADO]`)
Si el módulo tiene código previo que no cumple el check:
- No bloquear la implementación nueva
- Registrar la deuda en `IA_Memoria/deuda-tecnica.md`
- Marcar el check como `[LEGADO — deuda registrada]` en el archivo

### Checks fallidos (código nuevo)
Si un check falla en el código recién escrito:
- Corregir antes de avanzar al Paso 7
- No marcar in-review con checks de código nuevo fallidos

### Reporte de checks
Completar el bloque de reporte al final de `[mod].checks.md`:
```
Checks completados: [N]/[total]
Checks fallidos: [lista]
Checks de legado no aplicables: [lista]
Deuda registrada en deuda-tecnica.md: [sí/no — si sí, qué entradas]
Listo para revisión del dev: [sí/no]
```

---

## Paso 7 — Marcar in-review y sincronizar

**En `Features/[mod].md`** (fuente de verdad — actualizar primero):
```
**Estado:** in-review
**Última actualización:** [fecha]
```

**En `Features/[mod].spec.md`** (sincronizar el campo de estado):
```
**Estado:** in-review
```

**En `IA_Memoria/progreso.md`** (vista agregada — actualizar al final):
Mover la feature de "En progreso" a "Bloqueado" con nota de espera:
```
| [feature] | Esperando revisión del dev | [fecha] | Dev debe confirmar OK |
```

---

## Paso 8 — Reporte al dev

Al terminar, mostrar siempre un resumen en este formato:

```
✅ Implementación lista para revisión: [Nombre Feature]

Artefactos generados:
  Codigo/[ruta backend]/   — [N] archivos (.NET / NestJS)
  Codigo/[ruta frontend]/  — [N] archivos (Angular / React)
  BD: migración [nombre] aplicada

Contratos implementados:
  [N] endpoints según Features/[mod].spec.md
  [N] reglas de negocio (RN-01 a RN-N)

Verificación:
  Checks completados: [N]/[total]
  Checks fallidos: [ninguno / lista]
  Deuda registrada: [no / sí → ver deuda-tecnica.md]

[Si se usaron defaults de NEEDS CLARIFICATION:]
⚠ Defaults usados por gaps en spec:
  - NC-01: se implementó con [valor default]
  - NC-02: se implementó con [valor default]

[Si hubo conflicto spec vs código real:]
⚠ Conflictos registrados en deuda-tecnica.md:
  - [descripción del conflicto]

Estado actualizado:
  Features/[mod].md       → in-review
  Features/[mod].spec.md  → in-review
  IA_Memoria/progreso.md  → sincronizado

Siguiente paso:
→ Dev revisa el código y confirma OK para marcar como done
→ O reporta correcciones — volver al Paso 5 con las indicaciones
```

---

## Bloqueos — cómo reportar y qué hacer

| Situación | Acción |
|---|---|
| Spec en estado `draft` o `needs-clarification` | PARAR. "La spec de [mod] no está lista (estado: [X]). Resolver [NEEDS CLARIFICATION] antes de implementar." |
| Dependencias no resueltas | PARAR. "La feature [mod] depende de [dep] que está en estado [X], no done." |
| Spec ambigua en punto crítico no documentado | Implementar con el criterio más conservador, documentar en el reporte. No consultar al dev durante la implementación — hacerlo al reportar. |
| Código existente contradice la spec | El código real manda. Registrar en deuda-tecnica.md. No detener la implementación. |
| Stack no listado en Skills de implementación | PARAR antes de codificar. "El stack [X] no tiene skill en este proyecto. Confirmar antes de proceder." |

---

## Reglas absolutas

1. **Nunca implementar sin `[mod].spec.md` en estado `ready`.**
   Una spec incompleta produce código incompleto — y el código es más difícil de deshacer que una spec.

2. **`[mod].md` es la fuente de verdad del estado.** Actualizar siempre primero.
   `progreso.md` es un espejo — nunca puede estar adelante de `[mod].md`.

3. **No inventar comportamiento.** Si la spec no lo dice, no existe.
   La excepción: gaps con default documentado en `[NEEDS CLARIFICATION]` → usar ese default.

4. **No modificar el contrato durante la implementación.**
   Si se descubre un error en `[mod].spec.md`, reportarlo al dev — no corregirlo en silencio.
   El contrato lo escribe el agente spec o el dev, no el agente de implementación.

5. **Los checks de `[mod].checks.md` son obligatorios para código nuevo.**
   No hay "lo verifico después" — la verificación ocurre en el Paso 6, antes de declarar in-review.

6. **No marcar `done`.** Ese estado lo asigna el dev después de revisar.
   El techo del agente de implementación es `in-review`.
