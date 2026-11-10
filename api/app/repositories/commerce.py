from typing import Any

from psycopg import Connection

from app.schemas import SaleInput


def _next_number(connection: Connection, table: str) -> int:
    if table not in {'"Comprobante"', '"Transferencia"'}:
        raise ValueError("Nombre de tabla no permitido.")
    connection.execute(f"LOCK TABLE {table} IN EXCLUSIVE MODE")
    row = connection.execute(
        f"SELECT COALESCE(MAX(numero), 0) + 1 AS numero FROM {table}"
    ).fetchone()
    return row["numero"]


def get_comprobante(connection: Connection, numero: int) -> dict[str, Any] | None:
    receipt = connection.execute(
        """
        SELECT c.numero, c.fecha, c.cliente, cl.nombre AS cliente_nombre,
               c.sala, c.subtotal, c.descuento, c.total
        FROM "Comprobante" c
        JOIN "Cliente" cl ON cl.id_cliente = c.cliente
        WHERE c.numero = %s
        """,
        (numero,),
    ).fetchone()
    if receipt is None:
        return None
    receipt["renglones"] = connection.execute(
        """
        SELECT rc.vino, v.nombre, rc.cantidad, rc.precio_unitario,
               rc.descuento, rc.subtotal
        FROM "Renglon_Comprobante" rc
        JOIN "Vino" v ON v.codigo = rc.vino
        WHERE rc.comprobante = %s
        ORDER BY rc.vino
        """,
        (numero,),
    ).fetchall()
    return receipt


def create_comprobante(connection: Connection, sale: SaleInput) -> dict[str, Any]:
    with connection.transaction():
        numero = _next_number(connection, '"Comprobante"')
        connection.execute(
            """
            INSERT INTO "Comprobante" (numero, fecha, cliente, sala)
            VALUES (%s, %s, %s, %s)
            """,
            (numero, sale.fecha, sale.cliente, sale.sala),
        )
        for line in sale.renglones:
            inserted = connection.execute(
                """
                INSERT INTO "Renglon_Comprobante"
                    (comprobante, vino, cantidad, precio_unitario)
                SELECT %s, v.codigo, %s, v.precio
                FROM "Vino" v
                WHERE v.codigo = %s
                RETURNING vino
                """,
                (numero, line.cantidad, line.vino),
            ).fetchone()
            if inserted is None:
                raise LookupError(f"El vino {line.vino} no existe.")
    receipt = get_comprobante(connection, numero)
    if receipt is None:
        raise RuntimeError("El comprobante creado no se pudo recuperar.")
    return receipt
