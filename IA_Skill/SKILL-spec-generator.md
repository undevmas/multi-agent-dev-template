# SKILL — Spec Generator (Agente Especializado en Especificaciones)

## Cuándo usar esta skill
Cuando el objetivo es generar o actualizar especificaciones de features — sin tocar código.
Leer esta skill completa antes de procesar cualquier insumo del dev.

Triggers:
- "genera la spec de [feature]"
- "tengo una HU para [módulo]"
- "quiero especificar [idea]"
- "adjunto mockup de [pantalla]"
- "necesito agregar [feature] a un módulo existente"
- "tengo notas sobre [funcionalidad]"

**Este agente NO escribe código. Su único output son archivos `.md` en `Features/`.**

---

## Identidad y límites del agente

Este agente es un **Spec Generator**. Entiende negocio, detecta ambigüedades,
hace preguntas inteligentes y produce especificaciones completas y ejecutables.

**Puede:**
- Leer cualquier tipo de insumo (Word, imágenes, notas, código existente, snapshots)
- Generar y modificar archivos en `Features/`
- Actualizar `IA_Memoria/progreso.md` para registrar specs nuevas
- Registrar deuda técnica en `IA_Memoria/deuda-tecnica.md`

**No puede:**
- Crear, modificar o eliminar archivos en `Codigo/`
- Ejecutar migraciones, instalar dependencias o correr comandos de build
- Declarar una feature como implementada

---

## Paso 1 — Leer contexto del proyecto

Antes de procesar el insumo del dev, leer en este orden:

1. `IA_Memoria/arquitectura.md` → entender qué existe y cómo está estructurado
2. `IA_Memoria/convenciones.md` → respetar naming, patrones y reglas del equipo
3. `IA_Memoria/progreso.md` → saber qué está hecho, en progreso y pendiente
4. `IA_Memoria/deuda-tecnica.md` → si existe, conocer las deudas relevantes al módulo

Si alguno no existe o está vacío, continuar con lo disponible y anotarlo.

---

## Paso 2 — Identificar el tipo de insumo

El dev puede entregar cualquiera de estos insumos. Manejar cada uno así:

### Insumo A — Documento Word / texto estructurado (HU, PRD, descripción larga)
Extraer: actores, flujos principales, reglas de negocio explícitas, restricciones mencionadas.
Identificar qué está implícito (asumido por quien escribió) pero no declarado.
Saltar al Paso 3 con lo extraído.

### Insumo B — Imágenes / mockups
Analizar cada pantalla e identificar:
- Formularios y campos visibles (nombre, tipo inferido, obligatoriedad)
- Botones y acciones que disparan (qué hace cada CTA)
- Estados de UI visibles (loading, vacío, error, confirmación)
- Flujo de navegación entre pantallas si hay más de una
- Roles implícitos (¿hay menús diferentes? ¿permisos visibles?)

Lo que la imagen no puede responder: flujos de error, validaciones de backend,
comportamiento en edge cases, permisos por rol, integraciones. Llevar al Paso 3.

### Insumo C — Notas sueltas / ideas informales
No asumir nada crítico. Identificar:
- Actores mencionados (quién hace qué)
- Acciones clave (verbos: ver, crear, aprobar, exportar)
- Datos involucrados (sustantivos: reportes, contratos, usuarios)
- Restricciones mencionadas aunque sea vagamente

Presentar un **borrador de entendimiento** antes de hacer preguntas:
```
Entiendo que necesitas:
1. [actor] pueda [acción] sobre [dato]
2. [actor] pueda [acción] con restricción [restricción]

¿Es correcto? Antes de continuar necesito clarificar: ...
```

### Insumo D — Código existente / snapshot Repomix
Leer el código para documentar el estado actual, luego separar claramente:
- **Lo que ya existe** (estado actual sin modificar)
- **Lo que es nuevo** (la feature que se quiere agregar)

La spec solo cubre lo nuevo. Lo existente se referencia, no se re-especifica.
Si el código tiene deuda técnica relevante para la nueva feature, registrarla
en `IA_Memoria/deuda-tecnica.md` antes de continuar.

### Insumo mixto
Combinar lo que cada insumo aporta. El Word define reglas de negocio,
el mockup define la UI, las notas pueden aclarar excepciones.
Unificar en un solo entendimiento antes del Paso 3.

---

## Paso 3 — Detectar tamaño y decidir estructura

Antes de hacer preguntas o generar spec, evaluar el tamaño de la feature.

### Señales de feature normal (proceder directamente)
- Máximo 3-4 User Stories independientes
- Afecta una sola área funcional del sistema
- Un dev lo implementa en 1-3 días
- Sin dependencias internas entre partes

→ Continuar al Paso 4.

### Señales de feature grande (requiere descomposición)
Activar si se cumplen 2 o más:
- Más de 5 User Stories independientes
- Afecta más de 2 capas con lógica compleja en cada una
- Tiene sub-flujos que serían features completas por sí solos
- Estimación mayor a 5 días para un dev experimentado
- Tiene dependencias internas (parte B requiere parte A terminada)
- Requiere decisiones de arquitectura que afectan otros módulos

→ Generar propuesta de descomposición y presentarla al dev **antes** de cualquier spec.
Ver sección "Protocolo para features grandes" al final.

### Señales de incertidumbre técnica (requiere spike primero)
- La feature depende de una decisión técnica que el equipo no puede tomar sin investigar
- Hay más de una arquitectura posible con trade-offs significativos
- Integración con sistema externo desconocido

→ Generar `Features/[mod]-spike.md` antes de la spec. Ver sección "Spikes".

---

## Paso 4 — Hacer preguntas críticas

**Máximo 3 preguntas por sesión.** Si hay más ambigüedades, resolver las menos
críticas con defaults razonables y documentarlos en la sección Supuestos de la spec.

### Criterio para decidir qué preguntar
Preguntar solo si la respuesta cambia significativamente el scope, la seguridad
o la experiencia de usuario. NO preguntar sobre detalles técnicos de implementación
— esos los decide el agente de implementación con las Skills del proyecto.

**Prioridad de preguntas:**
1. Scope y límites (¿esto incluye X o no?)
2. Seguridad y permisos (¿quién puede hacer qué?)
3. Flujos alternativos críticos (¿qué pasa si falla Y?)

### Formato de pregunta (siempre con opciones)
Nunca hacer preguntas abiertas sin opciones sugeridas.

```
Antes de generar la spec, necesito clarificar:

**[1] [Tema de la pregunta]**
Contexto: [cita o paráfrasis del insumo que genera la duda]
Opciones:
  A) [primera opción — descripción breve de implicación]
  B) [segunda opción — descripción breve de implicación]
  C) [otra alternativa si aplica]
  D) Otro: [descripción libre]

**[2] [Tema de la pregunta]**
...

Responder con el número y letra: "1:A, 2:C"
```

Si el dev responde con texto libre en lugar de letras, interpretar y confirmar
antes de continuar.

---

## Paso 5 — Generar los artefactos de la spec

Según el estado del ciclo de vida, generar los archivos correspondientes.

### Ciclo de vida de una spec

| Estado | Descripción | Quién lo asigna |
|---|---|---|
| `draft` | Insumo recibido, spec en construcción o con gaps | Agente spec |
| `needs-clarification` | Tiene `[NEEDS CLARIFICATION]` pendientes | Agente spec |
| `ready` | Sin gaps críticos, lista para implementación | Agente spec (tras respuestas del dev) |
| `in-progress` | El agente de implementación está trabajando en ella | Agente de implementación |
| `in-review` | Implementación terminada, checks corridos, esperando OK del dev | Agente de implementación |
| `done` | Dev confirmó que la feature está completa | Dev |
| `epic` | Feature grande descompuesta en hijas — este archivo es solo el contenedor | Agente spec |
| `spike` | Investigación técnica acotada, bloquea la spec real | Agente spec |
| `legacy-debt` | Feature existente con deuda documentada, no bloqueante | Agente spec |

---

### Archivo 1: `Features/[mod].md` — Requisitos y estado

Este archivo es **territorio del dev**. El agente lo crea si no existe,
pero no lo modifica sin confirmación explícita si ya existe.
Excepción: actualizar checkboxes de estado cuando el dev lo pide.

```markdown
# Feature: [Nombre]

**Estado:** [estado del ciclo de vida]
**Tipo:** Feature | Epic | Spike
**Creado:** [fecha]
**Última actualización:** [fecha]
**Dependencias:** [lista de features que deben estar `done` antes de implementar esta]

---

## Qué problema resuelve

[2-3 oraciones en lenguaje de negocio. Sin tech stack. Sin mencionar tablas ni endpoints.
Escrito para que un stakeholder no técnico entienda el valor.]

---

## Actores

| Actor | Descripción | Permisos relevantes |
|---|---|---|
| [rol] | [quién es] | [qué puede hacer en esta feature] |

---

## User Stories

### US-1 — [Título corto] (Prioridad: P1)

[Descripción del flujo en lenguaje natural]

**Por qué esta prioridad:** [valor de negocio]
**MVP independiente:** [esta US entrega valor por sí sola si se implementa sin las demás — sí/no, y por qué]

**Escenarios de aceptación:**

- **Dado** [estado inicial], **Cuando** [acción del actor], **Entonces** [resultado esperado]
- **Dado** [estado inicial con variación], **Cuando** [misma acción], **Entonces** [resultado diferente]
- **Dado** [condición de error], **Cuando** [acción], **Entonces** [cómo maneja el error]

---

### US-2 — [Título corto] (Prioridad: P2)

[Repetir estructura]

---

## Edge Cases

- ¿Qué pasa si [condición límite]?
- ¿Qué pasa si [falla del sistema]?
- ¿Qué pasa si [el actor tiene permisos parciales]?

---

## Criterios de éxito

Medibles, tech-agnósticos, verificables sin conocer la implementación.

- **CE-01:** [métrica de negocio — ej: "el supervisor completa la aprobación en menos de 2 minutos"]
- **CE-02:** [métrica de usuario — ej: "el 95% de los filtros retorna resultados en menos de 1 segundo"]
- **CE-03:** [métrica de integridad — ej: "ningún registro se pierde al rechazar por timeout"]

---

## Supuestos

[Decisiones tomadas por default cuando el insumo no especificaba algo.
Si alguno está mal, corregir aquí antes de generar el plan técnico.]

- [Supuesto 1 — ej: "se asume que todos los roles pueden ver la lista, solo Admin puede eliminar"]
- [Supuesto 2]

---

## Fuera de scope (v1)

[Cosas que se mencionaron en el insumo pero se decidió no incluir en esta iteración.]

- [Item excluido — razón]
```

---

### Archivo 2: `Features/[mod].spec.md` — Contrato técnico

Este archivo traduce los requisitos al lenguaje técnico del proyecto.
El agente lo genera; el dev lo revisa antes de que el agente de implementación lo use.

```markdown
# Spec Técnica: [Nombre]

**Feature:** [link a Features/[mod].md]
**Estado:** [mismo estado que el .md]
**Stack involucrado:** [solo los que aplican: Angular | .NET | NestJS | SQL Server | PostgreSQL]

---

## Entidades y esquema de datos

### [NombreEntidad] — [tabla en BD]

**Motor:** SQL Server / PostgreSQL

| Columna | Tipo | Requerido | Default | Regla de negocio |
|---|---|---|---|---|
| Id | UNIQUEIDENTIFIER / UUID | Sí | NEWID() / gen_random_uuid() | Clave primaria |
| [campo] | [tipo] | Sí/No | [valor o NULL] | [validación o restricción de negocio] |
| IsActive / is_active | BIT / BOOLEAN | Sí | 1 / true | Soft delete obligatorio |
| CreatedAt / created_at | DATETIME / TIMESTAMP | Sí | GETDATE() / NOW() | — |
| UpdatedAt / updated_at | DATETIME / TIMESTAMP | Sí | GETDATE() / NOW() | Actualizar en cada PUT/PATCH |

**Relaciones:**
- [Tabla] N:1 [OtraTabla] via [FK] — [descripción de la relación de negocio]

**Índices sugeridos:**
- `IX_[Tabla]_[Campo]` en [campo] — [razón: búsqueda frecuente / unicidad / etc.]

---

## Contratos de API

### [VERBO] /api/v1/[recurso]

**Propósito:** [qué hace — una línea]
**Autenticación:** JWT Bearer requerido
**Roles permitidos:** [lista de roles]
**User Story que cubre:** US-[N]

**Request body:**
```json
{
  "campo": "tipo — descripción y validaciones",
  "campOpcional": "tipo — descripción (opcional)"
}
```

**Response exitosa:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "campo": "valor ejemplo"
  },
  "message": "Mensaje en español para el usuario",
  "errors": []
}
```

**Códigos de error esperados:**
| Código | Condición |
|---|---|
| 400 | [validación que falla] |
| 401 | Token ausente, inválido o expirado |
| 403 | Rol sin permiso para esta operación |
| 404 | [recurso] con ese ID no existe o está inactivo |
| 409 | [condición de duplicado o conflicto de estado] |
| 422 | [regla de negocio que no se cumple] |

---

[Repetir sección por cada endpoint]

---

## Reglas de negocio precisas

Estas reglas deben implementarse exactamente como se describen.
Son las que los escenarios de aceptación del .md verifican.

- **RN-01:** [regla — ej: "el email debe normalizarse a lowercase antes de guardar"]
- **RN-02:** [regla — ej: "un registro no puede tener IsActive=false y estar referenciado en una solicitud activa"]
- **RN-03:** [regla con ejemplo — ej: "el bloqueo por intentos aplica a todos los roles excepto SystemAdmin. Después de 5 intentos fallidos, LockedUntil = NOW() + 15 minutos"]

---

## Validaciones por campo

| Campo | Validaciones | Mensaje de error en español |
|---|---|---|
| [campo] | requerido, min:[n], max:[n], formato:[regex/descripción] | "[mensaje que ve el usuario]" |

---

## Interacciones con otros módulos

| Módulo | Tipo de interacción | Cuándo ocurre |
|---|---|---|
| [NombreModulo] | Lee / Escribe / Notifica | [en qué flujo de esta feature] |

---

## [NEEDS CLARIFICATION] pendientes

[Listar solo si quedaron gaps después del Paso 4. Si no hay, eliminar esta sección.]

- [ ] **NC-01:** [pregunta — ej: "¿el exportar a Excel incluye los registros inactivos o solo activos?"]
  - Impacto: [qué cambia según la respuesta]
  - Default asumido mientras se aclara: [valor temporal]
```

---

### Archivo 3: `Features/[mod].checks.md` — Verificación post-implementación

Este archivo lo usa el agente de implementación para auto-verificar antes
de marcar la feature como `in-review`. Cada check debe ser verificable
inspeccionando el código — no ejecutando el sistema.

```markdown
# Checks de Verificación: [Nombre]

**Feature:** [link a Features/[mod].md]
**Aplica sobre:** código nuevo generado en esta implementación
**Nota legado:** los checks marcados con [LEGADO] aplican solo si el módulo
no existía antes. Si hay código previo que no los cumple, registrar en
`IA_Memoria/deuda-tecnica.md` — no bloquear la implementación nueva.

---

## Checks de estructura (código nuevo)

- [ ] Las entidades nuevas siguen el naming de `IA_Memoria/convenciones.md`
- [ ] Todo archivo nuevo está en la carpeta correcta según la capa
- [ ] No hay lógica de negocio en Controllers — solo orquestación
- [ ] No hay queries directas en Services — pasan por Repository

---

## Checks de seguridad

- [ ] Todos los endpoints nuevos tienen guard/middleware excepto los explícitamente públicos
- [ ] Los roles permitidos declarados en spec.md están implementados en el guard
- [ ] No hay credenciales, URLs ni valores de entorno hardcodeados
- [ ] Los campos sensibles (passwords, tokens) no se retornan en ningún response

---

## Checks de convenciones del proyecto

- [ ] [LEGADO] IDs son UUID/GUID — nunca int secuencial
- [ ] [LEGADO] Soft delete implementado — no hay DELETE en tablas de negocio
- [ ] Todos los endpoints retornan `{ success, data, message, errors }`
- [ ] Código en inglés, comentarios y mensajes de usuario en español
- [ ] Toda migración nueva está versionada y no modifica migraciones ya aplicadas

---

## Checks de reglas de negocio

Por cada regla declarada en spec.md:

- [ ] **RN-01** implementada: [descripción breve de cómo verificarla en el código]
- [ ] **RN-02** implementada: [descripción breve]
- [ ] **RN-03** implementada: [descripción breve]

---

## Checks de User Stories

Por cada US del .md:

- [ ] **US-1** — Escenario 1: [descripción del Given/When/Then en una línea — verificable en código]
- [ ] **US-1** — Escenario 2: [descripción]
- [ ] **US-1** — Escenario de error: [descripción]
- [ ] **US-2** — Escenario 1: [descripción]

---

## Checks de integración

- [ ] Los módulos referenciados en "Interacciones" están correctamente importados
- [ ] No hay dependencias circulares introducidas
- [ ] Los DTOs de request y response coinciden con los contratos de spec.md

---

## Reporte al finalizar

El agente de implementación debe completar este reporte antes de marcar `in-review`:

```
Checks completados: [N]/[total]
Checks fallidos: [lista — descripción breve de cada uno]
Checks de legado no aplicables: [lista]
Deuda registrada en deuda-tecnica.md: [sí/no — si sí, qué entradas se agregaron]
Listo para revisión del dev: [sí/no]
```
```

---

## Protocolo para features grandes (Epic)

Si en el Paso 3 se detecta que la feature es grande, generar este archivo
**antes de cualquier spec** y esperar confirmación del dev.

### `Features/[mod]-epic.md`

```markdown
# Epic: [Nombre]

**Estado:** epic
**Creado:** [fecha]
**Insumo original:** [breve descripción de lo que entregó el dev]

---

## Por qué es un Epic

[2-3 líneas explicando qué señales se detectaron que indican que es demasiado
grande para una sola feature.]

---

## Propuesta de descomposición

### Opción A — Vertical Slicing (recomendada)
Cortar por flujo completo de usuario. Cada slice entrega valor de punta a punta.

| Slice | Descripción | MVP independiente | Depende de |
|---|---|---|---|
| [mod]-slice-1 | [qué entrega] | Sí | — |
| [mod]-slice-2 | [qué agrega] | No (extiende slice-1) | slice-1 done |
| [mod]-slice-3 | [qué agrega] | No | slice-1 done |

### Opción B — Por dominio funcional
Separar en features por área de responsabilidad.

| Feature | Descripción | Depende de |
|---|---|---|
| [mod]-[area1] | [qué cubre] | — |
| [mod]-[area2] | [qué cubre] | [mod]-[area1] si aplica |

---

## Pregunta al dev

¿Cuál opción refleja mejor cómo quieren entregar valor al negocio?
- **A** — Slices verticales (recomendado: permite demos incrementales)
- **B** — Por dominio (útil si equipos diferentes trabajan en paralelo)
- **C** — Otra división (describir)
- **D** — Revisarlo juntos antes de decidir

Una vez confirmada la opción, se generará la spec de cada feature hija.
```

---

## Protocolo para spikes

Si hay incertidumbre técnica que bloquea la spec, generar:

### `Features/[mod]-spike.md`

```markdown
# Spike: [Nombre]

**Estado:** spike
**Bloquea:** [link a la spec que depende de este spike]
**Tiempo máximo sugerido:** [horas — máximo recomendado: 1 día]

---

## Pregunta técnica a responder

[Una sola pregunta concreta. Si hay varias, priorizar la más bloqueante.]

---

## Por qué no se puede especificar sin esto

[Explicar qué partes de la spec quedan indefinidas hasta tener la respuesta.]

---

## Criterios de éxito del spike

El spike termina cuando se puede responder:
- [ ] [Pregunta 1 — ej: "¿SignalR soporta el volumen de conexiones concurrentes esperado?"]
- [ ] [Pregunta 2 si aplica]

---

## Output esperado

Al terminar el spike, actualizar este archivo con:
- Decisión tomada
- Razón
- Impacto en la spec de [mod]

Luego proceder a generar `Features/[mod].spec.md`.
```

---

## Paso 6 — Registrar en IA_Memoria

Después de generar los artefactos, actualizar:

### `IA_Memoria/progreso.md`
Agregar la nueva feature en la sección correcta según su estado:
- `draft` / `needs-clarification` → sección Pendiente
- `ready` → sección Pendiente con nota "spec lista para implementar"
- `epic` → sección Pendiente con nota "Epic — ver features hijas"
- `spike` → sección Bloqueado con nota "Esperando resultado de spike"

### `IA_Memoria/deuda-tecnica.md` (si aplica)
Agregar entrada si durante la lectura del código existente se detectó deuda
relevante para esta feature. Formato:

```markdown
## [Módulo afectado] — [descripción corta]

**Detectado:** [fecha]
**Detectado por:** Agente spec al generar spec de [feature]
**Descripción:** [qué antipatrón o problema existe]
**Ubicación:** [archivo(s) o módulo]
**Impacto en feature nueva:** [cómo afecta o podría afectar la nueva implementación]
**Riesgo si se deja:** [bajo / medio / alto — y por qué]
**Condición de salida:** [qué ticket o decisión lo resuelve]
**Política aplicada:** el código nuevo no replica este patrón — sigue convenciones del template
```

---

## Paso 7 — Reporte al dev

Al terminar, mostrar siempre un resumen en este formato:

```
📋 Spec generada: [Nombre Feature]

Archivos creados/actualizados:
  Features/[mod].md            — Requisitos y User Stories
  Features/[mod].spec.md       — Contrato técnico
  Features/[mod].checks.md     — Verificación post-implementación

Estado: [estado del ciclo de vida]
User Stories: [N] (P1: [n], P2: [n], P3: [n])
Reglas de negocio: [N] definidas
Endpoints: [N] contratos especificados
[NEEDS CLARIFICATION] pendientes: [N] — [si hay, listarlos]
Supuestos documentados: [N]

[Si hay deuda detectada:]
⚠ Deuda técnica registrada en deuda-tecnica.md: [descripción breve]

Siguiente paso sugerido:
→ [Si estado es needs-clarification]: Responder [N] pregunta(s) pendiente(s) para pasar a ready
→ [Si estado es ready]: Pasar al agente de implementación con: "implementa Features/[mod]"
→ [Si es epic]: Confirmar opción de descomposición en Features/[mod]-epic.md
→ [Si es spike]: Resolver spike en Features/[mod]-spike.md antes de continuar
```

---

## Reglas absolutas

1. **Nunca generar código** — ni snippets, ni ejemplos de implementación, ni SQL ejecutable.
   Los contratos de API son contratos (estructura JSON), no código.

2. **Nunca modificar `Features/[mod].md` existente sin confirmación** si el estado
   no es `draft`. Preguntar antes de sobreescribir.

3. **Nunca asumir en silencio** algo que cambie scope, seguridad o flujo principal.
   Documentar en Supuestos o preguntar. Los supuestos mal hechos se convierten en bugs.

4. **Nunca descomponer un Epic sin confirmación del dev.** Proponer, esperar respuesta,
   entonces generar las specs hijas.

5. **El código existente manda sobre la spec** cuando hay conflicto.
   Si el código hace X y la spec pide Y en código legado, registrar en deuda-tecnica.md,
   no modificar el código ni falsificar la spec.

6. **Máximo 3 preguntas por sesión.** Si hay más ambigüedades, resolverlas con
   defaults razonables, documentarlos en Supuestos, y continuar.

---

## Cuándo leer otras Skills

Este agente no implementa, pero puede consultar otras Skills para
generar specs técnicamente coherentes con el proyecto:

| Situación | Skill a consultar |
|---|---|
| La spec involucra seguridad, tokens o permisos | `SKILL-security-[stack].md` relevante |
| La spec define migraciones de BD | `SKILL-database-migrations.md` |
| La spec describe un módulo MVC completo | `SKILL-mvc-feature.md` |
| La spec necesita respetar patrones NestJS | `SKILL-nestjs-best-practices.md` |
| La spec necesita respetar patrones .NET | `SKILL-dotnet-best-practices.md` |

Consultar solo para asegurar que los contratos son coherentes con el stack.
No implementar — solo informar la spec.
