# Deuda Técnica del Proyecto

> Inventario de código existente que no sigue las convenciones del template.
> Este archivo NO es un tracker de bugs ni de features pendientes — eso va en `progreso.md`.
> Es un registro de decisiones técnicas que deben evolucionar, con su impacto real documentado.
>
> El código nuevo **nunca replica** los antipatrones listados aquí aunque esté en el mismo módulo.
> Cada entrada tiene una condición de salida clara — sin eso, no es deuda, es queja.

---

## Cómo usar este archivo

**Quién lo escribe:** El agente spec al inspeccionar código existente, o el agente de implementación
al detectar un antipatrón en zona ámbar/roja.

**Quién decide cuándo atacarla:** El dev o el equipo — no el agente.

**El agente consulta este archivo:** Al iniciar sesión si la tarea involucra módulos con deuda registrada.

---

## Entradas de deuda

<!-- Copiar este bloque por cada entrada nueva -->

<!--
### [Módulo] — [descripción corta del problema]

**Detectado:** [fecha]
**Detectado por:** [agente spec | agente implementación | dev]
**Estado:** pendiente | en progreso | resuelto

**Descripción:**
[Qué antipatrón existe y en qué archivos específicos vive.]

**Ubicación:**
- `Codigo/[ruta/al/archivo]`

**Impacto en desarrollo nuevo:**
[Cómo afecta o puede afectar a las features que se construyan sobre o cerca de este módulo.]

**Riesgo si se deja:**
[bajo | medio | alto] — [razón concreta, no genérica]

**Política aplicada:**
El código nuevo en este módulo sigue convenciones del template.
El código existente no se modifica sin ticket explícito.

**Condición de salida:**
[Qué ticket, sprint o decisión cierra esta entrada. Sin condición de salida, no agregar.]

---
-->

<!-- Si el proyecto es nuevo o no tiene deuda conocida, dejar este archivo vacío.
     El agente lo completará si detecta algo al inspeccionar el código. -->
