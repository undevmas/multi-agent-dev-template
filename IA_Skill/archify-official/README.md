# archify — diagramas desde el código (complementaria)

Copia fijada de [github.com/tt-a1i/archify](https://github.com/tt-a1i/archify): genera diagramas
validados (arquitectura, secuencia, ERD, flujo de datos, ciclo de vida, clases, workflow, árbol,
timeline, waterfall) como HTML interactivo autocontenido, con exportación a PNG/SVG. Licencia
Apache 2.0 (`LICENSE`, `NOTICE`) con texto alternativo MIT (`LICENSE-MIT`), © tt-a1i.

- **Versión instalada:** ver `SOURCE.txt` (commit, fecha, versión).
- **Qué se instala:** la carpeta `archify/` del repo (skill + motor Node ≥18, sin dependencias de
  runtime). Se excluyen `archify/examples/*.html` (renderizados de ejemplo, ~12 MB que el motor no
  usa; `doctor` verifica con los `.json`).
- **Idioma:** inglés, sin modificar. **No editar** `archify/`: el script de sincronización lo
  sobrescribe. Las adaptaciones van en este README o en `IA_Skill/SKILL-visual-evidence.md`.

---

## Cómo se usa en esta plantilla (obligatorio)

1. El procedimiento de la plantilla es `IA_Skill/SKILL-visual-evidence.md`; la referencia técnica
   para escribir el `candidate.json` es `archify/SKILL.md` y sus `references/`.
2. **Siempre** a través del wrapper, en lugar de `node bin/archify.mjs`:
   ```bash
   node Tools/entregables/archify.mjs <comando> [argumentos]
   ```
   El wrapper fija `ARCHIFY_UPDATE_CHECK_DISABLED=1` (sin llamadas de red) y `ARCHIFY_CHROME` al
   Chromium de Playwright del workspace.
3. Salida dentro de `Entregables/<Proyecto>/evidencias/diagramas/<id>/`, no en `.archify/`.
4. Diagramas de código real con `--repo-root Codigo/<proyecto>`: cada elemento cita su evidencia.

## Regla de precedencia

`AGENTS.md` → `IA_Memoria/convenciones.md` → skills propias (`SKILL-visual-evidence.md`,
`SKILL-technical-memory.md`, `SKILL-user-manual.md`) → `archify/SKILL.md`. Conflictos conocidos:

| archify dice | Aplica en la plantilla |
|---|---|
| Crear la carpeta `.archify/<tipo>-<slug>-<fecha>/` en el directorio de trabajo | Usar `Entregables/<Proyecto>/evidencias/diagramas/<id>/` (ruta estable que citan los documentos) |
| `node bin/archify.mjs …` y revisar actualizaciones (`update.noticeRequired`) | `node Tools/entregables/archify.mjs …` sin red; las actualizaciones se hacen con `sync-archify` y revisión del diff, nunca desde el agente |
| Exportar desde el menú del visor | Para documentos: `tests/evidencias/diagramas.capture.ts` usa ese mismo menú (Exportar → PNG) de forma automática |
| Explainers de una página (`[archify explainer: …]`) | Fuera del alcance de los entregables; no usar en memorias ni manuales |
| Marcas comerciales (`brand-marks`) | Solo logos de tecnologías que el proyecto usa realmente; nunca logos del cliente sin autorización |

Nunca incluir en un diagrama credenciales, cadenas de conexión, IPs o hosts internos de producción.

---

## Actualizar

```powershell
.\IA_Skill\archify-official\sync-archify.ps1          # Windows
```

```bash
./IA_Skill/archify-official/sync-archify.sh           # Linux / macOS / Git Bash
```

Después: `node Tools/entregables/archify.mjs doctor`, regenerar un diagrama de prueba y revisar el
diff (`git diff IA_Skill/archify-official`): es contenido de terceros que los agentes van a seguir.
