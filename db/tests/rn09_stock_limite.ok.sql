-- rn09_stock_limite.ok.sql
-- RN-09 (limites): venta exacta hasta dejar el stock en 0 (valido), rechazo inmediato
-- de una venta mas, y reposicion total al anular la venta (stock vuelve al estado).

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303201, 'Localidad limite RN-09');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303201, 303201);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777773', 'Bodega limite RN-09');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303201, 'Cepa limite', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-09-L1', 'Vino limite', 'blanco', 2021, '30777777773', 33.33);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-09-L1', 303201, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (303201, 'Cliente limite');

INSERT INTO "Socio"(id_cliente) VALUES (303201);

-- Existe exactamente una unidad: la venta de esa ultima unidad es legītima.
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (303201, 'B-09-L1', 1);

INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (303201, CURRENT_DATE, 303201, 303201);

INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (303201, 'B-09-L1', 1, 33.33);

DO $$
DECLARE
    v_stock INTEGER;
BEGIN
    v_stock := fn_stock_sala(303201, 'B-09-L1');

    IF v_stock <> 0 THEN
        RAISE EXCEPTION 'RN-09 FALLO: la venta de la ultima unidad dejo el stock en % (esperado 0)', v_stock;
    END IF;

    RAISE NOTICE 'OK RN-09: venta exacta deja el stock en 0 (ausencia de existencias)';
END;
$$;

-- Limite: la segunda venta ya no tiene unidades.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
        VALUES (303201, 'B-09-L1', 1, 33.33);

        RAISE EXCEPTION 'RN-09 FALLO: se acepto una segunda venta sin stock';
    EXCEPTION WHEN check_violation OR foreign_key_violation THEN
        RAISE NOTICE 'OK RN-09: segunda venta de la ultima unidad rechazada';
    END;
END;
$$;

-- Anulacion de la venta (delete): el stock vuelve a 1 (estado inicial).
DELETE FROM "Renglon_Comprobante"
WHERE comprobante = 303201 AND vino = 'B-09-L1';

DO $$
DECLARE
    v_stock INTEGER;
BEGIN
    v_stock := fn_stock_sala(303201, 'B-09-L1');

    IF v_stock <> 1 THEN
        RAISE EXCEPTION 'RN-09 FALLO: al anular la venta el stock quedo en % (esperado 1)', v_stock;
    END IF;

    RAISE NOTICE 'OK RN-09: la anulacion repone la unidad vendida';
END;
$$;

COMMIT;
