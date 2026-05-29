# Insumos del Proyecto

Carpeta para material de entrada que alimenta el desarrollo.
Esta carpeta NO se sube al repositorio de código.

---

## mockups/
Wireframes y diseños de pantallas.

Formatos aceptados: PNG, PDF, exportación de Figma.
Convención de nombre: `[feature]-[pantalla]-v[version].[ext]`

Ejemplos:
- `login-principal-v1.png`
- `dashboard-general-v2.pdf`
- `catalogos-listado-v1.png`

## especificaciones/
Documentos de reglas de negocio, flujos de aprobación, requisitos legales.

Formatos: MD, PDF, DOCX.
Convención de nombre: `[feature]-[tipo]-v[version].[ext]`

Ejemplos:
- `login-reglas-negocio-v1.md`
- `contratos-flujo-aprobacion-v1.pdf`

## datos/
Archivos para seeds de base de datos y escenarios de prueba.

Convención de nombre:
- Seeds: `seed-[tabla].[csv|json]`
- Pruebas: `test-[escenario].[csv|json]`

Ejemplos:
- `seed-catalogos-estados.csv`
- `seed-usuarios-iniciales.json`
- `test-login-usuarios-bloqueados.json`
