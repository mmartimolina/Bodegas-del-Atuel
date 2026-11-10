from typing import Any
from uuid import uuid4

from psycopg import Connection

from app.schemas import IncomeInput, IncomeLineInput, TransferInput, TransferLineInput


def create_transfer(connection: Connection, transfer: TransferInput) -> dict[str, Any]:
    with connection.transaction():
        connection.execute('LOCK TABLE "Transferencia" IN EXCLUSIVE MODE')
        number = connection.execute(
            'SELECT COALESCE(MAX(numero), 0) + 1 AS numero FROM "Transferencia"'
        ).fetchone()["numero"]
        connection.execute(
            'INSERT INTO "Transferencia" (numero, sala) VALUES (%s, %s)',
            (number, transfer.sala),
        )
    result = get_transfer(connection, number)
    if result is None:
        raise RuntimeError("La transferencia creada no se pudo recuperar.")
    return result


def add_transfer_lines(
    connection: Connection, number: int, lines: list[TransferLineInput]
) -> dict[str, Any] | None:
    with connection.transaction():
        for line in lines:
            connection.execute(
                """
                INSERT INTO "Renglon_Transferencia" (transferencia, vino, cantidad)
                VALUES (%s, %s, %s)
                """,
                (number, line.vino, line.cantidad),
            )
    return get_transfer(connection, number)


def get_transfer(connection: Connection, number: int) -> dict[str, Any] | None:
    transfer = connection.execute(
        """
        SELECT t.numero, t.fecha_confeccion, t.estado, t.sala,
               s.calle, s.numero AS sala_numero
        FROM "Transferencia" t
        JOIN "Sala" s ON s.id_sala = t.sala
        WHERE t.numero = %s
        """,
        (number,),
    ).fetchone()
    if transfer is None:
        return None
    transfer["renglones"] = connection.execute(
        """
        SELECT rt.vino, v.nombre, rt.cantidad
        FROM "Renglon_Transferencia" rt
        JOIN "Vino" v ON v.codigo = rt.vino
        WHERE rt.transferencia = %s
        ORDER BY rt.vino
        """,
        (number,),
    ).fetchall()
    return transfer


def change_transfer_state(
    connection: Connection, number: int, new_state: str
) -> dict[str, Any] | None:
    with connection.transaction():
        result = connection.execute(
            'UPDATE "Transferencia" SET estado = %s WHERE numero = %s RETURNING numero',
            (new_state, number),
        ).fetchone()
        if result is None:
            return None
    return get_transfer(connection, number)


def process_transfer(connection: Connection, number: int) -> dict[str, Any] | None:
    with connection.transaction():
        exists = connection.execute(
            'SELECT 1 FROM "Transferencia" WHERE numero = %s', (number,)
        ).fetchone()
        if exists is None:
            return None
        connection.execute("CALL sp_procesar_transferencia(%s)", (number,))
    return get_transfer(connection, number)


def create_income(connection: Connection, income: IncomeInput) -> dict[str, Any]:
    code = f"API-{uuid4().hex}"
    connection.execute(
        """
        INSERT INTO "Ingreso" (codigo, fecha, transportista, bodega_origen)
        VALUES (%s, CURRENT_DATE, %s, %s)
        """,
        (code, income.transportista, income.bodega_origen),
    )
    return {
        "codigo": code,
        "estado": "en_confeccion",
        "transportista": income.transportista,
        "bodega_origen": income.bodega_origen,
        "renglones": [],
    }


def add_income_lines(
    connection: Connection, code: str, lines: list[IncomeLineInput]
) -> dict[str, Any] | None:
    with connection.transaction():
        exists = connection.execute(
            'SELECT codigo FROM "Ingreso" WHERE codigo = %s FOR UPDATE', (code,)
        ).fetchone()
        if exists is None:
            return None
        for line in lines:
            connection.execute(
                'INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES (%s, %s, %s)',
                (code, line.vino, line.cantidad),
            )
    return get_income(connection, code)


def get_income(connection: Connection, code: str) -> dict[str, Any] | None:
    income = connection.execute(
        """
        SELECT i.codigo, i.fecha, i.estado, i.transportista,
               t.razon_social AS transportista_nombre,
               i.bodega_origen, b.razon_social AS bodega_nombre
        FROM "Ingreso" i
        JOIN "Transportista" t ON t.codigo = i.transportista
        JOIN "Bodega" b ON b.cuit = i.bodega_origen
        WHERE i.codigo = %s
        """,
        (code,),
    ).fetchone()
    if income is None:
        return None
    income["renglones"] = connection.execute(
        """
        SELECT ri.vino, v.nombre, ri.cantidad
        FROM "Renglon_Ingreso" ri
        JOIN "Vino" v ON v.codigo = ri.vino
        WHERE ri.ingreso = %s
        ORDER BY ri.vino
        """,
        (code,),
    ).fetchall()
    return income


def change_income_state(
    connection: Connection, code: str, new_state: str
) -> dict[str, Any] | None:
    with connection.transaction():
        result = connection.execute(
            'UPDATE "Ingreso" SET estado = %s WHERE codigo = %s RETURNING codigo',
            (new_state, code),
        ).fetchone()
        if result is None:
            return None
    return get_income(connection, code)


def process_income(connection: Connection, code: str) -> dict[str, Any] | None:
    with connection.transaction():
        exists = connection.execute(
            'SELECT 1 FROM "Ingreso" WHERE codigo = %s', (code,)
        ).fetchone()
        if exists is None:
            return None
        connection.execute("CALL sp_procesar_ingreso(%s)", (code,))
    return get_income(connection, code)
