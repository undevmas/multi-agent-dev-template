# SKILL — Baseline de Seguridad para Stack Legado (fuera de la tabla aprobada)

## Cuándo usar esta skill

Cuando la tarea requiere tocar código de un proyecto cuyo stack **no está**
en la tabla aprobada del template (Angular/React + .NET/NestJS +
SQL Server/PostgreSQL) — típicamente código heredado de un cliente que se
está auditando o manteniendo, no construyendo desde cero.

**Esta skill NO es una guía de modernización.** No propone migrar el
módulo al stack aprobado ni reescribir nada. Da la guía de seguridad
mínima para tocar con criterio un stack que ninguna otra skill del
template cubre — igual que un cirujano que opera con lo que hay, no
reconstruye el hospital primero.

Si la tarea es "modernizar/migrar X", esa es una conversación aparte con
el equipo, no algo que se decide leyendo esta skill.

---

## Regla de aplicación — igual para cualquier stack legado nuevo que aparezca

1. Identificar el stack real (no asumir que es el aprobado)
2. Buscar si existe una sección específica más abajo para ese stack
3. Si no existe sección específica: aplicar los principios genéricos de la
   sección "Principios universales" y documentar en
   `IA_Memoria/convenciones.md` que este proyecto usa un stack fuera de
   tabla, para que la próxima tarea no vuelva a descubrirlo desde cero
4. Todo fix sigue `SKILL-risk-zone-policy.md` — en stack legado, por
   default, inclinarse hacia zona ámbar salvo que el fix sea trivialmente
   acotado (zona verde solo si es código genuinamente nuevo)

---

## Principios universales (aplican a cualquier stack legado, no solo a los casos documentados abajo)

- **XSS**: cualquier motor de templates que permita "unescape explícito"
  (EJS `<%- %>`, Handlebars triple-stache `{{{ }}}`, PHP `echo` sin
  `htmlspecialchars`) — si el dato interpolado viene de usuario, escapar
  siempre salvo que exista una razón documentada para no hacerlo (ej. HTML
  ya sanitizado por una librería como DOMPurify antes de llegar ahí).
- **CSRF**: si el framework no trae protección CSRF integrada por default
  (a diferencia de Angular/NestJS con sus guards), verificar si el
  endpoint tocado es state-changing (POST/PUT/DELETE) y agregar protección
  puntual (token CSRF o verificación de origen) sin tocar el resto de la
  app.
- **Inyección SQL en ORMs legados**: confirmar que el ORM usa parámetros
  bindeados en cualquier query cruda (`raw()`, `query()`) — un ORM legado
  no garantiza esto por default en todas sus APIs, a diferencia de
  Entity Framework o TypeORM con query builder.
- **Sesiones/cookies**: verificar `httpOnly`, `secure`, `sameSite` en
  cualquier cookie de sesión del framework legado — estos flags no
  siempre son el default histórico.

---

## Caso documentado: Express + EJS + Sequelize

Primer stack legado real auditado en este template (ReporteadorV2 tiene
Python/FastAPI aprobado aparte — esto es distinto, es un proyecto Node
heredado de cliente).

### XSS reflejado — construcción manual de HTML en el controller

```javascript
// MAL — hallazgo típico en controllers legados
res.send('<div>Bienvenido ' + req.body.nombre + '</div>');

// BIEN — usar el motor de templates (que si se usa bien, ya escapa),
// o si de verdad se necesita construir el string, escapar explícito
const escapeHtml = (str) => String(str)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

res.send('<div>Bienvenido ' + escapeHtml(req.body.nombre) + '</div>');
```

Zona ámbar: escapar exactamente las líneas del hallazgo (ej.
`usuariosController.js:150,277,301,593`), no refactorizar el controller
completo para "hacerlo bien" — eso sería zona roja sin ticket.

### XSS en vistas EJS — `<%- %>` (unescape explícito)

```ejs
<!-- MAL — inicio.ejs:16, inicioValidador.ejs:44 -->
<div><%- usuario.nombre %></div>

<!-- BIEN — <%= %> escapa por default en EJS -->
<div><%= usuario.nombre %></div>
```

Cambiar `<%-` por `<%=` es zona ámbar casi siempre — **excepto** si esa
línea depende de que el HTML no se escape a propósito (ej. renderiza un
fragmento de HTML ya generado por el propio backend, no input directo de
usuario). Confirmar el origen del dato antes de cambiar el tag — si viene
de `req.body`/`req.query`/`req.params` sin sanitizar, es un hallazgo real,
no un falso positivo.

### CSRF ausente en `app.js`

```javascript
// Express no trae CSRF por default (a diferencia de NestJS/Angular)
const csrf = require('csurf');
app.use(csrf({ cookie: true }));

// En la vista EJS, incluir el token en cada form state-changing
// <input type="hidden" name="_csrf" value="<%= csrfToken %>">
```

Agregar el middleware es zona ámbar si el endpoint tocado en la tarea es
state-changing y no tenía ninguna protección — **no** agregarlo
globalmente a `app.js:17` para toda la app de una sola vez si eso no es
parte del alcance de la tarea; eso empieza a acercarse a zona roja porque
puede romper forms existentes que no envían el token.

### Sequelize — queries crudas

```javascript
// MAL — concatenación directa
sequelize.query(`SELECT * FROM usuarios WHERE email = '${email}'`);

// BIEN — bind parameters
sequelize.query('SELECT * FROM usuarios WHERE email = :email', {
  replacements: { email },
  type: QueryTypes.SELECT,
});
```

---

## Checklist antes de cerrar una tarea sobre stack legado

- [ ] El stack real quedó documentado en `IA_Memoria/convenciones.md` (si no lo estaba ya)
- [ ] El fix aplicado corresponde a la zona correcta según `SKILL-risk-zone-policy.md` — nunca se asumió "es legado, da igual, lo arreglo todo"
- [ ] Ningún fix se convirtió en refactor/modernización no solicitada
- [ ] Los hallazgos fuera del alcance de la tarea quedaron en `IA_Memoria/deuda-tecnica.md`, no ignorados
- [ ] Si el stack no tiene sección documentada aquí, se aplicaron los "Principios universales" y se anotó el gap para agregar el caso a esta skill después
