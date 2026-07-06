# SKILL — Python FastAPI Best Practices

## Cuándo usar esta skill
Antes de crear o modificar cualquier archivo del backend Python de
`Codigo/Reportes/ReporteadorV2/` (ReporteadorV2). Leer antes de implementar
routers, servicios, clientes HTTP hacia Azure DevOps o generación de PDF.

> Python (FastAPI) está aprobado en `CLAUDE.md` **solo para este tooling
> interno de reporting** — no usarlo como backend de una app de línea de
> negocio sin la misma aprobación explícita.

Este backend no tiene base de datos ni ORM: es un proxy hacia la API REST
de Azure DevOps + un generador de reportes/PDF. No forzar patrones de
Repository/Entity que no aplican aquí.

---

## Estructura de proyecto (obligatoria)

```
Codigo/Reportes/ReporteadorV2/backend/
├── app/
│   ├── main.py                  # Instancia FastAPI, CORS, exception handlers, routers
│   ├── config.py                # Settings vía pydantic-settings (variables de entorno)
│   ├── core/
│   │   ├── responses.py         # Envelope ApiResponse estandarizado
│   │   ├── exceptions.py        # Excepciones de dominio (AdoApiError, PatRequeridoError, ...)
│   │   └── security.py          # Extracción/validación del PAT desde header (nunca desde body/query)
│   ├── clients/
│   │   └── ado_client.py        # Wrapper httpx async sobre la REST API de Azure DevOps
│   ├── routers/
│   │   ├── reportes.py          # POST /api/v1/reportes/generar
│   │   └── bugs.py              # GET /api/v1/bugs/resumen
│   ├── services/
│   │   ├── reporte_service.py   # Reutiliza la lógica de Reporteador/ado_reporte.py
│   │   └── bugs_service.py      # WIQL + agregaciones para el dashboard de bugs
│   └── schemas/
│       ├── reporte.py           # Pydantic models de request/response
│       └── bugs.py
├── tests/                       # Espejo de app/ — ver SKILL-python-test-frameworks.md
├── requirements.txt
└── Dockerfile
```

Regla: un router = un dominio (`reportes`, `bugs`), igual que "un módulo NestJS
= un contexto de negocio". No crear routers por tipo técnico.

---

## Configuración con pydantic-settings

```python
# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="REPORTEADOR_")

    ado_org: str = "bsidevsts"
    ado_project: str = "IMSS.CE-MIGRACION-APPS"
    allowed_origins: list[str] = ["http://localhost:8080"]
    max_pat_length: int = 200  # sanity check, no valida el PAT en sí

settings = Settings()
```

Nunca hardcodear org/project/URLs base fuera de `config.py`. Nunca meter el
PAT en `Settings` — el PAT viaja por request, no vive en el proceso del
servidor (ver `SKILL-security-python.md`).

---

## Cliente Azure DevOps (reemplaza `requests` por `httpx` async)

```python
# app/clients/ado_client.py
import httpx
from app.core.exceptions import AdoApiError

class AdoClient:
    def __init__(self, org: str, project: str, pat: str):
        self._base = f"https://dev.azure.com/{org}/{project}/_apis"
        self._client = httpx.AsyncClient(
            auth=("", pat),  # Basic Auth — httpx codifica base64(":"+pat) automáticamente
            timeout=15.0,
        )

    async def get(self, path: str, api_version: str = "7.1") -> dict:
        resp = await self._client.get(f"{self._base}/{path}", params={"api-version": api_version})
        if resp.is_error:
            raise AdoApiError(status=resp.status_code, detail=resp.text[:300])
        return resp.json()

    async def post(self, path: str, body: dict, api_version: str = "7.1") -> dict:
        resp = await self._client.post(f"{self._base}/{path}", json=body, params={"api-version": api_version})
        if resp.is_error:
            raise AdoApiError(status=resp.status_code, detail=resp.text[:300])
        return resp.json()

    async def aclose(self) -> None:
        await self._client.aclose()
```

Usar siempre `async with` o cerrar explícitamente el cliente (`aclose`) —
nunca dejar conexiones `httpx.AsyncClient` abiertas entre requests.

```python
# app/core/security.py — inyección del cliente vía dependency, PAT desde header
from fastapi import Header, HTTPException, Depends
from app.clients.ado_client import AdoClient
from app.config import settings

async def get_ado_client(x_ado_pat: str = Header(..., alias="X-ADO-PAT")) -> AdoClient:
    if not x_ado_pat or len(x_ado_pat) > settings.max_pat_length:
        raise HTTPException(status_code=401, detail="PAT de Azure DevOps requerido o inválido")
    client = AdoClient(settings.ado_org, settings.ado_project, x_ado_pat)
    try:
        yield client
    finally:
        await client.aclose()
```

---

## Respuesta estandarizada

Sigue la convención de `CLAUDE.md` (`{ success, data, message, errors }`),
igual que las apps .NET/NestJS del resto del stack.

```python
# app/core/responses.py
from typing import Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar("T")

class ApiResponse(BaseModel, Generic[T]):
    success: bool
    data: Optional[T] = None
    message: str = ""
    errors: list[str] = []

    @classmethod
    def ok(cls, data: T, message: str = "Operación exitosa") -> "ApiResponse[T]":
        return cls(success=True, data=data, message=message, errors=[])

    @classmethod
    def fail(cls, message: str, errors: list[str] | None = None) -> "ApiResponse[None]":
        return cls(success=False, data=None, message=message, errors=errors or [])
```

**Excepción documentada:** el endpoint que devuelve el PDF generado
(`GET /api/v1/reportes/{id}/pdf`) responde con `FileResponse`/`StreamingResponse`
binario, no con el envelope JSON — es la excepción estándar de la industria
para descargas de archivo. No envolver bytes de PDF en JSON.

---

## Routers — sin lógica de negocio

```python
# app/routers/reportes.py
from fastapi import APIRouter, Depends
from app.core.responses import ApiResponse
from app.core.security import get_ado_client
from app.clients.ado_client import AdoClient
from app.schemas.reporte import GenerarReporteRequest, ReporteResumen
from app.services.reporte_service import generar_reporte

router = APIRouter(prefix="/api/v1/reportes", tags=["reportes"])

@router.post("/generar", response_model=ApiResponse[ReporteResumen])
async def generar(
    body: GenerarReporteRequest,
    ado: AdoClient = Depends(get_ado_client),
):
    resumen = await generar_reporte(ado, body)
    return ApiResponse.ok(resumen, "Reporte generado correctamente")
```

Responsabilidad del router: recibir/validar request (vía Pydantic), delegar
al service, envolver en `ApiResponse`. Nunca llamar `AdoClient` directo desde
el router ni construir el Markdown/PDF ahí.

---

## Schemas con Pydantic — validación de entrada

```python
# app/schemas/reporte.py
from datetime import date
from pydantic import BaseModel, field_validator

class GenerarReporteRequest(BaseModel):
    desde: date
    hasta: date

    @field_validator("hasta")
    @classmethod
    def hasta_no_antes_de_desde(cls, v: date, info) -> date:
        if "desde" in info.data and v < info.data["desde"]:
            raise ValueError("'hasta' no puede ser anterior a 'desde'")
        return v

class ReporteResumen(BaseModel):
    id: str
    desde: date
    hasta: date
    total_commits: int
    total_prs: int
    total_bugs: int
    url_pdf: str
```

No aceptar `org`/`project` como texto libre del request si no hace falta —
usar los de `config.py` por default y, si se permiten distintos, validarlos
contra un patrón/allowlist (ver `SKILL-security-python.md`, riesgo SSRF).

---

## Manejo de excepciones — exception handlers globales

```python
# app/core/exceptions.py
class AdoApiError(Exception):
    def __init__(self, status: int, detail: str):
        self.status = status
        self.detail = detail

# app/main.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.core.exceptions import AdoApiError
from app.core.responses import ApiResponse

app = FastAPI(title="ReporteadorV2 API")

@app.exception_handler(AdoApiError)
async def ado_api_error_handler(request: Request, exc: AdoApiError):
    return JSONResponse(
        status_code=502 if exc.status >= 500 else exc.status,
        content=ApiResponse.fail(f"Error al consultar Azure DevOps: {exc.detail}").model_dump(),
    )

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    # Loggear el detalle completo internamente, nunca exponerlo al cliente
    import logging
    logging.getLogger("reporteador").exception("Error no controlado")
    return JSONResponse(status_code=500, content=ApiResponse.fail("Error interno del servidor").model_dump())
```

Los errores de validación de Pydantic (422) ya vienen bien formados por
FastAPI — solo envolverlos en `ApiResponse` con un handler de
`RequestValidationError` si se quiere mantener el formato uniforme.

---

## Configuración de la app (`main.py`)

```python
# app/main.py (continuación)
from fastapi.middleware.cors import CORSMiddleware
from app.routers import reportes, bugs
from app.config import settings

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,   # nunca "*" — ver skill de seguridad
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "X-ADO-PAT"],
)

app.include_router(reportes.router)
app.include_router(bugs.router)
```

---

## Generación de PDF y trabajo pesado — no bloquear el event loop

La generación de PDF (headless Chrome/Edge, igual que `ado_reporte.py`) y
las consultas WIQL con muchos work items son operaciones lentas — no las
ejecutes de forma síncrona dentro de un `async def` sin `await`, bloquean
todo el servidor.

```python
# app/services/reporte_service.py
import asyncio
import subprocess

async def generar_pdf(md_path: str, pdf_path: str) -> None:
    # subprocess.run es bloqueante — correrlo en threadpool, no en el event loop
    await asyncio.to_thread(_generar_pdf_sync, md_path, pdf_path)

def _generar_pdf_sync(md_path: str, pdf_path: str) -> None:
    navegador = _buscar_navegador()  # misma lógica que ado_reporte.py
    subprocess.run(
        [navegador, "--headless", "--disable-gpu", f"--print-to-pdf={pdf_path}", md_path],
        check=True,
        timeout=60,
    )
```

Ver `SKILL-security-python.md` para por qué `subprocess.run` con lista de
argumentos (nunca `shell=True` ni f-strings armando el comando).

Si un reporte tarda más de unos segundos, considerar un endpoint que
dispare la generación (`202 Accepted` + `id` de job) y otro que consulte el
estado, en vez de mantener al cliente esperando en una sola llamada HTTP —
mismo patrón que ya usan los flujos multi-step documentados en
`IA_Skill/frontend-design/SKILL-animation-microinteractions.md` (loading state).

---

## Logging

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("reporteador")

logger.info("Reporte generado: %s (%s a %s)", reporte_id, desde, hasta)
```

Reglas:
- Nunca loggear el PAT ni ningún header `Authorization`/`X-ADO-PAT`.
- Loggear en inglés-técnico (nombres de nivel/campo) pero el mensaje puede
  ir en español, igual que el resto del proyecto (`IA_Memoria/convenciones.md`).

---

## Convenciones de nomenclatura Python (este proyecto)

- Archivos y módulos: `snake_case` → `ado_client.py`, `reporte_service.py`
- Clases: `PascalCase` → `AdoClient`, `ApiResponse`
- Funciones y variables: `snake_case` en inglés para código **nuevo**
  (`generar_reporte` es aceptable si se prefiere mantener el idioma de
  dominio de negocio en español, pero sé consistente dentro del mismo
  archivo — no mezclar `generar_reporte` con `getPdfPath` en el mismo módulo)
- Constantes: `SCREAMING_SNAKE_CASE`
- El código legado de `ado_reporte.py` (funciones/variables en español) no
  se renombra — ver excepción registrada en `IA_Memoria/convenciones.md`

---

## Checklist antes de PR

- [ ] Router sin lógica de negocio — todo delegado a `services/`
- [ ] Todo request/response tipado con Pydantic (`schemas/`)
- [ ] Respuesta envuelta en `ApiResponse` (excepto descargas binarias)
- [ ] PAT solo leído de header (`X-ADO-PAT`), nunca de query/body/log
- [ ] `httpx.AsyncClient` cerrado (`aclose`) al final del request
- [ ] Trabajo bloqueante (subprocess, PDF, loops largos) en `asyncio.to_thread`
- [ ] CORS con `allow_origins` explícito, nunca `"*"`
- [ ] Sin credenciales ni URLs hardcodeadas fuera de `config.py`
- [ ] Excepciones de ADO capturadas y traducidas a `ApiResponse.fail(...)`
