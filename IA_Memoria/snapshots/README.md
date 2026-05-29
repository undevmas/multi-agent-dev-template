# Snapshots Repomix

Esta carpeta guarda snapshots temporales del codigo en `Codigo/` para acelerar el arranque de sesiones con IA.

Archivos esperados:
- `snapshot-latest.md`: snapshot consolidado mas reciente.
- `snapshot-*.md`: snapshots por modulo (opcional).
- `snapshot-*.meta.json`: metadatos basicos del snapshot.

Regla:
- Estos snapshots NO se versionan en git.
- Solo se conserva este README y el .gitignore.
