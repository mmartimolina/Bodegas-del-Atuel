-- 011_vistas.sql
-- Issue #39: las tres vistas requeridas por la consigna.
-- Decision adoptada: las tres son vistas ordinarias (no materializadas): los datos
-- de la demo son suficientemente chicos y una captura durante el streaming
-- distintos la frescura de los datos: no aporte materializadas sin necesidad
-- (consigna: una sola puede ser materializada, no es obligatorio hacerlo).
--
-- 1) v_stock_total_vino: stock total por vino entre deposito y salas.
--    Left joins para no perder vinos sin movimientos (stock = 0 en vez de fila ausente).
--    Los LEFT JOIN garantizan la fila del vino aunque no quede stock.
-- 2) v_ventas_mensuales_sala: ventas por anio-mes y sala (cabecera Comprobante que
--    registra `fecha`, con renglones que muestran los vinos y los importes netos).
-- 3) v_documentos_pendientes: ingresos y transferencias pendientes de procesamiento
--    (estado en_confeccion y terminado): una fila por documento con el codigo de la
--    cabecera y el estado, para la bandeja central de en el sistema de dispatching.

CREATE VIEW v_stock_total_vino AS
SELECT
    v.codigo            AS vino,
    COALESCE(dp.cantidad, 0) AS stock_deposito,
    COALESCE(sl.cantidad, 0) AS stock_salas
FROM "Vino" v
LEFT JOIN "Stock_Deposito" dp
       ON dp.vino = v.codigo
LEFT JOIN (
    SELECT vino, SUM(cantidad) AS cantidad
      FROM "Stock_Sala"
     GROUP BY vino
) sl
       ON sl.vino = v.codigo;

COMMENT ON VIEW v_stock_total_vino IS
    'Issue #39: stock total por vino (deposito + salas).';

CREATE VIEW v_ventas_mensuales_sala AS
SELECT
    c.sala,
    to_char(c.fecha, 'YYYY-MM')            AS anio_mes,
    count(DISTINCT r.comprobante)          AS comprobantes,
    SUM(r.cantidad)                        AS unidades_vendidas,
    SUM(r.subtotal)                        AS importe_neto
FROM "Comprobante" c
JOIN "Renglon_Comprobante" r
  ON r.comprobante = c.numero
GROUP BY c.sala, to_char(c.fecha, 'YYYY-MM');

COMMENT ON VIEW v_ventas_mensuales_sala IS
    'Issue #39: ventas mensuales por sala (unidades e importe neto por renglones).';

CREATE VIEW v_documentos_pendientes AS
SELECT
    'INGRESO'          AS tipo,
    i.codigo::TEXT     AS documento,
    i.fecha            AS fecha,
    i.estado
FROM "Ingreso" i
WHERE i.estado <> 'procesado'
UNION ALL
SELECT
    'TRANSFERENCIA'    AS tipo,
    t.numero::TEXT     AS documento,
    t.fecha_confeccion AS fecha,
    t.estado
FROM "Transferencia" t
WHERE t.estado <> 'procesado';

COMMENT ON VIEW v_documentos_pendientes IS
    'Issue #39: ingreso/transferencias sin procesar para bandeja de pendientes.';

COMMIT;
