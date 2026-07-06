# SKILL — Python Test Frameworks

## Cuándo usar esta skill
Al escribir, revisar o estructurar tests del backend Python de
`Codigo/Reportes/ReporteadorV2/`. Leer antes de crear cualquier archivo de
test.

Framework principal: pytest
Async: pytest-asyncio
HTTP integration: FastAPI `TestClient` (síncrono) / `httpx.AsyncClient` con `ASGITransport` (async)
Mocking de HTTP saliente hacia Azure DevOps: `respx` (mockea `httpx`) o `unittest.mock`
Assertions: `assert` nativo de pytest

---

## Estructura de tests

```
Codigo/Reportes/ReporteadorV2/backend/
├── app/
│   ├── services/reporte_service.py
│   └── routers/reportes.py
└── tests/
    ├── conftest.py                     # Fixtures compartidos
    ├── services/
    │   └── test_reporte_service.py
    ├── routers/
    │   └── test_reportes_router.py     # Tests de integración HTTP (TestClient)
    └── clients/
        └── test_ado_client.py          # Mockea las respuestas de dev.azure.com
```

Convención de nombres:
- Archivo: `test_[módulo].py`
- Función: `test_[qué hace]_[escenario]_[resultado esperado]`

Ejemplo: `def test_generar_reporte_sin_commits_en_periodo_retorna_totales_en_cero():`

---

## Configuración pytest

```ini
# pytest.ini o [tool.pytest.ini_options] en pyproject.toml
[pytest]
asyncio_mode = auto
testpaths = tests
addopts = --cov=app --cov-report=term-missing
```

```
# requirements-dev.txt
pytest
pytest-asyncio
pytest-cov
respx
```

---

## Fixtures compartidos

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client() -> TestClient:
    return TestClient(app)

@pytest.fixture
def pat_header() -> dict[str, str]:
    return {"X-ADO-PAT": "pat-de-prueba-no-real"}
```

---

## Tests unitarios de servicios — patrón AAA

```python
# tests/services/test_reporte_service.py
from datetime import date
from unittest.mock import AsyncMock
from app.services.reporte_service import generar_reporte
from app.schemas.reporte import GenerarReporteRequest

async def test_generar_reporte_agrega_commits_de_todos_los_repos():
    # Arrange
    ado_mock = AsyncMock()
    ado_mock.get.side_effect = [
        {"value": [{"commitId": "abc123", "author": {"name": "Jorge Mojica Huerta"}}]},
        {"value": []},
    ]
    request = GenerarReporteRequest(desde=date(2026, 1, 1), hasta=date(2026, 5, 7))

    # Act
    resumen = await generar_reporte(ado_mock, request)

    # Assert
    assert resumen.total_commits == 1
    assert ado_mock.get.call_count == 2

async def test_generar_reporte_con_hasta_antes_de_desde_lanza_error():
    from pydantic import ValidationError
    import pytest as pt

    with pt.raises(ValidationError):
        GenerarReporteRequest(desde=date(2026, 5, 7), hasta=date(2026, 1, 1))
```

---

## Mockeando el cliente HTTP hacia Azure DevOps con `respx`

Nunca dejar que un test golpee `dev.azure.com` de verdad — ni siquiera con
un PAT de prueba. `respx` intercepta las llamadas de `httpx`.

```python
# tests/clients/test_ado_client.py
import respx
from httpx import Response
from app.clients.ado_client import AdoClient
from app.core.exceptions import AdoApiError

@respx.mock
async def test_get_retorna_json_cuando_la_api_responde_200():
    respx.get("https://dev.azure.com/org/proj/_apis/git/repositories").mock(
        return_value=Response(200, json={"value": [{"name": "SGSOL-IMSS"}]})
    )
    client = AdoClient(org="org", project="proj", pat="fake-pat")

    result = await client.get("git/repositories")

    assert result["value"][0]["name"] == "SGSOL-IMSS"
    await client.aclose()

@respx.mock
async def test_get_lanza_ado_api_error_cuando_la_api_responde_401():
    respx.get("https://dev.azure.com/org/proj/_apis/git/repositories").mock(
        return_value=Response(401, text="PAT inválido o expirado")
    )
    client = AdoClient(org="org", project="proj", pat="fake-pat")

    import pytest as pt
    with pt.raises(AdoApiError) as exc_info:
        await client.get("git/repositories")
    assert exc_info.value.status == 401
    await client.aclose()
```

---

## Tests de integración de routers con `TestClient`

```python
# tests/routers/test_reportes_router.py
from unittest.mock import patch, AsyncMock

def test_generar_sin_header_pat_retorna_401(client):
    response = client.post("/api/v1/reportes/generar", json={"desde": "2026-01-01", "hasta": "2026-05-07"})
    assert response.status_code == 401

def test_generar_con_fechas_invalidas_retorna_422(client, pat_header):
    response = client.post(
        "/api/v1/reportes/generar",
        json={"desde": "2026-05-07", "hasta": "2026-01-01"},
        headers=pat_header,
    )
    assert response.status_code == 422

@patch("app.routers.reportes.generar_reporte", new_callable=AsyncMock)
def test_generar_con_datos_validos_retorna_envelope_estandarizado(mock_generar, client, pat_header):
    mock_generar.return_value.model_dump.return_value = {
        "id": "r1", "desde": "2026-01-01", "hasta": "2026-05-07",
        "total_commits": 10, "total_prs": 2, "total_bugs": 3, "url_pdf": "/reportes/r1/pdf",
    }
    response = client.post(
        "/api/v1/reportes/generar",
        json={"desde": "2026-01-01", "hasta": "2026-05-07"},
        headers=pat_header,
    )
    body = response.json()
    assert response.status_code == 200
    assert body["success"] is True
    assert body["data"]["total_commits"] == 10
    assert body["errors"] == []
```

No golpear Azure DevOps real ni en tests de integración — mockear el
service (`generar_reporte`) o el `AdoClient` inyectado, nunca la red.

---

## Nunca verificar el PAT en asserts ni fixtures reales

```python
# MAL — usar un PAT real de Azure DevOps en un test, aunque sea "solo de prueba"
PAT_REAL = "abcdef1234567890..."  # nunca

# BIEN — cualquier string sirve, el mock de respx nunca llama a la red real
pat_header = {"X-ADO-PAT": "pat-de-prueba-no-real"}
```

---

## Ejecutar tests

```bash
# Todos los tests
pytest

# Con cobertura
pytest --cov=app --cov-report=term-missing

# Un archivo específico
pytest tests/services/test_reporte_service.py

# Un test específico
pytest tests/services/test_reporte_service.py::test_generar_reporte_agrega_commits_de_todos_los_repos -v

# Watch mode (requiere pytest-watch)
ptw
```

---

## Cobertura mínima requerida

- `services/`: 80% mínimo (happy path + principales casos de error de la API de ADO)
- `clients/ado_client.py`: 90% (éxito, 401, 404, 5xx, timeout)
- `schemas/`: 100% de las validaciones custom (`field_validator`)
- `routers/`: cubiertos por tests de integración con `TestClient`
