---
name: instruction-router
description: Router central de instrucciones, selección de skills primaria/auxiliares, presupuesto de contexto y clasificación de decisiones operativas para Antigravity y agentes del workspace.
---

# SKILL — Instruction Router y Optimización Operativa Multiagente

Esta skill es el motor operativo de ruteo, jerarquía y gestión de contexto del sistema multiagente.
Especializa y opera bajo `CLAUDE.md` (**AUTONOMY_POLICY_VERSION: 1**).

---

## 1. Jerarquía Efectiva de Instrucciones

Todo agente (Antigravity, Claude Code, Gemini CLI, OpenCode, Codex CLI, Cursor, Copilot) debe evaluar la precedencia en este orden estricto:

```text
1. Plataforma / Reglas de Sistema (límites de seguridad inviolables del runtime)
   └── 2. Solicitud actual del usuario (intención, parámetros y límites específicos de la sesión)
        └── 3. Fuente canónica local (CLAUDE.md: principios, stack tecnológico, autonomía y seguridad)
             └── 4. Router de instrucciones (IA_Skill/SKILL-instruction-router.md: ruteo y presupuesto)
                  └── 5. Skill primaria (lidera el ciclo de vida de la tarea)
                       └── 6. Skills auxiliares (cargadas progresivamente bajo demanda)
                            └── 7. Contrato específico de la tarea (Features/[mod].spec.md, checks.md, prompt.md)
                                 └── 8. Código como evidencia verificable (verdad física contra drift de docs)
```

### Tabla de Niveles de Autoridad

| Nivel                                         | Autoridad               | Alcance                           | Qué puede sobrescribir             | Qué NO puede sobrescribir                   |
| --------------------------------------------- | ----------------------- | --------------------------------- | ---------------------------------- | ------------------------------------------- |
| **1. Plataforma**                             | Suprema de ejecución    | Sandbox, herramientas y runtime   | Todo nivel inferior                | Nada                                        |
| **2. Solicitud actual**                       | Intención de sesión     | Tarea puntual y alcances          | Contratos y prioridades previas    | Políticas de seguridad S1 y stack base      |
| **3. Fuente canónica (`CLAUDE.md`)**          | Normativa transversal   | Autonomía, stack, zonas de riesgo | Bridges locales y convenciones     | Solicitud explícita del dev dentro de stack |
| **4. Router (`SKILL-instruction-router.md`)** | Orquestación operativa  | Selección de skills y contexto    | Listas planas de skills en bridges | Precedencia canónica de CLAUDE.md           |
| **5. Skill primaria**                         | Conducción del flujo    | Ciclo de vida y artefactos clave  | Pasos genéricos no especializados  | Criterios de parada de la fuente canónica   |
| **6. Skills auxiliares**                      | Especialización técnica | Implementación puntual de capa    | Valores por defecto del lenguaje   | Límites de la skill primaria o spec         |
| **7. Contrato específico**                    | Definición funcional    | Reglas de negocio del módulo      | Supuestos previos no aprobados     | Restricciones de seguridad o arquitectura   |
| **8. Código real**                            | Evidencia física        | Estado real del sistema           | Documentación desactualizada       | Decisiones de negocio pendientes de spec    |

---

## 2. Reglas Esperadas del Router

1. **Una sola skill primaria por tarea:** Toda tarea tiene exactamente un líder de flujo.
2. **Carga auxiliar bajo demanda demostrable:** No cargar skills secundarias hasta que la capa correspondiente esté en edición inmediata.
3. **Cero duplicación o solapamiento:** Si se atiende HTML/JS vanilla, no cargar skills de diseño para Angular/React.
4. **Resolución de contradicciones por precedencia:** En caso de conflicto entre spec y código legado, el código real marca la realidad, pero una spec `ready` autoriza modificarlo dentro de su alcance.
5. **No cargar frontend para worker sin UI:** Prohibido leer skills de Angular, React, CSS o Playwright si la tarea es un worker, daemon, pipeline o API interna sin interfaz.
6. **No cargar migraciones si no hay cambio de persistencia:** Tareas de refactor, contratos en memoria o fixes de controllers no leen `SKILL-database-migrations.md`.
7. **No activar auditoría completa de seguridad para fixes acotados:** Usar `SKILL-preprod-security-audit.md` únicamente ante auditorías pre-productivas explícitas; para bugs puntuales usar la skill del stack.
8. **Carga progresiva:** El agente puede incorporar una skill auxiliar cuando la ejecución descubra una necesidad justificada.
9. **Registro breve de activación:** Registrar en una línea: `Activando [Skill] como [Primaria|Auxiliar] para [Motivo]`.
10. **Rechazo estricto de ruteos circulares:** Ninguna skill puede transferir el control a otra que a su vez la tenga como requisito sin avanzar el estado.

---

## 3. Matriz Obligatoria de Ruteo

| Tipo de tarea                                    | Skill primaria                                                       | Skills auxiliares                                                                                        | Lecturas obligatorias                                  | Lecturas condicionales                                       | No debe cargar                                               |
| ------------------------------------------------ | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Implementar SPEC `ready`**                     | `SKILL-implementation.md`                                            | Stack de la capa actual (`dotnet`, `nestjs`, `frontend`, etc.) + `SKILL-e2e-playwright.md` (si tiene UI) | `[mod].spec.md`, `[mod].checks.md`, `[mod].md`         | `arquitectura.md`, `convenciones.md` (si crea código nuevo)  | `SKILL-spec-generator.md`, `SKILL-preprod-security-audit.md` |
| **Reanudar SPEC `in-progress`**                  | `SKILL-implementation.md`                                            | Stack según capa pendiente                                                                               | `[mod].checks.md`, `[mod].md`                          | Archivo fuente donde quedó pausado                           | Relecturas de memoria completa, snapshots globales           |
| **Generar SPEC**                                 | `SKILL-spec-generator.md`                                            | Ninguna (solo especificación)                                                                            | Insumo entregado, `[mod]-epic.md` (si aplica)          | `convenciones.md`, `arquitectura.md`                         | Skills de codificación, compilación o frameworks             |
| **Corregir bug localizado**                      | Skill del stack (`SKILL-dotnet-best-practices.md`, etc.)             | Testing del stack (`SKILL-dotnet-test-frameworks.md`, etc.)                                              | Archivo del fallo + test que reproduce                 | Convenciones locales de ese archivo                          | `SKILL-spec-generator.md`, `progreso.md`, snapshots          |
| **Revisar código**                               | `SKILL-dotnet-design-pattern-review.md` o `SKILL-pr-review-fixes.md` | `SKILL-risk-zone-policy.md`                                                                              | Archivos modificados en el diff                        | `convenciones.md`                                            | Skills de creación de specs, migraciones                     |
| **Modificar contrato interno**                   | `SKILL-implementation.md`                                            | Tests de contrato del stack                                                                              | Contrato actual + productores y consumidores conocidos | `SKILL-risk-zone-policy.md`                                  | Skills de UI, estilos, migraciones BD                        |
| **Realizar migración BD**                        | `SKILL-database-migrations.md`                                       | `SKILL-risk-zone-policy.md`                                                                              | Entidades modificadas + script de migración previo     | `arquitectura.md` (puertos y cadenas de conexión)            | Skills de frontend, E2E, maquetación                         |
| **Ejecutar pruebas unitarias**                   | Skill de test del stack (`SKILL-*-test-*.md`)                        | Ninguna                                                                                                  | Archivo de prueba + clase bajo prueba                  | Ninguna                                                      | Skills de diseño, specs, migraciones                         |
| **Worker sin UI**                                | Skill del stack (`dotnet`, `nestjs`, etc.)                           | Tests de integración / contratos                                                                         | `[mod].spec.md` + código del worker                    | `arquitectura.md`                                            | `SKILL-e2e-playwright.md`, frameworks UI, CSS                |
| **Cambio frontend visible**                      | `SKILL-e2e-playwright.md`                                            | Skill de framework UI correspondiente                                                                    | `[mod].checks.md` o escenario a validar                | `.claude/skills/playwright-cli/SKILL.md` (si es interactivo) | Skills de backend, SQL, migraciones                          |
| **Dependencia SOFT ausente**                     | `SKILL-implementation.md`                                            | Degradación / Fallback seguro                                                                            | `[mod].spec.md` + interfaz de la dependencia           | `convenciones.md`                                            | `NEEDS CLARIFICATION` (no debe bloquear)                     |
| **Investigar ambigüedad / Spike**                | `SKILL-instruction-router.md`                                        | `SKILL-risk-zone-policy.md`                                                                              | Fuentes internas relevantes (código, spec, contratos)  | `arquitectura.md`, `convenciones.md`                         | Lectura completa del repo, snapshots masivos                 |
| **Tratar riesgo de seguridad / Hallazgo**        | `SKILL-risk-zone-policy.md`                                          | `SKILL-dependency-vulnerability-triage.md` o `SKILL-secrets-scanning.md`                                 | Archivo con el hallazgo o reporte SAST/SCA             | Skill del stack afectado                                     | `SKILL-preprod-security-audit.md` (salvo auditoría completa) |
| **Acción destructiva o sensible**                | `SKILL-risk-zone-policy.md`                                          | Ninguna (detenerse y solicitar autorización S1)                                                          | Contexto exacto de la acción solicitada                | Ninguna                                                      | Herramientas de ejecución sin autorización humana            |

---

## 4. Clasificación Obligatoria de Decisiones (Taxonomía)

Toda incertidumbre o decisión técnica debe clasificarse antes de determinar si requiere intervención del usuario:

### `T1 — Decisión técnica reversible`

- **Definición:** Nombres internos de clases, métodos, variables, DTOs, mappers, queries, estructura de carpetas estándar, estrategia de pruebas o representación nullable interna.
- **Conducta:** Investigar patrones existentes en el código → elegir la opción más coherente → implementar directamente → registrar brevemente en el reporte.
- **Regla:** **PROHIBIDO PREGUNTAR AL USUARIO.**

### `T2 — Decisión arquitectónica acotada`

- **Definición:** Extensión compatible y aditiva de un contrato interno, elección entre dos patrones ya aprobados en el repositorio, o persistencia auxiliar reversible.
- **Conducta:** Revisar consumidores conocidos y convenciones → adoptar la alternativa aditiva no destructiva → documentar en checks/supuestos → continuar.
- **Regla:** **NO CONSTITUYE BLOQUEO.**

### `B1 — Regla de negocio faltante pero aislable`

- **Definición:** Falta de un umbral cuantitativo, peso relativo, fórmula matemática, catálogo aún no aprobado o criterio de selección opcional.
- **Conducta:** No inventar valores. Implementar soporte configurable nullable, mantener la regla deshabilitada por defecto, retornar estados seguros explícitos (`PENDING_CONFIGURATION`, `NOT_EVALUATED`, `UNKNOWN`) y continuar con todo el resto.
- **Regla:** La ausencia nunca equivale a `PASS`, `APPROVED`, cero ni colección vacía interpretada como éxito.

### `B2 — Decisión de negocio material no aislable`

- **Definición:** Cambio sustancial de alcance funcional o alteración de la experiencia clave que no puede desacoplarse con configuración ni interfaces.
- **Conducta:** Intentar aislar mediante contratos provisionales. Solo si es imposible aislar, detener la porción dependiente y escalar en formato obligatorio. Continuar todo trabajo independiente.

### `S1 — Seguridad, datos o acción irreversible`

- **Definición:** Credenciales productivas, despliegues a servidores remotos, borrado físico de datos de negocio (`DELETE`), `DROP TABLE`, eliminación de migraciones.
- **Conducta:** **DETENCIÓN OBLIGATORIA.** Requiere confirmación humana explícita, actual y específica en el turno inmediato anterior.

### `X1 — Bloqueo externo real`

- **Definición:** Falta de credenciales externas indispensables no simulables, caída total de infraestructura no reemplazable o dependencia HARD no mockeable.
- **Conducta:** Demostrar por qué no puede resolverse con mocks, stubs o degradación. Continuar todos los módulos, contratos y tests independientes antes de reportar.

---

## 5. Definición Estricta de Bloqueo

Solo declarar `NEEDS CLARIFICATION` o pausar si se cumplen **TODAS** las siguientes condiciones:

1. Se agotó la evidencia interna en spec, contratos, código, migraciones y patrones existentes.
2. La decisión fue clasificada formalmente como `B2` no aislable, `S1` o `X1`.
3. La incógnita no puede aislarse detrás de configuración nullable, interfaz, feature flag, estado explícito o mock seguro.
4. Continuar implicaría inventar reglas de negocio materiales, vulnerar la seguridad o corromper datos.
5. No existe ningún trabajo independiente restante que pueda adelantarse.

### Lo que NUNCA es Bloqueante

- Falta de nombre de clase, tabla, DTO o mapper (resolver con T1).
- Elección entre dos patrones reversibles aprobados (resolver con T2).
- Campo adicional requerido en contrato interno extensible (resolver con T2 aditivo).
- Dependencia `SOFT` ausente (aplicar fallback o estado degradado).
- Umbral de scoring o filtro pendiente (dejar desactivado como B1 con `PENDING_CONFIGURATION`).
- Servicios externos en tests que pueden simularse con mocks/fakes.
- Estado `in-progress` cuando el usuario pide reanudar o continuar.
- Tareas que se pueden verificar parcialmente mientras se espera validación final.

---

## 6. Formato Obligatorio de Escalamiento

Cuando se cumplan estrictamente las 5 condiciones de bloqueo, el agente debe reportar con este esquema exacto:

```text
DECISIÓN REQUERIDA
Clasificación: [B2 | S1 | X1]
Pregunta concreta: [Pregunta clara y concisa]
Evidencia agotada: [Archivos, líneas y contratos inspeccionados]
Por qué no puede aislarse: [Razón técnica por la cual no es posible stub/configuración]
Opciones viables:
  1. [Opción A - Descripción]
  2. [Opción B - Descripción]
Opción recomendada y razón: [(Recomendada) Opción X porque...]
Impacto de cada opción: [Impacto técnico o de negocio]
Riesgo de continuar sin decisión: [Riesgo identificado]
Trabajo no bloqueado ya completado: [Lista de código, contratos y pruebas ya terminados]
```

---

## 7. Presupuesto Operativo de Contexto y Eficiencia de Tokens

### Distribución de Capacidad de Sesión

- **20% Descubrimiento y lectura obligatoria:** Inventario de cabeceras, rutas y contratos indispensables.
- **20% Diagnóstico y diseño de cambios:** Clasificación de decisiones y formulación de diffs mínimos.
- **30% Aplicación de correcciones locales:** Edición quirúrgica de archivos autorizados.
- **25% Validación obligatoria:** Pruebas estáticas, de ruteo, compilación y tests.
- **5% Entrega final:** Informe compacto con veredicto y evidencia verificable.

### 14 Reglas de Eficiencia de Tokens

1. **Inventario antes de abrir:** Comenzar por nombres, cabeceras y referencias con `find_by_name` y `grep_search`.
2. **Apertura quirúrgica:** Usar `view_file` con `StartLine` y `EndLine` para leer solo los bloques pertinentes.
3. **No volcar archivos completos:** Prohibido pegar código fuente o documentos completos en la narrativa o chat.
4. **Resumir evidencia comprendida:** Citar únicamente `archivo:línea` y hallazgo sintético.
5. **No releer archivos sin cambios:** Una vez leído un archivo, no volver a cargarlo salvo edición.
6. **No repetir búsquedas idénticas:** Cachear internamente los resultados de búsquedas previas.
7. **Agrupar consultas relacionadas:** Realizar búsquedas compuestas o inspecciones conjuntas.
8. **No cargar snapshots masivos innecesarios:** Solo usar snapshots si la tarea involucra refactor amplio multimodular.
9. **No abrir el catálogo completo de skills:** Cargar estrictamente la skill primaria y la auxiliar requerida.
10. **Evitar sobre-explicación:** No narrar planes repetidamente; ejecutar y entregar evidencia.
11. **Validar antes del 75% del contexto:** Comenzar pruebas obligatoriamente antes de consumir el último cuarto de tokens.
12. **Protocolo ante contexto bajo:** Si la ventana se reduce, detener exploración adicional, aplicar cambios esenciales y priorizar validación sobre explicaciones.
13. **No sacrificar validación por prosa:** Vale más una prueba ejecutada que un reporte literario extenso.
14. **No exagerar el estado completado:** La salida de toda implementación es `in-review`. Solo el dev o un test E2E/humano aprueba `done`.

### Prioridades ante Presupuesto Limitado

1. Corregir causa raíz de bloqueos falsos.
2. Corregir ruteo y jerarquía de skills.
3. Preservar y reforzar restricciones de seguridad (S1/X1).
4. Validar clasificación de decisiones (T1/T2/B1/B2).
5. Validar continuidad de trabajo independiente.
6. Resolver duplicaciones menores en bridges.
7. Mejoras de redacción o estilo.
