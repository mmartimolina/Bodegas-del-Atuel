from typing import Any

from psycopg import Connection

from app.schemas import CustomerInput

CUSTOMER_SELECT = """
    SELECT c.id_cliente, c.nombre, c.tipo_doc, c.n_doc, c.direccion,
           c.localidad, c.fecha_alta, c.descuento,
           CASE
               WHEN s.id_cliente IS NOT NULL THEN 'Socio'
               WHEN d.id_cliente IS NOT NULL THEN 'Distribuidor'
               WHEN e.id_cliente IS NOT NULL THEN 'Exportador'
           END AS subtipo,
           d.zona, d.n_habilitacion, e.pais
    FROM "Cliente" c
    LEFT JOIN "Socio" s ON s.id_cliente = c.id_cliente
    LEFT JOIN "Distribuidor" d ON d.id_cliente = c.id_cliente
    LEFT JOIN "Exportador" e ON e.id_cliente = c.id_cliente
"""


def list_customers(
    connection: Connection,
    *,
    limit: int,
    offset: int,
    subtipo: str | None,
    query: str | None,
) -> dict[str, Any]:
    where = """
        (%s::text IS NULL
         OR (%s = 'Socio' AND s.id_cliente IS NOT NULL)
         OR (%s = 'Distribuidor' AND d.id_cliente IS NOT NULL)
         OR (%s = 'Exportador' AND e.id_cliente IS NOT NULL))
        AND (%s::text IS NULL
             OR c.nombre ILIKE ('%' || %s || '%')
             OR c.n_doc ILIKE ('%' || %s || '%'))
    """
    parameters = (subtipo, subtipo, subtipo, subtipo, query, query, query)
    total = connection.execute(
        f"""
        SELECT COUNT(*) AS total
        FROM "Cliente" c
        LEFT JOIN "Socio" s ON s.id_cliente = c.id_cliente
        LEFT JOIN "Distribuidor" d ON d.id_cliente = c.id_cliente
        LEFT JOIN "Exportador" e ON e.id_cliente = c.id_cliente
        WHERE {where}
        """,
        parameters,
    ).fetchone()["total"]
    items = connection.execute(
        f"{CUSTOMER_SELECT} WHERE {where} ORDER BY c.id_cliente LIMIT %s OFFSET %s",
        (*parameters, limit, offset),
    ).fetchall()
    return {"items": items, "limit": limit, "offset": offset, "total": total}


def get_customer(connection: Connection, customer_id: int) -> dict[str, Any] | None:
    customer = connection.execute(
        f"{CUSTOMER_SELECT} WHERE c.id_cliente = %s", (customer_id,)
    ).fetchone()
    if customer is None:
        return None
    if customer["subtipo"] == "Exportador":
        customer["permisos"] = connection.execute(
            """
            SELECT codigo, fecha_emision, fecha_vencimiento
            FROM "Permiso_Exportacion"
            WHERE exportador = %s
            ORDER BY fecha_emision, codigo
            """,
            (customer_id,),
        ).fetchall()
    else:
        customer["permisos"] = []
    return customer


def _insert_subtype(connection: Connection, customer_id: int, customer: CustomerInput) -> None:
    if customer.subtipo == "Socio":
        connection.execute('INSERT INTO "Socio" (id_cliente) VALUES (%s)', (customer_id,))
    elif customer.subtipo == "Distribuidor":
        connection.execute(
            """
            INSERT INTO "Distribuidor" (id_cliente, zona, n_habilitacion)
            VALUES (%s, %s, %s)
            """,
            (customer_id, customer.zona, customer.n_habilitacion),
        )
    else:
        connection.execute(
            'INSERT INTO "Exportador" (id_cliente, pais) VALUES (%s, %s)',
            (customer_id, customer.pais),
        )
        _replace_permissions(connection, customer_id, customer)


def _replace_permissions(
    connection: Connection, customer_id: int, customer: CustomerInput
) -> None:
    connection.execute(
        'DELETE FROM "Permiso_Exportacion" WHERE exportador = %s', (customer_id,)
    )
    if customer.permisos:
        connection.executemany(
            """
            INSERT INTO "Permiso_Exportacion"
                (codigo, exportador, fecha_emision, fecha_vencimiento)
            VALUES (%s, %s, %s, %s)
            """,
            [
                (item.codigo, customer_id, item.fecha_emision, item.fecha_vencimiento)
                for item in customer.permisos
            ],
        )


def create_customer(connection: Connection, customer: CustomerInput) -> dict[str, Any]:
    with connection.transaction():
        row = connection.execute(
            """
            INSERT INTO "Cliente"
                (nombre, tipo_doc, n_doc, direccion, localidad, fecha_alta)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id_cliente
            """,
            (
                customer.nombre,
                customer.tipo_doc,
                customer.n_doc,
                customer.direccion,
                customer.localidad,
                customer.fecha_alta,
            ),
        ).fetchone()
        customer_id = row["id_cliente"]
        _insert_subtype(connection, customer_id, customer)
    result = get_customer(connection, customer_id)
    if result is None:
        raise RuntimeError("El cliente insertado no se pudo recuperar.")
    return result


def update_customer(
    connection: Connection, customer_id: int, customer: CustomerInput
) -> dict[str, Any] | None:
    with connection.transaction():
        existing = get_customer(connection, customer_id)
        if existing is None:
            return None
        if existing["subtipo"] != customer.subtipo:
            raise ValueError("No se permite cambiar el subtipo de un cliente existente.")

        connection.execute(
            """
            UPDATE "Cliente"
            SET nombre = %s, tipo_doc = %s, n_doc = %s, direccion = %s,
                localidad = %s, fecha_alta = %s
            WHERE id_cliente = %s
            """,
            (
                customer.nombre,
                customer.tipo_doc,
                customer.n_doc,
                customer.direccion,
                customer.localidad,
                customer.fecha_alta,
                customer_id,
            ),
        )
        if customer.subtipo == "Distribuidor":
            connection.execute(
                """
                UPDATE "Distribuidor" SET zona = %s, n_habilitacion = %s
                WHERE id_cliente = %s
                """,
                (customer.zona, customer.n_habilitacion, customer_id),
            )
        elif customer.subtipo == "Exportador":
            connection.execute(
                'UPDATE "Exportador" SET pais = %s WHERE id_cliente = %s',
                (customer.pais, customer_id),
            )
            _replace_permissions(connection, customer_id, customer)
    return get_customer(connection, customer_id)


def delete_customer(connection: Connection, customer_id: int) -> bool:
    deleted = connection.execute(
        'DELETE FROM "Cliente" WHERE id_cliente = %s RETURNING id_cliente',
        (customer_id,),
    ).fetchone()
    return deleted is not None


def list_salas(connection: Connection) -> list[dict[str, Any]]:
    return connection.execute(
        """
        SELECT s.id_sala, s.calle, s.numero, s.dia_cierre,
               l.nombre AS localidad
        FROM "Sala" s
        JOIN "Localidad" l ON l.id_localidad = s.localidad
        ORDER BY s.id_sala
        """
    ).fetchall()


def list_catalogs(connection: Connection) -> dict[str, list[dict[str, Any]]]:
    return {
        "cepas": connection.execute(
            'SELECT id, nombre, tipo FROM "Cepa" ORDER BY nombre, id'
        ).fetchall(),
        "bodegas": connection.execute(
            'SELECT cuit, razon_social FROM "Bodega" ORDER BY razon_social, cuit'
        ).fetchall(),
        "maridajes": connection.execute(
            'SELECT id, nombre, temperatura FROM "Maridaje" ORDER BY nombre, id'
        ).fetchall(),
        "tipos_vino": connection.execute(
            'SELECT DISTINCT tipo FROM "Vino" WHERE tipo IS NOT NULL ORDER BY tipo'
        ).fetchall(),
    }
