# Uso de Repomix

`Codigo/` es una zona de trabajo: el Git de este template ignora los proyectos que se copien o clonen ahí. Conserva el repositorio Git propio de cada proyecto; el escáner sí puede leer su contenido.

## Windows

```powershell
# Snapshot comprimido de todo Codigo/. Es el comando habitual de bootstrap.
.\repomix-scan.ps1

# Snapshot de un proyecto o módulo puntual. Indica el stack para aplicar
# exclusiones específicas y reducir tiempo/tokens.
.\repomix-scan.ps1 -Target personal-cripto -Stack react

# Snapshot sin compresión, útil solo cuando se necesite máxima fidelidad.
.\repomix-scan.ps1 -Full

# Muestra ayuda; no descarga ni escanea nada.
.\repomix-scan.ps1 -?
```

## Linux/macOS

```bash
./repomix-scan.sh
./repomix-scan.sh personal-cripto --stack=react
./repomix-scan.sh --full
./repomix-scan.sh --help
```

## Qué esperar

La primera ejecución descarga automáticamente `repomix@1.18.0` a la caché local de npm y muestra su progreso. No agrega dependencias a los proyectos dentro de `Codigo/`.

El resultado queda en `IA_Memoria/snapshots/`:

- `snapshot-latest.md` para un escaneo completo.
- `snapshot-<target>.md` para uno puntual.

Al finalizar se imprime un prompt para que el agente actualice los archivos de memoria. Si Repomix falla, el script termina con error y no presenta un snapshot anterior como si fuera nuevo.

## Eficiencia y seguridad

- El modo por defecto comprime la salida y omite dependencias, artefactos de compilación, cobertura y logs.
- Usa `-Target`/`--stack` para tareas de uno o dos módulos; evita escanear el monorepo completo sin necesidad.
- El `.gitignore` del contenedor se desactiva solo para Repomix, porque ignora los proyectos completos. El archivo de configuración mantiene exclusiones explícitas para `.env`, claves, certificados, secretos y configuraciones de desarrollo.
