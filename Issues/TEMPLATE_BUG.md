# TEMPLATE_BUG — Plantilla para reportar issues

> Copiar este archivo, renombrarlo como `bugs_[modulo]_[descripcion].md`
> y completar todos los campos.

---

# Bug: [Título descriptivo del problema]

**Módulo:** [login | catalogos | tickets | contratos | usuarios | otro]
**Severidad:** 🔴 Crítico | 🟠 Alto | 🟡 Medio | 🟢 Bajo
**Estado:** 🔄 Abierto | 🔨 En solución | ✅ Resuelto | ⏸ En pausa
**Reportado por:** [nombre o iniciales]
**Fecha reporte:** [YYYY-MM-DD]
**Fecha resolución:** [YYYY-MM-DD o —]

---

## Descripción
[Qué está pasando. Ser específico y concreto.]

## Pasos para reproducir
1. Ir a [pantalla/URL]
2. Hacer [acción específica]
3. Observar [qué pasa]

## Comportamiento esperado
[Qué debería ocurrir según las especificaciones]

## Comportamiento actual
[Qué está ocurriendo realmente]

## Evidencia
[Screenshots, videos, URLs afectadas — agregar archivos en Issues/ si es posible]

## Contexto técnico

- Entorno: [ ] Dev  [ ] Staging  [ ] Producción
- Browser y versión: [Chrome 120 / Edge 121 / etc.]
- Sistema operativo: [Windows 11 / macOS / etc.]

### Log de error (si aplica)
```
[Pegar el error exacto aquí — del browser console, del backend log, etc.]
```

---

## Análisis de causa raíz
[Completar al resolver: dónde estaba el problema]

## Solución aplicada
[Completar al resolver: qué se hizo exactamente]

## Archivos modificados
- `ruta/al/archivo.ts` — [descripción del cambio]
- `ruta/al/archivo.cs` — [descripción del cambio]

## Cómo verificar la solución
[Pasos para confirmar que el bug está resuelto]
