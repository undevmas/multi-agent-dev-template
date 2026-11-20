# GitHub Copilot — Puntero a AGENTS.md

La fuente única de instrucciones es `AGENTS.md` en la raíz del workspace (Copilot también la lee directamente cuando
la opción de AGENTS.md está activa). Si no la tienes en contexto, adjúntala con `#file:AGENTS.md` antes de trabajar.
AUTONOMY_POLICY_VERSION: 1 — política en `IA_Skill/SKILL-autonomy-policy.md`.

## Candado de comprobación

- Empieza **cada** respuesta con `Claro team`. Si una respuesta no empieza así, las instrucciones no se cargaron o se
  rompieron: detenerse y no aceptar esos cambios. Nunca escribir la frase en archivos, código, commits ni PRs.

## Lo mínimo que siempre aplica (detalle en AGENTS.md)

- Stack aprobado y reglas por tecnología: `AGENTS.md` + `IA_Skill/SKILL-stack-policy.md`. Nada fuera del stack sin aprobación.
- Skills: elegir una primaria con `IA_Skill/SKILL-instruction-router.md`; catálogo completo en `IA_Skill/README.md`.
  Adjuntar solo la skill que la tarea necesita (`#file:IA_Skill/<skill>.md`).
- Soft delete (nunca `DELETE` en tablas de negocio), IDs UUID/GUID, migraciones versionadas, respuesta de API estandarizada,
  nada hardcodeado, nunca tokens en `localStorage`/`sessionStorage`.
- Nunca sin confirmación: archivos de entorno, `DROP`/`DELETE FROM`, tecnologías fuera del stack, upgrades de runtime,
  pipelines de CI/CD, `docker build/push`, `aspire deploy`, servidores remotos, proveedores de IA no aprobados.
