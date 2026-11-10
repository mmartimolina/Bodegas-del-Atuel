from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from psycopg import Error as PsycopgError
from psycopg_pool import ConnectionPool

from app.config import Settings, settings
from app.database import create_pool
from app.errors import handle_database_error
from app.routes import router


def create_app(config: Settings = settings) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        pool: ConnectionPool = create_pool(config)
        pool.open()
        try:
            app.state.pool = pool
            yield
        finally:
            pool.close()

    application = FastAPI(
        title="Bodegas del Atuel API",
        version="1.0.0",
        description=(
            "API REST para vinos, clientes, ventas, movimientos y reportes. "
            "Las reglas de negocio y el stock se controlan en PostgreSQL."
        ),
        lifespan=lifespan,
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origins=list(config.cors_origins),
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Content-Type"],
    )
    application.add_exception_handler(PsycopgError, handle_database_error)
    application.include_router(router)
    return application


app = create_app()
