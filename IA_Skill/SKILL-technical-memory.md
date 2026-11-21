---
name: technical-memory
description: >
  Genera memorias técnicas formales en .docx para proyectos de software destinados a clientes
  de gobierno o externos, con diagramas generados desde el código (archify) y, si aplica,
  capturas reales de pantallas (Playwright). Úsala cuando el usuario pida "memoria técnica",
  "documentación técnica formal", "entregable técnico", "documento de proyecto para cliente", o
  cuando mencione que necesita documentar un proyecto con código fuente disponible. Requiere al
  menos una de estas fuentes: snapshot de Repomix, manual de usuario (Word o MD), o carpeta de
  código. Produce un .docx con índice navegable, índice de figuras, numeración jerárquica y
  lenguaje institucional —nunca genérico, siempre apegado al proyecto real. Activa esta skill
  también cuando el usuario mencione "multi-agent-dev-template", "IA_Memoria", "Insumos",
  "Entregables" o "Repomix" en el contexto de documentar un sistema.
---

# Skill: Memoria Técnica

Genera un documento Word formal (`.docx`) con índice navegable, lenguaje institucional, diagramas
reales del sistema y contenido 100% apegado al proyecto real — nunca inventado ni genérico.

**Reparto del trabajo:** el agente investiga y escribe el contenido en Markdown; la plantilla
aplica siempre el mismo formato institucional con `Tools/entregables/build-docx.mjs`
(portada, índice, índice de figuras, numeración, estilos, encabezado y pie). No generar scripts
`docx` propios por documento: el formato vive en la herramienta para que todos los agentes
produzcan el mismo resultado.

---

## Fuentes de entrada esperadas

```
workspace/
├── Codigo/<PROYECTO>/          ← código fuente (fuente de verdad técnica)
├── Entregables/<PROYECTO>/     ← memoria-tecnica/, manual-usuario/, evidencias/ (aquí va el .docx)
├── IA_Memoria/                 ← arquitectura.md, convenciones.md, progreso.md, deuda-tecnica.md, snapshots/
├── Insumos/                    ← Manual_de_Usuario.docx / .md, README.md, documentos del cliente
└── Features/                   ← definición funcional de módulos
```

Adapta si la estructura difiere, pero siempre prioriza estas fuentes en orden:

| Prioridad | Fuente | Extrae |
|-----------|--------|--------|
| 1 | `IA_Memoria/arquitectura.md` | Stack, patrones, módulos, decisiones técnicas, comandos |
| 2 | `IA_Memoria/snapshots/snapshot-latest.md` (Repomix) y `Codigo/<PROYECTO>/` | Estructura real del código, dependencias, archivos clave |
| 3 | Manual de usuario (`Insumos/` o `Entregables/<PROYECTO>/manual-usuario/`) | Flujos de negocio, terminología del dominio, pantallas |
| 4 | `IA_Memoria/convenciones.md` | Estándares de código, naming, patrones aplicados |
| 5 | `Features/` | Alcance funcional, casos de uso |

---

## Flujo de ejecución

### Paso 1 — Leer todas las fuentes disponibles

Leer `arquitectura.md` y `convenciones.md` siempre; luego `Insumos/`, `Features/` y el snapshot.
Si el snapshot de Repomix no existe o tiene más de 7 días, pedir al usuario que lo genere
(`.\repomix-scan.ps1` en Windows o `./repomix-scan.sh`). Las versiones exactas se leen de los
manifiestos reales (`*.csproj`, `Directory.Packages.props`, `package.json`, `requirements.txt`).

### Paso 2 — Construir el modelo mental del proyecto

Antes de escribir, sintetiza internamente (no va en el documento):

- **Nombre oficial del sistema**: extraído de README o manual, no inventado
- **Propósito real**: qué problema resuelve, para quién
- **Stack técnico real**: versiones exactas si están disponibles
- **Módulos/componentes reales**: nombres tal como aparecen en el código
- **Integraciones reales**: APIs, servicios externos, bases de datos
- **Plan de figuras** (tabla abajo): qué diagramas aplican a este proyecto

### Paso 3 — Datos de portada

Si faltan, pregunta al usuario ANTES de generar, en un solo mensaje:
- Nombre de la organización/dependencia destinataria
- Nombre del autor o área que elabora
- Clasificación del documento (Público / Uso Interno / Confidencial)

### Paso 4 — Diagramas desde el código (archify)

Generar los diagramas con `IA_Skill/SKILL-visual-evidence.md` (archify con evidencia del
repositorio, exportados a PNG). Plan de figuras de una memoria técnica:

| Sección | Diagrama archify | Obligatorio |
|---|---|---|
| 3.1 Vista general de la arquitectura | `architecture` (capas, servicios, BD, integraciones) | Sí |
| 3.3 Diagrama de componentes | `architecture` o `class` del módulo principal | Sí, si hay más de un módulo |
| 4.4 Infraestructura y despliegue | `architecture` de despliegue (contenedores, VM, Aspire) | Si hay evidencia en el repo |
| 6.2 Esquema de base de datos | `erd` desde las entidades/migraciones reales | Sí, si hay BD |
| 7.x Integraciones | `sequence` o `dataflow` de cada integración relevante | Si hay integraciones |
| 8.1 Autenticación y autorización | `sequence` del flujo de login/token (perfil A o B) | Sí, si hay auth |

Cada nodo y relación del diagrama corresponde a algo que existe en el código; archify valida la
evidencia con `--repo-root Codigo/<PROYECTO>`. Sin evidencia, la figura no se dibuja: se deja
`[Pendiente — …]` en el texto.

### Paso 5 — Capturas de pantalla (opcional)

Solo si el cliente pide mostrar la interfaz (p. ej. sección "Interfaz de usuario" o anexo de
pantallas principales). Se generan con los specs de `tests/evidencias/` descritos en
`IA_Skill/SKILL-visual-evidence.md`, contra local o QA con datos de prueba y máscaras.

### Paso 6 — Redactar y generar el .docx

1. Escribir `Entregables/<PROYECTO>/memoria-tecnica/memoria-tecnica.md` con el front matter y la
   estructura de abajo (Markdown soportado: `Tools/entregables/README.md`). Las figuras se
   referencian como `![Pie de figura](../evidencias/diagramas/<id>/<id>.png)`.
2. Validar: `node Tools/entregables/build-docx.mjs Entregables/<PROYECTO>/memoria-tecnica/memoria-tecnica.md --check`
   (lista pendientes, advertencias y errores; falla si falta una imagen).
3. Generar: el mismo comando sin `--check`.

```markdown
---
tipo: memoria-tecnica
sistema: <Nombre oficial del sistema>
version: 1.0
fecha: <AAAA-MM-DD>
organizacion: <Dependencia o cliente>
elaboro: <Autor o área>
clasificacion: Uso Interno
anexo-evidencias: si
---
```

`anexo-evidencias: si` agrega al final la tabla "Origen de las figuras" (archivo, origen, fecha
y commit de cada figura) para auditoría.

---

## Estructura del documento

Usa esta estructura estándar para clientes de gobierno. Ajusta secciones si el proyecto
no aplica (p. ej. si no hay API REST, omite esa sección). En el Markdown los títulos van **sin
número**: la herramienta numera (1., 1.1, 1.1.1) y pone los capítulos en mayúsculas.

```
[Portada]                         ← la genera la herramienta desde el front matter
[Tabla de Contenidos — navegable] ← automática
[Índice de figuras]               ← automático si hay figuras

1. INTRODUCCIÓN
   1.1 Propósito del documento
   1.2 Alcance del sistema
   1.3 Definiciones, acrónimos y abreviaturas
   1.4 Referencias

2. DESCRIPCIÓN GENERAL DEL SISTEMA
   2.1 Contexto y justificación
   2.2 Objetivos del sistema
   2.3 Usuarios del sistema
   2.4 Restricciones y suposiciones

3. ARQUITECTURA DEL SISTEMA
   3.1 Vista general de la arquitectura      ← figura (architecture)
   3.2 Componentes principales
   3.3 Diagrama de componentes               ← figura (architecture/class)
   3.4 Patrones de diseño aplicados

4. STACK TECNOLÓGICO
   4.1 Lenguajes y frameworks
   4.2 Dependencias principales (tabla: nombre | versión | propósito)
   4.3 Herramientas de desarrollo
   4.4 Infraestructura y despliegue          ← figura si hay evidencia

5. MÓDULOS Y COMPONENTES
   5.1 [Módulo 1 — nombre real del proyecto]
       5.1.1 Responsabilidad
       5.1.2 Estructura de archivos
       5.1.3 Interfaces expuestas
   [repetir por módulo real]

6. MODELO DE DATOS
   6.1 Entidades principales (tabla: entidad | descripción | relaciones)
   6.2 Esquema de base de datos              ← figura (erd)

7. INTEGRACIONES Y SERVICIOS EXTERNOS
   7.1 [Integración 1 — nombre real]         ← figura (sequence/dataflow) si aplica
       Descripción, protocolo, autenticación, endpoint (sin credenciales)

8. SEGURIDAD
   8.1 Autenticación y autorización          ← figura (sequence del flujo)
   8.2 Manejo de datos sensibles
   8.3 Consideraciones de seguridad

9. INSTALACIÓN Y CONFIGURACIÓN
   9.1 Requisitos previos (tabla: componente | versión mínima)
   9.2 Pasos de instalación
   9.3 Variables de configuración (tabla: variable | descripción | valor ejemplo)
   9.4 Verificación de la instalación

10. OPERACIÓN Y MANTENIMIENTO
    10.1 Arranque y detención del sistema
    10.2 Monitoreo y logs
    10.3 Procedimientos de respaldo

11. CONTROL DE VERSIONES
    11.1 Historial de versiones del documento (tabla)
    11.2 Estado actual del desarrollo

[Anexo. Origen de las figuras]    ← automático con anexo-evidencias: si
```

---

## Reglas de contenido

**Nunca inventar.** Si una sección no tiene información disponible en las fuentes:
- Escribe `[Pendiente — requiere información del equipo de desarrollo]` (la herramienta lo resalta
  en amarillo y lo lista en el reporte)
- NO escribas contenido genérico como "El sistema utiliza buenas prácticas..."

**Solo hechos, nunca justificaciones.** La memoria técnica describe lo que el sistema ES y cómo
funciona. No explica por qué se eligió una tecnología, qué ocurrió históricamente, ni compara con
alternativas no usadas:
- ❌ "El sistema se construyó con Node.js por velocidad de entrega durante el prototipo"
- ❌ "Esta decisión difiere del template institucional aprobado (NestJS / Angular)"
- ❌ "Esta desviación está registrada como deuda técnica"
- ❌ "Se utilizó X en lugar de Y debido a Z"
- ✅ "El sistema utiliza Node.js 22.x con Express 4.21.2"

Si las fuentes contienen notas de deuda técnica, justificaciones de diseño o contexto histórico,
ignorarlos. Extraer únicamente el dato técnico concreto (qué tecnología, qué versión, qué hace).

**Lenguaje institucional:**
- ❌ "El backend expone endpoints REST"
- ✅ "El servidor de aplicaciones proporciona servicios web mediante interfaz REST"
- ❌ "Se usa JWT para auth"
- ✅ "La autenticación de usuarios se implementa mediante tokens de acceso (JWT — JSON Web Token)"

**Terminología del dominio primero:** usa los nombres exactos que aparecen en el manual de usuario
y en el código. Si el sistema se llama "Sistema de Indicadores", úsalo siempre así, no "la aplicación".

**Tablas para datos técnicos:** dependencias, variables de entorno, entidades, requisitos →
siempre en tabla, nunca en lista de párrafos.

**Versiones explícitas:** extrae versiones de `*.csproj`, `Directory.Packages.props`,
`package.json`, `requirements.txt`, `pyproject.toml` o equivalente. Si no están disponibles,
indica `[verificar versión]`.

**Figuras:** cada figura lleva un pie descriptivo (texto entre corchetes de `![…](…)`), se cita en
el texto antes de aparecer ("La Figura 1 muestra…") y solo contiene componentes reales. Nunca
credenciales, cadenas de conexión, IPs o hosts internos de producción en diagramas ni capturas.

---

## Portada y estilos

La portada (sistema, tipo de documento, versión, fecha, organización, elaboró, clasificación), el
encabezado ("Sistema · Memoria Técnica | Clasificación"), el pie ("Página X de Y") y los estilos
los aplica la herramienta. Paleta institucional: azul `1F3864` (títulos), `2E75B6` (subtítulos),
`D6E4F7` (encabezados de tabla); tipografía Arial 11 pt, código Courier New 10 pt. No cambiar el
formato en el Markdown.

---

## Entrega

1. El `.docx` queda en `Entregables/<PROYECTO>/memoria-tecnica/Memoria_Tecnica_<Sistema>_v<version>.docx`.
2. Reporta al usuario:
   - Secciones generadas con contenido real y figuras incluidas
   - Secciones marcadas como `[Pendiente]` y qué información se necesita (lista del reporte de la herramienta)
   - Que al abrir el `.docx` Word pide actualizar campos: aceptar para completar índices
3. Estado: `in-review` hasta que el dev o el responsable apruebe el documento.

---

## Referencias internas

- Generador y Markdown soportado: `Tools/entregables/README.md`
- Diagramas y capturas: `IA_Skill/SKILL-visual-evidence.md`
- Manual de usuario (fuente de terminología y pantallas): `IA_Skill/SKILL-user-manual.md`
- Especificación técnica para auditorías: `IA_Skill/technical-audit-spec-generic.md`
