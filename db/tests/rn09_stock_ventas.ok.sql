-- rn09_stock_ventas.ok.sql
-- RN-09: descuento de stock al vender; no hay doble descuento en UPDATE;
-- DELETE repono (incluido el caso sin cascada); fn_stock_sala refleja disponible.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303001, 'Localidad RN-09');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303001, 303001);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777771', 'Bodega RN-09');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303001, 'Cepa RN-09', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-09-AA', 'Tinto RN-09',   'tinto',   2019, '30777777771', 100.00),
    ('B-09-BB', 'Blanco RN-09',  'blanco',  2020, '30777777771',  80.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-09-AA', 303001, 100.00),
    ('B-09-BB', 303001, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (303001, 'Cliente RN-09');

INSERT INTO "Socio"(id_cliente) VALUES (303001);

-- Stock inicial de la sala para los dos vinos.
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (303001, 'B-09-AA', 50), (303001, 'B-09-BB', 25);

INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (303001, CURRENT_DATE, 303001, 303001);

-- Alta de renglones: consume stock (50 - 4 = 46; 25 - 2 = 23).
INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (303001, 'B-09-AA', 4, 100.00), (303001, 'B-09-BB', 2, 80.00);

DO $$
DECLARE
    v_aa INTEGER;
    v_bb INTEGER;
BEGIN
    v_aa := fn_stock_sala(303001, 'B-09-AA');
    v_bb := fn_stock_sala(303001, 'B-09-BB');

    IF v_aa <> 46 OR v_bb <> 23 THEN
        RAISE EXCEPTION 'RN-09 FALLO: stock tras el alta es %/% (esperado 46/23)', v_aa, v_bb;
    END IF;

    RAISE NOTICE 'OK RN-09: el alta de renglones descuento el stock (46/23)';
END;
$$;

-- Update de cantidad renglon (-2 unidades): aplica solo el DELTA (NO DOBLE DESCUENTO).
UPDATE "Renglon_Comprobante"
   SET cantidad = 6
 WHERE comprobante = 303001 AND vino = 'B-09-AA';

DO $$
DECLARE
    v_aa INTEGER;
BEGIN
    v_aa := fn_stock_sala(303001, 'B-09-AA');

    IF v_aa <> 44 THEN
        RAISE EXCEPTION 'RN-09 FALLO: el update de cantidad dejo el stock en % (esperado 44: solo el delta)', v_aa;
    END IF;

    RAISE NOTICE 'OK RN-09: el update de un renglon aplica solo el delta (44)';
END;
$$;

-- Update que NO cambia la cantidad: reintento sin efectos laterales.
UPDATE "Renglon_Comprobante"
   SET precio_unitario = 105.00
 WHERE comprobante = 303001 AND vino = 'B-09-AA';

DO $$
DECLARE
    v_aa INTEGER;
BEGIN
    v_aa := fn_stock_sala(303001, 'B-09-AA');

    IF v_aa <> 44 THEN
        RAISE EXCEPTION 'RN-09 FALLO: update sin cambio de cantidad toco el stock (%)', v_aa;
    END IF;

    RAISE NOTICE 'OK RN-09: update sin delta deja el stock intacto (44)';
END;
$$;

-- Baja del renglon de B-09-BB: repone unidades (25).
DELETE FROM "Renglon_Comprobante"
WHERE comprobante = 303001 AND vino = 'B-09-BB';

DO $$
DECLARE
    v_bb INTEGER;
BEGIN
    v_bb := fn_stock_sala(303001, 'B-09-BB');

    IF v_bb <> 25 THEN
        RAISE EXCEPTION 'RN-09 FALLO: el delete no repuso el stock de B-09-BB (%)', v_bb;
    END IF;

    RAISE NOTICE 'OK RN-09: el delete de renglon repone el stock de la sala';
END;
$$;

COMMIT;
