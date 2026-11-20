# SKILL — Principios de ejecución (adaptados de las observaciones de Andrej Karpathy)

Esta skill especializa, pero no reemplaza, la `Política de autonomía y ambigüedades` de
`IA_Skill/SKILL-autonomy-policy.md` (**AUTONOMY_POLICY_VERSION: 1**) ni la política de zonas de
`IA_Skill/SKILL-risk-zone-policy.md`.

## Cuándo usar esta skill

`AGENTS.md` resume los cuatro principios y aplican **siempre**. Leer esta skill solo cuando:

- haya duda sobre el alcance de un cambio (¿esto entra en el pedido o es una "mejora" no pedida?);
- al diseñar una solución aparezca la tentación de abstraer, generalizar o agregar opciones;
- un pedido sea vago y haya que convertirlo en criterios verificables;
- en code review, para nombrar el problema: sobreingeniería, cambio no trazable al pedido, deriva de estilo.

## Precedencia (leer primero)

| Si el principio sugiere… | …y la plantilla dice… | Aplica |
|---|---|---|
| Ante la duda, detenerse y preguntar | Investigar antes de preguntar; T1/T2 se deciden y documentan; solo B2/S1/X1 no aislables escalan | La política de autonomía |
| Sin configurabilidad ni manejo de casos no pedidos | B1: configuración nullable con la regla deshabilitada; estados seguros (`UNKNOWN`, `PENDING_CONFIGURATION`…) | La política de autonomía |
| Lo ajeno se reporta, no se arregla | Zona roja → `IA_Memoria/deuda-tecnica.md`; zonas verde/ámbar según su alcance | La política de zonas |
| Verificar antes de cerrar | Comandos de verificación, `[mod].checks.md`, Playwright en módulos con UI, cierre en `in-review` | Ambas (se suman) |

## 1. Pensar antes de actuar

**No esconder supuestos ni confusión.**

- Antes de cambiar código, enunciar en una o dos líneas qué se entendió del pedido y qué supuestos se toman.
- Si el pedido admite varias lecturas con resultados distintos, nombrarlas y decir cuál se toma y por qué
  (decisión T1/T2) — o escalar con el formato de la política de autonomía si es B2/S1/X1 no aislable.
- Si existe un camino más simple que el pedido literal, decirlo antes de implementar el complejo.
- Si algo no cuadra (spec contra código, dato ausente), investigar primero (spec, checks, código, memoria) y
  registrar el supuesto con el formato de la política de autonomía.
- Nunca: elegir en silencio una interpretación con impacto de negocio, ni preguntar por un detalle técnico
  reversible que el código ya responde.

Ejemplo — "Exportar los contratos a Excel":

- ❌ Exportar todas las columnas de todos los tenants, de forma síncrona, sin mencionar ninguna decisión.
- ✅ "Supuestos: solo contratos activos del tenant actual (respeta el filtro global existente), columnas del
  listado actual, exportación síncrona porque el máximo es ~5k filas (T1, reversible). Si se necesitara
  asíncrona por volumen, sería un cambio de contrato (T2) y lo documentaría."

## 2. Simplicidad primero

**La solución mínima que cumple el criterio; nada especulativo.**

- Sin abstracciones de un solo uso (interfaz + fábrica + strategy para una única implementación), salvo las
  que exige la arquitectura del proyecto (capas controller → service → repository) o un punto de extensión que
  el código ya usa.
- Sin parámetros, flags ni opciones que nadie pidió.
- Sin manejo de errores para casos imposibles — pero sí para los que la política de autonomía declara
  posibles (dato ausente, fuente degradada).
- Pregunta de control: ¿un dev senior del equipo diría que está sobrediseñado? Si sí, simplificar antes de entregar.

Ejemplo .NET — "aplicar un descuento porcentual":

- ❌ `IDiscountStrategy` + `PercentageDiscountStrategy` + `DiscountStrategyFactory` + registro en DI, para una sola regla.
- ✅ Un método en el service que ya existe:

```csharp
public decimal ApplyDiscount(decimal amount, decimal percentage)
{
    if (percentage is < 0 or > 100)
        throw new ValidationException("El porcentaje debe estar entre 0 y 100");

    return amount - (amount * percentage / 100m);
}
```

Cuando aparezca una segunda regla de descuento, ese es el momento de extraer una abstracción.

Ejemplo Angular — "mostrar el total en la tabla":

- ❌ Un `TotalsService` configurable con caché y un pipe genérico de agregación.
- ✅ Un `computed()` en el componente que ya tiene los datos:

```typescript
readonly total = computed(() => this.rows().reduce((sum, row) => sum + row.amount, 0));
```

## 3. Cambios quirúrgicos

**Tocar solo lo que el pedido exige: cada línea del diff se puede trazar al pedido.**

- Respetar el estilo y las convenciones del archivo aunque se prefiera otro (nombres, formato, manejo de
  errores, forma de respuesta).
- No "mejorar" código, comentarios ni formato adyacentes; no refactorizar lo que funciona.
- Problemas ajenos detectados: reportarlos en la entrega; si están en zona roja, registrarlos en
  `IA_Memoria/deuda-tecnica.md` (`SKILL-risk-zone-policy.md`).
- Huérfanos: eliminar solo lo que el propio cambio dejó sin uso (usings, imports, variables, métodos privados).
  El código muerto preexistente se reporta, no se borra.
- Prueba final: si el revisor preguntaría "¿por qué cambiaste esto también?", ese cambio sobra.

Ejemplo — "el validador de email falla con un string vacío":

- ❌ Corregir el vacío y además reescribir la regex, agregar validación de longitud, renombrar variables y reformatear el archivo.
- ✅ Solo la línea que corrige el caso, y la observación en la entrega:

```diff
 public bool IsValidEmail(string? email)
 {
+    if (string.IsNullOrWhiteSpace(email)) return false;
     return EmailRegex.IsMatch(email);
 }
```

> "La regex tampoco acepta dominios de más de 4 letras. No lo cambié porque no era parte del pedido; queda como observación."

## 4. Ejecución guiada por objetivos verificables

**Antes de implementar, convertir el pedido en un criterio comprobable; no cerrar sin comprobarlo.**

| Pedido vago | Criterio verificable |
|---|---|
| "Arregla el bug" | Un test que lo reproduce (falla), el fix, y el mismo test en verde |
| "Agrega validación" | Tests con entradas inválidas que fallan antes del cambio y pasan después |
| "Optimiza la consulta" | Medición antes/después: plan de ejecución, tiempo o número de round-trips |
| "Configura X" | Valor aplicado + lectura de vuelta o health check |
| "Pantalla nueva" | Validación Playwright del happy path y del error principal |

Para tareas de varios pasos, declarar el plan como `paso → verificación`:

```text
1. Agregar columna IsArchived con su migración → verificar: el script de la migración la incluye, con up y down
2. Filtrar archivados en el repository        → verificar: el test de integración devuelve solo no archivados
3. Mostrar el filtro en la UI                  → verificar: Playwright marca/desmarca y la tabla cambia
```

- Verificar con los comandos de `AGENTS.md` → "Comandos de verificación" y con los checks de `[mod].checks.md`.
- Reportar qué se verificó y cómo; lo no verificado se declara como tal. La tarea cierra en `in-review`.

## Señales de que funciona

- Diffs pequeños donde cada cambio corresponde al pedido.
- Menos reescrituras por sobrediseño.
- Supuestos visibles en la entrega, no descubiertos en la revisión.
- Cada entrega trae su evidencia de verificación.
- El revisor no tiene que preguntar "¿por qué cambiaste X también?".

## Origen

Adaptación propia (redacción, precedencia y ejemplos) de los cuatro principios que Andrej Karpathy describió
sobre errores frecuentes de los LLM al programar (https://x.com/karpathy/status/2015883857489522876), tal como
los empaquetan `github.com/multica-ai/andrej-karpathy-skills` (MIT) y `github.com/emavv/karpathy-guidelines`.
No se copió texto de esos repositorios.
