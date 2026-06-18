# Features/ — Especificaciones de Módulos

Aquí viven las specs de cada feature: requisitos de negocio, contrato técnico y lista de verificación.
**No contiene código.** Todo el código va en `Codigo/`.

---

## Cómo arrancar el desarrollo de una feature

### Paso 1 — Deposita el insumo en `Insumos/`

Coloca el material de entrada antes de pedirle algo al agente:
- Mockup o pantalla → `Insumos/mockups/`
- Documento Word / PDF de reglas de negocio → `Insumos/especificaciones/`
- Notas sueltas → pégalas directo en el chat

### Paso 2 — Pídele al agente que genere la spec

Escríbele esto al agente (ajusta el nombre de la feature y el archivo):

```
Genera la spec para la feature [nombre-feature].
Lee IA_Skill/SKILL-spec-generator.md primero.
El insumo está en Insumos/[carpeta]/[archivo].
```

El agente creará los tres archivos de la feature:
- `Features/[mod].md` → requisitos + estado del ciclo
- `Features/[mod].spec.md` → contrato técnico: entidades, API, reglas
- `Features/[mod].checks.md` → lista de verificación post-implementación

### Paso 3 — Revisa y aprueba la spec (tú, el dev)

Abre `Features/[mod].spec.md` y verifica:
- ¿Los flujos reflejan lo que pediste?
- ¿Las entidades y campos son correctos?
- ¿Las reglas de negocio están completas?

Si hay gaps, corrígelos en el archivo o díselos al agente. Cuando esté lista, cambia el campo `**Estado:**` a `ready` en `[mod].md`.

### Paso 4 — Pídele al agente que implemente

```
Implementa Features/[nombre-feature].
Lee IA_Skill/SKILL-implementation.md primero.
```

El agente verificará que el estado sea `ready`, leerá el contrato técnico e implementará por capas (BD → backend → frontend). Al terminar:
- Marcará `[mod].md` como `in-review`
- Completará `[mod].checks.md`
- Actualizará `IA_Memoria/progreso.md` con el nuevo estado

### Paso 5 — Valida la implementación (tú, el dev)

Abre `Features/[mod].checks.md` y verifica cada punto contra el código generado. Si todo está correcto, cambia `**Estado:**` a `done` en `[mod].md`.

### Paso 6 — Pídele al agente que cierre el progreso

```
La feature [nombre-feature] quedó done. Actualiza IA_Memoria/progreso.md.
```

El agente sincronizará `progreso.md` para que refleje el estado `done`. Este archivo es la vista agregada de todos los módulos del proyecto — mantenerlo al día permite arrancar cualquier sesión futura con contexto real.

---

## Patrón de tres archivos por feature

```
Features/
├── [mod].md          ← Requisitos en lenguaje de negocio + estado del ciclo
├── [mod].spec.md     ← Contrato técnico: entidades, API, reglas de negocio
└── [mod].checks.md   ← Lista de verificación post-implementación
```

Para features grandes, descomponer en slices:
```
Features/
├── reportes-epic.md           ← Contenedor del epic, propuesta de slices
├── reportes-lista.md
├── reportes-lista.spec.md
├── reportes-lista.checks.md
├── reportes-exportar.md
├── reportes-exportar.spec.md
└── reportes-exportar.checks.md
```

---

## Estados del ciclo de vida

El campo `**Estado:**` en `[mod].md` refleja en qué punto está la feature. Solo avanza — nunca retrocede sin razón documentada.

| Estado | Quién lo asigna | Qué significa |
|---|---|---|
| `draft` | Agente | Spec en construcción |
| `needs-clarification` | Agente | Hay `[NEEDS CLARIFICATION]` sin resolver |
| `ready` | **Dev** | Spec aprobada, lista para implementar |
| `in-progress` | Agente | Implementación en curso |
| `in-review` | Agente | Implementación terminada, esperando OK del dev |
| `done` | **Dev** | Feature confirmada como completa |
| `epic` | Agente | Feature grande → ver `[mod]-epic.md` |
| `spike` | Agente | Investigación técnica pendiente |

**Fuente de verdad:** `[mod].md` es el estado oficial de esa feature.
`IA_Memoria/progreso.md` es la vista agregada de todos los módulos.
Si hay inconsistencia entre ambos, `[mod].md` manda.

---

## Qué NO va en esta carpeta

- Código fuente (va en `Codigo/`)
- Bugs puntuales (van en `Issues/`)
- Mockups y documentos originales (van en `Insumos/`)
- Decisiones de arquitectura globales (van en `IA_Memoria/arquitectura.md`)
