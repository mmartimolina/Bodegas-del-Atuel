-- rn14_protecciones.ok.sql
-- RN-14 (rechazos internos, exit 0): no se borra un transportista, bodega ni vino
-- con movimientos/informacion asociados; si no tienen dependencias, la eliminacion
-- es legítima (FK con RESTRICT; sin cascada destructiva de historicos).

BEGIN;

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-14-OK', 'Transportista sin movimientos'), ('TR-14-VINC', 'Transportista vinculado');

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777821', 'Bodega con vinos'), ('30777777822', 'Bodega libre de dependencias');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304201, 'Cepa RN-14', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-14-VIN', 'Vino vinculado', 'tinto', 2014, '30777777821', 90.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-14-VIN', 304201, 100.00);

-- Un ingreso revisado: vincula transportista y vino.
INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-14-1', CURRENT_DATE, 'TR-14-VINC', '30777777821');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-14-1', 'B-14-VIN', 2);

-- Eliminacion permitida sin dependencias (ni vinos ni movimientos la referencian).
DELETE FROM "Transportista" WHERE codigo = 'TR-14-OK';
DELETE FROM "Bodega" WHERE cuit = '30777777822';

DO $$
DECLARE
    v_tr INTEGER;
    v_bodega INTEGER;
    v_vino INTEGER;
BEGIN
    SELECT count(*) INTO v_tr FROM "Transportista" WHERE codigo IN ('TR-14-OK', 'TR-14-VINC');
    SELECT count(*) INTO v_bodega FROM "Bodega" WHERE cuit IN ('30777777821', '30777777822');
    SELECT count(*) INTO v_vino FROM "Vino" WHERE codigo = 'B-14-VIN';

    IF v_tr <> 1 OR v_bodega <> 1 OR v_vino <> 1 THEN
        RAISE EXCEPTION 'RN-14 FALLO: el estado base no quedó intacto (%, %, %)', v_tr, v_bodega, v_vino;
    END IF;

    RAISE NOTICE 'OK RN-14: sin dependencias, transportista y bodega se eliminan sin cascada (quedan 1/1)';
END;
$$;

-- Eliminacion permitida: vino sin movimientos (aqui el resto restante lo verifica bloqueado).
DO $$
BEGIN
    BEGIN
        DELETE FROM "Transportista" WHERE codigo = 'TR-14-VINC';

        RAISE EXCEPTION 'RN-14 FALLO: se borro transportista con ingreso';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'OK RN-14: transportista con movimiento rechazado';
    END;

    BEGIN
        DELETE FROM "Bodega" WHERE cuit = '30777777821';

        RAISE EXCEPTION 'RN-14 FALLO: se borro bodega con vino';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'OK RN-14: bodega con vino rechazada';
    END;

    BEGIN
        DELETE FROM "Vino" WHERE codigo = 'B-14-VIN';

        RAISE EXCEPTION 'RN-14 FALLO: se borro vino con movimiento';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'OK RN-14: vino con renglon rechazado';
    END;
END;
$$;

-- Conservacion de los datos historicos tras los rechazos (count se mantiene).
DO $$
DECLARE
    v_bootstrap INTEGER;
BEGIN
    SELECT count(*) INTO v_bootstrap FROM v_documentos_pendientes
     WHERE tipo = 'INGRESO' AND documento = 'ING-14-1';

    IF v_bootstrap <> 1 THEN
        RAISE EXCEPTION 'RN-14 FALLO: datos historicos no conservados';
    END IF;

    RAISE NOTICE 'OK RN-14: rechazos preservan los movimientos vinculados (ingreso visible: %)', v_bootstrap;
END;
$$;

COMMIT;
