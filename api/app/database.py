from collections.abc import Generator

from fastapi import Request
from psycopg import Connection, sql
from psycopg.conninfo import make_conninfo
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app.config import Settings


def configure_connection(connection: Connection, role: str) -> None:
    connection.execute(sql.SQL("SET ROLE {}").format(sql.Identifier(role)))
    connection.commit()


def create_pool(settings: Settings) -> ConnectionPool:
    return ConnectionPool(
        conninfo=settings.conninfo,
        min_size=settings.pool_min_size,
        max_size=settings.pool_max_size,
        kwargs={"row_factory": dict_row},
        configure=lambda connection: configure_connection(connection, settings.db_role),
        open=False,
    )


def get_connection(request: Request) -> Generator[Connection, None, None]:
    pool: ConnectionPool = request.app.state.pool
    with pool.connection() as connection:
        yield connection
