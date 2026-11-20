# Skills oficiales de Microsoft para .NET (complementarias)

Copia curada de [github.com/dotnet/skills](https://github.com/dotnet/skills) — skills mantenidas
por el equipo de .NET de Microsoft, formato [Agent Skills](https://agentskills.io) (`SKILL.md` +
`references/`). Licencia MIT, copyright .NET Foundation and Contributors (ver `LICENSE`).

- **Versión instalada:** ver `SOURCE.txt` (commit, fecha, cantidad).
- **Qué se instala:** `skills.manifest` es la única lista. 30 de las 110 skills del repo.
- **Idioma:** inglés, sin modificar. **No editar** los archivos dentro de `dotnet*/`: el script de
  sincronización los sobrescribe. Las adaptaciones a la plantilla van en este README o en las
  skills propias de `IA_Skill/`.

---

## Regla de precedencia (obligatoria)

Estas skills **complementan** a las skills propias de `IA_Skill/`; no las reemplazan.

1. `CLAUDE.md` (y sus copias) → 2. `IA_Memoria/convenciones.md` → 3. skill propia de `IA_Skill/`
   → 4. skill oficial de esta carpeta.
2. Leer primero la skill propia de la situación (según la tabla de ruteo de `CLAUDE.md`); la
   oficial aporta el detalle técnico.
3. Si una skill oficial contradice a la plantilla, gana la plantilla. Conflictos ya identificados:

| Skill oficial | Lo que dice | Lo que aplica en la plantilla |
|---|---|---|
| `dotnet-aspnetcore/dotnet-webapi` | Errores como `ProblemDetails`; `TypedResults` como forma de respuesta | La **respuesta estandarizada** de `IA_Memoria/convenciones.md` en todos los endpoints. Arquitectura en capas de `SKILL-dotnet-best-practices.md`. UI de OpenAPI: Scalar (la skill oficial ya coincide en `AddOpenApi`/`MapOpenApi` y en no usar Swashbuckle) |
| `dotnet-aspnetcore/dotnet-webapi` | `MapDelete` / `[HttpDelete]` | El verbo DELETE es válido, pero la implementación es **soft delete** (`IsActive = 0`) |
| `dotnet-data/optimizing-ef-core-queries` | `ExecuteDeleteAsync` para borrados masivos | Prohibido en tablas de negocio → `ExecuteUpdateAsync` con `IsActive = false` |
| `dotnet-diag/dotnet-trace-collect`, `dump-collect` | Descargar herramientas (`curl`, `Invoke-WebRequest`) y capturar trazas/dumps en el servidor | El agente **propone** los comandos; el dev los ejecuta. El agente no accede a servidores remotos. Los dumps pueden contener datos sensibles: no subirlos a repos ni a herramientas externas |
| `dotnet-upgrade/migrate-dotnet8-to-dotnet9` | Migrar a .NET 9 | Política de versiones: solo LTS. Aplicar `8→9` y luego `9→10` **en el mismo upgrade** con destino `net10.0`; nunca liberar en .NET 9 |
| `dotnet-test/*` | Ejemplos con MSTest, NUnit, TUnit | El framework del stack es **xUnit**. Ignorar sugerencias de migrar a otro framework |
| Varias | Mencionan skills que **no** están instaladas (`find-untested-sources`, `test-tagging`, `writing-mstest-tests`, skills de `dotnet-msbuild`…) | Ignorar esas menciones, o agregarlas al manifest con aprobación |
| `dotnet-ai/technology-selection` | Proveedores `Azure.AI.OpenAI` / `OpenAI` / `Azure.AI.Inference` detrás de `IChatClient` | Las librerías están aprobadas, pero el **proveedor** es un servicio externo que recibe datos: se aprueba por proyecto y se registra en `IA_Memoria/arquitectura.md`. Datos confidenciales o personales solo a proveedores aprobados para ese nivel de dato |
| `dotnet-ai/technology-selection` | `Microsoft.Agents.AI` (prerelease), `Microsoft.Extensions.AI.DataIngestion` (preview) | Política de versiones estables: un paquete prerelease/preview requiere **aprobación explícita por proyecto** mientras no tenga versión estable |
| `dotnet-ai/technology-selection` | Vector stores: Azure AI Search, Milvus, MongoDB, Pinecone, Qdrant, Redis… | Aprobado: vectores dentro de la BD del stack (PostgreSQL + pgvector, o SQL Server con tipo vector cuando la versión lo soporte). Cualquier otro store requiere aprobación |
| `dotnet-ai/technology-selection` | Entrenar modelos custom en Python (PyTorch/TensorFlow) y exportar a ONNX | Python sigue restringido a tooling interno: entrenar en Python requiere aprobación explícita. Inferencia con ONNX Runtime en .NET sí está aprobada |
| `dotnet-diag/microbenchmarking` | Crear proyectos de benchmark y `dotnet add package BenchmarkDotNet` sin versión | BenchmarkDotNet aprobado **solo** en proyectos de benchmark separados (`*.Benchmarks`), nunca referenciado por código productivo. Con Central Package Management, la versión va en `Directory.Packages.props`. Benchmarks en CI = cambio de pipeline → confirmación |

Cualquier otra herramienta o paquete que una skill oficial sugiera instalar (dotnet-trace,
ReportGenerator, un vector store fuera de la BD del stack, etc.) sigue la regla de la plantilla:
**confirmación explícita** antes de instalar.

---

## Skills instaladas

| Carpeta | Para qué |
|---|---|
| `dotnet/csharp-refactoring` | Refactorizar C# sin cambiar comportamiento (rename, extract, move, consolidar tipos) |
| `dotnet/dotnet-breaking-changes` | Cambiar código con consumidores que no controlamos (librerías NuGet compartidas, API pública) |
| `dotnet/msbuild` | `.csproj`/`.props`/`.targets`, builds lentos o fallidos, binlogs (incluye en `references/` el contenido de las skills del plugin `dotnet-msbuild`) |
| `dotnet-aspnetcore/dotnet-webapi` | Endpoints Web API: semántica HTTP, metadata OpenAPI, archivos `.http` |
| `dotnet-data/optimizing-ef-core-queries` | Revisar/optimizar acceso a datos con EF Core (N+1, round-trips, tracking, materialización) |
| `dotnet-upgrade/migrate-dotnet8-to-dotnet9` | Breaking changes 8→9 (primer tramo del upgrade LTS 8→10) |
| `dotnet-upgrade/migrate-dotnet9-to-dotnet10` | Breaking changes 9→10 (segundo tramo; incluye cambio de imágenes de contenedor) |
| `dotnet-upgrade/migrate-nullable-references` | Habilitar nullable reference types en código existente |
| `dotnet-nuget/convert-to-cpm` | Central Package Management (`Directory.Packages.props`) |
| `dotnet-diag/analyzing-dotnet-performance` | Revisión de código por ~50 anti-patrones de rendimiento |
| `dotnet-diag/dotnet-trace-collect` | Elegir y capturar trazas de rendimiento en entornos desplegados |
| `dotnet-diag/dump-collect` | Configurar/capturar crash dumps (incluye Docker) |
| `dotnet-diag/microbenchmarking` | Diseñar, ejecutar y comparar microbenchmarks con BenchmarkDotNet |
| `dotnet-ai/technology-selection` | Elegir e implementar IA/ML en .NET: ML.NET, LLM con Microsoft.Extensions.AI, agentes con Microsoft Agent Framework, RAG, ONNX Runtime, Ollama, Copilot SDK |
| `dotnet-test/run-tests` (+ `platform-detection`, `filter-syntax`) | Ejecutar tests y armar el comando `dotnet test` con filtros (VSTest/MTP) |
| `dotnet-test/code-testing` (+ `code-testing-extensions`) | Generar, reparar o reforzar tests de código existente |
| `dotnet-test/test-anti-patterns`, `assertion-quality`, `test-gap-analysis` (+ `test-analysis-extensions`) | Auditar la calidad de una suite de tests |
| `dotnet-test/coverage-analysis`, `crap-score` | Interpretar cobertura y riesgo CRAP |
| `dotnet-test/testability-obstacle`, `detect-static-dependencies` | Hacer testeable código con `DateTime.Now`, `File`, `Environment`, etc. |
| `dotnet-test/scaffold-dotnet-test-project` | Crear/reparar proyectos de test y su registro en `.sln`/`.slnx`/CI |
| `dotnet-test-migration/migrate-xunit-to-xunit-v3` | Migrar xUnit v2 → xUnit v3 |
| `dotnet-test-migration/migrate-vstest-to-mtp` | Migrar de VSTest a Microsoft.Testing.Platform |

**Scripts incluidos** (revisados al instalar: análisis local de solo lectura, sin llamadas de red):
`dotnet-upgrade/migrate-nullable-references/scripts/Get-NullableReadiness.ps1` y
`dotnet-test/coverage-analysis/scripts/*.ps1`. Al sincronizar una versión nueva, volver a revisar
cualquier script antes de ejecutarlo.

## Excluidas a propósito

| Plugin / skill | Motivo |
|---|---|
| `dotnet-blazor/*`, `dotnet-aspnetcore/convert-blazor-server-to-webapp` | El frontend del stack es Angular/React |
| `dotnet-maui/*`, `dotnet-winforms/*`, `dotnet-diag/android-*`, `apple-*` | Plataformas fuera del stack |
| `dotnet11/*`, `dotnet-upgrade/migrate-dotnet10-to-dotnet11` | .NET 11 es STS; la política es solo LTS. Se agregará `10→11` cuando se planee el salto 10→12 (LTS) |
| `dotnet-test/writing-mstest-tests`, `mtp-hot-reload`, `dotnet-test-migration/migrate-*-to-mstest`, `migrate-mstest-*` | El framework del stack es xUnit |
| `dotnet-msbuild/*` (21 skills) | Su contenido ya viene en `dotnet/msbuild/references/` |
| `dotnet/csharp-expert` | Es un enrutador hacia el marketplace de plugins; aquí el ruteo lo hace `CLAUDE.md` |
| `dotnet/setup-local-sdk` | Orientada a SDKs preview; la política es LTS estable |
| `dotnet-data/create-datadriven-aspnetcore` | Genera Razor Pages/Blazor/MVC y no sigue la arquitectura en capas de la plantilla |
| `dotnet-advanced/*`, `dotnet-upgrade/dotnet-aot-compat`, `thread-abort-migration`, `dotnet-template-engine/*`, `dotnet-test/find-untested-sources`, `test-smell-detection`, `test-tagging`, `test-value-evidence`, `grade-tests`, testability wrappers, `dotnet-experimental/*` | Nicho para este stack, dependencias externas (tree-sitter) o experimentales. Candidatas a agregar si un proyecto las necesita |

---

## Actualizar o cambiar la selección

```powershell
# Windows
.\IA_Skill\dotnet-official\sync-dotnet-skills.ps1
```

```bash
# Linux / macOS / Git Bash
./IA_Skill/dotnet-official/sync-dotnet-skills.sh
```

El script clona solo `plugins/` del repo en una carpeta temporal, valida que todas las entradas del
manifest existan (si alguna se renombró, aborta sin tocar nada), reemplaza las carpetas `dotnet*/`,
copia `LICENSE` y reescribe `SOURCE.txt`. Acepta la ruta de un clon existente para trabajar sin red.

Después de sincronizar:
1. Revisar el diff (`git diff IA_Skill/dotnet-official`) — es contenido de terceros que los agentes
   van a seguir. Buscar scripts nuevos y cambios que choquen con la tabla de precedencia.
2. Si se agregó o quitó una skill del manifest, actualizar el ruteo en `CLAUDE.md`, `AGENTS.md`,
   `.gemini/GEMINI.md`, `.github/copilot-instructions.md` y `.cursor/rules/project.mdc`.
3. Actualizar la tabla de conflictos de este README si aparece uno nuevo.

## Alternativa: instalarlas como plugin (por desarrollador)

Claude Code, GitHub Copilot CLI y Codex pueden instalar el marketplace oficial directamente
(ver el README del repo). En Claude Code:

```
/plugin marketplace add dotnet/skills
/plugin install <plugin>@dotnet-agent-skills
```

Eso instala plugins completos (todas sus skills, sin la regla de precedencia ni el filtro de stack)
y solo para ese desarrollador. Para el equipo, la fuente compartida es esta carpeta.
