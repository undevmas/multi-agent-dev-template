# SKILL — Humanizer

## Cuándo usar esta skill
Al generar texto que usuarios finales van a leer directamente:
- Mensajes de error en la UI
- Emails de notificación
- Textos de empty states, confirmaciones, tooltips
- Documentación de usuario final
- Comentarios de código en español que otros devs van a leer
- Cualquier texto visible en la aplicación

NO usar para: código fuente, logs del sistema, documentación técnica interna.

---

## El problema que resuelve

El texto generado por IA tiene patrones reconocibles que suenan artificiales:
- Frases demasiado formales o corporativas
- Estructura repetitiva y predecible
- Palabras de relleno sin valor
- Tono uniforme sin variación natural
- Oraciones perfectamente balanceadas que nadie escribe así

---

## Señales de texto AI que eliminar

### Palabras y frases de relleno
```
Evitar:
- "En el contexto de..."
- "Es importante destacar que..."
- "Cabe mencionar que..."
- "En conclusión..."
- "Por supuesto"
- "Ciertamente"
- "Sin duda alguna"
- "En primer lugar... En segundo lugar..."
- "Como se puede observar..."
- "Es fundamental tener en cuenta..."
- "Asegúrese de..."
- "Tenga en cuenta que..."
```

### Estructura demasiado perfecta
```
AI: "El sistema realiza tres operaciones principales:
     primero valida los datos, luego los procesa,
     y finalmente los almacena."

Humano: "Valida, procesa y guarda. Si algo falla en cualquier paso, verás el error."
```

### Formalidad excesiva
```
AI: "Se ha producido un error durante el procesamiento
     de su solicitud. Por favor, inténtelo de nuevo."

Humano: "Algo salió mal. Intenta de nuevo."
```

---

## Técnicas de humanización

### 1. Variar longitud de oraciones
```
AI (uniforme):
"El proceso de login verifica tus credenciales. El sistema valida
el formato del correo. Después comprueba la contraseña. Finalmente
genera un token de acceso."

Humanizado (variado):
"El login verifica tus credenciales. Primero el formato del correo,
luego la contraseña — si todo cuadra, genera tu token y entras."
```

### 2. Contracciones y lenguaje natural
```
AI: "No es posible completar la operación en este momento."
Humano: "No pudimos completarlo ahora. Intenta en unos minutos."

AI: "El archivo no fue encontrado en el sistema."
Humano: "No encontramos ese archivo."
```

### 3. Voz activa sobre pasiva
```
Pasiva (AI): "El formulario fue enviado correctamente."
Activa: "Enviamos tu formulario."

Pasiva: "Los datos han sido guardados exitosamente."
Activa: "Tus datos están guardados."
```

### 4. Specificity — ser concreto
```
Genérico (AI): "Ocurrió un error con los datos ingresados."
Específico: "El correo no tiene formato válido."

Genérico: "La operación no pudo completarse."
Específico: "No pudimos conectarnos al servidor. Revisa tu internet."
```

### 5. Empatía sin exagerar
```
Frío (AI): "Se ha producido un error. Contacte al soporte."
Con empatía: "Algo no salió bien. Si el problema continúa, escríbenos."

Exagerado (también AI): "¡Lo sentimos muchísimo! Esto no debería haber ocurrido."
Equilibrado: "Algo falló de nuestro lado. Ya lo estamos revisando."
```

---

## Mensajes de UI — ejemplos antes/después

### Mensajes de error
```
Antes: "Se ha producido un error durante el procesamiento de la solicitud."
Después: "Algo salió mal. Intenta de nuevo."

Antes: "Los campos obligatorios no han sido completados correctamente."
Después: "Faltan algunos datos requeridos."

Antes: "No se ha podido establecer conexión con el servidor."
Después: "Sin conexión con el servidor. Verifica tu red."

Antes: "Las credenciales proporcionadas son incorrectas."
Después: "Correo o contraseña incorrectos."

Antes: "Su sesión ha expirado. Por favor, inicie sesión nuevamente."
Después: "Tu sesión expiró. Inicia sesión de nuevo."
```

### Empty states
```
Antes: "No se encontraron registros que coincidan con los criterios de búsqueda."
Después: "No encontramos resultados para esa búsqueda."

Antes: "No existen contratos registrados en el sistema actualmente."
Después: "Todavía no hay contratos. Crea el primero."

Antes: "La lista de usuarios está vacía en este momento."
Después: "Aún no hay usuarios aquí."
```

### Confirmaciones de éxito
```
Antes: "La operación ha sido completada exitosamente."
Después: "Listo."

Antes: "Los cambios han sido guardados correctamente en el sistema."
Después: "Cambios guardados."

Antes: "El registro ha sido eliminado de forma permanente."
Después: "Eliminado."

Antes: "Su contraseña ha sido actualizada satisfactoriamente."
Después: "Contraseña actualizada."
```

### Confirmaciones de acción destructiva
```
Antes: "¿Está usted seguro de que desea eliminar este registro?
        Esta acción no puede ser revertida."
Después: "¿Eliminar este contrato? No podrás recuperarlo."

Antes: "¿Confirma que desea proceder con la eliminación del usuario?"
Después: "¿Seguro que quieres eliminar a este usuario?"
```

### Emails de notificación
```
Antes: "Estimado usuario, le informamos que se ha realizado un cambio
        en su cuenta. Si usted no realizó esta acción, por favor
        contacte a nuestro equipo de soporte."

Después: "Hubo un cambio en tu cuenta. Si no fuiste tú, escríbenos."

Antes: "Su solicitud ha sido recibida y se encuentra en proceso
        de revisión por parte de nuestro equipo."
Después: "Recibimos tu solicitud. La revisamos en breve."
```

---

## Tono por contexto

### Aplicación empresarial / B2B (este proyecto)
- Directo y profesional, no frío
- Sin jerga ni tecnicismos para el usuario final
- Conciso — los usuarios están trabajando, no leyendo
- Ejemplos: "Guardado", "Sin acceso", "Revisa los datos"

### Diferencia entre directo y grosero
```
Grosero: "Contraseña incorrecta. Inténtalo bien."
Directo: "Contraseña incorrecta."
Con contexto útil: "Contraseña incorrecta. Te quedan 3 intentos."
```

---

## Checklist antes de usar texto en UI

- [ ] ¿Usa voz activa? ("Guardamos" vs "fue guardado")
- [ ] ¿Es concreto? ("El correo no es válido" vs "Error en los datos")
- [ ] ¿Dice qué pasó Y qué puede hacer el usuario?
- [ ] ¿Tiene palabras de relleno que se pueden eliminar?
- [ ] ¿Suena como algo que un humano real diría?
- [ ] ¿Es apropiado para el contexto (error, éxito, advertencia)?
- [ ] ¿Tiene la longitud correcta? (mensajes cortos para toasts, más contexto para modales)

---

## Longitud recomendada por tipo de mensaje

- Toast de éxito: 1-5 palabras ("Guardado", "Contraseña actualizada")
- Toast de error: 5-10 palabras ("No pudimos guardar. Intenta de nuevo.")
- Empty state: 10-20 palabras con CTA
- Modal de confirmación: 15-30 palabras
- Email de notificación: 2-4 oraciones cortas
- Mensaje de error detallado: máximo 3 oraciones
