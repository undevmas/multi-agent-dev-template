# SKILL — Política de Zonas de Riesgo (Verde / Ámbar / Roja)

Esta skill especializa, pero no reemplaza, la `Política de autonomía y ambigüedades`
de `IA_Skill/SKILL-autonomy-policy.md` (**AUTONOMY_POLICY_VERSION: 1**).

## Cuándo usar esta skill

**Esta es la única fuente de verdad de la política de zonas — antes vivía
duplicada, con wording distinto, en `CLAUDE.md`, `AGENTS.md`, `.gemini/GEMINI.md`
y `.github/copilot-instructions.md`. Ahora los 4 solo apuntan aquí.** Si se
necesita ajustar qué califica como cada zona, se ajusta en este único
archivo, no en los 4 por separado.

Aplica en dos escenarios:

1. **Convenciones del template vs. código legado que no las sigue** — el
   caso original: ¿este código nuevo/modificado debe seguir el estándar
   completo del template, o hay que respetar lo que ya existe?
2. **Triage de hallazgos** (SAST, SCA, secrets, PR review) — ¿este fix se
   aplica directo, se acota al síntoma, o requiere ticket explícito?

Es la misma lógica de 3 zonas en ambos casos — un cambio de código nunca
dice "no soy código, soy un vulnerability fix" para saltarse la política.

---

## Las 3 zonas

### 🟢 Zona verde — código nuevo, estándar completo siempre

Archivos que no existían antes, o hallazgos sobre código sin usuarios en
producción dependiendo de él. Seguir las convenciones del template al
100% aunque el módulo alrededor sea legado — no heredar antipatrones del
código de al lado.

- UUID/GUID siempre, aunque la tabla vecina use int secuencial
- Soft delete, response estandarizada, guards en todos los endpoints nuevos
- Naming en inglés, estructura de carpetas según convenciones
- Retirar una credencial expuesta del código, logs o artefactos locales y evitar
  seguir propagándola es contención inmediata dentro del alcance autorizado.
  Revocarla o rotarla en un proveedor externo es `S1`: requiere autorización
  humana separada, actual y específica, además de coordinación para evitar una
  interrupción del servicio. Nunca registrar ni mostrar el valor del secreto.

### 🟡 Zona ámbar — código existente, cambio acotado al síntoma exacto

Tocar solo lo mínimo necesario para la tarea o el hallazgo. No aprovechar
para "mejorar" lo que no se pidió, y no expandir el diff más allá de lo
directamente relacionado.

- Agregar un método nuevo siguiendo convenciones, sin tocar los existentes
- Si el archivo tiene DELETE directo en BD, el código nuevo usa soft
  delete — el viejo queda igual
- Escapar una salida HTML sin sanitizar, agregar un middleware de
  validación puntual (`SKILL-legacy-stack-security-baseline.md`)
- Bump de dependencia en versión patch/minor sin cambio de API
  (`SKILL-dependency-vulnerability-triage.md`)
- Si un cambio rompería la interfaz existente — PARAR, no continuar en ámbar

### 🔴 Zona roja — no se toca sin ticket explícito

Código legado que funciona pero no sigue convenciones, o cualquier fix
cuyo impacto no se pueda acotar con certeza. Detectar, documentar, dejar
como está.

- No modificar migraciones ya aplicadas en producción
- No cambiar IDs de int a UUID en tablas existentes con datos
- No renombrar endpoints que ya consumen clientes externos
- Bump mayor de una dependencia con breaking changes conocidos
- Reescritura/modernización de un módulo completo, aunque el hallazgo
  original sea pequeño
- Registrar en `IA_Memoria/deuda-tecnica.md` con impacto y condición de salida

---

## Árbol de decisión, en orden

1. ¿Es código nuevo / sin usuarios en producción dependiendo de él?
   → 🟢 verde, seguir el estándar completo, listo.
2. ¿El cambio es breaking, elimina o renombra campos, altera semántica
   existente, afecta consumidores externos, o no está autorizado por la
   tarea/Spec?
   → 🔴 roja, detenerse aquí.
   ¿Es una extensión aditiva y backward-compatible de un contrato interno,
   requerida por una Spec `ready`, con productor y consumidor bajo este
   workspace?
   → 🟡 ámbar; proceder con revisión de consumidores y pruebas de contrato en
   ambos lados.
3. ¿El cambio se puede acotar al alcance de la tarea y a consumidores conocidos,
   aunque requiera cambios coordinados en más de un archivo o módulo?
   → Sí: 🟡 ámbar, proceder. No: 🔴 roja.

En caso de duda, investigar y clasificar el impacto antes de elegir zona. Si
después de agotar evidencia el cambio sigue siendo no acotable, gana la zona
más conservadora.

### Regla de desempate spec vs. código real

Cuando la Spec y el código real se contradicen fuera del cambio autorizado, el
código real gana. La contradicción se documenta en
`IA_Memoria/deuda-tecnica.md`. Una Spec `ready` sí puede modificar
deliberadamente código existente dentro de su alcance; no debe tratarse la
ausencia del comportamiento nuevo como veto de la Spec. Los cambios breaking,
no autorizados o de impacto no acotable se consultan al dev.

---

## Cómo reportar al terminar una tarea

```
🟢 Verde: [N] cambios aplicados sin restricción — [lista breve]
🟡 Ámbar: [N] fixes aplicados, acotados al hallazgo — [lista con archivo:línea]
🔴 Roja: [N] hallazgos documentados en deuda-tecnica.md, requieren ticket — [lista]
```

Si algo es zona roja, el resultado esperado de la tarea es la entrada en
`deuda-tecnica.md`, no código modificado.

---

## Skills que dependen de esta política (no la redefinen)

`SKILL-pr-review-fixes.md` · `SKILL-dependency-vulnerability-triage.md` ·
`SKILL-secrets-scanning.md` · `SKILL-legacy-stack-security-baseline.md`

---

## ❌ Qué NO hacer

- No inventar una cuarta zona ni renombrar estas tres en una skill nueva
- No aplicar un fix de zona roja alegando que "es un cambio chiquito" —
  el tamaño del diff no es el criterio, el impacto en el contrato lo es
- No usar zona verde para código que reemplaza código en producción solo
  porque el archivo en sí es nuevo — eso es ámbar o roja según el árbol
- No volver a copiar esta política dentro de `CLAUDE.md`/`AGENTS.md`/
  `GEMINI.md`/`copilot-instructions.md` — esos archivos apuntan aquí
