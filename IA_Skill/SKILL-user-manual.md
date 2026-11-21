# SKILL — Manual de Usuario

## Cuándo usar esta skill

Cuando el usuario pida "manual de usuario", "guía de usuario", "instructivo", "manual operativo",
"material de capacitación" o "cómo se usa el sistema" para entregar a usuarios finales o a un
cliente. Produce un `.docx` institucional con capturas de pantalla **reales** del sistema.

| Necesidad | Skill |
|---|---|
| Explicar al **usuario final** cómo operar el sistema (pantallas, pasos, mensajes) | Esta skill |
| Describir al cliente o auditor **cómo está construido** el sistema (arquitectura, stack, datos) | `IA_Skill/SKILL-technical-memory.md` |
| Documentar para el **equipo de desarrollo** una feature recién terminada | `IA_Skill/SKILL-docs-feature.md` |

Precedencia: `AGENTS.md` > `IA_Memoria/convenciones.md` > skills propias. La tarea termina en
`in-review`: el dev revisa y aprueba el manual. El entregable vive en `Entregables/` y nunca va al
repositorio de código del proyecto.

---

## Fuentes (en este orden)

| Prioridad | Fuente | Extrae |
|---|---|---|
| 1 | La aplicación corriendo (local o QA) | Pantallas, textos exactos de botones, campos y mensajes |
| 2 | `Features/<mod>.md`, `.spec.md`, `.checks.md` | Historias de usuario, roles, reglas y mensajes esperados |
| 3 | `tests/e2e/` | Guion de los flujos reales que ya se validan |
| 4 | `Insumos/` (manual previo, mockups) | Terminología del cliente y estructura heredada |
| 5 | `IA_Memoria/arquitectura.md` | Roles, URL de acceso de QA, comandos para levantar la app |

La app manda: si una spec dice "Guardar" y la pantalla dice "Registrar", el manual usa
**Registrar** y se reporta la diferencia al dev.

---

## Flujo

1. **Leer las fuentes** de la tabla anterior. No redactar sin haber visto la pantalla real.
2. **Inventario por rol**: armar la tabla rol → tareas que el manual va a cubrir.

   | Rol | Tareas |
   |---|---|
   | Capturista | Registrar contrato, consultar contratos |
   | Supervisor | Aprobar contrato, generar reporte |

3. **Datos de portada**: si faltan organización, elaboró o clasificación, preguntar al usuario
   **antes** de generar (igual que la memoria técnica). La clasificación por defecto es "Uso Interno".
4. **Guion de capturas**: por cada tarea, definir paso → captura → pie de figura. Escribir o
   actualizar los specs `tests/evidencias/<modulo>.capture.ts` con el helper `capturar()` y
   correrlos. Cómo escribir los specs: `IA_Skill/SKILL-visual-evidence.md` (no se duplica aquí).

   ```powershell
   $env:EVIDENCIAS_DIR='Entregables/<Proyecto>/evidencias'; $env:EVIDENCIAS_REPO='Codigo/<proyecto>'; npm run evidencias
   ```
   ```bash
   EVIDENCIAS_DIR=Entregables/<Proyecto>/evidencias EVIDENCIAS_REPO=Codigo/<proyecto> npm run evidencias
   ```

5. **Redactar** `Entregables/<Proyecto>/manual-usuario/manual-usuario.md` con la estructura de abajo.
6. **Validar**: `node Tools/entregables/build-docx.mjs Entregables/<Proyecto>/manual-usuario/manual-usuario.md --check`
   (lista pendientes, advertencias y errores; falla si falta una imagen).
7. **Generar**: el mismo comando sin `--check`. Salida por defecto:
   `Manual_de_Usuario_<Sistema>_v<version>.docx` en la misma carpeta.
8. **Reportar** (ver "Entrega").

---

## Estructura estándar

```
[Portada · Contenido · Índice de figuras]  ← los genera build-docx.mjs

# Introducción
## Propósito del manual
## A quién va dirigido            (roles del inventario)
## Convenciones del documento     (negritas = botones/campos, notas, figuras)
# Requisitos y acceso
## Navegadores soportados
## Dirección de acceso            (QA o producción solo si el dev la proporciona)
## Credenciales                   ("Las proporciona el administrador del sistema")
# Ingreso y navegación general
## Iniciar sesión
## Menú principal
## Cerrar sesión
## Recuperar contraseña           (solo si existe en la app)
# <Módulo 1 — nombre como aparece en el menú>
## <Tarea: Registrar un contrato>
   Objetivo · Rol requerido · Pasos con capturas · Resultado esperado · Mensajes del sistema
## <Tarea siguiente>
# <Módulo N>
# Mensajes y errores frecuentes   (tabla: mensaje → significado → qué hacer)
# Preguntas frecuentes
# Glosario
# Soporte y contacto              ([Pendiente — …] si no hay dato)
# Control de versiones {-}        (tabla: versión · fecha · cambios · elaboró)
```

---

## Redacción de procedimientos

- Texto visible al usuario: seguir `IA_Skill/SKILL-humanizer.md`. Claro, sin jerga técnica
  (nada de "endpoint", "request", "token", "modal"), con el trato que use el proyecto (usted o tú).
- Un estilo verbal consistente en todo el manual: imperativo ("Seleccione…") o infinitivo
  ("Seleccionar…"); no mezclar.
- Un paso = una acción. Si un paso tiene "y", probablemente son dos.
- Botones, campos, menús y pestañas en **negrita**, escritos exactamente como en pantalla.
- La captura va **después** del paso que la muestra. No capturar cada clic: solo cuando cambia la
  pantalla, hay un formulario lleno o aparece un resultado o mensaje importante.
- Pie de figura descriptivo: "Pantalla de registro de contratos con el formulario completo", no
  "Captura 3".
- No narrar lo obvio de la captura; el texto dice qué hacer y por qué.
- Advertencias y consejos como cita (`> `), que se ve como nota resaltada.
- Nunca inventar: lo que no se pueda verificar en la app, specs o código va como
  `[Pendiente — <qué falta y quién lo provee>]`.
- Nunca incluir credenciales, URLs internas de producción ni datos reales de personas.

---

## Capturas para manual

- Resolución, tema e idioma fijos: los define el proyecto Playwright `evidencias`
  (1440×900, escala 2×, tema claro, es-MX). No capturar a mano.
- Solo entorno local o de QA con datos de prueba, nunca producción. Credenciales por variables de
  entorno; reutilizar el login/`storageState` de `IA_Skill/SKILL-e2e-playwright.md`.
- Datos de prueba realistas pero ficticios ("Contrato de prueba 001", "Proveedor Demo SA de CV").
- Si aparece cualquier dato personal (nombres, RFC, CURP, correos, teléfonos), enmascararlo con
  `mascaras` en `capturar()`.
- Banners de entorno (QA, versión de compilación) que confundan al usuario: enmascararlos o
  capturar el elemento relevante con `elemento`.
- Cuando la UI cambie, volver a correr los specs: quedan versionados en el workspace para regenerar
  el manual sin rehacer capturas a mano.

---

## Ejemplo breve

```markdown
---
tipo: manual-usuario
sistema: Sistema de Gestión de Contratos
version: 1.0
fecha: 2026-11-20
organizacion: [Pendiente — dependencia destinataria]
elaboro: Equipo de Desarrollo
clasificacion: Uso Interno
---

# Contratos

## Registrar un contrato

**Objetivo:** dar de alta un contrato nuevo para que pueda revisarlo el supervisor.
**Rol requerido:** Capturista.

1. En el menú principal, seleccione **Contratos** y después **Nuevo contrato**.

![Listado de contratos con el botón Nuevo contrato](../evidencias/capturas/contratos/01-listado.png)

2. Capture los campos **Proveedor**, **Monto** y **Fecha de inicio**.
3. Seleccione **Registrar**.

![Formulario de registro de contrato con los datos completos](../evidencias/capturas/contratos/02-formulario.png)

> Los campos marcados con asterisco son obligatorios. Si falta alguno, el sistema no permite registrar.

**Resultado esperado:** el contrato aparece en el listado con estatus **En revisión**.

### Mensajes del sistema

| Mensaje | Significado | Qué hacer |
|---|---|---|
| Contrato registrado correctamente | El contrato se guardó | Ninguna acción adicional |
| El monto debe ser mayor a cero | El monto capturado no es válido | Corregir el campo **Monto** |
```

---

## Entrega

1. Guardar en `Entregables/<Proyecto>/manual-usuario/` el `.md` (fuente) y el `.docx` generado.
2. Reportar al usuario:
   - Ruta del `.docx`.
   - Capítulos y tareas documentadas por rol.
   - Número de figuras (lo reporta `build-docx.mjs`).
   - Pendientes listados por `--check` y qué información se necesita del dev para cerrarlos.
   - Diferencias detectadas entre specs y la app real.
3. Aclarar que al abrir el `.docx` Word pide actualizar campos: **aceptar** para completar el
   contenido y el índice de figuras.
4. Estado: `in-review` hasta que el dev apruebe.

---

## Checklist antes de entregar

- [ ] Datos de portada confirmados con el usuario (o marcados como pendientes con su motivo).
- [ ] Cada tarea del inventario rol → tareas tiene su procedimiento.
- [ ] Botones, campos y menús en **negrita** y con el texto exacto de la pantalla.
- [ ] Capturas generadas por los specs de `tests/evidencias/`, no a mano; ninguna de producción.
- [ ] Datos personales enmascarados; datos de prueba ficticios.
- [ ] Cada figura con pie descriptivo.
- [ ] Sin jerga técnica, credenciales ni URLs internas de producción.
- [ ] `--check` sin errores; pendientes listados en el reporte.
- [ ] `.docx` generado en `Entregables/<Proyecto>/manual-usuario/`; estado `in-review`.
