from typing import Any

from psycopg import Connection

from app.repositories.wines import get_wine


def top_wines(connection: Connection, limit: int) -> list[dict[str, Any]]:
    return connection.execute(
        """
        SELECT v.codigo, v.nombre, v.tipo, SUM(rc.cantidad) AS botellas_vendidas
        FROM "Renglon_Comprobante" rc
        JOIN "Vino" v ON v.codigo = rc.vino
        GROUP BY v.codigo, v.nombre, v.tipo
        ORDER BY botellas_vendidas DESC, v.codigo
        LIMIT %s
        """,
        (limit,),
    ).fetchall()


def sales_by_sala(connection: Connection) -> list[dict[str, Any]]:
    return connection.execute(
        """
        SELECT s.id_sala, s.calle, s.numero, l.nombre AS localidad,
               COUNT(c.numero) AS comprobantes,
               COALESCE(SUM(c.total), 0) AS monto_total
        FROM "Sala" s
        JOIN "Localidad" l ON l.id_localidad = s.localidad
        LEFT JOIN "Comprobante" c
          ON c.sala = s.id_sala
         AND c.fecha >= CURRENT_DATE - INTERVAL '3 months'
         AND c.fecha <= CURRENT_DATE
        GROUP BY s.id_sala, s.calle, s.numero, l.nombre
        ORDER BY monto_total DESC, s.id_sala
        """
    ).fetchall()


def wines_without_sala_stock(
    connection: Connection, sala: int
) -> list[dict[str, Any]]:
    return connection.execute(
        """
        SELECT v.codigo, v.nombre, v.tipo, v.anada,
               COALESCE(ss.cantidad, 0) AS stock_sala,
               sd.cantidad AS stock_deposito
        FROM "Vino" v
        JOIN "Stock_Deposito" sd ON sd.vino = v.codigo AND sd.cantidad > 0
        LEFT JOIN "Stock_Sala" ss ON ss.sala = %s AND ss.vino = v.codigo
        WHERE COALESCE(ss.cantidad, 0) = 0
        ORDER BY sd.cantidad DESC, v.codigo
        """,
        (sala,),
    ).fetchall()


def active_carriers(connection: Connection) -> list[dict[str, Any]]:
    return connection.execute(
        """
        SELECT t.codigo, t.razon_social,
               COUNT(DISTINCT i.codigo) AS ingresos_confeccionados,
               COALESCE(SUM(ri.cantidad), 0) AS botellas_trasladadas
        FROM "Transportista" t
        JOIN "Ingreso" i ON i.transportista = t.codigo
                        AND i.fecha >= CURRENT_DATE - 30
                        AND i.fecha <= CURRENT_DATE
        LEFT JOIN "Renglon_Ingreso" ri ON ri.ingreso = i.codigo
        GROUP BY t.codigo, t.razon_social
        ORDER BY ingresos_confeccionados DESC, botellas_trasladadas DESC, t.codigo
        """
    ).fetchall()


def wine_traceability(connection: Connection, codigo: str) -> dict[str, Any] | None:
    wine = get_wine(connection, codigo)
    if wine is None:
        return None
    wine["ingresos"] = connection.execute(
        """
        SELECT i.codigo, i.fecha, i.estado, i.transportista,
               ri.cantidad, i.bodega_origen
        FROM "Renglon_Ingreso" ri
        JOIN "Ingreso" i ON i.codigo = ri.ingreso
        WHERE ri.vino = %s
        ORDER BY i.fecha DESC, i.codigo
        """,
        (codigo,),
    ).fetchall()
    wine["transferencias"] = connection.execute(
        """
        SELECT t.numero, t.fecha_confeccion, t.estado, t.sala, rt.cantidad
        FROM "Renglon_Transferencia" rt
        JOIN "Transferencia" t ON t.numero = rt.transferencia
        WHERE rt.vino = %s
        ORDER BY t.fecha_confeccion DESC, t.numero
        """,
        (codigo,),
    ).fetchall()
    wine["ventas"] = connection.execute(
        """
        SELECT c.numero AS comprobante, c.fecha, c.cliente, c.sala,
               rc.cantidad, rc.precio_unitario, rc.descuento, rc.subtotal
        FROM "Renglon_Comprobante" rc
        JOIN "Comprobante" c ON c.numero = rc.comprobante
        WHERE rc.vino = %s
        ORDER BY c.fecha DESC, c.numero
        """,
        (codigo,),
    ).fetchall()
    return wine
