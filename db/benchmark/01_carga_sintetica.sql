-- 01_carga_sintetica.sql
-- Carga sintetica para issues #44/#46 sobre la base rn_bench_tmp.
-- Volumen: 20.000 vinos, 5 salas, 5.000 comprobantes / 60.000 renglones,
-- 3.000 ingresos (estados mixtos), 2.000 transferencias, 20.000 filas de
-- Auditoria_Precio (generadas con UPDATE de precios).
--
-- Requiere: migraciones 001..012 aplicadas (sin 013); el runner compara los
-- planes EXPLAIN antes y despues de 013.

\set ON_ERROR_STOP on

SET work_mem = '64MB';

BEGIN;

-- Catalogo minimo: localidad, 5 salas, bodega, transportista, clientes.
INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (990001, 'Localidad BENCH');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE
SELECT g, 990001::int FROM generate_series(990011, 990015) AS g;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30900000001', 'Bodega BENCH');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (990001, 'Cepa BENCH', 'tinta');

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (990002, 'Cliente BENCH');

INSERT INTO "Socio"(id_cliente) VALUES (990002);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-BENCH', 'Transportista BENCH');

-- 20.000 vinos (una composicion del 100 % cada uno) con stock en deposito y salas.
INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio, graduacion)
SELECT
    'BENCH-' || lpad(g::text, 6, '0'),
    'Vino BENCH ' || g,
    CASE WHEN g % 2 = 0 THEN 'tinto' ELSE 'blanco' END,
    2015 + (g % 8),
    '30900000001',
    ROUND(50 + ((g * 37) % 70000) / 100.0, 2),
    9.0 + (g % 70) / 10.0
FROM generate_series(1, 20000) AS g;

INSERT INTO "Composicion"(vino, cepa, porcentaje)
SELECT 'BENCH-' || lpad(g::text, 6, '0'), 990001::int, 100.00
FROM generate_series(1, 20000) AS g;

-- Deposito: todas las existencias base; Salas: 5 salas con stock amplio para
-- absorver las ventas sinteticas del paso siguiente.
INSERT INTO "Stock_Deposito"(vino, cantidad)
SELECT 'BENCH-' || lpad(g::text, 6, '0'), 10000
FROM generate_series(1, 20000) AS g;

INSERT INTO "Stock_Sala"(sala, vino, cantidad)
SELECT s.id_sala, 'BENCH-' || lpad(g::text, 6, '0'), 10000
FROM generate_series(1, 20000) AS g
CROSS JOIN (SELECT id_sala FROM "Sala") s;

-- 5.000 comprobantes (fechas 2025-2026) y 12 renglones cada uno = 60.000.
INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
SELECT g,
       DATE '2026-01-01' + ((g * 7919) % 600),        -- distribuye en 20 meses
       990002::int,
       990011 + (g % 5)
FROM generate_series(50001, 55000) AS g;

INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
SELECT c.numero,
       'BENCH-' || lpad((((c.numero * 13 + r * 977) % 20000) + 1)::text, 6, '0'),
       1 + ((c.numero * 7 + r) % 5),
       v.precio
FROM "Comprobante" c
CROSS JOIN generate_series(1, 12) AS r
JOIN "Vino" v
  ON v.codigo = 'BENCH-' || lpad((((c.numero * 13 + r * 977) % 20000) + 1)::text, 6, '0');


-- =========================================================
-- 3.000 ingresos con renglones y transiciones RN-10 validas
-- Distribucion final: 1.000 por estado.
-- =========================================================

INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
SELECT
    'ING-BENCH-' || g,
    DATE '2026-01-01' + (g % 150),
    'TR-BENCH',
    '30900000001'
FROM generate_series(1, 3000) AS g;

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
SELECT
    'ING-BENCH-' || g,
    'BENCH-' || lpad(g::text, 6, '0'),
    10
FROM generate_series(1, 3000) AS g;

-- En confeccion -> terminado.
-- Los grupos 0 y 1 quedan terminados inicialmente.
UPDATE "Ingreso"
   SET estado = 'terminado'
 WHERE substring(codigo FROM '[0-9]+$')::int % 3 IN (0, 1);

-- Terminado -> procesado exclusivamente mediante el procedimiento RN-10.
DO $$
DECLARE
    reg RECORD;
BEGIN
    FOR reg IN
        SELECT codigo
          FROM "Ingreso"
         WHERE substring(codigo FROM '[0-9]+$')::int % 3 = 0
         ORDER BY codigo
    LOOP
        CALL sp_procesar_ingreso(reg.codigo);
    END LOOP;
END;
$$;

-- Resultado: 1.000 procesados, 1.000 terminados y 1.000 en confeccion.


-- =========================================================
-- 2.000 transferencias con renglones y transiciones RN-11
-- Distribucion final: aproximadamente un tercio por estado.
-- =========================================================

-- El estado se omite intencionalmente: usa DEFAULT en_confeccion.
INSERT INTO "Transferencia"(numero, fecha_confeccion, sala)
SELECT
    g,
    DATE '2026-01-01' + (g % 150),
    990011 + (g % 5)
FROM generate_series(1, 2000) AS g;

-- Un renglon por transferencia, con vino existente y stock suficiente.
INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
SELECT
    g,
    'BENCH-' || lpad(g::text, 6, '0'),
    1
FROM generate_series(1, 2000) AS g;

-- En confeccion -> terminado para los grupos 0 y 1.
UPDATE "Transferencia"
   SET estado = 'terminado'
 WHERE numero % 3 IN (0, 1);

-- Terminado -> procesado exclusivamente mediante RN-11.
DO $$
DECLARE
    reg RECORD;
BEGIN
    FOR reg IN
        SELECT numero
          FROM "Transferencia"
         WHERE numero % 3 = 0
         ORDER BY numero
    LOOP
        CALL sp_procesar_transferencia(reg.numero);
    END LOOP;
END;
$$;

-- Auditoria_Precio: 20.000 filas reales via las UPDATE de precios (RN-13).
UPDATE "Vino"
   SET precio = precio + 1.00
 WHERE codigo LIKE 'BENCH-%';

COMMIT;

ANALYZE;
