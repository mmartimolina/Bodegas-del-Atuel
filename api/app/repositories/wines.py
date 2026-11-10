from typing import Any

from psycopg import Connection

from app.schemas import WineInput


def list_wines(
    connection: Connection,
    *,
    limit: int,
    offset: int,
    tipo: str | None,
    cepa: int | None,
    bodega: str | None,
    anada: int | None,
) -> dict[str, Any]:
    filters = """
        (%s::text IS NULL OR v.tipo = %s)
        AND (%s::bigint IS NULL OR EXISTS (
            SELECT 1 FROM "Composicion" co
            WHERE co.vino = v.codigo AND co.cepa = %s
        ))
        AND (%s::text IS NULL OR v.bodega = %s)
        AND (%s::smallint IS NULL OR v.anada = %s)
    """
    values = (tipo, tipo, cepa, cepa, bodega, bodega, anada, anada)

    total = connection.execute(
        f'SELECT COUNT(*) AS total FROM "Vino" v WHERE {filters}', values
    ).fetchone()["total"]
    items = connection.execute(
        f"""
        SELECT v.codigo, v.nombre, v.tipo, v.anada, v.volumen_ml,
               v.graduacion, v.precio, v.bodega, b.razon_social AS bodega_nombre
        FROM "Vino" v
        JOIN "Bodega" b ON b.cuit = v.bodega
        WHERE {filters}
        ORDER BY v.nombre, v.codigo
        LIMIT %s OFFSET %s
        """,
        (*values, limit, offset),
    ).fetchall()
    return {"items": items, "limit": limit, "offset": offset, "total": total}


def get_wine(connection: Connection, codigo: str) -> dict[str, Any] | None:
    wine = connection.execute(
        """
        SELECT v.codigo, v.nombre, v.tipo, v.anada, v.volumen_ml,
               v.graduacion, v.precio, v.bodega, b.razon_social AS bodega_nombre,
               COALESCE(st.stock_deposito, 0) AS stock_deposito,
               COALESCE(st.stock_salas, 0) AS stock_salas
        FROM "Vino" v
        JOIN "Bodega" b ON b.cuit = v.bodega
        LEFT JOIN v_stock_total_vino st ON st.vino = v.codigo
        WHERE v.codigo = %s
        """,
        (codigo,),
    ).fetchone()
    if wine is None:
        return None

    wine["composicion"] = connection.execute(
        """
        SELECT co.cepa, cp.nombre AS nombre, cp.tipo, co.porcentaje
        FROM "Composicion" co
        JOIN "Cepa" cp ON cp.id = co.cepa
        WHERE co.vino = %s
        ORDER BY co.porcentaje DESC, cp.nombre
        """,
        (codigo,),
    ).fetchall()
    wine["maridajes"] = connection.execute(
        """
        SELECT m.id, m.nombre, m.temperatura
        FROM "Vino_Maridaje" vm
        JOIN "Maridaje" m ON m.id = vm.maridaje
        WHERE vm.vino = %s
        ORDER BY m.nombre
        """,
        (codigo,),
    ).fetchall()
    return wine


def create_wine(connection: Connection, wine: WineInput) -> dict[str, Any]:
    with connection.transaction():
        connection.execute(
            """
            INSERT INTO "Vino"
                (codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                wine.codigo,
                wine.nombre,
                wine.tipo,
                wine.anada,
                wine.volumen_ml,
                wine.graduacion,
                wine.precio,
                wine.bodega,
            ),
        )
        connection.executemany(
            """
            INSERT INTO "Composicion" (vino, cepa, porcentaje)
            VALUES (%s, %s, %s)
            """,
            [(wine.codigo, item.cepa, item.porcentaje) for item in wine.composicion],
        )
        if wine.maridajes:
            connection.executemany(
                'INSERT INTO "Vino_Maridaje" (vino, maridaje) VALUES (%s, %s)',
                [(wine.codigo, maridaje) for maridaje in wine.maridajes],
            )
    result = get_wine(connection, wine.codigo)
    if result is None:
        raise RuntimeError("El vino insertado no se pudo recuperar.")
    return result


def update_wine(
    connection: Connection, codigo: str, wine: WineInput
) -> dict[str, Any] | None:
    with connection.transaction():
        updated = connection.execute(
            """
            UPDATE "Vino"
            SET nombre = %s, tipo = %s, anada = %s, volumen_ml = %s,
                graduacion = %s, precio = %s, bodega = %s
            WHERE codigo = %s
            RETURNING codigo
            """,
            (
                wine.nombre,
                wine.tipo,
                wine.anada,
                wine.volumen_ml,
                wine.graduacion,
                wine.precio,
                wine.bodega,
                codigo,
            ),
        ).fetchone()
        if updated is None:
            return None

        connection.execute('DELETE FROM "Composicion" WHERE vino = %s', (codigo,))
        connection.executemany(
            """
            INSERT INTO "Composicion" (vino, cepa, porcentaje)
            VALUES (%s, %s, %s)
            """,
            [(codigo, item.cepa, item.porcentaje) for item in wine.composicion],
        )
        connection.execute('DELETE FROM "Vino_Maridaje" WHERE vino = %s', (codigo,))
        if wine.maridajes:
            connection.executemany(
                'INSERT INTO "Vino_Maridaje" (vino, maridaje) VALUES (%s, %s)',
                [(codigo, maridaje) for maridaje in wine.maridajes],
            )
    return get_wine(connection, codigo)


def delete_wine(connection: Connection, codigo: str) -> bool:
    with connection.transaction():
        if connection.execute(
            'SELECT 1 FROM "Vino" WHERE codigo = %s FOR UPDATE', (codigo,)
        ).fetchone() is None:
            return False
        connection.execute('DELETE FROM "Vino_Maridaje" WHERE vino = %s', (codigo,))
        connection.execute('DELETE FROM "Composicion" WHERE vino = %s', (codigo,))
        connection.execute('DELETE FROM "Vino" WHERE codigo = %s', (codigo,))
    return True
