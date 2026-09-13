# SKILL — Implementation (Agente de Implementación Guiado por Spec)

Esta skill especializa, pero no reemplaza, `CLAUDE.md` → `Política de autonomía
y ambigüedades` (**AUTONOMY_POLICY_VERSION: 1**).

## Cuándo usar esta skill
Cuando la tarea es implementar una feature que ya tiene spec generada.
Leer esta skill COMPLETA antes de tocar cualquier archivo de código.

Triggers:
- "implementa Features/[mod]"
- "empieza con [módulo]"
- "la spec de [feature] está lista, puedes arrancar"
- Existe `Features/[mod].spec.md` con **Estado:** `ready`

Si no existe `[mod].spec.md`, o está `draft`/`needs-clarification`, aplicar la
definición estricta de `NEEDS CLARIFICATION` de `CLAUDE.md`.
Una Spec `ready` puede implementarse y una implementación `in-progress` puede
reanudarse cuando la solicitud actual ordena continuar, reanudar o finalizar.

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
- Inventar reglas de negocio, umbrales, efectos o contratos funcionales no
  especificados. Sí puede resolver detalles técnicos reversibles y crear
  extensiones internas compatibles necesarias para materializar la Spec.
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
- **Estado:** `needs-clarification` → no implementar el comportamiento
  dependiente; continuar únicamente alcance independiente ya autorizado.
- **Estado:** `draft` → no implementar esta Spec; puede continuarse con otras
  Specs independientes.
- **Estado:** `in-progress` → reanudar si la solicitud actual lo autoriza.
  Solo escalar si se verifica una colisión real con otro trabajo concurrente.
- **Dependencias HARD:** deben estar satisfechas.
- **Dependencias SOFT:** no bloquean; implementar el degradado documentado.

Solo una dependencia HARD no aislable puede bloquear. Continuar todo trabajo
independiente y reportar el alcance afectado.

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

Si `[mod].spec.md` indica **Interfaz de usuario: Sí**, leer además
`IA_Skill/SKILL-playwright-e2e.md`, identificar los escenarios y archivos
Playwright exigidos, y agregarlos al plan. No tratar esos checks como opcionales.

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
  4. Verificación: [mod].checks.md y, si hay frontend, Playwright con evidencia al terminar
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
| Python (FastAPI — tooling interno) | `IA_Skill/SKILL-python-fastapi-best-practices.md` |
| Python — PersonalCripto `jmh_trading` | `IA_Skill/SKILL-jmh-trading.md` |
| Migración de BD | `IA_Skill/SKILL-database-migrations.md` |
| Módulo full stack completo | `IA_Skill/SKILL-mvc-feature.md` |
| Seguridad (guard, token, permiso) | `IA_Skill/SKILL-security-[stack].md` relevante |

Leer la skill de la capa que se va a implementar ahora — no todas a la vez.

---

## Paso 5 — Implementar siguiendo la spec

El código debe ser fiel al comportamiento de `[mod].spec.md`. El agente decide
autónomamente los detalles técnicos reversibles usando evidencia, convenciones
y patrones existentes. No agrega reglas de negocio ni amplía el alcance.

### Entidades y base de datos
- Crear exactamente las columnas declaradas en la tabla de entidades
- Aplicar los tipos, defaults y reglas de negocio de cada columna
- No agregar campos de dominio, defaults o reglas de negocio no declarados.
- Metadatos técnicos necesarios para disponibilidad, fuente, freshness,
  versionado o estados seguros pueden agregarse como T2 si son aditivos,
  no destructivos, reversibles y quedan documentados y probados.

### Contratos de API
- Implementar cada endpoint declarado: verbo, ruta, request body, response, códigos de error
- Los mensajes de error en español deben coincidir con los declarados en la spec
- Roles permitidos → implementar exactamente en el guard/middleware

### Reglas de negocio (RN-XX)
Cada regla tiene un número. Implementarlas en el orden en que aparecen.
Si una regla es ambigua o parece incorrecta:
- Investigar las fuentes internas y clasificarla como T1/T2/B1/B2/S1/X1.
- Resolver T1/T2 autónomamente.
- Para B1, implementar soporte configurable y estado seguro sin activarla.
- Aislar B2 cuando sea posible y continuar el resto.
- Escalar únicamente según la definición estricta de `NEEDS CLARIFICATION`.
- Registrar evidencia, decisión y comportamiento provisional en el reporte.

### Gaps en spec (`[NEEDS CLARIFICATION]`)
Si `[mod].spec.md` tiene ítems `[NEEDS CLARIFICATION]` sin resolver:
- No implementar ni activar el comportamiento dependiente de la decisión.
- Aplicar el comportamiento seguro documentado (`disabled`, `UNKNOWN`,
  `PENDING_CONFIGURATION` o equivalente), sin convertirlo en aprobación.
- Continuar todo alcance independiente y registrar la decisión pendiente.
- Un default solo puede usarse si está aprobado explícitamente en una Spec
  `ready` y no debilita seguridad, capital real ni integridad de datos.

### Propiedad del gap

- Determinar qué Spec es propietaria del contrato o comportamiento faltante.
- Si pertenece a otra Spec, registrar deuda técnica con `Spec propietaria`,
  `Detectada desde`, `Retomar en`, evidencia, comportamiento provisional y
  condición de salida. No adjudicarla genéricamente a la Spec consumidora.
- Al retomar una Spec, buscar en `IA_Memoria/deuda-tecnica.md` deudas cuyo campo
  `Retomar en` apunte a esa Spec e incorporarlas al plan y a los checks.
- Si pertenece a la Spec actual, resolver T1/T2 con la mejor opción reversible,
  implementarla y registrar la decisión en `[mod].checks.md`. Actualizar
  `arquitectura.md` o `convenciones.md` solo si la decisión es transversal.
- Una deuda cross-Spec permite continuar lo independiente, pero no declarar
  operativo el comportamiento dependiente mientras su condición de salida no
  esté cumplida.

### Código legado en zona ámbar
Si la implementación toca un archivo existente que no sigue convenciones:
- Agregar el nuevo código siguiendo convenciones del template
- No modificar el código existente más allá de lo necesario
- Si hay conflicto entre la Spec y código legado fuera del cambio autorizado,
  el código real manda y se registra el conflicto. Esto no impide modificaciones
  explícitamente requeridas por una Spec `ready`, siempre que sean acotadas,
  compatibles y verificadas.

---

## Paso 6 — Autoverificación con `[mod].checks.md`

Antes de declarar la implementación terminada, recorrer cada check del archivo.

### Validación UI requerida

Si la spec declara **Interfaz de usuario: Sí**:

El agente debe ejecutar de forma autónoma la validación visual en navegador, sin requerir que el operador lo pida explícitamente en el prompt:

1. **Verificar servicios en background:** Comprobar si `http://localhost:4200` está activo. Si no responde, arrancarlo en segundo plano (daemon/background) según `IA_Skill/SKILL-playwright-e2e.md`, nunca con un comando síncrono bloqueante que congele la terminal del agente.
2. **Ejecutar Playwright en modo visual:** En desarrollo local, ejecutar las pruebas Playwright que exige la spec en modo encabezado/visible (`--headed --project=chromium`), permitiendo observar la navegación física en pantalla.
3. **Registrar evidencia:** Anotar en "Evidencia de validación UI" de `[mod].checks.md` el comando, base URL, navegador, escenarios y resultado real.
4. Corregir fallas de código nuevo y repetir la prueba. No sustituir la ejecución por una revisión de código, una llamada API aislada o un build.

Si Playwright no está disponible, reportar el bloqueo; no marcar `in-review`
sin la excepción explícita del dev escrita en `[mod].checks.md`.

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
Validación UI requerida: [sí/no — razón]
Evidencia Playwright: [PASS + comando/archivo | no aplica | excepción autorizada]
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

[Si hubo ambigüedades o comportamiento provisional:]
⚠ Supuestos y decisiones pendientes:
  - [ID]: [T1/T2/B1/B2/S1/X1]
    Evidencia: [fuentes revisadas]
    Decisión aplicada: [decisión]
    Comportamiento provisional: [disabled/UNKNOWN/etc.]
    Condición de activación: [evidencia o aprobación necesaria]

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
| Spec en estado `draft` o `needs-clarification` | No implementar el comportamiento dependiente. Reportar la decisión exacta y continuar únicamente unidades independientes ya autorizadas. |
| Dependencia HARD no resuelta y no aislable | PARAR solo el alcance dependiente; continuar el resto. |
| Dependencia SOFT no disponible | Implementar contrato degradado y pruebas; no bloquear. |
| T1/T2 | Investigar, decidir, implementar y documentar sin preguntar. |
| B1 | Implementar soporte configurable; regla deshabilitada y estado explícito. |
| B2/S1/X1 no aislable | Escalar usando el formato de `CLAUDE.md`; continuar lo independiente. |
| Gap propiedad de otra Spec | Registrar deuda con Spec propietaria y `Retomar en`; continuar lo independiente. |
| Gap T1/T2 propiedad de la Spec actual | Resolver, implementar, probar y documentar; no diferir ni preguntar. |
| Código legado fuera del cambio autorizado contradice la Spec | El código real manda en ese alcance; registrar sin detener lo independiente. |
| Código existente carece del comportamiento nuevo autorizado por una Spec `ready` | Implementar el cambio acotado; la ausencia actual no veta la Spec. |
| Stack no listado en Skills de implementación | PARAR antes de codificar. "El stack [X] no tiene skill en este proyecto. Confirmar antes de proceder." |

---

## Reglas absolutas

1. **Nunca implementar sin `[mod].spec.md` en estado `ready`.**
   Una spec incompleta produce código incompleto — y el código es más difícil de deshacer que una spec.

2. **`[mod].md` es la fuente de verdad del estado.** Actualizar siempre primero.
   `progreso.md` es un espejo — nunca puede estar adelante de `[mod].md`.

3. **No inventar reglas de negocio.** La ausencia de una decisión funcional no
   impide tomar decisiones técnicas reversibles ni implementar soporte seguro
   deshabilitado.

4. **No introducir cambios funcionales silenciosos.** Las extensiones aditivas
   y compatibles requeridas por una Spec `ready` se permiten con pruebas de
   contrato en productor y consumidor. Los cambios breaking o de negocio se
   escalan.

5. **Los checks de `[mod].checks.md` son obligatorios para código nuevo.**
   No hay "lo verifico después" — la verificación ocurre en el Paso 6, antes de declarar in-review.

   Si la spec tiene frontend, esto incluye la evidencia Playwright requerida;
   compilar o pasar tests unitarios no la reemplaza.

6. **No marcar `done`.** Ese estado lo asigna el dev después de revisar.
   El techo del agente de implementación es `in-review`.
