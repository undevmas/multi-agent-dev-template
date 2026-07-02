---
name: technical-audit-spec-generic
description: >
  Genera un documento de Especificaciones Técnicas en .docx orientado a procesos de auditoría,
  distinto de una memoria técnica narrativa. Úsala cuando el usuario pida "especificaciones
  técnicas", "documento para auditoría", "especificación para auditor", "control de seguridad
  documentado", o cuando mencione que un cliente o dependencia solicita evidencia verificable
  del sistema (no solo descripción). Requiere al menos una de estas fuentes: código fuente,
  output de Repomix, especificación funcional o acuerdos convertidos a MD en Insumos/, o
  IA_Memoria/arquitectura.md. A diferencia de la skill technical-memory, este documento se
  organiza por control/requisito verificable con evidencia trazable (archivo, tabla, endpoint,
  configuración), no por módulo narrativo. No asume ningún formato de dependencia específica
  — es genérico y reutilizable entre proyectos; si el cliente exige una plantilla propia,
  se necesita otra skill basada en esa plantilla.
---

# Skill: Especificaciones Técnicas para Auditoría (genérica)

Genera un documento Word formal (`.docx`) de **especificaciones técnicas verificables**,
distinto en estructura y propósito de una memoria técnica. Este documento no narra cómo
está construido el sistema — **declara qué cumple, con qué evidencia, y dónde verificarlo**.

---

## Diferencia con `technical-memory`

| Aspecto | technical-memory | technical-audit-spec-generic |
|---|---|---|
| Organización | Por módulo/componente del sistema | Por control/requisito verificable |
| Tono | Descriptivo | Afirmativo + evidencia |
| Unidad mínima de contenido | Sección narrativa | Ficha de control: afirmación + evidencia + ubicación |
| Deuda técnica | Se documenta como nota | Se documenta como **hallazgo de auditoría + plan de mitigación** |
| Seguridad | Una sección entre varias | Eje central del documento |
| Trazabilidad | Opcional | Obligatoria — toda afirmación apunta a archivo/tabla/línea/config real |

Si el usuario ya generó una memoria técnica para el mismo proyecto, **reutiliza las fuentes
ya leídas** (no vuelvas a leer todo desde cero si la información ya está disponible en la
conversación), pero reestructura el contenido al formato de control/evidencia.

---

## Fuentes de entrada esperadas

Misma estructura base de `multi-agent-dev-template`, con una fuente adicional:

```
workspace/
├── Codigo/<PROYECTO>/          ← código fuente + repomix.config.json
├── Entregables/                ← aquí va el .docx final
├── IA_Memoria/                 ← arquitectura.md, convenciones.md
├── Insumos/
│   ├── Manual_de_Usuario.md
│   └── Espec.Funcional/        ← especificaciones funcionales / acuerdos convertidos a MD
└── Features/                   ← README.md con alcance funcional
```

Prioridad de lectura:

| Prioridad | Fuente | Extrae |
|-----------|--------|--------|
| 1 | Código fuente / Repomix output | Evidencia técnica real: implementación de controles, configuración |
| 2 | `IA_Memoria/arquitectura.md` | Stack, mecanismos de seguridad, patrones de acceso a datos |
| 3 | `Insumos/Espec.Funcional/*.md` | Requisitos pactados, acuerdos, alcance contractual a verificar |
| 4 | `Insumos/Manual_de_Usuario.md` | Confirmar comportamiento esperado vs. comportamiento implementado |
| 5 | `Features/README.md` | Alcance funcional adicional |

```bash
ls IA_Memoria/ Insumos/ Insumos/Espec.Funcional/ Features/ Codigo/ 2>/dev/null

cat IA_Memoria/arquitectura.md
cat Insumos/Espec.Funcional/*.md 2>/dev/null
cat Insumos/Manual_de_Usuario*.md 2>/dev/null

# Si no hay Repomix generado:
# cd Codigo/<PROYECTO> && repomix --output ../../repomix-output.md
```

---

## Flujo de ejecución

### Paso 1 — Leer fuentes y construir el inventario de controles

A partir del código y la especificación funcional, identifica qué controles/requisitos son
verificables en este proyecto. No todos los proyectos tienen todas las categorías — omite
las que no apliquen, no inventes controles que no existen en el código.

Categorías típicas a inspeccionar:

- **Autenticación**: mecanismo (sesión, JWT, OAuth), almacenamiento de credenciales, expiración
- **Autorización**: modelo de control de acceso (RBAC, ACL), dónde se aplica en el código
- **Manejo de datos sensibles**: cifrado en tránsito (TLS/SSL), cifrado en reposo, hashing de contraseñas
- **Auditoría y trazabilidad**: logs de acceso, audit_log, retención de logs
- **Validación de entrada**: sanitización, validación de parámetros en endpoints
- **Gestión de sesiones**: TTL, invalidación, cookies (flags HttpOnly/Secure/SameSite)
- **Control de versiones de base de datos**: migraciones aplicadas, rollback disponible
- **Seguridad de infraestructura**: usuario sin privilegios en contenedor, escaneo de vulnerabilidades (Trivy, npm audit), gestión de secretos
- **Disponibilidad**: health checks, manejo de errores, código de respuesta HTTP
- **Cumplimiento de especificación funcional**: requisitos pactados (RF-XX) vs. implementación real

### Paso 2 — Para cada control, construir una ficha verificable

```
Control: [nombre del control]
Afirmación: [qué hace el sistema, en una frase verificable]
Evidencia: [archivo:línea / tabla / endpoint / variable de configuración]
Estado: Cumple / Cumple parcialmente / No cumple / No aplica
Observación de auditoría: [solo si Estado ≠ Cumple — hallazgo + riesgo]
```

Ejemplo real de ficha (no usar como texto genérico, ilustra el formato):

```
Control: Almacenamiento de credenciales de usuario
Afirmación: Las contraseñas de usuario se almacenan en la tabla usuarios, columna contrasena_hash
Evidencia: usuarioController.js, función hashPass; tabla usuarios.contrasena_hash
Estado: No cumple
Observación de auditoría: Las contraseñas se almacenan sin un algoritmo de hashing
criptográfico estándar. Riesgo: exposición de credenciales ante acceso no autorizado a la
base de datos. Remediación propuesta: migración a bcrypt o equivalente.
```

### Paso 3 — Generar el .docx

Lee `/mnt/skills/public/docx/SKILL.md` para las APIs de generación. Genera un script Node.js
con el paquete `docx` y ejecútalo. Guarda el resultado en `Entregables/`.

---

## Estructura del documento

```
[Portada]
[Tabla de Contenidos — navegable]

1. OBJETO Y ALCANCE DEL DOCUMENTO
   1.1 Propósito
   1.2 Alcance de la auditoría (qué se cubre, qué no)
   1.3 Sistema auditado (nombre, versión)

2. RESUMEN DE CONTROLES EVALUADOS
   Tabla: Control | Categoría | Estado (Cumple/Parcial/No cumple/No aplica)

3. AUTENTICACIÓN Y GESTIÓN DE IDENTIDAD
   [Fichas de control aplicables]

4. AUTORIZACIÓN Y CONTROL DE ACCESO
   [Fichas de control aplicables]

5. PROTECCIÓN DE DATOS
   5.1 Cifrado en tránsito
   5.2 Cifrado en reposo / hashing
   5.3 Manejo de datos sensibles
   [Fichas de control aplicables]

6. AUDITORÍA Y TRAZABILIDAD
   [Fichas de control aplicables]

7. VALIDACIÓN Y SEGURIDAD DE ENTRADA
   [Fichas de control aplicables]

8. INFRAESTRUCTURA Y DESPLIEGUE SEGURO
   8.1 Contenedores y privilegios
   8.2 Escaneo de vulnerabilidades
   8.3 Gestión de secretos
   [Fichas de control aplicables]

9. CONTROL DE VERSIONES Y CAMBIOS
   9.1 Migraciones de base de datos
   9.2 Trazabilidad de despliegues (CI/CD)

10. CUMPLIMIENTO DE ESPECIFICACIÓN FUNCIONAL
    Tabla: Requisito (RF-XX) | Descripción pactada | Estado de implementación | Evidencia

11. HALLAZGOS Y RECOMENDACIONES
    Tabla: ID | Hallazgo | Riesgo | Severidad | Remediación propuesta
    (Solo controles con Estado ≠ Cumple van aquí, consolidados)

12. CONTROL DE VERSIONES DEL DOCUMENTO
```

---

## Reglas de contenido

**Toda afirmación requiere evidencia.** Nunca escribir "el sistema es seguro" o "se siguen
buenas prácticas" sin apuntar a un archivo, tabla, línea o configuración específica. Si no
hay evidencia disponible en las fuentes, el control se marca `No verificado — requiere
inspección adicional`, nunca se asume cumplimiento.

**Solo hechos, nunca justificaciones de diseño.** Igual que en `technical-memory`: no se
explica por qué se tomó una decisión técnica ni se compara con alternativas no usadas.
La única excepción es la sección 11 (Hallazgos), donde sí se documenta el riesgo y la
remediación — porque es el propósito explícito de esa sección, no una justificación.

**Neutralidad ante hallazgos negativos.** No suavizar ni dramatizar un "No cumple". Se
redacta como un hecho técnico verificable, igual que un "Cumple":
- ❌ "Lamentablemente el sistema no implementa cifrado adecuado"
- ❌ "El sistema cuenta con un nivel aceptable de seguridad en este rubro"
- ✅ "Estado: No cumple. Evidencia: [ubicación]. Observación: [hallazgo + riesgo]"

**Severidad de hallazgos** — usar escala consistente:
| Severidad | Criterio |
|---|---|
| Crítica | Exposición directa de datos sensibles o acceso no autorizado al sistema |
| Alta | Falla de control que facilita explotación con esfuerzo moderado |
| Media | Desviación de práctica estándar sin explotación directa inmediata |
| Baja | Mejora recomendada sin riesgo de explotación identificado |

**No mapear contra normas específicas** (ISO 27001, NOM, etc.) salvo que el usuario lo pida
explícitamente y proporcione el documento normativo — esta skill es genérica. Si se requiere
mapeo normativo, es una skill distinta basada en la norma exacta.

**Terminología:** usar nombres exactos del código y la especificación funcional, igual que
en `technical-memory`. No genéricos como "el módulo de seguridad".

---

## Portada

Igual que `technical-memory`, pero el campo "Clasificación" casi siempre es más estricto
en documentos de auditoría. Si el usuario no especifica, preguntar:
- Nombre de la organización/dependencia que audita o recibe el documento
- Nombre del autor o área que elabora
- Clasificación del documento (recomendar "Confidencial" por defecto en contexto de auditoría,
  confirmar con el usuario)
- Alcance temporal de la auditoría (si aplica — ej. "Auditoría correspondiente a la versión 2.0.0")

---

## Estilos Word

Reutilizar la misma paleta institucional de `technical-memory` (azul gobierno), pero agregar
colores semánticos para el campo Estado en tablas:

```javascript
const ESTADO_COLOR = {
  "Cumple": "2E7D32",            // verde
  "Cumple parcialmente": "B8860B", // ámbar
  "No cumple": "C62828",         // rojo
  "No aplica": "757575",         // gris
  "No verificado": "757575"      // gris
};
```

Aplicar el color como shading o texto en la celda de Estado dentro de las tablas de
resumen de controles y de cumplimiento funcional.

---

## Entrega

1. Guarda el `.docx` en `Entregables/Especificaciones_Tecnicas_Auditoria_[NOMBRE_SISTEMA]_v1.0.docx`
2. Reporta al usuario:
   - Cantidad de controles evaluados por categoría
   - Cantidad de hallazgos por severidad (si los hay)
   - Controles marcados `No verificado` y qué evidencia se necesita para cerrarlos

---

## Referencias internas

- Para generación Word: `/mnt/skills/public/docx/SKILL.md`
- Para lectura de archivos Word existentes (especificación funcional, acuerdos): skill `file-reading`
- Skill relacionada (documento narrativo, no de auditoría): `technical-memory`