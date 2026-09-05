---
name: technical-memory
description: >
  Genera memorias técnicas formales en .docx para proyectos de software destinados a clientes
  de gobierno o externos. Úsala cuando el usuario pida "memoria técnica", "documentación técnica
  formal", "entregable técnico", "documento de proyecto para cliente", o cuando mencione que
  necesita documentar un proyecto con código fuente disponible. Requiere al menos una de estas
  fuentes: output de Repomix, manual de usuario (Word o MD), o carpeta de código. Produce un
  .docx con índice navegable, numeración jerárquica y lenguaje institucional —nunca genérico,
  siempre apegado al proyecto real. Activa esta skill también cuando el usuario mencione
  "multi-agent-dev-template", "IA_Memoria", "Insumos", "Entregables" o "Repomix" en el
  contexto de documentar un sistema.
---

# Skill: Memoria Técnica

Genera un documento Word formal (`.docx`) con índice navegable, lenguaje institucional y
contenido 100% apegado al proyecto real — nunca inventado ni genérico.

---

## Fuentes de entrada esperadas

El workspace del usuario sigue esta estructura estándar (basada en `multi-agent-dev-template`):

```
workspace/
├── Codigo/<PROYECTO>/          ← código fuente + repomix.config.json
├── Entregables/                ← aquí va el .docx final
├── IA_Memoria/                 ← arquitectura.md, convenciones.md, progreso.md, deuda-tecnica.md
├── Insumos/                    ← Manual_de_Usuario.docx / .md, README.md
└── Features/                  ← README.md con alcance funcional
```

Adapta si la estructura difiere, pero siempre prioriza estas fuentes en orden:

| Prioridad | Fuente | Extrae |
|-----------|--------|--------|
| 1 | `IA_Memoria/arquitectura.md` | Stack, patrones, módulos, decisiones técnicas |
| 2 | Repomix output | Estructura real del código, dependencias, archivos clave |
| 3 | `Insumos/Manual_de_Usuario.md` | Flujos de negocio, terminología del dominio, pantallas |
| 4 | `IA_Memoria/convenciones.md` | Estándares de código, naming, patrones aplicados |
| 5 | `Features/README.md` | Alcance funcional, casos de uso |

---

## Flujo de ejecución

### Paso 1 — Leer todas las fuentes disponibles

```bash
# Listar fuentes disponibles
ls IA_Memoria/ Insumos/ Features/ Codigo/ 2>/dev/null

# Leer fuentes primarias (siempre)
cat IA_Memoria/arquitectura.md
cat IA_Memoria/convenciones.md

# Leer insumos
cat Insumos/README.md
# Si existe .md del manual, leerlo directamente
cat "Insumos/Manual_de_Usuario_Sistema_de_Indicadores.md"

# Leer Repomix output si existe generado
# (normalmente está en raíz o en Codigo/)
ls *.md repomix-output* 2>/dev/null
```

Si el Repomix output NO está generado aún, instruye al usuario:
```bash
cd Codigo/<PROYECTO>
repomix --output ../../repomix-output.md
```

### Paso 2 — Construir el modelo mental del proyecto

Antes de generar el Word, sintetiza internamente (no escribas esto en el documento):

- **Nombre oficial del sistema**: extraído de README o manual, no inventado
- **Propósito real**: qué problema resuelve, para quién
- **Stack técnico real**: versiones exactas si están disponibles
- **Módulos/componentes reales**: nombres tal como aparecen en el código
- **Integraciones reales**: APIs, servicios externos, bases de datos

### Paso 3 — Generar el .docx

Lee primero `IA_Skill/document-artifacts/SKILL.md`. Usa la capacidad nativa de documentos disponible en el agente; no asumas una ruta del sistema ni instales paquetes para generar el archivo. Guarda el resultado en `Entregables/`.

---

## Estructura del documento

Usa esta estructura estándar para clientes de gobierno. Ajusta secciones si el proyecto
no aplica (p.ej. si no hay API REST, omite esa sección).

```
[Portada]
[Tabla de Contenidos — navegable]

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
   3.1 Vista general de la arquitectura
   3.2 Componentes principales
   3.3 Diagrama de componentes (descripción textual si no hay imagen)
   3.4 Patrones de diseño aplicados

4. STACK TECNOLÓGICO
   4.1 Lenguajes y frameworks
   4.2 Dependencias principales (tabla: nombre | versión | propósito)
   4.3 Herramientas de desarrollo
   4.4 Infraestructura y despliegue

5. MÓDULOS Y COMPONENTES
   5.1 [Módulo 1 — nombre real del proyecto]
       5.1.1 Responsabilidad
       5.1.2 Estructura de archivos
       5.1.3 Interfaces expuestas
   [repetir por módulo real]

6. MODELO DE DATOS
   6.1 Entidades principales (tabla: entidad | descripción | relaciones)
   6.2 Esquema de base de datos (si aplica)

7. INTEGRACIONES Y SERVICIOS EXTERNOS
   7.1 [Integración 1 — nombre real]
       Descripción, protocolo, autenticación, endpoint (sin credenciales)

8. SEGURIDAD
   8.1 Autenticación y autorización
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
```

---

## Reglas de contenido

**Nunca inventar.** Si una sección no tiene información disponible en las fuentes:
- Escribe `[Pendiente — requiere información del equipo de desarrollo]`
- NO escribas contenido genérico como "El sistema utiliza buenas prácticas..."

**Lenguaje institucional:**
- ❌ "El backend expone endpoints REST"
- ✅ "El servidor de aplicaciones proporciona servicios web mediante interfaz REST"
- ❌ "Se usa JWT para auth"
- ✅ "La autenticación de usuarios se implementa mediante tokens de acceso (JWT — JSON Web Token)"

**Terminología del dominio primero:**
Usa los nombres exactos que aparecen en el manual de usuario y en el código.
Si el sistema se llama "Sistema de Indicadores IMSS", úsalo siempre así, no "la aplicación".

**Tablas para datos técnicos:**
Dependencias, variables de entorno, entidades, requisitos → siempre en tabla, nunca en lista de párrafos.

**Versiones explícitas:**
Extrae versiones del `package.json`, `requirements.txt`, `pyproject.toml`, o equivalente.
Si no están disponibles, indica `[verificar versión]`.

---

## Portada

```javascript
// Elementos de portada — extrae del proyecto real:
// - Nombre oficial del sistema (de README o manual)
// - Versión del documento: "1.0" si es nuevo
// - Fecha: fecha actual
// - Organización: extraer de README o preguntar al usuario
// - Clasificación: "Uso Interno" por defecto, ajustar si usuario especifica
// - Elaboró: preguntar al usuario o dejar [Nombre del autor]
```

Si faltan datos de portada, pregunta al usuario ANTES de generar:
- Nombre de la organización/dependencia destinataria
- Nombre del autor o área que elabora
- Clasificación del documento (Público / Uso Interno / Confidencial)

---

## Estilos Word requeridos

```javascript
// Paleta institucional: azul gobierno
const COLORS = {
  primary: "1F3864",    // azul oscuro institucional
  secondary: "2E75B6",  // azul medio para headings 2
  accent: "D6E4F7",     // azul claro para headers de tabla
  text: "000000",
  subtle: "595959"
};

// Tipografía
const FONTS = {
  heading: "Arial",
  body: "Arial",
  code: "Courier New"
};

// Tamaños (half-points)
const SIZES = {
  h1: 32,   // 16pt
  h2: 28,   // 14pt
  h3: 24,   // 12pt bold
  body: 22, // 11pt
  code: 20, // 10pt
  small: 18 // 9pt — para tablas densas
};
```

---

## Entrega

1. Guarda el `.docx` en `Entregables/Memoria_Tecnica_[NOMBRE_SISTEMA]_v1.0.docx`
2. Reporta al usuario:
   - Secciones generadas con contenido real
   - Secciones marcadas como `[Pendiente]` y qué información se necesita
   - Tamaño aproximado del documento

---

## Referencias internas

- Para generar o leer documentos: `IA_Skill/document-artifacts/SKILL.md`
