# SKILL — UI/UX Pro Max

## Cuándo usar esta skill
Al diseñar cualquier interfaz de usuario que requiera decisiones de UX avanzadas:
formularios complejos, flujos multi-paso, dashboards, tablas de datos,
estados de carga, mensajes de error, o cualquier pantalla crítica para el negocio.

Complementa SKILL-frontend-design.md (estética) — esta skill se enfoca en comportamiento,
flujo y experiencia del usuario.

---

## Principios fundamentales

### Jerarquía de decisiones UX
1. ¿El usuario puede completar su tarea sin fricción?
2. ¿El sistema comunica claramente qué está pasando?
3. ¿Los errores son recuperables y comprensibles?
4. ¿La interfaz previene errores antes de que ocurran?

### Feedback y tiempos de respuesta
- Menos de 100ms: sin indicador, se siente instantáneo
- 100ms a 1s: sin indicador si es posible
- 1s a 3s: spinner o skeleton screen
- Más de 3s: barra de progreso con mensaje descriptivo
- Más de 10s: progreso con opción de cancelar

---

## Los 4 estados obligatorios

Todo componente que cargue o muestre datos DEBE manejar explícitamente:

### 1. Loading
- Preferir skeleton screen sobre spinner genérico
- Skeleton debe imitar la forma del contenido real
- Nunca pantalla en blanco mientras carga

Angular skeleton pattern:
```html
<div *ngIf="loading" class="skeleton-wrapper">
  <div class="skeleton skeleton--title"></div>
  <div class="skeleton skeleton--line"></div>
  <div class="skeleton skeleton--line skeleton--short"></div>
</div>
```

### 2. Empty state
- Nunca dejar vacío sin mensaje
- Incluir: ícono contextual + título + descripción + CTA
- El CTA debe llevar al usuario a crear su primer registro

Estructura recomendada:
```
[Ícono contextual]
No hay [entidades] todavía
Crea tu primera [entidad] para comenzar
[Botón: Crear [entidad]]
```

### 3. Error state
- Lenguaje humano, nunca códigos técnicos
- Estructura: Qué pasó + Por qué + Qué puede hacer
- Siempre incluir botón de retry o acción alternativa

Ejemplos:
- "Error 500" → "No pudimos cargar la información. Intenta de nuevo."
- "Network error" → "Sin conexión. Verifica tu internet."
- "Validation failed" → "El correo no es válido."
- "Unauthorized 401" → "Tu sesión expiró. Inicia sesión nuevamente."

### 4. Success state
- Confirmación visible antes de redirigir
- Toast verde, 3 segundos, luego redirect
- Nunca silencio después de una acción importante

---

## Formularios — reglas avanzadas

### Validación
- Validar en blur (al salir del campo), NO en cada keystroke
- Nunca mostrar errores antes de que el usuario toque el campo
- Error message: ícono + texto descriptivo + color rojo bajo el campo
- Resaltar campo con border-color rojo, no solo el mensaje

### Prevención de pérdida de datos
- Confirmar antes de navegar si hay cambios sin guardar
- Guard de Angular para formularios sucios:

```typescript
canDeactivate(): Observable<boolean> | boolean {
  if (this.form.dirty) {
    return this.dialog.confirm('¿Salir sin guardar los cambios?');
  }
  return true;
}
```

### Submit y doble envío
- Deshabilitar botón durante submit
- Mostrar spinner dentro del botón (no reemplazar el texto)
- Re-habilitar solo en error (en éxito ya redirigió)

```html
<button [disabled]="isSubmitting">
  <span *ngIf="!isSubmitting">Guardar</span>
  <span *ngIf="isSubmitting">Guardando...</span>
</button>
```

### Acciones destructivas
- Siempre confirmar con modal (nunca window.confirm)
- Botón de confirmar describe la acción: "Sí, eliminar" (no "Aceptar")
- Color rojo en el botón de confirmar
- Considerar acción de "Deshacer" como alternativa más amigable

---

## Tablas de datos — patrones enterprise

### Paginación
- Server-side para más de 100 registros
- Mostrar: "[n] de [total] registros"
- Opciones de page size: 10, 20, 50, 100

### Filtros
- Persistir filtros en URL query params (poder compartir/bookmarkear)
- Indicador visual de filtros activos
- Botón "Limpiar filtros" visible cuando hay filtros activos

### Búsqueda
- Debounce de 300ms (no buscar en cada keystroke)
- Mínimo 2 caracteres antes de buscar
- Indicador "buscando..." mientras espera respuesta

### Selección múltiple
- Barra de acciones aparece al seleccionar registros
- Mostrar: "[n] registros seleccionados [Acción] [✕ Limpiar]"
- Checkbox en header selecciona/deselecciona todos
- Confirmar si la acción en lote es destructiva

### Columnas ordenables
- Ícono de flecha indica columna activa y dirección
- Click en columna activa invierte el orden
- Persistir orden en URL cuando sea posible

---

## Flujos de aprobación / workflow

### Indicadores de progreso
- Stepper horizontal para 5 pasos o menos
- Stepper vertical para más de 5 pasos o con descripciones largas
- Estados: completado (check verde) / activo (resaltado) / pendiente (gris)

### Historial de cambios
- Registrar: quién, cuándo, desde qué estado, hacia qué estado
- Mostrar en panel lateral o tab "Historial"
- Formato: "Juan García aprobó el 15/05/2025 a las 10:23"

### Notificaciones
- Notificar al responsable del siguiente paso
- Incluir link directo al registro en la notificación
- No depender de que el usuario recuerde revisar manualmente

---

## Mensajes de sistema (toasts)

- Éxito: verde, desaparece en 3s
- Error: rojo, persiste hasta cierre manual
- Advertencia: amarillo, desaparece en 5s
- Info: azul, desaparece en 4s
- Máximo 3 toasts simultáneos (apilar, no superponer)

---

## Navegación y orientación

### Breadcrumbs
- Obligatorios en estructuras de más de 2 niveles
- Último elemento no es link (es la página actual)
- Formato: Inicio > Módulo > Submodulo > Página actual

---

## Accesibilidad mínima (no negociable)

- Todo input tiene label asociado (no solo placeholder)
- Contraste mínimo AA: 4.5:1 texto normal, 3:1 texto grande
- Navegación completa con teclado (Tab, Enter, Escape, flechas)
- Imágenes decorativas: alt=""
- Imágenes informativas: alt descriptivo
- Mensajes de error: aria-live="polite" para lectores de pantalla
- Modales: focus trap mientras están abiertos

---

## Patrones de login (específico para este proyecto)

- Recordar último email en localStorage (nunca la contraseña)
- Mensaje diferenciado: "Usuario no existe" vs "Contraseña incorrecta"
- Contador visible de intentos restantes: "Te quedan [n] intentos"
- Bloqueo temporal con cuenta regresiva: "Intenta en 14:32"
- Link "¿Olvidaste tu contraseña?" visible desde el inicio, no solo después de error
