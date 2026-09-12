# Progreso del Proyecto

> Snapshot verificado el 2026-09-04.

## Estado actual

Monorepo existente `Codigo/personal-cripto/` con backend .NET 10, frontend Angular 22, Aspire, persistencia EF Core y módulos funcionales de Identity, Catálogo, Trading y Worker. Business y Reportes permanecen como scaffolding parcial.

**Última actualización:** 2026-09-04
**Iteración / Sprint:** [COMPLETAR]
**Prioridad actual:** [COMPLETAR]

## Completado ✅

- [x] Gateway YARP con routing, JWT, rate limiting, blocklist IP, API key opcional, resiliencia y manejo global de excepciones.
- [x] Identity: usuarios, login, refresh/revocación de tokens, tenants, membresías, roles/permisos, invitaciones, auditoría, MFA TOTP/email/WebAuthn y SSO.
- [x] Catálogo: módulo Productos con listar, obtener, crear, actualizar y desactivar/eliminar mediante infraestructura de soft delete.
- [x] Trading: registro/listado/detalle/estado de pares, endpoints internos y preparación/calibración de pares.
- [x] Worker: persistencia de jobs, Quartz, consulta/administración y jobs de trading configurados.
- [x] Frontend Angular: autenticación, administración, pares, preparación de pares, provisioning, layout, permisos, tenant context, PWA y componentes compartidos.
- [x] Librerías compartidas: Domain, Contracts, Dtos, Data, Cache, Mail, Messaging, Security, Secrets, Resilience y Observability.
- [x] Migraciones EF Core para Identity, Catalogo, Trading y Worker.
- [x] Tests de Gateway, Trading y Worker presentes.

## En progreso 🔄

- [ ] Etapa 4 de Trading — cierre de `job-semanal-rescoring` y `alta-par-activacion-vigilancia`. El disparador Quartz y `EnTop` existen; falta verificar el flujo Python de punta a punta y propagar `score_provisional`/`muestra_insuficiente` en contratos y UI.

## Pendiente 📋

1. [ ] Confirmar la descomposición de `Features/trading-roadmap-epic.md` para generar las specs hijas de las Etapas 4–9+.
2. [ ] Etapa 5 de Trading — cuantificación de riesgo con Monte Carlo, net expectancy y evaluación de Sortino; puede avanzar en paralelo al cierre de Etapa 4.
3. [ ] Etapas 6–9+ de Trading — vigilancia en vivo, riesgo/ejecución, paper trading, piloto de $100 y escalamiento, sujetos a las compuertas del Epic.
4. [ ] Implementar endpoints y casos de uso reales de Reportes.
5. [ ] Reemplazar el scaffold WeatherForecast de Business por su módulo de negocio.
6. [ ] Resolver las ramas de Identity que devuelven respuestas HTTP crudas en lugar de `ApiResponse`.
7. [ ] Definir y documentar el puerto de `ng serve` si debe ser fijo para el entorno local.

## Bloqueado ⛔

| Tarea | Bloqueado por | Desde | Acción requerida |
|---|---|---|---|
| — | — | — | — |

## Decisiones técnicas tomadas

| Fecha | Decisión | Razón |
|---|---|---|
| 2026-09-04 | Mantener .NET 10, Angular 22, Aspire y Vitest | Compatibilidad verificada de PersonalCripto |
| 2026-09-04 | Usar GUID para IDs y soft delete mediante `IsDeleted`/`IsActive` e interceptor | Consistencia multi-tenant y preservación de historial |
| 2026-09-04 | Usar PostgreSQL como persistencia principal con SQL Server alternativo en Identity | Providers configurados en los módulos existentes |

## Próximos pasos

1. Confirmar las tres decisiones abiertas en `Features/trading-roadmap-epic.md`.
2. Generar primero las specs hijas de cierre de Etapa 4 y validación estadística de Etapa 5; pueden atenderse en paralelo.
3. Mantener Etapas 8, 9 y 9+ bloqueadas hasta cumplir sus compuertas de evidencia y seguridad.
4. Implementar o especificar Reportes y Business cuando la prioridad del sprint lo permita.
5. Abrir ticket para normalizar las respuestas crudas de Identity.
