# Insumos/ — Material de Entrada

Aquí va todo el material que le entregas al agente antes de pedirle que genere una spec.
**Esta carpeta no se sube al repositorio de código.**

Coloca el archivo antes de escribirle al agente. El agente lo leerá desde aquí.

---

## mockups/

Wireframes, pantallas y diseños visuales.

Formatos: PNG, PDF, exportación de Figma.
Convención: `[feature]-[pantalla]-v[version].[ext]`

Ejemplos:
- `login-principal-v1.png`
- `dashboard-general-v2.pdf`
- `catalogos-listado-v1.png`

## especificaciones/

Documentos de reglas de negocio, flujos de aprobación, requisitos legales, historias de usuario.

Formatos: MD, PDF, DOCX.
Convención: `[feature]-[tipo]-v[version].[ext]`

Ejemplos:
- `login-reglas-negocio-v1.md`
- `contratos-flujo-aprobacion-v1.pdf`
- `usuarios-historia-usuario-v1.docx`

## datos/

Archivos para seeds de base de datos y escenarios de prueba.

Convención:
- Seeds: `seed-[tabla].[csv|json]`
- Pruebas: `test-[escenario].[csv|json]`

Ejemplos:
- `seed-catalogos-estados.csv`
- `seed-usuarios-iniciales.json`
- `test-login-usuarios-bloqueados.json`
