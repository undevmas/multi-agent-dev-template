# SKILL — Política de autonomía y ambigüedades

> Fuente canónica de la política de autonomía. `AGENTS.md` (y sus punteros) la referencian;
> no duplicarla en ellos. Se lee al clasificar una ambigüedad, antes de preguntar al usuario,
> al escalar una decisión o al registrar deuda/supuestos.

## Política de autonomía y ambigüedades

**AUTONOMY_POLICY_VERSION: 1**

Esta política aplica a generación de Specs, implementación, revisión, corrección
de bugs y mantenimiento. Las restricciones de seguridad,
credenciales, producción, acciones destructivas, despliegues remotos y
tecnologías no aprobadas conservan plena vigencia.

### 1. Investigar antes de preguntar

Una pregunta al usuario nunca sustituye la investigación técnica.

Antes de declarar un bloqueo o solicitar una decisión, el agente debe revisar,
según corresponda:

1. Feature, Spec, checks, prompt de ejecución y Specs anteriores/posteriores.
2. `IA_Memoria/progreso.md`, `arquitectura.md` y `convenciones.md`.
3. Código, contratos, modelos, migraciones, configuración no sensible y pruebas.
4. Skills aplicables y cualquier skill que estas referencien para el caso.
5. Implementaciones equivalentes, catálogos versionados y patrones ya usados.

El reporte debe identificar qué fuentes se inspeccionaron y qué evidencia se
encontró o no se encontró. Está prohibido preguntar de qué tabla, DTO, interfaz
o patrón obtener un dato sin haber agotado primero estas fuentes.

### 2. Clasificación obligatoria de incógnitas

Toda ambigüedad se clasifica antes de decidir si bloquea:

- `T1 — Detalle técnico reversible`: nombres internos, DTOs, mappers, ubicación
  de código, interfaces, representación nullable, estrategia de consulta y
  decisiones equivalentes de bajo costo. El agente decide e implementa.
- `T2 — Decisión arquitectónica de impacto acotado`: elección entre patrones
  existentes, evolución compatible de contratos internos o persistencia
  adicional no destructiva. El agente investiga, elige la opción más coherente,
  documenta la decisión y continúa si es reversible.
- `B1 — Regla de negocio faltante`: umbral, fórmula, peso o criterio no aprobado.
  El agente no inventa el valor; implementa contrato, configuración,
  observabilidad y estados seguros, manteniendo la regla desactivada.
- `B2 — Decisión de negocio material`: cambia de forma importante el alcance,
  significado del producto o experiencia principal.
  Puede requerir confirmación, pero primero se debe intentar aislarla.
- `S1 — Seguridad, datos o acción destructiva`: credenciales, producción,
  integridad de datos, permisos, borrados o cambios irreversibles.
  Se aplican las políticas de confirmación explícita.
- `X1 — Bloqueo externo real`: falta acceso, infraestructura, credenciales o una
  dependencia que no puede sustituirse ni simularse de manera segura.

Una Spec aprobada o evidencia técnica nunca conceden por sí mismas autorización
operativa sobre credenciales o producción. Esas acciones requieren autorización
humana separada, actual y específica inmediatamente antes de ejecutarlas.

### 3. Definición estricta de NEEDS CLARIFICATION

`NEEDS CLARIFICATION` solo procede cuando, después de investigar:

1. la decisión es `B2`, `S1` o `X1`, o cambia materialmente alcance, seguridad
   o experiencia principal;
2. no puede aislarse detrás de configuración, interfaz, feature flag, estado
   explícito o comportamiento degradado; y
3. es irreversible, costosa de revertir, afecta seguridad o
   integridad de datos, o impide objetivamente una implementación segura.

No constituye `NEEDS CLARIFICATION` por sí solo:

- que la Spec no nombre una tabla, DTO, clase, método u operador;
- que haya varias implementaciones técnicas reversibles;
- que falte un campo en un contrato interno extensible;
- que una dependencia SOFT esté ausente o degradada;
- que falte un umbral que puede permanecer sin configurar;
- que un componente independiente pueda marcarse no disponible.

Una feature cuyo propósito único dependa de una regla de negocio ausente puede
permanecer en `needs-clarification`. Un gap parcial no convierte automáticamente
toda la Spec en bloqueada.

### 4. Regla de negocio ausente

La falta de una regla de negocio puede impedir activar esa regla, pero no
necesariamente impide implementar su contrato, persistencia, configuración,
estados, observabilidad, pruebas estructurales y flujo de integración.

Cuando falte una regla de negocio:

- no inventar umbrales, pesos, fórmulas ni equivalencias semánticas;
- usar configuración nullable/no establecida;
- mantener la regla deshabilitada;
- exponer `PENDING_CONFIGURATION` o `NOT_EVALUATED`;
- probar que la regla no produce efectos mientras no esté aprobada;
- indicar la condición exacta necesaria para activarla.

### 5. Estados seguros y ausencia de datos

Usar, según el contexto: `UNKNOWN`, `UNAVAILABLE`, `NOT_EVALUATED`,
`PENDING_CONFIGURATION` o `SOURCE_UNAVAILABLE`.

La ausencia o incertidumbre nunca se convierte silenciosamente en:

- `PASS`, `APPROVED`, `ELIGIBLE` o equivalente;
- cero;
- colección vacía que parezca una evaluación válida;
- valor por defecto cuantitativo;
- transición, promoción u orden.

Si un filtro activo requiere un dato ausente, el contrato debe aplicar una
semántica explícita y probada: exclusión fail-closed con razón observable, o
error/degradación según la Spec. Nunca debe incluir el elemento como aprobado.

### 6. Implementación provisional segura

Una implementación provisional debe:

1. desacoplar proveedor y consumidor mediante una interfaz o contrato estable;
2. exponer disponibilidad, fuente, freshness y versión;
3. mantener desactivado cualquier comportamiento sin definición aprobada;
4. preservar `null`/estado explícito en vez de fabricar datos;
5. incluir pruebas del caso configurado, no configurado y fuente degradada;
6. poder reemplazarse sin migración destructiva ni cambio breaking;
7. no exagerar la evidencia ni declararse funcionalmente completa.

### 7. Continuidad del trabajo

El agente debe continuar con todas las partes no bloqueadas.

Una ambigüedad localizada puede dejar un componente provisional, pero no detiene
backend, persistencia, UI, observabilidad, contratos o pruebas independientes.
La entrega queda como máximo en `in-review`, indicando qué está operativo, qué
es provisional y qué decisión sigue pendiente.

### 7.1 Propiedad del gap y trazabilidad entre Specs

Antes de registrar una ambigüedad o deuda, identificar qué Spec es propietaria
del contrato, dato o comportamiento faltante.

- **Gap propiedad de otra Spec:** si la Spec actual consume una capacidad que
  otra Spec debía producir y su contrato o evidencia está incompleto, registrar
  deuda técnica vinculada a la **Spec propietaria**. La deuda debe indicar la
  Spec donde se detectó, el alcance afectado, evidencia, comportamiento
  provisional, criterio de salida y `Retomar en: SPEC-[propietaria]`. El agente
  que retome la Spec propietaria debe revisar y resolver sus deudas vinculadas.
- Si la Spec propietaria ya está `done`, la Spec consumidora no la modifica ni
  cambia su estado silenciosamente. La deuda abre una pasada correctiva bajo la
  Spec propietaria; el agente asignado la mueve por `in-progress` → `in-review`
  y el dev conserva la decisión final de volver a marcarla `done`.
- **Gap propiedad de la Spec actual:** el agente no lo difiere como deuda de
  otra Spec ni pregunta por una decisión técnica. Investiga, elige la mejor
  opción T1/T2 reversible, la implementa, la prueba y registra la decisión en
  `[mod].checks.md`; si cambia una convención o frontera transversal, actualiza
  también `convenciones.md` o `arquitectura.md` según corresponda.
- Para B1 propia, implementar soporte seguro deshabilitado y documentar la
  condición de activación. Para B2/S1/X1, aplicar la definición estricta de
  `NEEDS CLARIFICATION`, sin detener el trabajo independiente.
- La deuda técnica no sustituye implementar una decisión T1/T2 propia ni
  permite declarar operativo o completo un comportamiento pendiente.

Formato mínimo de deuda cross-Spec:

- `Spec propietaria`:
- `Detectada desde`:
- `Clasificación`:
- `Evidencia`:
- `Alcance afectado`:
- `Comportamiento provisional`:
- `Decisión técnica recomendada`:
- `Condición de salida`:
- `Retomar en`:

### 8. Evolución de contratos

Una extensión aditiva, backward-compatible y autorizada por una Spec `ready`
no es automáticamente zona roja, especialmente en APIs internas.

Debe:

- conservar campos y semántica existentes;
- actualizar productor, consumidor y documentación;
- agregar pruebas de contrato en ambos lados;
- revisar consumidores conocidos;
- versionar cuando la compatibilidad no pueda conservarse.

Los cambios breaking, externos, no autorizados o de impacto incierto mantienen
las reglas de zona roja y confirmación.

### 9. Registro de supuestos

Registrar cada supuesto con este formato:

- `ID`:
- `Categoría`: T1 | T2 | B1 | B2 | S1 | X1
- `Pregunta o gap`:
- `Evidencia revisada`:
- `Decisión aplicada`:
- `Impacto`:
- `Reversibilidad`:
- `Comportamiento provisional`:
- `Decisión pendiente`:
- `Condición de activación`:
- `Pruebas`:

### 10. Escalamiento al usuario

Cuando una aclaración sea realmente necesaria, reportar:

- `DECISIÓN REQUERIDA`:
- `Clasificación`:
- `Evidencia agotada`:
- `Por qué no puede aislarse`:
- `Opciones viables`:
- `Opción recomendada y razón`:
- `Impacto de cada opción`:
- `Riesgo de continuar sin decisión`:
- `Trabajo no bloqueado ya completado`:

No pedir al usuario que diseñe DTOs, tablas, interfaces, mappers, queries o
patrones internos salvo que su elección cambie materialmente el contrato de
negocio o un sistema externo bajo su responsabilidad.

### 11. Presupuesto operativo y gestión eficiente de contexto

Para garantizar que toda tarea alcance implementación y validación sin agotar prematuramente la ventana de contexto:

- **Distribución de esfuerzo recomendada:** 20% descubrimiento y lectura mínima indispensable; 20% diagnóstico y diseño del cambio; 30% aplicación de correcciones; 25% validación y pruebas; 5% entrega final.
- **Eficiencia en lecturas:** Investigar primero con `find_by_name` y `grep_search`. Abrir archivos con `view_file` de forma acotada (usando `StartLine` y `EndLine`). No volcar documentos completos en la narrativa ni releer archivos que no han sufrido modificaciones.
- **Prioridad de validación:** Iniciar la validación antes de consumir el 75% del contexto disponible. Si el presupuesto de tokens es bajo, detener la exploración adicional, aplicar los cambios mínimos necesarios y priorizar la ejecución de pruebas sobre la prosa extensa.
- **Cierre de ciclo:** El resultado estándar de una tarea completada por el agente es `in-review`, nunca `done` (salvo autorización explícita del desarrollador).

### 12. Jerarquía de instrucciones y ruteo central

La selección de skills, resolución de conflictos entre instrucciones y reglas de carga progresiva se rigen por `IA_Skill/SKILL-instruction-router.md`:

1. Existe exactamente **una skill primaria** por tarea que conduce el ciclo de vida.
2. Las **skills auxiliares** se cargan exclusivamente bajo demanda demostrable por capa.
3. Se prohíbe la lectura indiscriminada de todo el catálogo de skills o la carga de skills de frontend para procesos de backend/worker sin interfaz de usuario.
4. En caso de contradicción, la precedencia es: Reglas de plataforma > Solicitud actual del usuario > `AGENTS.md` (vía `CLAUDE.md` y demás punteros) > `SKILL-instruction-router.md` > Skill primaria > Skills auxiliares > Contrato específico de feature > Evidencia en código.
