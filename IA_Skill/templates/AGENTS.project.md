# AGENTS.md — [Nombre del proyecto]

<!-- Plantilla para Codigo/<proyecto>/AGENTS.md. Copiar, completar y borrar estos comentarios.
     Máximo ~100 líneas: solo lo que hace ÚNICO a este proyecto. Lo general ya está en el AGENTS.md raíz.
     Imperativo y verificable; nada de reglas de formato (eso es del linter). -->

## Contexto

- [Qué es el sistema en una línea] — [.NET 10 / Angular NN / NestJS NN / ...], ver `IA_Memoria/arquitectura.md`.
- Perfil de auth: [A — OIDC + BFF (IdP: ...) | B — Identity API endpoints]. Perfil de datos: [Equilibrado | Alto rendimiento].

## Comandos de verificación (ejecutar antes de terminar)

- Build: `[dotnet build src/Proyecto.sln --no-restore]`
- Tests unitarios: `[dotnet test --filter Category=Unit]`
- Formato / lint: `[dotnet format --verify-no-changes]` · `[npm run lint --prefix src/Web]`
- E2E (si el cambio tiene UI): `[npm run test:e2e]` con `[comando para levantar la app / AppHost]`

## Reglas locales

- [Regla propia del proyecto, ej.: "Toda consulta nueva respeta el filtro global de TenantId; nunca `.IgnoreQueryFilters()` sin aprobación"]
- [Ej.: "No modificar migraciones ya aplicadas en `src/Infrastructure/Migrations/`"]

## Referencias (leer bajo demanda)

- [Esquema de BD: `docs/database-schema.md`]
- [Flujo de autenticación: `docs/auth-flow.md`]
