# Deuda Técnica del Proyecto

> Antipatrones reales detectados en código existente. El código nuevo debe respetar `convenciones.md`.

## Entradas de deuda

### Identity — respuestas HTTP crudas fuera de ApiResponse

**Detectado:** 2026-09-04
**Detectado por:** agente de inspección
**Estado:** pendiente

**Descripción:**
Varias ramas de controllers de Identity retornan directamente `BadRequest()`, `Forbid()`, `Unauthorized()` o `NotFound()` sin el envelope `{ success, data, error, traceId }`. Esto crea cuerpos vacíos o formatos dependientes de ASP.NET Core en un API que por convención usa `ApiResponse`.

**Ubicación:**
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/Tenants/TenantsController.cs`
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/TenantUsers/TenantUsersController.cs`
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/Invitations/InvitationsController.cs`
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/TenantMemberships/TenantMembershipsController.cs`
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/TenantProvisioning/TenantProvisioningController.cs`
- `Codigo/personal-cripto/src/Identity/Modules/Identity/Application/Features/Tokens/TokenController.cs`

**Impacto en desarrollo nuevo:**
Los clientes deben manejar dos contratos de error y pueden perder `code`, mensajes localizados y `traceId`.

**Riesgo si se deja:** medio — inconsistencia observable y diagnóstico más difícil.

**Política aplicada:**
El código nuevo debe usar `ApiResponse.Fail`; el código existente no se modifica sin ticket explícito.

**Condición de salida:**
Ticket de normalización de respuestas de Identity con pruebas de contrato para 400/401/403/404/204.

### DS-50 — Costos de trading sin calibración final

**Detectado:** 2026-09-04  
**Detectado por:** `Insumos/plan-trade.md` y revisión del agente spec  
**Estado:** pendiente; bloquea paper/live, no bloquea desarrollo aislado

**Descripción:**
Las comisiones y el slippage del backtesting permanecen como supuestos pendientes de calibración. El plan exige además spread y funding cuando apliquen, pero no define una fuente/versionado de costos aprobado.

**Ubicación:**
Motor de backtesting `jmh_trading`, no incluido en el workspace actual.

**Impacto en desarrollo nuevo:**
Impide fijar net expectancy y decidir si una estrategia puede pasar a paper trading o capital real.

**Riesgo si se deja:** alto — una ventaja bruta aparente puede ser negativa después de costos.

**Política aplicada:**
Los contratos nuevos deben soportar costos versionados y marcar valores no calibrados; no se inventarán defaults de producción.

**Condición de salida:**
Fuente, fecha, mercado y valores de fees/spread/slippage/funding documentados; backtest y motor de ejecución usan la misma versión.

### DS-67 — Muestra insuficiente y win rate bajo el punto de equilibrio

**Detectado:** 2026-09-04  
**Detectado por:** `Insumos/plan-trade.md` y revisión del agente spec  
**Estado:** abierto

**Descripción:**
La única muestra real reportada tiene 14 operaciones y win rate de 21.4%, por debajo del punto de equilibrio aproximado de 37.5% para TP=2.5×ATR y SL=1.5×ATR.

**Ubicación:**
Resultados del backtesting de Etapa 3; fuente Python no incluida en el workspace actual.

**Impacto en desarrollo nuevo:**
El score no puede interpretarse como autorización para operar. Etapas 5 y 8 deben medir incertidumbre y confirmar/refutar la ventaja.

**Riesgo si se deja:** crítico para capital real — el sistema puede carecer de expectancy positiva.

**Política aplicada:**
`EnTop` y score son indicadores analíticos, nunca permisos de ejecución.

**Condición de salida:**
Paper trading con muestra y umbrales estadísticos aprobados, net expectancy positivo y drawdown dentro del límite acordado.

### DS-69 — Datos no frescos entre re-scoring semanales

**Detectado:** 2026-09-04  
**Detectado por:** `Insumos/plan-trade.md` y revisión del agente spec  
**Estado:** abierto

**Descripción:**
Los pares Top N no tienen ingesta continua; entre jobs semanales las decisiones potenciales usarían datos con hasta siete días de antigüedad.

**Ubicación:**
Etapa 6 aún no implementada; no se encontró consumidor WebSocket de mercado en Trading/Worker.

**Impacto en desarrollo nuevo:**
Bloquea señales en vivo, paper trading y ejecución.

**Riesgo si se deja:** crítico — decisiones basadas en mercado obsoleto.

**Política aplicada:**
El sistema debe operar fail-closed cuando no cumpla el umbral de freshness.

**Condición de salida:**
Etapa 6 implementada con reconexión, verificación de continuidad, freshness observable y pruebas de recuperación.

### DS-70 — Specs históricas referenciadas pero ausentes

**Detectado:** 2026-09-04  
**Detectado por:** agente spec al analizar `trading-roadmap-epic`  
**Estado:** pendiente

**Descripción:**
El código y el plan citan specs como `job-semanal-rescoring` y `alta-par-activacion-vigilancia`, pero `Features/` solo contiene `README.md` antes de crear el Epic actual. Se perdió o no se incorporó la trazabilidad de requisitos, decisiones y checks de las Etapas 1–4.

**Ubicación:**
`Features/`; referencias distribuidas en Trading, Worker y sus tests.

**Impacto en desarrollo nuevo:**
Dificulta distinguir contratos aprobados de comentarios de implementación y aumenta el riesgo de reespecificar o romper reglas previas.

**Riesgo si se deja:** medio — deriva contractual y verificación incompleta del cierre de Etapa 4.

**Política aplicada:**
No se declararán completas las partes no verificables ni se falsificará el contenido de las specs ausentes.

**Condición de salida:**
Recuperar los artefactos originales o confirmar que deben reconstruirse desde el código y los respaldos disponibles.
