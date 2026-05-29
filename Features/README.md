# Features/ — Especificaciones de Módulos

Esta carpeta contiene las especificaciones de cada feature del proyecto.
Las escribe el agente spec a partir de insumos del dev. No contiene código.

---

## Patrón de tres archivos por feature

Cada módulo tiene exactamente tres archivos. Los tres deben existir antes
de que el agente de implementación arranque.

```
Features/
├── [mod].md          ← Requisitos en lenguaje de negocio + estado del ciclo
├── [mod].spec.md     ← Contrato técnico: entidades, API, reglas de negocio
└── [mod].checks.md   ← Lista de verificación post-implementación
```

**Ejemplo para el módulo `aprobacion`:**
```
Features/
├── aprobacion.md
├── aprobacion.spec.md
└── aprobacion.checks.md
```

Para features grandes descompuestas en partes:
```
Features/
├── reportes-epic.md           ← Contenedor del epic, propuesta de slices
├── reportes-lista.md          ← Slice 1
├── reportes-lista.spec.md
├── reportes-lista.checks.md
├── reportes-exportar.md       ← Slice 2
├── reportes-exportar.spec.md
└── reportes-exportar.checks.md
```

---

## Ciclo de vida de una spec

El campo `**Estado:**` en `[mod].md` y `[mod].spec.md` refleja en qué punto
del ciclo está la feature. Solo avanza — nunca retrocede sin razón documentada.

| Estado | Quién lo asigna | Qué significa |
|---|---|---|
| `draft` | Agente spec | Insumo recibido, spec en construcción |
| `needs-clarification` | Agente spec | Tiene `[NEEDS CLARIFICATION]` sin resolver |
| `ready` | Agente spec | Sin gaps críticos, lista para implementar |
| `in-progress` | Agente implementación | Alguien está codificando esta feature |
| `in-review` | Agente implementación | Implementación terminada, esperando OK del dev |
| `done` | Dev | Feature confirmada como completa |
| `epic` | Agente spec | Feature grande → ver archivo `[mod]-epic.md` |
| `spike` | Agente spec | Investigación técnica pendiente antes de especificar |
| `legacy-debt` | Agente spec | Feature existente con deuda documentada |

**Fuente de verdad:** `[mod].md` es el estado oficial de esa feature.
`IA_Memoria/progreso.md` es la vista agregada de todos los módulos.
Si hay inconsistencia entre ambos, `[mod].md` manda.

---

## Cómo generar una spec

Darle al agente cualquier insumo y pedirle que lea `IA_Skill/SKILL-spec-generator.md`:

```
"Genera la spec para esta feature. Lee SKILL-spec-generator.md primero."
```

El agente acepta cuatro tipos de insumo:
- **Documento Word / HU** — el insumo más rico: el agente extrae actores, flujos y reglas
- **Imágenes / mockups** — el agente lee pantallas e infiere comportamiento
- **Notas sueltas** — el agente estructura, hace preguntas críticas y genera la spec
- **Código existente** — el agente documenta lo que existe y especifica lo nuevo

---

## Cómo implementar desde una spec

Cuando `[mod].spec.md` tiene `Estado: ready`, decirle al agente:

```
"Implementa Features/[mod]. Lee SKILL-implementation.md primero."
```

El agente verificará el estado, leerá el contrato técnico, implementará
por capas y completará `[mod].checks.md` antes de marcar `in-review`.

---

## Qué NO va en esta carpeta

- Código fuente de ningún tipo (va en `Codigo/`)
- Bugs y problemas puntuales (van en `Issues/`)
- Mockups, archivos Word o PDFs originales (van en `Insumos/`)
- Decisiones de arquitectura globales (van en `IA_Memoria/arquitectura.md`)
