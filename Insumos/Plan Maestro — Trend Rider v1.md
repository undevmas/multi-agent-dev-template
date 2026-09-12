# PLAN MAESTRO — TREND RIDER v1

**Proyecto:** PersonalCripto / JMH Trading Management  
**Versión del plan:** v2.0 — consolidación arquitectónica y evolución de Trend Rider v1  
**Base temporal:** septiembre de 2026  
**Estado:** documento vivo  
**Estrategia base:** Trend Rider v1  
**Timeframe principal:** 4H  
**Modalidad actual:** desarrollo, validación estadística y construcción progresiva hacia paper trading  
**Capital real:** prohibido hasta cumplir las condiciones explícitas de salida de las etapas de validación  

---

# 1. Propósito del documento

Este documento define el plan maestro técnico, cuantitativo, operativo y funcional para la evolución de **Trend Rider v1** dentro de PersonalCripto.

Su propósito no es solamente describir una estrategia de trading.

Define un sistema completo capaz de:

- descubrir y clasificar pares;
- mantener información histórica;
- reevaluar continuamente el universo;
- identificar oportunidades compatibles con Trend Rider v1;
- aprender cuándo su propio proceso de selección se equivocó;
- observar el estado actual del mercado;
- incorporar gradualmente order flow y microestructura;
- separar claramente percepción, estrategia, riesgo y ejecución;
- validar estadísticamente cada modificación;
- operar inicialmente únicamente en simulación;
- ejecutar capital real únicamente bajo condiciones controladas;
- auditar cada decisión;
- presentar en frontend todo lo necesario para que una persona no técnica pueda verificar visualmente qué está ocurriendo;
- validar las funcionalidades completas de extremo a extremo, incluyendo frontend, API, procesos de fondo y persistencia.

El documento no debe tratarse como una especificación estática.

Es un documento vivo y versionado.

Las decisiones anteriores no deben borrarse silenciosamente.

Toda modificación relevante debe quedar asociada a:

- versión;
- fecha;
- razón;
- evidencia;
- impacto;
- deuda técnica relacionada;
- hipótesis que motivó el cambio;
- resultado observado posteriormente.

---

# 2. Objetivo general del sistema

PersonalCripto busca construir un sistema de trading algorítmico disciplinado para mercados de criptomonedas, inicialmente conectado a Binance, evitando las fallas típicas de estrategias construidas exclusivamente alrededor de señales técnicas aisladas.

El sistema no pretende competir contra:

- high-frequency trading;
- market makers institucionales;
- arbitraje de microsegundos;
- bots especializados en latencia;
- infraestructura colocada físicamente junto al exchange.

La ventaja que se busca es diferente.

Se busca una ventaja basada en:

1. selección disciplinada del universo;
2. reducción progresiva del número de candidatos;
3. uso de timeframes donde el ruido sea manejable;
4. paciencia;
5. posibilidad explícita de no operar;
6. validación estadística;
7. control de riesgo;
8. observación del mercado actual;
9. auditoría completa;
10. aprendizaje de decisiones incorrectas;
11. capacidad de cuestionar los propios filtros;
12. capacidad de detectar degradación del edge;
13. evolución gradual de una estrategia simple hacia una plataforma cuantitativa más sofisticada.

---

# 3. Filosofía central

Trend Rider v1 parte de un principio importante:

> El sistema no necesita predecir cada movimiento del mercado.

Debe identificar situaciones donde exista una combinación suficientemente favorable de:

- estructura;
- tendencia;
- volatilidad;
- liquidez;
- comportamiento histórico;
- riesgo;
- contexto;
- confirmación presente.

El sistema debe ser capaz de decir:

> No operar.

con la misma naturalidad con la que puede generar una oportunidad.

No existe obligación de estar permanentemente dentro del mercado.

---

# 4. Principio fundamental: riesgo, no monto fijo

El tamaño de una posición nunca debe partir de:

```text
Voy a comprar USD 50.
```

Debe partir del riesgo permitido.

La regla conceptual es:

```text
Position Size =
(Capital × Riesgo objetivo %) / Distancia al Stop Loss
```

Por lo tanto:

```text
Capital
  ↓
Riesgo permitido
  ↓
Stop Loss
  ↓
Tamaño máximo de posición
```

y nunca:

```text
Monto arbitrario
  ↓
Posición
```

Este principio debe mantenerse cuando el capital sea:

```text
$100

$200

$1,000

$10,000

$100,000
```

La estrategia no debe necesitar ser reescrita para cada nivel de capital.

---

# 5. Trend Rider v1 debe permanecer congelado como baseline

Antes de introducir microestructura, machine learning o reglas nuevas, Trend Rider v1 debe quedar formalmente definido y congelado como estrategia base.

La razón es experimental.

Si simultáneamente se modifican:

- indicadores;
- timeframe;
- condiciones;
- selector de pares;
- order flow;
- microestructura;
- stops;
- take profits;
- scoring;

resulta imposible saber qué cambio produjo una mejora o deterioro.

Por eso:

```text
TREND RIDER v1
──────────────

Timeframe principal:
4H

Motor:
reglas actuales

Backtesting:
walk-forward actual

Stop:
1.5 × ATR

Take Profit:
2.5 × ATR

Scoring:
versión actual

Estado:
BASELINE CONGELADO
```

"Cerrar" la estrategia no significa que no pueda evolucionar.

Significa:

```text
Trend Rider v1
↓
baseline experimental

Trend Rider v1.1
↓
cambio explícito

Trend Rider v2
↓
cambio estructural
```

Nunca deben realizarse modificaciones silenciosas.

---

# 6. Arquitectura actual del proyecto

El sistema existente se construye alrededor del monorepo:

```text
Codigo/personal-cripto/
```

Código principal:

```text
Codigo/personal-cripto/src/
```

---

# 7. Stack tecnológico actual

## Backend principal

```text
.NET 10
ASP.NET Core
C#
EF Core
Dapper
MediatR
Polly
Quartz.NET
YARP
```

## Frontend

```text
Angular 22
TypeScript
RxJS
Signals
PWA
Vitest
```

## Analítica

```text
Python
jmh_trading
```

Actualmente `jmh_trading` se considera una dependencia externa respecto al workspace .NET actual.

Sus responsabilidades observables comprenden:

- descarga histórica;
- procesamiento OHLCV;
- calibración;
- backtesting;
- re-scoring;
- activación de vigilancia.

## Persistencia

```text
PostgreSQL 15+
EF Core
Dapper
```

El proyecto puede utilizar TimescaleDB cuando el almacenamiento temporal de gran volumen lo justifique.

## Tiempo real y cache

```text
Redis
Redis Streams
StackExchange.Redis
```

## Jobs

```text
Quartz.NET
```

## Observabilidad

```text
OpenTelemetry
Serilog
Health Checks
```

## Orquestación local

```text
.NET Aspire
AppHost
ServiceDefaults
```

## Mensajería disponible

```text
Azure Service Bus
RabbitMQ
AWS SQS/SNS
```

---

# 8. Arquitectura funcional existente

```text
Angular gestion-pwa
        │
        ▼
Gateway YARP
        │
        ├──────── Identity
        │
        ├──────── Catalogo
        │
        ├──────── Trading
        │              │
        │              ├── PostgreSQL
        │              ├── Redis
        │              └── jmh_trading
        │
        ├──────── Reportes
        │
        ├──────── Business
        │
        └──────── Worker
                       │
                       ├── Quartz
                       ├── PostgreSQL
                       ├── Messaging
                       └── jmh_trading
```

---

# 9. Responsabilidad de cada plataforma

Debe mantenerse una separación explícita.

## .NET

Responsable principalmente de:

```text
workflow
estado operativo
usuarios
seguridad
multi-tenant
autorización
API
orquestación
riesgo
portfolio
ejecución
reconciliación
auditoría
jobs
integración frontend
```

## Python

Responsable principalmente de:

```text
procesamiento cuantitativo
features
indicadores
estadística
backtesting
walk-forward
scoring
ranking
market state
order flow
microestructura
counterfactual evaluation
análisis experimental
machine learning futuro
```

## Redis

Responsable principalmente de:

```text
estado efímero
streams
comunicación realtime
buffers
rolling windows
estado operativo temporal
```

## PostgreSQL

Responsable de:

```text
persistencia histórica
configuraciones
resultados
decisiones
experimentos
métricas
operaciones
auditoría
evaluaciones
```

## Angular

Responsable de hacer visible y verificable:

```text
qué hace el sistema
por qué lo hace
qué decidió
qué descartó
qué está observando
qué riesgo tiene
qué está fallando
qué habría ocurrido
qué cambió
```

---

# 10. Regla arquitectónica sobre Quartz y procesos persistentes

El patrón actual establece:

```text
Quartz.NET = capa de disparo
Python = lógica cuantitativa
```

Este patrón permanece.

Sin embargo, debe documentarse una excepción importante.

Un WebSocket conectado permanentemente al exchange no es un job periódico.

No debe implementarse así:

```text
Quartz
   ↓ cada segundo
consultar Binance
```

Para market streams debe existir un proceso persistente.

Conceptualmente:

```text
MarketDataWorker
    │
    ├── connect
    ├── authenticate si aplica
    ├── subscribe
    ├── consume
    ├── heartbeat
    ├── detectar pérdida
    ├── reconnect
    ├── resync
    └── continue
```

Quartz puede:

- iniciar procesos;
- programar mantenimiento;
- disparar recalibraciones;
- ejecutar re-scoring;
- ejecutar análisis periódicos.

Pero no sustituye un consumidor streaming permanente.

---

# 11. Principios no negociables

## 11.1 No operar con capital real antes de validación

No debe existir paso automático:

```text
backtest positivo
↓
dinero real
```

La secuencia obligatoria es:

```text
backtesting
↓
shadow mode
↓
paper trading
↓
validación
↓
capital mínimo controlado
↓
escalamiento
```

---

## 11.2 No modificar una estrategia para producir más trades

Aumentar el número de operaciones no constituye una justificación.

Toda modificación debe responder a una hipótesis.

Ejemplo correcto:

```text
Hipótesis:
El filtro X reduce entradas durante régimen lateral
sin deteriorar expectancy.
```

Ejemplo incorrecto:

```text
Cambiar X porque salen más operaciones.
```

---

# 12. Ningún parámetro inventado debe presentarse como decisión final

Todo valor no validado debe identificarse como:

```text
SUPUESTO_PENDIENTE_CALIBRACION
```

Ejemplos:

```text
score mínimo

peso de CVD

porcentaje de exploración

ventana de order book

máximo riesgo por operación
```

pueden utilizar valores iniciales durante desarrollo.

Pero esos valores no deben presentarse como parámetros científicamente validados.

---

# 13. Frontend como parte obligatoria de la funcionalidad

Esta regla se eleva a principio no negociable del proyecto.

## Una funcionalidad NO está completa porque:

```text
compila

el endpoint responde 200

el Worker terminó

la tabla tiene datos
```

Una funcionalidad con información útil para operación humana sólo puede considerarse completa cuando existe también una forma adecuada de:

- visualizarla;
- comprenderla;
- verificarla;
- detectar inconsistencias;
- consultar historial;
- inspeccionar razones;
- reproducir condiciones importantes desde el frontend.

---

# 14. No escatimar en frontend

El frontend no debe considerarse una capa secundaria.

Para este proyecto es una herramienta de:

```text
validación
auditoría
operación
diagnóstico
explicabilidad
control
```

Por lo tanto:

> No se debe ahorrar esfuerzo de frontend cuando una pantalla permita verificar que el backend está haciendo correctamente su trabajo.

Si un módulo genera:

```text
ranking
```

debe existir una pantalla que permita inspeccionar el ranking.

Si genera:

```text
score
```

debe poder observarse:

- score;
- componentes;
- versión;
- fecha;
- razones.

Si descarta:

```text
430 pares
```

debe ser posible consultar:

- cuáles;
- por qué;
- con qué valores;
- con qué thresholds;
- en qué versión;
- qué ocurrió posteriormente.

---

# 15. El frontend debe ser comprensible para un usuario no técnico

No debe asumirse que el usuario entiende:

```text
CVD

OBI

ATR

OI

PF

Sharpe

Sortino

microprice
```

Cada concepto relevante debe tener:

- nombre comprensible;
- definición;
- tooltip;
- explicación funcional;
- valor;
- interpretación;
- estado visual.

Ejemplo:

```text
CVD
Cumulative Volume Delta

¿Qué representa?
Diferencia acumulada entre volumen ejecutado
por compradores agresivos y vendedores agresivos.

Estado:
Comprador fuerte
```

No basta con:

```text
CVD = 13234.23
```

---

# 16. Las pantallas deben eliminar ambigüedad

Una pantalla debe poder responder claramente:

```text
¿Este par está seleccionado?

¿Por qué?

¿Desde cuándo?

¿Qué cambió?

¿Qué componente lo favoreció?

¿Qué componente lo perjudicó?

¿Qué datos estaban disponibles?

¿Qué versión tomó la decisión?

¿Se ha equivocado anteriormente el selector con este par?

¿Qué haría la estrategia hoy?

¿El sistema permite operar?

¿Por qué no permite operar?

```

---

# 17. Playwright como parte del Definition of Done

Las pruebas end-to-end de interfaz deben utilizar herramientas como Playwright.

Una funcionalidad con frontend no se considera validada por:

```text
test unitario backend
```

solamente.

Debe existir cuando corresponda:

```text
unit test
+
integration test
+
API test
+
frontend test
+
Playwright E2E
```

Ejemplo:

```text
Usuario abre Preparación de Pares
↓
ejecuta proceso
↓
ve progreso
↓
espera finalización
↓
consulta candidatos
↓
abre detalle
↓
observa score y razones
↓
verifica coherencia
```

Ese flujo completo constituye una validación mucho más fuerte que probar únicamente un UseCase.

---

# 18. Evidencia visual como criterio de aceptación

Para módulos críticos se recomienda conservar evidencia automática:

```text
screenshots Playwright
videos ante fallo
traces
logs correlacionados
```

Especialmente para:

- ranking;
- selección;
- activación;
- market state;
- riesgo;
- ejecución;
- reconciliación;
- circuit breakers.

---

# 19. Arquitectura conceptual de Trend Rider

El sistema evoluciona hacia:

```text
UNIVERSO
   ↓
SELECCIÓN
   ↓
ESTRATEGIA 4H
   ↓
CONTEXTO
   ↓
PERCEPCIÓN ACTUAL
   ↓
CONFIRMACIÓN
   ↓
RIESGO
   ↓
EJECUCIÓN
```

Trend Rider v1 permanece en el centro como estrategia base.

La microestructura no reemplaza inicialmente a Trend Rider.

La complementa.

---

# 20. Jerarquía temporal

No deben crearse bots independientes para cada timeframe.

La jerarquía inicial será:

```text
4H
│
│ Trend Rider
│ generación de oportunidad
│
▼
1H
│
│ contexto y régimen
│
▼
15M
│
│ estructura
│ liquidez
│ setup
│
▼
5M
│
│ confirmación
│ sweep
│ rechazo
│ breakout
│
▼
Trades + Order Book
│
│ order flow
│ microestructura
│
▼
Decision
```

---

# 21. Filosofía multi-timeframe

El timeframe responde a una función.

## 4H

Responsable de:

```text
estrategia principal
tendencia
condiciones Trend Rider
oportunidad
```

## 1H

Responsable de:

```text
régimen
contexto
volatilidad
estructura intermedia
```

## 15M

Responsable de:

```text
setup
zonas
liquidez
pullback
estructura
```

## 5M

Responsable de:

```text
confirmación
sweep
rejection
breakout
failed breakout
```

## Event stream

Responsable de:

```text
trades
order book
agresión
delta
CVD
absorción
microprice
```

---

# 22. No utilizar microestructura para competir en velocidad

Aunque se procesen datos de:

```text
100 ms
250 ms
1s
```

el objetivo inicial no será realizar HFT.

El sistema utilizará microestructura para responder:

> ¿Lo que ocurre ahora respalda o contradice una oportunidad de mayor horizonte?

Por tanto:

```text
4H encuentra

1H contextualiza

15M estructura

5M prepara

Order Flow confirma

Risk autoriza

Execution ejecuta
```

---

# 23. Problema del filtrado inicial

Actualmente el sistema reduce aproximadamente:

```text
485 pares
```

a aproximadamente:

```text
55 candidatos
```

utilizando criterios como:

- volumen;
- spread;
- ATR.

Esto produce eficiencia computacional.

Sin embargo, genera un riesgo.

Si un par es incorrectamente descartado en el primer filtro:

```text
selector
↓
REJECTED
```

todo el pipeline posterior pierde la oportunidad de descubrir que fue un buen candidato.

Por ello:

> Rechazado no debe significar olvidado.

---

# 24. Nuevo principio del selector

El selector no define:

```text
qué pares existen
```

Define:

```text
dónde gastar más capacidad de cómputo.
```

Por tanto:

```text
485 pares
↓
todos observables

~55
↓
mayor análisis

Top N
↓
análisis intensivo
```

---

# 25. Separar elegibilidad de calidad

No debe existir una sola decisión:

```text
PASS / FAIL
```

Se requieren dos conceptos.

## Elegibilidad técnica

Un par puede quedar fuera por razones objetivas:

```text
deslistado

sin datos

histórico insuficiente

datos corruptos

instrumento no soportado
```

## Calidad

Un par elegible debe recibir:

```text
score
ranking
estado
incertidumbre
```

y no desaparecer completamente.

---

# 26. El estado pertenece al par en un momento, no al par para siempre

No utilizar conceptualmente:

```text
BAD_PAIR
```

Utilizar:

```text
PairState
{
    symbol,
    timestamp,
    liquidityScore,
    volatilityScore,
    spreadScore,
    tradabilityScore,
    trendScore,
    ranking,
    uncertainty
}
```

Un par malo hoy puede ser excelente mañana.

---

# 27. Estados del Candidate Lifecycle

Se define un ciclo explícito.

```text
DISCOVERED
     ↓
ELIGIBLE
     ↓
CANDIDATE
     ↓
CHALLENGER
     ↓
CORE
     ↓
TOP
     ↓
WATCHING
```

También puede retroceder:

```text
TOP
 ↓
DEGRADED
 ↓
CHALLENGER
 ↓
RESERVOIR
```

Y regresar:

```text
RESERVOIR
 ↓
IMPROVING
 ↓
CHALLENGER
 ↓
TOP
```

---

# 28. Pools operativos

## CORE

Conjunto de candidatos principales.

Reciben:

```text
backtesting
scoring profundo
análisis 4H
revisión recurrente
```

---

# 29. CHALLENGER

Candidatos cercanos al corte.

Ejemplo:

```text
#50 = 71.7
#51 = 71.4
```

El sistema no debe concluir:

```text
#50 bueno
#51 malo
```

El #51 debe permanecer en observación.

---

# 30. SHADOW

El Shadow Pool conserva candidatos rechazados o no promocionados para aprender posteriormente.

El sistema puede registrar:

```text
DOGEUSDT

Score:
54.1

Rank:
82

Decision:
SHADOW

Reasons:
volumen insuficiente
spread desfavorable

Fecha:
2026-XX-XX
```

y posteriormente evaluar:

```text
¿Qué habría ocurrido si lo hubiéramos aceptado?
```

---

# 31. RESERVOIR

Contiene pares elegibles de menor prioridad.

No reciben el mismo nivel de cómputo.

Pero deben permanecer bajo un scanner barato.

---

# 32. Explotación y exploración

El sistema no debe destinar el 100% del presupuesto computacional únicamente a los candidatos considerados mejores.

Debe existir capacidad de exploración.

Conceptualmente:

```text
Exploitation
────────────
mejores candidatos actuales

Exploration
───────────
candidatos inciertos,
emergentes o subestimados
```

Un ejemplo inicial puede ser:

```text
85% Core/Top
10% Challenger
5% Exploration
```

pero estos porcentajes deben considerarse:

```text
SUPUESTO_PENDIENTE_CALIBRACION
```

---

# 33. Exploración inteligente

No debe ser necesariamente aleatoria.

Puede priorizar:

```text
scores cercanos al threshold

mayor incertidumbre

cambios rápidos de ranking

aumento de volumen

cambio de régimen

divergencia entre modelos

candidatos anteriormente mal clasificados
```

---

# 34. Score dinámico

No guardar solamente:

```text
score actual
```

Guardar también evolución.

Ejemplo:

```text
T-4   39
T-3   42
T-2   47
T-1   51
T     54
```

Se requieren conceptos como:

```text
Score

ScoreVelocity

ScoreAcceleration
```

Ejemplo:

```text
ScoreVelocity =
Score(t) - Score(t-1)
```

---

# 35. Cheap Universe Scanner

No es necesario ejecutar análisis intensivo sobre todos los pares.

Debe existir un scanner barato.

Por ejemplo:

```text
cada 4H

universo completo
      ↓
OHLCV reciente
volume
spread
ATR
momentum
basic regime
      ↓
ranking ligero
```

La periodicidad exacta debe validarse.

El timeframe 4H constituye un candidato natural porque coincide con Trend Rider.

---

# 36. Niveles de costo computacional

```text
NIVEL 1
──────────────────────────

Universo completo

LOW COST

OHLCV
volumen
spread
ATR
momentum
estructura básica


NIVEL 2
──────────────────────────

Core / Challenger

MEDIUM COST

backtesting
walk-forward
scoring
regime
features adicionales


NIVEL 3
──────────────────────────

Top N

HIGH COST

WebSocket
trades
order book
order flow
microestructura
```

---

# 37. El sistema debe aprender de decisiones incorrectas

Esta capacidad pasa a ser requisito formal.

El sistema debe registrar no solamente:

```text
trades ejecutados
```

sino también decisiones no tomadas.

Ejemplos:

```text
NOT_SELECTED

NOT_PROMOTED

NOT_ACTIVATED

NO_BUY

REJECTED
```

---

# 38. Candidate Decision History

Debe existir una entidad o modelo equivalente a:

```text
CandidateEvaluation

EvaluationId

Symbol

Timestamp

StrategyVersion

SelectorVersion

ScoringVersion

FeatureVersion

Volume

Spread

ATR

Momentum

Regime

FeaturesSnapshot

Score

Rank

Uncertainty

Decision

ReasonCodes

ThresholdSnapshot

FutureEvaluationStatus

FutureOutcome
```

---

# 39. No sobrescribir decisiones anteriores

Si un candidato fue rechazado:

```text
T0
DOGE
score 52
REJECT
```

y posteriormente mejora:

```text
T1
DOGE
score 79
TOP
```

la decisión de T0 debe conservarse.

Nunca:

```text
UPDATE previous decision
```

Debe ser:

```text
T0 evaluation
T1 evaluation
```

---

# 40. Counterfactual Evaluation

El sistema debe responder:

> ¿Qué habría ocurrido si hubiéramos aceptado un candidato que descartamos?

Ejemplo:

```text
T0

SOL
Rank 82
Decision REJECTED
```

Posteriormente:

```text
T0 + horizonte

Trend Rider habría generado:
8 operaciones

PF:
1.8

Expectancy:
+0.42R
```

Entonces debe etiquetarse como posible:

```text
FALSE_NEGATIVE
```

---

# 41. El resultado no es "la moneda subió"

La evaluación contrafactual debe utilizar Trend Rider.

No debe decir:

```text
SOL subió 12%
por lo tanto fue mal descartado
```

Debe preguntar:

```text
¿Trend Rider v1 habría encontrado
operaciones válidas y explotables?
```

---

# 42. Etiquetas de evaluación

Se definen inicialmente:

```text
GOOD_SELECTION

BAD_SELECTION

GOOD_REJECTION

FALSE_NEGATIVE
```

---

# 43. Matriz conceptual de resultados

```text
                      REALIDAD POSTERIOR

                    Bueno          Malo

SELECTED          TRUE POSITIVE   FALSE POSITIVE

REJECTED          FALSE NEGATIVE  TRUE NEGATIVE
```

El sistema debe prestar especial atención a:

```text
FALSE NEGATIVE
```

porque representa oportunidades perdidas por mala selección.

---

# 44. Métricas de selección

## Recall

```text
Recall =
Buenos seleccionados
/
Todos los buenos
```

---

# 45. Missed Opportunity Rate

```text
MissedOpportunityRate =
Buenos rechazados
/
Todos los buenos
```

---

# 46. Selection Regret

Debe medir cuánto rendimiento potencial perdió el selector al priorizar incorrectamente.

Conceptualmente:

```text
expectancy candidatos seleccionados

vs

expectancy candidatos rechazados
que posteriormente demostraron calidad
```

---

# 47. Separar Strategy Performance de Selection Performance

Debe existir:

```text
StrategyPerformance
```

y:

```text
SelectionPerformance
```

por separado.

Es posible que:

```text
Trend Rider = bueno

Pair Selector = malo
```

Si ambas métricas se mezclan, el equipo puede intentar arreglar la estrategia equivocada.

---

# 48. Dataset de decisiones

Cada evaluación debe producir datos útiles para aprendizaje futuro.

```text
Features en T0
       ↓
Decision
       ↓
Outcome futuro
       ↓
Label
```

Después de acumular suficiente volumen:

```text
dataset propietario
```

puede utilizarse para:

- análisis estadístico;
- calibración;
- modelos de clasificación;
- detección de falsos negativos;
- detección de drift;
- machine learning futuro.

---

# 49. Evitar data leakage

Nunca:

```text
vemos quién subió
↓
modificamos retrospectivamente el filtro
↓
decimos que el filtro lo habría detectado
```

Las decisiones deben congelarse en T0.

Sólo después debe calcularse el resultado futuro.

---

# 50. Incertidumbre

No utilizar siempre:

```text
score >= 60 → PASS
score < 60 → FAIL
```

Si:

```text
score = 59.8
threshold = 60
```

el estado correcto puede ser:

```text
UNCERTAIN
```

Debe conservarse:

```text
distanceFromThreshold
uncertainty
```

Esto permite priorizar challengers.

---

# 51. ETAPA 0 — Fundamentos y arquitectura

**Estado:** completada.

Comprende:

```text
Python jmh_trading

.NET
Services/Trading
Services/Worker

Angular
gestion-pwa

PostgreSQL / TimescaleDB

Redis / Redis Streams

Quartz

Gateway YARP

Shared Contracts

Observability

Aspire
```

Patrones principales:

```text
Quartz = disparo programado

Python = analítica cuantitativa

servicios desacoplados

contratos versionados

sin acceso directo al schema de otro servicio

progreso visible para trabajos de fondo

frontend obligatorio para interacción humana
```

---

# 52. ETAPA 1 — Preparación de pares

**Estado:** completada.

Incluye:

```text
preparacion-pares-ingesta-universo

preparacion-pares-calibracion

panel-candidatos

alta-lote
```

Se utilizan calibraciones actuales sobre:

```text
volumen

spread

ATR
```

Resultados observados:

```text
~485 pares

↓

~55 candidatos
```

Esta etapa debe evolucionar para incorporar:

```text
Candidate Lifecycle
Shadow
Challenger
Reservoir
Decision History
```

sin invalidar el funcionamiento existente.

---

# 53. ETAPA 2 — Registro e histórico

**Estado:** completada.

Incluye:

```text
alta-par-registro

alta-par-descarga-historica
```

Debe continuar siendo responsable de garantizar:

```text
integridad

suficiencia de histórico

calidad OHLCV

disponibilidad para backtesting
```

---

# 54. ETAPA 3 — Scoring inicial

**Estado:** completada con riesgo abierto.

Incluye:

```text
walk-forward

8-12 semanas

ancla 4H
```

Score compuesto actual:

```text
profit factor       35%
Sharpe              30%
drawdown invertido  20%
win rate            15%
```

Estos pesos pertenecen a la versión actual.

No deben modificarse silenciosamente.

---

# 55. Riesgo estadístico DS-67

Existe una muestra pequeña.

Se observaron:

```text
14 operaciones

win rate:
21.4%
```

Esto es inferior al punto de equilibrio esperado bajo la combinación actual de:

```text
TP = 2.5 × ATR

SL = 1.5 × ATR
```

La muestra es insuficiente para concluir:

```text
estrategia inválida
```

o:

```text
varianza estadística normal
```

Trend Rider v1 no debe operar dinero real únicamente a partir de este score.

---

# 56. ETAPA 4 — Re-scoring y activación

**Estado:** en construcción.

Incluye:

```text
job-semanal-rescoring

alta-par-activacion-vigilancia
```

Debe evolucionar hacia:

```text
Core

Challenger

Shadow

Reservoir
```

---

# 57. Re-scoring profundo vs scanner ligero

Debe separarse:

```text
deep rescoring
```

de:

```text
universe scanning
```

El deep rescoring puede conservar una frecuencia menor.

El scanner ligero puede ejecutarse más frecuentemente.

---

# 58. DS-69

Existe actualmente un hueco de datos frescos entre evaluaciones.

La Etapa 6 resolverá este problema mediante ingesta realtime para candidatos activos.

---

# 59. ETAPA 5 — Cuantificación de riesgo

Debe ejecutarse antes del capital real.

Incluye:

## Monte Carlo

Sobre operaciones existentes.

Objetivo:

```text
estimar distribución probable de drawdowns
```

y no únicamente observar el drawdown histórico.

---

# 60. Net Expectancy

Debe mostrarse explícitamente:

```text
Net Expectancy =
Gross Expectancy
- Fees
- Spread
- Slippage
- Funding
```

Nunca esconder estos costos dentro de una métrica agregada sin visibilidad.

---

# 61. Sortino Ratio

Debe evaluarse como complemento a Sharpe.

No sustituirlo automáticamente.

Debe documentarse la hipótesis de uso.

---

# 62. ETAPA 6 — Realtime Market Perception

La Etapa 6 deja de ser únicamente "vigilancia realtime".

Se convierte formalmente en:

# REALTIME MARKET DATA & MARKET PERCEPTION

Su función es construir una representación estructurada de lo que está ocurriendo actualmente.

---

# 63. ETAPA 6.1 — Market Data Gateway

Crear capacidad de conexión continua al exchange.

Debe soportar:

```text
conectar

suscribirse

desuscribirse

heartbeat

reconectar

detectar gaps

resincronizar

health checks

telemetría
```

---

# 64. ETAPA 6.2 — Trade Stream

Consumir operaciones ejecutadas.

Inicialmente calcular:

```text
buyVolume

sellVolume

delta

CVD

tradeVelocity

largeBuyCount

largeSellCount

aggressorRatio
```

---

# 65. ETAPA 6.3 — Order Book

Mantener un libro local sincronizado.

Features iniciales:

```text
bestBid

bestAsk

spread

bidDepth

askDepth

imbalance

microprice
```

---

# 66. ETAPA 6.4 — Feature Engine

El Feature Engine debe normalizar información en familias.

## Price Features

```text
returns

ATR

range

volatility

momentum

distanceToHigh

distanceToLow
```

## Flow Features

```text
buyVolume

sellVolume

delta

CVD

aggressorRatio

tradeVelocity
```

## Book Features

```text
spread

depth

imbalance

microprice
```

## Event Features

```text
sweep

rejection

breakout

failedBreakout
```

## Derivatives Features futuras

```text
openInterest

openInterestDelta

funding

longLiquidations

shortLiquidations
```

---

# 67. ETAPA 6.5 — Multi-Timeframe State

Construir un estado normalizado.

Ejemplo:

```text
MarketState
{
    symbol,

    timestamp,

    regime,

    timeframe4h,

    timeframe1h,

    timeframe15m,

    timeframe5m,

    orderFlow,

    orderBook,

    derivatives
}
```

---

# 68. ETAPA 6.6 — Event Detectors

Primera versión:

```text
Liquidity Sweep

Rejection

Breakout

Failed Breakout
```

Versiones posteriores:

```text
Absorption

Exhaustion

Replenishment

Liquidity Cluster
```

---

# 69. ETAPA 6.7 — Market State Engine

El sistema no debe producir inmediatamente:

```text
BUY
```

Los componentes de percepción deben producir:

```text
qué está pasando
```

Ejemplo:

```text
Trend:
bullish

Structure:
pullback

Sweep:
yes

Aggressor:
buyers

CVD:
positive

Book:
bid dominant
```

---

# 70. ETAPA 6.8 — Shadow Mode

Esta etapa es obligatoria.

Microstructure v0.x no debe modificar inicialmente una operación.

Ejemplo:

```text
Trend Rider:
LONG

Microstructure:
REJECT

Confidence:
31/100
```

El sistema conserva:

```text
qué habría hecho
```

pero ejecuta el baseline experimental correspondiente.

---

# 71. ETAPA 6.9 — Comparison Dataset

Guardar:

```text
Trend Rider decision

Microstructure decision

Market State

Outcome
```

Esto permite comparar posteriormente:

```text
Trend Rider v1

vs

Trend Rider v1 + Confirmation
```

---

# 72. ETAPA 6.10 — Confirmation Score

Sólo después de acumular evidencia.

Debe poder considerar:

```text
ContextScore

SetupScore

OrderFlowScore

LiquidityScore

DerivativesScore
```

Los pesos iniciales son hipótesis.

Deben etiquetarse como:

```text
SUPUESTO_PENDIENTE_CALIBRACION
```

---

# 73. Microstructure v0.1

Primera versión deliberadamente pequeña.

## Trades

```text
buy volume

sell volume

delta

CVD

trade velocity
```

## Book

```text
spread

depth

imbalance

microprice
```

## Structure

```text
previous high

previous low

sweep

rejection
```

---

# 74. Microstructure v0.2

Añadir:

```text
absorption

replenishment

cancel rate

add rate
```

---

# 75. Microstructure v0.3

Añadir:

```text
Open Interest

Funding

Long Liquidations

Short Liquidations
```

---

# 76. Microstructure v0.4

Añadir:

```text
exhaustion

failed breakout avanzado

liquidity clusters

advanced state classification
```

---

# 77. Persistencia de microestructura

No almacenar indiscriminadamente cada snapshot completo del book para siempre.

Separar:

## Estado efímero

Redis / memoria:

```text
current order book

rolling windows

recent trades

CVD realtime

velocity

microprice
```

## Persistencia histórica

PostgreSQL / Timescale:

```text
feature snapshots

market state

aggregated trades

important events

signals

decisions

experiments
```

---

# 78. Market Replay futuro

El backtester OHLCV no es suficiente para reconstruir microestructura.

Debe existir posteriormente:

```text
historical event stream
      ↓
chronological replay
      ↓
trade event
book event
trade event
liquidation event
      ↓
Feature Engine
      ↓
Market State
      ↓
Strategy
```

No es requisito para Microstructure v0.1.

Puede empezarse acumulando datos propios.

---

# 79. ETAPA 7 — Risk & Execution Engine

Antes de capital real deben resolverse todos los siguientes componentes.

---

# 80. 7.1 Position Sizing

```text
Position Size =
Capital × Risk %
/
Stop Distance
```

---

# 81. 7.2 Riesgo por operación

Definir porcentaje máximo.

Valor:

```text
SUPUESTO_PENDIENTE_CALIBRACION
```

hasta finalizar análisis correspondiente.

---

# 82. 7.3 Riesgo total del portfolio

Debe calcular:

```text
suma de riesgos abiertos
```

y no únicamente capital asignado.

---

# 83. 7.4 Límite de exposición

Definir exposición máxima por instrumento.

---

# 84. 7.5 Exposición correlacionada

Evitar:

```text
BTC long
ETH long
SOL long
```

como si fueran tres operaciones completamente independientes cuando en realidad pueden constituir una única apuesta macro.

---

# 85. 7.6 Stop Loss y Take Profit

Baseline actual:

```text
SL = 1.5 × ATR

TP = 2.5 × ATR
```

Todo cambio debe versionar la estrategia.

---

# 86. 7.7 Slippage

Debe existir:

```text
slippage esperado

slippage observado

desviación
```

---

# 87. 7.8 Fees

Deben estar presentes en:

```text
backtesting

decision engine

execution

performance reporting
```

---

# 88. 7.9 Máximo de posiciones abiertas

Debe determinarse junto al riesgo de cartera.

---

# 89. 7.10 Límites de pérdida

Incluir:

```text
diario

semanal

drawdown máximo
```

---

# 90. 7.11 Circuit Breaker

Debe detener automáticamente el sistema ante condiciones definidas.

Ejemplos:

```text
drawdown excesivo

desviación crítica

problema de exchange

error de reconciliación

problema de sizing
```

---

# 91. 7.12 Reconciliación

El sistema debe comprobar continuamente:

```text
posición interna

vs

posición real en Binance
```

Especialmente después de:

```text
reconexión

timeout

error HTTP

reinicio del servicio

fill parcial
```

---

# 92. ETAPA 8 — Paper Trading

Es condición obligatoria antes de capital real.

Debe usar:

```text
Market Data real

Strategy real

Risk Engine real

Execution Simulator
```

---

# 93. Experimentos A/B conceptuales

## Grupo A

```text
Trend Rider v1
```

## Grupo B

```text
Trend Rider v1
+
Microstructure Confirmation
```

Comparar:

```text
trades

win rate

profit factor

expectancy

max drawdown

fees

slippage

exposure

missed opportunities
```

---

# 94. Condición de avance

No basta con:

```text
ganamos dinero
```

Se requiere:

```text
Net Expectancy > 0

drawdown aceptable

costos coherentes

riesgo correcto

reconciliación estable

sistema estable

muestra suficiente
```

---

# 95. ETAPA 9 — Primer capital real

Capital inicial:

```text
USD 100
```

Objetivo:

```text
validar operación real del sistema
```

No:

```text
obtener rentabilidad
```

---

# 96. Criterios de éxito del capital inicial

Debe comprobarse:

```text
sizing correcto

fills registrados

riesgo respetado

reconciliación correcta

circuit breaker correcto

pérdidas dentro del riesgo previsto
```

---

# 97. Una pérdida es aceptable

Si es consecuencia de:

```text
varianza normal
```

dentro del riesgo autorizado.

No es aceptable si proviene de:

```text
bug

doble orden

sizing incorrecto

reconexión defectuosa

estado inconsistente

fill no reconciliado
```

---

# 98. ETAPA 9+ — Escalamiento

Ejemplo:

```text
$100
 ↓ validación

$200
 ↓ validación

$400
 ↓ validación

$600
 ↓
...
```

Nunca escalar únicamente porque el capital aumentó.

---

# 99. Condición de escalamiento

Mantener:

```text
expectancy neta positiva

drawdown aceptable

riesgo correcto

operación estable

sin incidentes críticos sin resolver
```

---

# 100. Frontend — Mapa funcional obligatorio

El frontend debe crecer junto al sistema.

No se debe dejar todo el análisis encerrado en:

```text
logs

JSON

Redis

PostgreSQL

Grafana
```

Grafana y observabilidad no sustituyen una interfaz funcional de negocio.

---

# 101. Pantalla — Universo Binance

Mostrar:

```text
total de pares

elegibles

inelegibles

Core

Challenger

Shadow

Reservoir

Top N

Watching
```

Filtros:

```text
exchange

estado

score

ranking

volumen

spread

ATR

trend

regime
```

---

# 102. Pantalla — Ranking

Tabla completa.

Columnas:

```text
rank

symbol

score

previous rank

rank delta

score velocity

uncertainty

state

updated at
```

---

# 103. Pantalla — Detalle de candidato

Debe mostrar:

```text
estado actual

ranking

score

historial de score

componentes

thresholds

razones

versión del selector

versión de estrategia

historial de estados
```

---

# 104. Pantalla — Razón de selección/rechazo

Debe responder:

```text
¿Por qué está aquí?
```

Ejemplo:

```text
DOGEUSDT

Estado:
SHADOW

Motivos:

✓ ATR aceptable

✗ volumen debajo de p45

✗ spread superior al objetivo

Score:
54.3

Distancia del cutoff:
-5.7

Incertidumbre:
Alta
```

---

# 105. Pantalla — Candidate Timeline

Timeline:

```text
Discover

Eligible

Candidate

Shadow

Challenger

Top

Watching

Degraded
```

con fecha y razones.

---

# 106. Pantalla — False Negatives

Debe mostrar específicamente:

```text
pares descartados

resultado posterior

Trend Rider hypothetical trades

expectancy contrafactual

motivo original de descarte
```

---

# 107. Pantalla — Selection Performance

Visualizar:

```text
Recall

Missed Opportunity Rate

False Negative Rate

Selection Regret

True Positive

False Positive

True Negative

False Negative
```

---

# 108. Pantalla — Trend Rider

Mostrar:

```text
estado 4H

reglas

indicadores

condiciones cumplidas

condiciones no cumplidas

entrada hipotética

stop

target

risk/reward
```

---

# 109. Pantalla — Market State

Debe mostrar de forma visual:

```text
4H
1H
15M
5M
```

por separado.

Ejemplo:

```text
4H:
Bullish

1H:
Trending

15M:
Pullback

5M:
Liquidity Sweep

Order Flow:
Buyer Aggression

Book:
Bid Dominance
```

---

# 110. Pantalla — Order Flow

Debe mostrar:

```text
buy volume

sell volume

delta

CVD

trade velocity

aggressor ratio
```

con gráficos y explicación.

---

# 111. Pantalla — Order Book

Mostrar:

```text
best bid

best ask

spread

depth

imbalance

microprice
```

y visualización de profundidad cuando sea útil.

---

# 112. Pantalla — Eventos

Timeline de:

```text
sweep

rejection

breakout

failed breakout

absorption

liquidations
```

según la versión implementada.

---

# 113. Pantalla — Shadow Mode

Comparar:

```text
Trend Rider:

LONG

Microstructure:

REJECT

Outcome:

...
```

Esto será fundamental durante desarrollo.

---

# 114. Pantalla — Experimentos

Comparar versiones.

Ejemplo:

```text
Trend Rider v1

vs

Trend Rider v1 + Micro v0.1
```

Métricas:

```text
trades

expectancy

win rate

profit factor

drawdown

fees

slippage

selection effect
```

---

# 115. Pantalla — Risk Dashboard

Mostrar:

```text
capital

risk per trade

open risk

total portfolio risk

correlated exposure

drawdown

daily loss

weekly loss

circuit breaker
```

---

# 116. Pantalla — Ejecución

Mostrar:

```text
orders

fills

partial fills

fees

slippage

exchange state

internal state
```

---

# 117. Pantalla — Reconciliación

Debe existir una vista explícita:

```text
BOT                BINANCE

BTC:
0.015              0.015
✓ MATCH

ETH:
0.120              0.118
✗ MISMATCH
```

Nunca esconder una divergencia.

---

# 118. Pantalla — Paper Trading

Mostrar:

```text
equity

positions

trades

P&L

expectancy

drawdown

strategy version

market perception version
```

---

# 119. Pantalla — Jobs y procesos de fondo

Debe mostrar:

```text
nombre

estado

inicio

duración

progreso

último éxito

último error

retry

logs relevantes
```

---

# 120. Pantalla — Market Data Health

Mostrar:

```text
Binance WebSocket

Connected / Disconnected

latency

last message

reconnect count

book synchronized

trade stream

Redis

Python
```

---

# 121. Frontend y pruebas end-to-end

Cada épica debe incluir pruebas Playwright cuando exista interacción de usuario.

Ejemplo Etapa 1:

```text
abrir preparación

lanzar ingesta

observar progreso

esperar finalización

abrir ranking

seleccionar candidato

consultar razones
```

---

# 122. Prueba E2E de candidate lifecycle

```text
par inicia Reservoir

scanner actualiza score

pasa Challenger

rescoring lo promueve

frontend refleja Top

usuario abre historial

timeline contiene todas las transiciones
```

---

# 123. Prueba E2E de Shadow

```text
par rechazado

aparece Shadow

se conserva decisión

se ejecuta counterfactual

se etiqueta False Negative

frontend muestra el hallazgo
```

---

# 124. Prueba E2E de Market Perception

```text
WebSocket activo

features actualizadas

MarketState generado

frontend recibe estado

valores coinciden con backend
```

---

# 125. Prueba E2E de riesgo

```text
se genera oportunidad

risk engine calcula size

frontend muestra cálculo

orden paper utiliza mismo size

posición queda registrada
```

---

# 126. Prueba E2E de reconciliación

```text
estado interno

estado simulado exchange

provocar mismatch

detectar

mostrar alerta

bloquear acción si corresponde
```

---

# 127. Definition of Done general

Una feature relevante no está Done hasta cumplir cuando aplique:

```text
backend implementado

persistencia implementada

contratos definidos

observabilidad

manejo de errores

tests unitarios

tests integración

frontend implementado

estados loading

estados error

estado vacío

información explicativa

Playwright E2E

evidencia de prueba

documentación actualizada
```

---

# 128. Política especial para agentes de desarrollo

Los agentes no deben declarar un módulo como terminado únicamente porque:

```text
el código compila
```

o:

```text
pasaron unit tests
```

Si el módulo tiene impacto visible para usuario:

> debe existir frontend y debe probarse el flujo funcional completo.

Esto es especialmente importante porque agentes automáticos pueden crear:

```text
controller

service

repository

migration

tests
```

sin comprobar la experiencia completa.

---

# 129. Regla contra "backend terminado, frontend pendiente"

En features de negocio debe evitarse el patrón:

```text
Backend: Done

Frontend: someday
```

Las historias deben incluir frontend desde su definición.

---

# 130. Observabilidad

Cada componente nuevo debe exponer:

```text
logs

traces

metrics

health
```

utilizando la infraestructura existente:

```text
OpenTelemetry

Serilog

Health Checks
```

---

# 131. Correlation ID

Todo flujo importante debe permitir rastrear:

```text
frontend request
↓
Gateway
↓
Trading
↓
Worker
↓
Python
↓
Redis/PostgreSQL
```

con IDs correlacionados cuando aplique.

---

# 132. Auditoría

Cada decisión relevante debe ser explicable.

Ejemplos:

```text
¿Por qué DOGE no entró?

¿Por qué SOL pasó a Challenger?

¿Por qué BTC dejó Top?

¿Por qué no se ejecutó la señal?

¿Por qué se activó el circuit breaker?
```

Nunca debe existir como respuesta:

```text
porque el algoritmo lo decidió
```

---

# 133. Versionado

Versionar:

```text
StrategyVersion

SelectorVersion

ScoringVersion

FeatureVersion

MicrostructureVersion

RiskVersion
```

Esto permite reproducibilidad.

---

# 134. Configuración

Cada resultado debe guardar un snapshot de parámetros relevantes.

No depender únicamente de:

```text
config actual
```

porque puede haber cambiado.

---

# 135. Deuda técnica actual crítica

Debe conservarse explícitamente:

## DS-50

Fees/slippage todavía requieren calibración completa.

## DS-51

Cobertura parcial de tests.

## DS-67

Muestra insuficiente y win rate observado bajo.

## DS-69

Ausencia de ingesta continua realtime.

---

# 136. Nuevas deudas o épicas recomendadas

Deben crearse IDs formales para:

```text
Candidate Decision History

Candidate Lifecycle

Cheap Universe Scanner

Shadow Pool

Counterfactual Evaluator

Selection Metrics

Market Data Gateway

Trade Stream

Local Order Book

Feature Engine

Market State

Event Detection

Shadow Microstructure

Playwright coverage
```

Los IDs concretos deben asignarse conforme al esquema de deuda/épicas existente.

---

# 137. Machine Learning no es prioridad inmediata

Antes de ML deben existir:

```text
datos

labels

decisiones

errores

counterfactuals

versiones

histórico
```

Después podrá evaluarse:

```text
P(good candidate | features)
```

con información propia.

---

# 138. Evolución futura — Market Regime

Añadir:

```text
trending

mean reverting

high volatility

low volatility

transition
```

Trend Rider podría operar únicamente en regímenes compatibles.

---

# 139. Evolución futura — Mean Reversion

Será una estrategia independiente.

No debe mezclarse silenciosamente con Trend Rider.

---

# 140. Evolución futura — Correlaciones

Incluir:

```text
BTC ↔ ETH

BTC ↔ SOL

crypto ↔ Nasdaq

correlation clusters

cointegration
```

---

# 141. Evolución futura — Edge Decay

El sistema debe poder detectar:

```text
estrategia histórica antes buena
↓
expectancy reciente deteriorándose
```

No asumir que una ventaja es permanente.

---

# 142. Roadmap consolidado

```text
ETAPA 0
Fundamentos
✅

↓

ETAPA 1
Preparación de Pares
✅

↓

ETAPA 2
Histórico
✅

↓

ETAPA 3
Backtesting / Scoring
✅ con DS-67

↓

ETAPA 4
Re-scoring
Activación
Candidate Lifecycle
Challenger
Shadow
Reservoir

↓

ETAPA 5
Monte Carlo
Net Expectancy
Sortino

↓

ETAPA 6
REALTIME MARKET PERCEPTION

6.1 Market Data Gateway

6.2 Trade Stream

6.3 Order Book

6.4 Feature Engine

6.5 Multi-Timeframe State

6.6 Event Detection

6.7 Market State

6.8 Shadow Mode

6.9 Dataset experimental

6.10 Confirmation Engine

↓

ETAPA 7
RISK & EXECUTION

Sizing
Portfolio Risk
Exposure
Correlation
Stops
Slippage
Fees
Loss Limits
Circuit Breaker
Reconciliation

↓

ETAPA 8
PAPER TRADING

Trend Rider v1

vs

Trend Rider v1 + Microstructure

↓

ETAPA 9
USD 100 reales

↓

ETAPA 9+
Escalamiento validado
```

---

# 143. Roadmap paralelo de selección

En paralelo:

```text
Universe

↓

Cheap Scanner

↓

Candidate Lifecycle

↓

Decision History

↓

Shadow

↓

Counterfactual

↓

False Negative Detection

↓

Selection Metrics

↓

Selector Calibration

↓

Statistical Learning

↓

ML futuro
```

---

# 144. Roadmap paralelo de frontend

Cada una de las etapas anteriores debe incorporar simultáneamente:

```text
pantalla

UX

explicaciones

estados

auditoría

histórico

Playwright
```

Nunca debe existir:

```text
backend terminado
↓
frontend indefinidamente diferido
```

---

# 145. Resultado arquitectónico esperado

Cuando el sistema alcance madurez, la arquitectura lógica deberá verse así:

```text
                 BINANCE
                    │
        ┌───────────┴───────────┐
        │                       │
      REST                  WebSocket
        │                       │
        ▼                       ▼
 Cheap Universe Scanner     Market Data
        │                       │
        ▼                       ▼
 Candidate Lifecycle        Feature Engine
        │                       │
        │                       ▼
        │                  Market State
        │                       │
        └────────────┬──────────┘
                     │
                     ▼
               Trend Rider v1
                     │
                     ▼
             Confirmation Layer
                     │
                     ▼
                  Risk
                     │
                     ▼
                Execution
                     │
                     ▼
              Reconciliation
                     │
                     ▼
                 Outcome
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
Strategy Learning          Selection Learning
```

---

# 146. Resultado funcional esperado

El sistema debe ser capaz de explicar:

> BTC está en Top porque actualmente ocupa el ranking #3, tiene score 82.4, tendencia 4H compatible, spread adecuado y volatilidad dentro del rango esperado.

También:

> DOGE está en Shadow porque no superó el cutoff de liquidez. Sin embargo, su score aumentó 18 puntos durante tres evaluaciones consecutivas y actualmente se encuentra en exploración.

También:

> SOL fue descartado hace dos semanas. La evaluación contrafactual encontró que Trend Rider v1 habría producido cuatro operaciones válidas con expectancy neta positiva. Este evento fue clasificado como falso negativo del selector v1.2.

También:

> Trend Rider detectó LONG en BTC, pero Microstructure v0.1 lo habría rechazado debido a CVD descendente, agresión vendedora y desaparición de liquidez bid. El resultado se registra sólo en Shadow Mode y todavía no modifica la ejecución.

También:

> El Risk Engine rechazó la operación debido a que la exposición correlacionada BTC+ETH+SOL superaría el límite permitido.

Y todo ello debe poder consultarse visualmente.

---

# 147. Principio final de Trend Rider v1

Trend Rider v1 no debe convertirse en una acumulación indiscriminada de indicadores.

La arquitectura buscada es:

```text
SELECCIÓN
    ↓
encuentra dónde observar

4H
    ↓
encuentra oportunidad

1H
    ↓
contextualiza

15M
    ↓
estructura

5M
    ↓
confirma setup

ORDER FLOW
    ↓
observa comportamiento presente

MICROSTRUCTURE
    ↓
confirma o contradice

RISK
    ↓
autoriza

EXECUTION
    ↓
ejecuta

RECONCILIATION
    ↓
verifica

LEARNING
    ↓
evalúa aciertos y errores
```

---

# 148. Principio final del selector

La reducción:

```text
485
↓
55
```

no debe entenderse como:

```text
55 existen

430 desaparecen
```

Debe entenderse como:

```text
485 permanecen observables

55 reciben más cómputo

Top N recibe cómputo intensivo
```

El filtrado administra recursos.

No decide permanentemente qué mercados merecen existir para el sistema.

---

# 149. Principio final de aprendizaje

El sistema debe aprender tanto de:

```text
operaciones realizadas
```

como de:

```text
operaciones evitadas

candidatos seleccionados

candidatos rechazados

errores de ranking

falsos negativos

fallos técnicos

incidentes de ejecución
```

El objetivo es construir una plataforma capaz de decir:

> Me equivoqué.

y conservar evidencia de:

```text
cuándo

por qué

con qué versión

qué información tenía

qué información faltó

qué habría ocurrido

cómo puede probarse una mejora
```

---

# 150. Principio final de frontend

En PersonalCripto el frontend no es decoración.

Es parte del sistema de control.

Debe permitir a una persona no técnica:

```text
entender

consultar

verificar

comparar

detectar

auditar
```

todo lo relevante.

La ausencia de una vista funcional apropiada puede esconder durante semanas errores que un usuario detectaría inmediatamente mirando una pantalla.

Por eso:

> Un módulo funcionalmente observable no se considera terminado sin frontend adecuado y sin una prueba de extremo a extremo que demuestre su funcionamiento.

Playwright debe utilizarse sistemáticamente para verificar los flujos críticos.

---

# 151. Regla de cierre

Ninguna etapa debe avanzar porque:

```text
"parece funcionar"
```

Debe avanzar porque existe:

```text
evidencia

métricas

pruebas

observabilidad

auditoría

validación frontend

resultado reproducible
```

La meta de Trend Rider v1 no es construir rápidamente un bot que coloque órdenes.

La meta es construir un sistema que pueda demostrar:

```text
qué sabe

qué cree

qué desconoce

qué decidió

por qué decidió

cuánto arriesgó

qué ocurrió

si se equivocó

y cómo aprender de ello
```

Ese es el criterio de madurez de la plataforma.