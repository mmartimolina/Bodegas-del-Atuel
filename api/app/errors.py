import logging
from collections.abc import Mapping

from fastapi import Request
from fastapi.responses import JSONResponse
from psycopg import Error as PsycopgError, OperationalError

logger = logging.getLogger(__name__)

SQLSTATE_RESPONSES: Mapping[str, tuple[int, str]] = {
    "23505": (409, "El recurso ya existe."),
    "23503": (409, "La operación referencia un recurso inexistente o protegido."),
    "23514": (422, "La operación viola una regla de negocio."),
    "23502": (422, "Falta un dato obligatorio."),
    "P0001": (422, "La operación fue rechazada por una regla de negocio."),
    "P0002": (404, "El recurso solicitado no existe."),
    "22P02": (422, "El formato de uno de los valores no es válido."),
    "40001": (503, "Conflicto concurrente; vuelva a intentar la operación."),
    "40P01": (503, "Conflicto concurrente; vuelva a intentar la operación."),
}


async def handle_database_error(request: Request, error: PsycopgError) -> JSONResponse:
    sqlstate = error.sqlstate
    if isinstance(error, OperationalError) or (sqlstate and sqlstate.startswith("08")):
        return JSONResponse(
            status_code=503,
            content={"detail": "La base de datos no está disponible."},
            headers={"Retry-After": "1"},
        )

    status_code, message = SQLSTATE_RESPONSES.get(
        sqlstate or "", (500, "Ocurrió un error al procesar la operación.")
    )
    if status_code == 500:
        logger.error(
            "Error PostgreSQL no clasificado en %s",
            request.url.path,
            exc_info=(type(error), error, error.__traceback__),
        )

    headers = {"Retry-After": "1"} if status_code == 503 else None
    return JSONResponse(status_code=status_code, content={"detail": message}, headers=headers)
