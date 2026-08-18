# SKILL — Secrets Scanning (Gitleaks y prevención)

## Cuándo usar esta skill

Al configurar un proyecto nuevo (asegurarse de que el escaneo de secretos
esté activo desde el commit inicial), al revisar el resultado de un
escaneo de Gitleaks (o equivalente) antes de un release, y ante cualquier
sospecha de que una credencial real quedó commiteada — sin importar si el
escaneo automatizado la detectó o no.

---

## Escaneo de línea base — antes de confiar en "0 leaks"

Un resultado de "0 leaks" solo es confiable si el escaneo cubre todo el
historial, no solo el HEAD actual:

```bash
# Escaneo completo del historial (no solo el commit actual)
gitleaks detect --source . --report-format json --report-path gitleaks-report.json --log-opts="--all"

# Verificación rápida de qué está trackeado que no debería
git ls-files | grep -E '\.env$|\.env\.|\.pem$|\.key$|id_rsa|credentials\.json'
```

Si `git ls-files` devuelve algo, no importa lo que diga Gitleaks — un
archivo de secretos trackeado en el repo (aunque hoy esté vacío o con
placeholders) es un hallazgo que hay que resolver: sacarlo del tracking
(`git rm --cached`) y confirmar que está en `.gitignore`.

---

## Si Gitleaks encuentra un leak real

**No basta con borrar el commit o hacer force-push.** Si la credencial
llegó a un remoto compartido (GitHub, Azure DevOps), ya se considera
comprometida — el historial de git puede reescribirse, pero no hay
garantía de que nadie la haya visto o clonado antes.

Procedimiento, en orden:

1. **Rotar la credencial primero, antes que cualquier otra cosa.** Generar
   una nueva API key/password/token y revocar la expuesta. Esto es zona
   verde siempre (`SKILL-risk-zone-policy.md`) — nunca requiere ticket,
   se hace de inmediato.
2. Confirmar en los logs del proveedor (Azure DevOps, AWS, etc.) si hubo
   uso no autorizado de la credencial mientras estuvo expuesta.
3. Limpiar el historial de git (`git filter-repo` o BFG Repo-Cleaner) —
   esto es limpieza, no reemplaza el paso 1.
4. Documentar el incidente: qué credencial, cuánto tiempo estuvo expuesta,
   si se detectó uso indebido. Esto no es opcional aunque la rotación
   ya haya cerrado el riesgo activo.

---

## Configuración de línea base para proyectos nuevos

```yaml
# .gitleaks.toml — ejemplo mínimo, ajustar allowlist según el proyecto
title = "gitleaks config"

[allowlist]
description = "Falsos positivos conocidos del proyecto"
paths = [
  '''\.md$''',           # documentación con ejemplos de config
  '''\.spec\.ts$''',     # fixtures de test con valores fake
]
```

Pre-commit hook recomendado (evita que el leak llegue siquiera al primer
commit local):

```bash
# .git/hooks/pre-commit (o vía husky/lefthook si el proyecto ya lo usa)
gitleaks protect --staged --redact
```

---

## Qué SÍ va en `.gitignore` desde el día uno de cualquier proyecto

```
.env
.env.*
!.env.example
*.pem
*.key
*.pfx
appsettings.*.json
!appsettings.json
!appsettings.Development.json.example
secrets.json
credentials.json
```

`appsettings.Development.json` con secretos reales no debe trackearse —
solo la versión `.example` con placeholders. Ver también
`SKILL-security-python.md` para el caso específico del PAT de Azure
DevOps en ReporteadorV2 (nunca se persiste, ni siquiera en archivo local).

---

## Checklist antes de cerrar cualquier tarea que toque configuración/CI

- [ ] `gitleaks detect --log-opts="--all"` corrido sobre todo el historial, no solo HEAD
- [ ] `git ls-files` no devuelve ningún `.env`, `.pem`, `.key`, ni archivo de credenciales
- [ ] El pre-commit hook de Gitleaks está activo si el proyecto lo tiene configurado
- [ ] Si se encontró un leak real: la credencial ya fue rotada (no solo borrada del historial)
- [ ] El `.gitignore` cubre los patrones de secretos de la lista de arriba
