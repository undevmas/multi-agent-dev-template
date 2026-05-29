# SKILL — Web Search (MCP)

## Qué es MCP
Model Context Protocol — un protocolo que permite a Claude Code conectarse
a herramientas externas (como plugins). El MCP de Web Search le permite
buscar información actualizada en internet mientras trabaja en el proyecto.

---

## Cuándo usar búsqueda web

Solo cuando estas fuentes no responden la duda:
1. CLAUDE.md del proyecto
2. Skills en IA_Skill/
3. Código actual del proyecto
4. Conocimiento base de Claude (hasta agosto 2025)

### Casos válidos para buscar
- Versión más reciente y estable de una dependencia antes de instalarla
- Error muy específico con número de versión de librería
- Cambio de API en versión reciente de Angular / .NET / NestJS
- CVE o vulnerabilidad de seguridad reciente
- Compatibilidad entre versiones de dependencias

### Casos donde NO buscar
- Conceptos generales de programación (ya los sé)
- Patrones de arquitectura conocidos (REST, MVC, Repository, etc.)
- Sintaxis básica del stack del proyecto
- Algo que ya está respondido en CLAUDE.md o en las Skills

---

## Cómo formular la búsqueda

Incluir siempre la versión específica:
```
"NestJS 10 guard JWT example 2024"
"Angular 17 standalone components lazy loading"
".NET 8 minimal API FluentValidation"
"TypeORM PostgreSQL migration rollback"
```

Priorizar fuentes oficiales:
- Angular: `angular.dev` o `angular.io`
- .NET: `learn.microsoft.com`
- NestJS: `docs.nestjs.com`
- TypeORM: `typeorm.io`
- Node.js: `nodejs.org`

---

## Instalación del MCP Web Search

```bash
# Opción 1 — desde Claude Code CLI
/mcp add web-search

# Opción 2 — configuración manual
# Editar: ~/.claude/mcp.json
{
  "mcpServers": {
    "web-search": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-web-search"]
    }
  }
}
```

Verificar que está activo:
```bash
/mcp list
```

---

## Otros MCPs útiles para este proyecto

| MCP | Para qué | Instalación |
|---|---|---|
| `web-search` | Buscar documentación actualizada | Ver arriba |
| `github` | Ver issues, PRs, código de repos públicos | `/mcp add github` |
| `postgres` | Consultar esquema de BD directamente | Requiere config de conexión |
| `filesystem` | Acceso avanzado a archivos locales | Incluido en Claude Code |

> Nota: Verificar disponibilidad actualizada en `docs.claude.ai`
