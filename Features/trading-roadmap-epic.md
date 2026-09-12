# Epic: Trading algorítmico — cierre de validación, vigilancia, riesgo y ejecución

**Estado:** epic
**Creado:** 2026-09-04
**Insumo original:** `Insumos/plan-trade.md` v1.0, contrastado contra el snapshot vigente y el código de `Codigo/personal-cripto/`.

---

## Por qué es un Epic

El plan abarca desde el cierre del scoring semanal hasta paper trading, ejecución con capital real y escalamiento. Incluye más de cinco flujos independientes, afecta Python, .NET, Angular, PostgreSQL/TimescaleDB, Redis y Binance, y contiene dependencias de seguridad y riesgo que impiden implementarlo como una sola feature.

Las Etapas 4 a 9 deben dividirse en entregas verificables. Varias pueden prepararse en paralelo, pero ninguna autorización de capital real puede adelantarse a las compuertas de riesgo, reconciliación y paper trading.

---

## Estado real contrastado

| Etapa | Estado encontrado | Evidencia / detalle pendiente |
|---|---|---|
| 0 — Fundamentos | Completada | Arquitectura .NET/Angular/Aspire, contratos internos, Redis y Worker presentes. |
| 1 — Preparación de pares | Completada | Backend y frontend de ingesta, calibración, candidatos y alta por lote presentes. |
| 2 — Registro e histórico | Completada según el plan | Trading registra las cinco combinaciones y publica a Redis; el procesamiento Python no está incluido en este workspace. |
| 3 — Backtesting inicial | Completada con riesgo abierto | Trading expone score y estado, pero las métricas y operaciones del motor Python no están en este workspace. DS-67 sigue abierta. |
| 4 — Re-scoring y activación | Parcial / en construcción | `RecalcularScoresSemanalJob` y sus tests existen. `EnTop` existe en backend y frontend. No se encontraron `score_provisional` ni `muestra_insuficiente` en entidad, contratos o UI. No puede verificarse el endpoint Python ni el watchdog porque `jmh_trading` no está presente. |
| 5 — Cuantificación | Pendiente | No se encontraron Monte Carlo, net expectancy explícita ni Sortino en el código disponible. |
| 6 — Vigilancia en vivo | Pendiente | No se encontró ingesta WebSocket de mercado ni persistencia continua para el Top N. DS-69 sigue abierta. |
| 7 — Riesgo y ejecución | Pendiente | No se encontró dominio de cuentas, posiciones, decisiones, órdenes, fills, límites o reconciliación con Binance. |
| 8 — Paper trading | Pendiente | No existe simulador/adapter paper, ledger ni protocolo cuantitativo de salida. |
| 9 / 9+ — Capital real y escalamiento | Pendiente y bloqueado por compuertas | Correctamente condicionado a Etapas 6, 7 y 8, pero faltan criterios cuantitativos completos de aprobación/rechazo. |

---

## Detalles faltantes detectados en el plan

Estos puntos deben formar parte de las specs hijas; no deben resolverse por inferencia durante la implementación:

1. **Repositorio Python no disponible:** el plan asigna la lógica a `jmh_trading`, pero su fuente no está en `Codigo/personal-cripto/` ni en el snapshot. Solo están los clientes y contratos .NET que lo invocan.
2. **Propagación incompleta de calidad del score:** `score_provisional` y `muestra_insuficiente` están exigidos por el plan, pero no aparecen en `ParAnalisis`, el endpoint interno, los DTOs públicos ni Angular.
3. **Progreso operativo de Etapa 4:** el Worker registra que aceptó/disparó la solicitud; el resultado detallado queda en `jmh_trading`. Falta confirmar el contrato de progreso en vivo, cancelación, reintento e idempotencia de extremo a extremo.
4. **Motor de señales en vivo:** el plan pasa de recibir mercado en tiempo real a dimensionar/ejecutar, pero no especifica quién evalúa Trend Rider al cierre de vela, cómo versiona la estrategia ni cómo genera una señal idempotente.
5. **Mercado de Binance:** no se define Spot vs. Futuros USD-M, dirección long-only vs. long/short, margen, apalancamiento ni tratamiento de liquidación. La mención de `funding` sugiere futuros, pero no es suficiente para decidirlo.
6. **Ciclo de vida de órdenes:** faltan estados, `clientOrderId`, deduplicación, partial fills, rechazos, expiración, cancel/replace, rate limits y recuperación tras timeout.
7. **Fuente de capital:** falta definir si “Capital” significa equity total, balance disponible, equity neta de PnL no realizado o capital asignado a la estrategia.
8. **Exposición y correlación:** falta la ventana, métrica, umbral y comportamiento cuando no haya histórico suficiente para calcular correlación.
9. **Límites de pérdida:** faltan porcentajes/valores, zona horaria de corte diario/semanal, política de reset y procedimiento de reactivación tras emergency stop.
10. **Paper trading:** falta elegir simulador interno con mercado real, Binance Testnet o una secuencia de ambos; también faltan reglas de fills, latencia y slippage.
11. **Compuerta estadística:** “operaciones suficientes”, expectancy aceptable y drawdown aceptable no tienen todavía muestra mínima, intervalo de confianza ni umbral de decisión.
12. **Seguridad y auditoría de ejecución:** faltan alcance de API keys, separación read/trade, prohibición de retiros, rotación, audit trail inmutable y control humano para habilitar capital real.
13. **Kill switch manual:** el circuit breaker automático no sustituye un emergency stop manual, autenticado, auditable y con estado fail-closed.
14. **Modos explícitos:** `EnTop=true` no autoriza operar. Falta una máquina de modos como mínimo para `observation`, `paper` y `live`, con transición manual protegida.
15. **Trazabilidad de specs previas:** el código referencia specs de Etapas 1–4, pero `Features/` contiene actualmente solo su README; deben recuperarse o declararse archivadas antes de modificar esos contratos.

---

## Propuesta de descomposición

### Opción A — Slices verticales con compuertas de riesgo (recomendada)

Cada slice deja un resultado demostrable. Los componentes peligrosos permanecen bloqueados hasta cumplir sus dependencias.

| Orden | Slice propuesto | Entrega | MVP independiente | Depende de |
|---:|---|---|---|---|
| 1 | `trading-etapa4-cierre-rescoring-activacion` | Cierra el job semanal, activación Top N, flags de calidad, progreso y UI integral. | Sí | Etapas 1–3 |
| 2 | `trading-etapa5-validacion-estadistica` | Informe reproducible de Monte Carlo, net expectancy, costos y decisión sobre Sortino. No habilita trading. | Sí | Operaciones históricas de Etapa 3 |
| 3 | `trading-etapa6-vigilancia-tiempo-real` | Ingesta continua solo para Top N, reconexión, continuidad, freshness y monitoreo. Cierra DS-69. | Sí, en modo observación | Slice 1 |
| 4 | `trading-etapa7a-politica-riesgo-sizing` | Contrato de capital, position sizing, riesgo por trade, exposición individual y máximo de posiciones; cálculo puro y auditable. | Sí, como simulación | Decisión de mercado; Slice 2 para calibrar valores finales |
| 5 | `trading-etapa7b-senales-decision` | Evalúa la estrategia versionada al cierre de vela y produce decisiones idempotentes `approve/reject`, sin enviar órdenes. | Sí, en shadow mode | Slices 3 y 4 |
| 6 | `trading-etapa7c-riesgo-cartera-correlacion` | Riesgo abierto agregado, límites de cartera y exposición correlacionada con fallback conservador. | No | Slice 4; datos de Slice 3 |
| 7 | `trading-etapa7d-ordenes-proteccion-costos` | Ciclo de vida de orden, SL/TP ATR, fees/slippage/funding, partial fills e idempotencia. Inicialmente con adapter no-live. | No | Slices 5 y 6 |
| 8 | `trading-etapa7e-limites-circuit-breaker` | Límites diario/semanal/drawdown, circuit breaker automático, kill switch manual y reactivación controlada. | No | Slices 4, 6 y 7 |
| 9 | `trading-etapa7f-reconciliacion-exchange` | Reconciliación bot↔exchange, arranque seguro, detección de divergencias y bloqueo fail-closed. | No | Slice 7; puede avanzar junto al Slice 8 |
| 10 | `trading-etapa8-paper-trading` | Ejecución paper con ledger, dashboard, métricas reales/modeladas y reporte automático de compuerta. | Sí, sin capital real | Slices 3–9 |
| 11 | `trading-etapa9-capital-real-100` | Habilitación manual y reversible de $100, observabilidad reforzada e informe de incidentes. | Sí, piloto controlado | Slice 10 aprobado por el dev |
| 12 | `trading-etapa9-escalamiento-controlado` | Escalones configurados, cada uno sujeto a una nueva aprobación basada en evidencia. | No | Slice 11 aprobado y cada escalón previo validado |

### Opción B — Por dominio funcional

Útil si equipos distintos son dueños permanentes de cada dominio, pero concentra el riesgo de descubrir incompatibilidades tarde.

| Epic de dominio | Alcance | Dependencias principales |
|---|---|---|
| `trading-analytics` | Re-scoring, flags de calidad, Monte Carlo, expectancy, Sortino y señales | Etapas 1–3 |
| `trading-market-data` | Top N, WebSocket, continuidad y freshness | Activación Top N |
| `trading-risk` | Sizing, cartera, correlación, límites y circuit breaker | Métricas y definición del mercado |
| `trading-execution` | Órdenes, fills, protección, costos y reconciliación | Señales + riesgo + market data |
| `trading-operations` | Progreso, dashboards, modos observation/paper/live, kill switch y auditoría | Contratos de todos los dominios |
| `trading-validation-rollout` | Paper, piloto $100 y escalamiento | Todos los dominios anteriores |

---

## Orden de ejecución y paralelismo recomendado

| Ola | Trabajo | ¿Paralelo? | Motivo / compuerta de salida |
|---:|---|---|---|
| 0 | Confirmar descomposición, incorporar/ubicar `jmh_trading` y decidir Spot/Futuros. | Sí, son decisiones independientes | Sin esto no se pueden cerrar contratos técnicos ejecutables. |
| 1 | Slice 1 (cierre Etapa 4) + Slice 2 (validación estadística). | **Sí** | Ambos usan datos existentes; Etapa 5 no requiere vigilancia en vivo. |
| 2 | Slice 3 (vigilancia) + diseño/implementación base del Slice 4 (riesgo configurable). | **Sí, parcialmente** | El motor de sizing puede construirse sin órdenes; los valores finales quedan bloqueados por evidencia y decisión de mercado. |
| 3 | Slice 5 (señales/decisión) + Slice 6 (riesgo de cartera). | **Sí, tras estabilizar contratos de 3 y 4** | Se integran al final de la ola en shadow mode. |
| 4 | Slice 7 (órdenes) y preparación de Slices 8–9. | **Paralelo parcial** | Circuit breaker y reconciliación pueden avanzar con contratos/fakes, pero no cerrarse antes del ciclo de órdenes. |
| 5 | Slice 8 (límites) + Slice 9 (reconciliación). | **Sí** | Ambos deben pasar antes de paper trading. |
| 6 | Slice 10 (paper trading). | **No** | Es una prueba integrada de todo lo anterior. |
| 7 | Slice 11 (piloto $100). | **No** | Requiere aprobación humana explícita de la compuerta de paper trading. |
| 8 | Slice 12 (escalamiento). | **No entre escalones** | Cada aumento depende de validar el anterior. |

### Ruta crítica

`Etapa 4 → Etapa 6 → señales/decisión → órdenes → reconciliación + circuit breaker → paper trading → $100 → escalamiento`

La Etapa 5 y la base del motor de riesgo reducen tiempo total porque pueden avanzar fuera de la ruta crítica, pero sus resultados sí condicionan los valores finales antes de paper trading.

---

## Compuertas no negociables

- Ninguna spec o implementación puede convertir `EnTop` en autorización para ordenar.
- Los valores de riesgo no pueden inventarse para desbloquear desarrollo; deben ser configurables y quedar inhabilitados hasta aprobación.
- Los modos `observation`, `paper` y `live` deben estar separados y ser auditables.
- Paper trading no puede comenzar sin reconciliación, circuit breaker y kill switch verificables.
- Live no puede comenzar por un cambio de configuración accidental ni por despliegue; requiere una acción humana explícita con permisos.
- El escalamiento no puede automatizarse solo por rentabilidad; cada salto requiere una nueva compuerta completa.

---

## Preguntas al dev antes de generar las specs hijas

### Q1 — Forma de descomposición

- **A — Slices verticales con compuertas (recomendada):** permite demostrar valor incremental y reduce el riesgo de integración antes de tocar capital.
- **B — Dominios funcionales:** favorece ownership por equipos especializados, con integración posterior más pesada.
- **C — Otra división:** describir el ajuste requerido.

### Q2 — Alcance de `jmh_trading`

- **A — Incorporar o señalar su ubicación en este workspace (recomendada):** permite contrastar y especificar el flujo completo Python↔.NET.
- **B — Tratarlo como sistema externo:** las specs definirán contratos e invariantes, dejando la implementación Python fuera de alcance.
- **C — Limitar por ahora las specs a .NET/Angular:** las partes Python quedarán bloqueadas y no podrán marcarse `ready`.

### Q3 — Producto de Binance para v1

- **A — Spot long-only:** menor superficie de riesgo; no aplica funding ni posiciones short.
- **B — Futuros USD-M long/short:** requiere margen, apalancamiento, funding, liquidación y controles adicionales.
- **C — Spot primero, Futuros en una epic posterior (recomendada si no hay decisión previa):** reduce el primer alcance sin cerrar la evolución futura.

Responder en formato: `Q1:A, Q2:A, Q3:C`. Tras la confirmación se generarán las specs hijas en el orden de las olas anteriores.

