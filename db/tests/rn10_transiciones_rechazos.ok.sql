-- rn10_transiciones_rechazos.ok.sql
-- RN-10 (rechazos internos, exit 0): transiciones invalidas de estado y la
-- inmutabilidad posterior al procesamiento (renglones protegidos por RN-12).

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777782', 'Bodega transiciones');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303401, 'Cepa transiciones', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-10-R1', 'Vino transicion', 'blanco', 2020, '30777777782', 50.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-10-R1', 303401, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-10-R1', 0);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-10R', 'Transportista transiciones');

INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-10-R', CURRENT_DATE, 'TR-10R', '30777777782');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-10-R', 'B-10-R1', 1);

-- Rechazo 1: salto directo en_confeccion -> procesado.
DO $$
BEGIN
    BEGIN
        UPDATE "Ingreso" SET estado = 'procesado' WHERE codigo = 'ING-10-R';

        RAISE EXCEPTION 'RN-10 FALLO: se acepto en_confeccion -> procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-10: en_confeccion -> procesado es invalido sin procedure';
    END;
END;
$$;

-- Transicion valida: en_confeccion -> terminado (manual, permitida).
UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-10-R';

-- Rechazo 2: la cabecera fuera de confeccion no admite cambios de negocio (RN-12).
DO $$
BEGIN
    BEGIN
        UPDATE "Ingreso" SET bodega_origen = '30777777781' WHERE codigo = 'ING-10-R';

        RAISE EXCEPTION 'RN-10/12 FALLO: se acepto modificar la cabecera terminada';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-10/12: la cabecera terminada no admite cambios de negocio';
    END;
END;
$$;

-- Procesamiento legítimo.
CALL sp_procesar_ingreso('ING-10-R');

-- Rechazo 3: retroceso de estado (procesado -> terminado).
DO $$
BEGIN
    BEGIN
        UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-10-R';

        RAISE EXCEPTION 'RN-10 FALLO: se acepto retroceder de procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-10: el estado procesado no retrocede';
    END;
END;
$$;

-- Rechazo 4: una vez procesado, los renglones no se modifican (RN-12).
DO $$
BEGIN
    BEGIN
        INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
        VALUES ('ING-10-R', 'B-10-R1', 5);

        RAISE EXCEPTION 'RN-12 FALLO: renglon insertado en ingreso procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-12: insertar renglon en ingreso procesado es rechazado';
    END;

    BEGIN
        UPDATE "Renglon_Ingreso" SET cantidad = 9 WHERE ingreso = 'ING-10-R';

        RAISE EXCEPTION 'RN-12 FALLO: renglon actualizado en ingreso procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-12: actualizar renglon en ingreso procesado es rechazado';
    END;

    BEGIN
        DELETE FROM "Renglon_Ingreso" WHERE ingreso = 'ING-10-R';

        RAISE EXCEPTION 'RN-12 FALLO: renglon eliminado en ingreso procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-12: eliminar renglon de ingreso procesado es rechazado';
    END;
END;
$$;

COMMIT;
