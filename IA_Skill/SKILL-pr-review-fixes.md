# SKILL — PR Review Fixes (Resolución de comentarios de Pull Request)

## Cuándo usar este skill

Leer este skill cuando la tarea sea resolver comentarios de revisión de un Pull Request
en GitHub. Triggers:

- "resuelve los comentarios del PR [número]"
- "aplica el feedback del PR"
- "hay comentarios de revisión que hay que atender"
- "el revisor pidió cambios en el PR"
- "fix the PR review comments"

Este skill requiere acceso a `gh` CLI y al filesystem completo del workspace.
Si `gh` no está disponible o no hay sesión activa, reportar al dev antes de continuar.

**Política de zona (verde/ámbar/roja) usada en todo este skill: ver
`SKILL-risk-zone-policy.md` — es la fuente canónica, no se redefine aquí.**

---

## Paso 1 — Leer contexto del proyecto

Antes de obtener el PR o tocar cualquier archivo:

1. Leer `IA_Memoria/convenciones.md` — naming, patrones, estructura de capas
2. Leer `IA_Memoria/arquitectura.md` — servicios, módulos, decisiones técnicas activas
3. Leer `IA_Memoria/deuda-tecnica.md` — antipatrones ya registrados (para no repetirlos
   ni confundirlos con fixes nuevos)

Si alguno de estos archivos no existe o está vacío, continuar con lo disponible
y anotarlo en el reporte final.

---

## Paso 2 — Obtener el PR

Si el dev no proporcionó el número de PR, preguntar antes de continuar:

```
¿Cuál es el número del PR que debo revisar?
```

Con el número disponible, ejecutar:

```bash
gh pr view <número> --comments
gh pr diff <número>
```

Si el PR no existe o el repositorio no está configurado con `gh`, reportar el error
exacto al dev y detener la ejecución.

Identificar también el branch del PR para referencia durante el paso de verificación:

```bash
gh pr view <número> --json headRefName,baseRefName
```

---

## Paso 3 — Clasificar comentarios

Por cada comentario en el PR, asignar una de estas categorías:

| Categoría | Descripción | Acción del agente |
|---|---|---|
| BLOQUEANTE | Debe resolverse para que el PR sea aprobado | Aplicar en Paso 5 |
| SUGERENCIA | Mejora no obligatoria | Reportar al dev, no auto-aplicar |
| PREGUNTA | El revisor pide explicación, no cambio de código | Incluir en PENDIENTES DEV |
| NITPICK | Estilo menor de bajo riesgo | Aplicar solo si no introduce riesgo |
| ARQUITECTURA | Decisión de diseño con impacto en otros módulos | Bloquear hasta confirmación del dev |

Presentar la clasificación completa al dev en este formato antes de continuar:

```
Clasificación de comentarios — PR #<número>

BLOQUEANTES (<n>):
  [1] <archivo>:<línea> — <resumen del comentario>
  [2] ...

SUGERENCIAS (<n>):
  [3] <resumen>

PREGUNTAS (<n>):
  [4] <resumen>

NITPICKS (<n>):
  [5] <resumen>

ARQUITECTURA (<n>):
  [6] <resumen>

¿Confirmas esta clasificación antes de continuar?
```

Esperar confirmación explícita del dev. Si el dev corrige alguna categoría,
actualizar la clasificación antes de pasar al Paso 4.

Si hay más de 10 BLOQUEANTES, preguntar antes de continuar:

```
Hay <n> bloqueantes. ¿Prefieres que los resuelva todos de una vez
o en batches? (sugerido: batches de 5 para revisar incrementalmente)
```

---

## Paso 4 — Mapear bloqueantes a archivos

Por cada comentario BLOQUEANTE y NITPICK confirmado, identificar:

- Archivo exacto en `Codigo/`
- Líneas afectadas (desde el diff del PR)
- Cambio requerido según el comentario

Si un comentario es ambiguo — puede interpretarse de más de una forma — listar
las interpretaciones posibles y preguntar al dev cuál aplica:

```
El comentario "[texto del comentario]" en <archivo>:<línea> puede interpretarse como:
  A) <interpretación 1 — implicación>
  B) <interpretación 2 — implicación>
  C) Otra interpretación (describir)

¿Cuál aplica?
```

No asumir en silencio. Un fix mal aplicado es peor que uno postergado.
Sin respuesta del dev en la sesión activa, mover el comentario a PENDIENTES DEV y continuar con los demás.

---

## Paso 5 — Aplicar fixes

Política de zona para este paso: **zona ámbar siempre**.
Cada fix toca solo las líneas indicadas por el comentario del revisor.
No aprovechar para mejorar, refactorizar ni "limpiar" código adyacente.

Por cada BLOQUEANTE y NITPICK confirmado:

1. Abrir el archivo indicado
2. Aplicar el cambio mínimo necesario para resolver el comentario
3. No modificar firmas de métodos, nombres de clases ni contratos de interfaz
   salvo que el comentario lo pida explícitamente
4. No agregar imports que no sean estrictamente necesarios para el fix

**Conflicto con convenciones.md:**
Si el fix que pide el revisor contradice una convención declarada en
`IA_Memoria/convenciones.md`, no aplicar el fix. Reportar la contradicción
al dev en el reporte final bajo PENDIENTES DEV:

```
CONTRADICCIÓN DETECTADA
Comentario del revisor: <descripción>
Convención del proyecto (convenciones.md): <descripción>
Acción tomada: fix no aplicado — requiere decisión del dev
```

La convención del proyecto tiene precedencia sobre el criterio del revisor.
El dev decide si la convención debe actualizarse o si el revisor tiene razón.

**Comentarios de ARQUITECTURA:**
No aplicar ningún cambio de arquitectura sin confirmación explícita del dev.
Incluir en BLOQUEADOS del reporte con la descripción del cambio propuesto
y la razón por la que requiere decisión humana.

---

## Paso 6 — Verificar

Por cada archivo modificado en el Paso 5, confirmar los tres puntos siguientes
inspeccionando el código — no ejecutando el sistema:

**6.1 Firmas de métodos**
Verificar que ningún método modificado cambia su firma (nombre, parámetros,
tipo de retorno) de forma que rompa archivos que lo consumen. Buscar
referencias al método en otros archivos del módulo afectado.

**6.2 Coherencia con arquitectura**
Verificar que el fix respeta el patrón de capas declarado en `arquitectura.md`.
Ejemplo: si el fix es en un Service, confirmar que no introduce lógica de
presentación ni queries directas a BD que violen la separación de capas.

**6.3 Imports y dependencias**
Verificar que no se introdujeron:
- Imports de paquetes no declarados en el stack aprobado del proyecto
- Dependencias circulares entre módulos
- Referencias a archivos fuera de `Codigo/`

Si alguno de estos tres puntos falla, revertir el fix correspondiente e incluirlo
en PENDIENTES DEV del reporte con la razón específica.

---

## Paso 7 — Reportar

Generar el reporte final con esta estructura exacta:

```
Reporte PR #<número> — fixes aplicados

RESUELTOS (<n>):
  [1] <archivo>:<líneas> — <descripción del cambio aplicado>
  [2] ...

PENDIENTES DEV (<n>):
  Requieren tu respuesta o decisión antes de poder resolverse:
  [3] SUGERENCIA: <resumen — qué propone el revisor y por qué no se auto-aplicó>
  [4] PREGUNTA: <texto de la pregunta del revisor>
  [5] CONTRADICCIÓN: <descripción del conflicto entre comentario y convenciones.md>

BLOQUEADOS (<n>):
  No aplicados — requieren decisión de arquitectura:
  [6] <archivo> — <descripción del cambio propuesto por el revisor>
      Razón del bloqueo: <por qué requiere validación humana>

DEUDA REGISTRADA:
  [ninguna / lista de entradas agregadas a IA_Memoria/deuda-tecnica.md]
  Ejemplo: usuarios/UserService.cs — DELETE directo en tabla de negocio detectado
  en comentario del revisor. Código no modificado (zona roja). Entrada registrada.

Próximo paso sugerido:
→ Revisar PENDIENTES DEV y responder las preguntas para desbloquear los fixes restantes
→ [si hay BLOQUEADOS]: Confirmar o descartar los cambios de arquitectura propuestos
→ Cuando estés listo: gh pr push o git push para actualizar el PR
```

---

## Deuda técnica detectada durante la revisión

Si un comentario del revisor señala un antipatrón en código que no puede modificarse
sin ticket explícito (zona roja), registrar una entrada en `IA_Memoria/deuda-tecnica.md`:

```markdown
### [Módulo afectado] — [descripción corta del antipatrón]

**Detectado:** [fecha]
**Detectado por:** Agente PR-review — comentario del revisor en PR #<número>
**Descripción:** [qué antipatrón existe y en qué archivos]
**Ubicación:** Codigo/[ruta/al/archivo]
**Impacto:** [cómo afecta al desarrollo futuro]
**Riesgo si se deja:** [bajo / medio / alto — razón]
**Política aplicada:** código no modificado (zona roja). Fix requiere ticket explícito.
**Condición de salida:** [qué ticket o decisión lo resuelve]
```

---

## Reglas absolutas

1. **Nunca marcar el PR como aprobado ni ejecutar merge.**
   `gh pr review --approve` y `gh pr merge` están fuera del alcance de este skill.

2. **Nunca modificar archivos de entorno.**
   `.env`, `appsettings.json`, `appsettings.*.json`, `secrets.json`, `.env.*`
   son intocables aunque el comentario del revisor lo pida. Incluir en PENDIENTES DEV.

3. **Nunca resolver un comentario de ARQUITECTURA sin confirmación del dev.**
   Aunque el cambio parezca obvio o simple, la categoría ARQUITECTURA siempre
   requiere validación humana antes de cualquier modificación.

4. **La convención del proyecto tiene precedencia sobre el revisor.**
   Si hay contradicción entre lo que pide el revisor y `convenciones.md`,
   no aplicar el fix y reportar la contradicción. El dev decide.

5. **Zona ámbar siempre en código existente.**
   Este skill nunca aplica refactorizaciones oportunistas. Cada modificación
   tiene exactamente un comentario del revisor que la justifica.

6. **Sin confirmación de clasificación, sin fixes.**
   El Paso 3 requiere confirmación explícita del dev antes de continuar.
   Si el dev no responde la confirmación, detener y esperar.