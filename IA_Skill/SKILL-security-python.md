# SKILL — Security Python (FastAPI / ReporteadorV2)

## Cuándo usar esta skill
Al crear o revisar cualquier router, servicio, cliente HTTP o configuración
del backend Python de `Codigo/Reportes/ReporteadorV2/` que maneje el PAT de
Azure DevOps, genere archivos (PDF), o reciba input del usuario (org,
proyecto, fechas, tags).

Este backend no maneja contraseñas, JWT propio ni base de datos — el
"secreto" central es el **PAT de Azure DevOps** que el usuario provee por
request. Las reglas de esta skill giran en torno a eso.

---

## El PAT nunca se persiste en el servidor

```python
# MAL — guardar el PAT en variable de entorno, archivo, caché o BD
os.environ["ADO_PAT"] = pat  # nunca
with open("pat.txt", "w") as f: f.write(pat)  # nunca
redis_client.set("pat", pat)  # nunca, ni con TTL

# BIEN — el PAT vive solo en el scope del request, vía header
async def get_ado_client(x_ado_pat: str = Header(..., alias="X-ADO-PAT")) -> AdoClient:
    client = AdoClient(settings.ado_org, settings.ado_project, x_ado_pat)
    try:
        yield client
    finally:
        await client.aclose()  # el cliente (y el PAT que envuelve) muere con el request
```

Esto mantiene la misma garantía que ya tiene `panel-bugs.html` y
`ado_reporte.py`: el PAT nunca toca disco. Ver decisión registrada en
`IA_Memoria/progreso.md`.

---

## Nunca loggear el PAT

```python
# MAL
logger.info(f"Request con headers: {request.headers}")  # incluye X-ADO-PAT
logger.debug(f"Llamando a ADO con PAT={pat}")

# BIEN — loggear metadata, nunca el secreto
logger.info("Consultando repos de %s/%s", org, project)
```

Si se usa un middleware de logging de requests (ej. para medir latencia),
excluir explícitamente el header `X-ADO-PAT` del log:

```python
SENSITIVE_HEADERS = {"x-ado-pat", "authorization"}

def headers_seguros(headers: dict) -> dict:
    return {k: ("***" if k.lower() in SENSITIVE_HEADERS else v) for k, v in headers.items()}
```

---

## Validar org/proyecto para evitar SSRF

El backend arma URLs hacia `dev.azure.com/{org}/{project}/...` — si `org`/
`project` vienen de input del usuario sin validar, un request podría
intentar apuntar a otro host o path arbitrario.

```python
import re

ORG_PROJECT_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,100}$")

def validar_org_o_project(valor: str) -> str:
    if not ORG_PROJECT_PATTERN.match(valor):
        raise HTTPException(status_code=400, detail="Organización o proyecto con formato inválido")
    return valor
```

Preferir, cuando sea posible, **no** aceptar `org`/`project` como input
libre — usar los valores fijos de `config.py` (`bsidevsts` /
`IMSS.CE-MIGRACION-APPS`) y solo parametrizar lo que de verdad varía
(fechas, tags). Menos superficie de ataque.

---

## `subprocess` para generar PDF — nunca `shell=True`

```python
# MAL — permite inyección de comandos si algún dato del usuario llega aquí
subprocess.run(f"{navegador} --print-to-pdf={ruta_pdf} {ruta_html}", shell=True)

# BIEN — lista de argumentos, sin shell
subprocess.run(
    [navegador, "--headless", "--disable-gpu", f"--print-to-pdf={ruta_pdf}", ruta_html],
    check=True,
    timeout=60,
)
```

`ruta_pdf` y `ruta_html` deben ser generados por el backend (ej. con
`tempfile` + `uuid`), nunca construidos a partir de un nombre de archivo que
venga del usuario — evita path traversal (`../../etc/passwd`).

```python
import tempfile, uuid

def ruta_temporal_segura(sufijo: str) -> str:
    nombre = f"{uuid.uuid4()}{sufijo}"
    return str(Path(tempfile.gettempdir()) / nombre)
```

---

## Validación de entrada con Pydantic — no confiar en nada del cliente

```python
from pydantic import BaseModel, field_validator
from datetime import date

class GenerarReporteRequest(BaseModel):
    desde: date
    hasta: date

    @field_validator("hasta")
    @classmethod
    def rango_valido(cls, v: date, info) -> date:
        desde = info.data.get("desde")
        if desde and v < desde:
            raise ValueError("'hasta' no puede ser anterior a 'desde'")
        if desde and (v - desde).days > 366:
            raise ValueError("El rango no puede superar 366 días")  # evita queries masivas accidentales
        return v
```

Cualquier tag/nombre de repo que el usuario envíe para crear/filtrar bugs
debe validarse contra la lista conocida de repos (`IA_Memoria/progreso.md`
tiene el mapeo repo↔negocio), no aceptarse como texto libre sin cotejar.

---

## CORS — nunca `allow_origins=["*"]`

```python
# MAL
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True)

# BIEN — origen explícito del frontend (localhost en dev, dominio real en la VM en prod)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,  # ej. ["https://reportes.tudominio.mx"]
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "X-ADO-PAT"],
)
```

Con `allow_credentials=True` nunca se puede usar `"*"` — pero aquí no se
usan cookies de sesión, así que ni siquiera hace falta `allow_credentials`.

---

## Proteger el backend propio, aunque no tenga "usuarios"

Este backend no implementa login (el PAT lo trae el usuario en cada
request), pero **si se expone más allá de `localhost`** (ej. en la VM del
usuario, accesible por IP/dominio), debe protegerse el acceso al backend en
sí — de lo contrario cualquiera en la red podría usarlo como proxy abierto
hacia Azure DevOps con su propio PAT.

Opciones, de más simple a más robusta:
1. Restringir por red: exponer el backend solo en una VPN/red interna, o
   con un firewall/`ufw` limitando IPs de origen.
2. Reverse proxy con autenticación básica (nginx/Traefik + `htpasswd`) delante
   del backend — no requiere tocar el código Python.
3. Shared secret propio de la app (header `X-App-Key` fijo, distinto del PAT
   de ADO) validado con una dependency de FastAPI, si el reverse proxy no es
   viable.

No implementar JWT/OAuth2 completo para esto — sería sobre-ingeniería para
una herramienta interna de un solo equipo; usar la opción 1 o 2 primero.

---

## Rate limiting básico (opcional, si el backend queda expuesto)

```python
# pip install slowapi
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@router.post("/generar")
@limiter.limit("10/minute")
async def generar(request: Request, body: GenerarReporteRequest, ado: AdoClient = Depends(get_ado_client)):
    ...
```

Relevante sobre todo para el endpoint que dispara generación de PDF
(costoso) y para evitar golpear los rate limits de la propia API de Azure
DevOps por accidente.

---

## Checklist de seguridad antes de PR

### PAT y secretos
- [ ] El PAT solo se lee de header (`X-ADO-PAT`), nunca de query string ni body
- [ ] El PAT nunca se escribe a disco, caché, BD ni variable de entorno del proceso
- [ ] El PAT nunca aparece en logs (incluyendo logs de request/response completos)
- [ ] Sin PATs reales en tests ni fixtures

### Input del usuario
- [ ] `org`/`project` validados contra patrón o allowlist si son parametrizables
- [ ] Rango de fechas validado (orden correcto, límite razonable de días)
- [ ] Tags/nombres de repo cotejados contra la lista conocida, no texto libre sin validar

### Subprocess y archivos
- [ ] `subprocess.run` con lista de argumentos, nunca `shell=True` ni f-strings armando el comando
- [ ] Rutas de archivos temporales generadas por el backend (`uuid`/`tempfile`), nunca a partir de input del usuario
- [ ] Archivos temporales de PDF/HTML limpiados después de servir la respuesta

### Red y exposición
- [ ] CORS con `allow_origins` explícito, nunca `"*"`
- [ ] Si el backend se expone fuera de `localhost`: acceso restringido por red, reverse-proxy auth, o shared secret propio
- [ ] Rate limiting en el endpoint de generación de reportes/PDF si está expuesto más allá de la red local

### Manejo de errores
- [ ] Errores de la API de Azure DevOps no exponen detalles internos innecesarios al cliente (sí el mensaje de ADO, no stack traces)
- [ ] Excepciones no controladas devuelven 500 genérico, detalle completo solo en logs internos
