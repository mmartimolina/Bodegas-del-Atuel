-- rn11_transferencias_rechazos.ok.sql
-- RN-11 (rechazos internos, exit 0): la fecha de confeccion no se puede modificar,
-- las transiciones invalidas se rechazan, y la cabecera fuera de confeccion solo
-- cambia su estado (RN-12).

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303801, 'Localidad rechazos RN-11');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303801, 303801), (303802, 303801);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777792', 'Bodega rechazo RN-11');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303801, 'Cepa rechazo', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-11-R1', 'Vino rechazo transferencia', 'tinto', 2019, '30777777792', 70.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-11-R1', 303801, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-11-R1', 100);

INSERT INTO "Transferencia"(numero, sala)
OVERRIDING SYSTEM VALUE VALUES (311101, 303801);

INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
VALUES (311101, 'B-11-R1', 1);

-- Rechazo 1: la fecha de confeccion no se modifica.
DO $$
BEGIN
    BEGIN
        UPDATE "Transferencia"
           SET fecha_confeccion = CURRENT_DATE - 1
         WHERE numero = 311101;

        RAISE EXCEPTION 'RN-11 FALLO: se acepto modificar la fecha de confeccion';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-11: modificacion de fecha_confeccion rechazada';
    END;
END;
$$;

-- Rechazo 2: en_confeccion -> procesado manual (sin bandera del sistema).
DO $$
BEGIN
    BEGIN
        UPDATE "Transferencia" SET estado = 'procesado' WHERE numero = 311101;

        RAISE EXCEPTION 'RN-11 FALLO: se acepto en_confeccion -> procesado sin proceso';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-11: en_confeccion -> procesado invalido sin procedure';
    END;
END;
$$;

-- Transicion valida y rechazo de negocio en cabecera fuera de confeccion.
UPDATE "Transferencia" SET estado = 'terminado' WHERE numero = 311101;

DO $$
BEGIN
    BEGIN
        UPDATE "Transferencia" SET sala = 303802 WHERE numero = 311101;

        RAISE EXCEPTION 'RN-11/12 FALLO: se acepto cambiar sala en transferencia terminada';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-11/12: la sala no cambia en una cabecera fuera de confeccion';
    END;
END;
$$;

-- Rechazo 3: una vez procesada, los renglones no se tocan (RN-12).
CALL sp_procesar_transferencia(311101);

DO $$
BEGIN
    BEGIN
        UPDATE "Renglon_Transferencia"
           SET cantidad = 9
         WHERE transferencia = 311101;

        RAISE EXCEPTION 'RN-12 FALLO: renglon modificado en transferencia procesada';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-12: renglon de transferencia procesada no se modifica';
    END;

    BEGIN
        DELETE FROM "Renglon_Transferencia" WHERE transferencia = 311101;

        RAISE EXCEPTION 'RN-12 FALLO: renglon eliminado de transferencia procesada';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-12: renglon de transferencia procesada no se elimina';
    END;
END;
$$;

-- Rechazo 4: retroceso de estado.
DO $$
BEGIN
    BEGIN
        UPDATE "Transferencia" SET estado = 'terminado' WHERE numero = 311101;

        RAISE EXCEPTION 'RN-11 FALLO: se acepto retroceder de procesado';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-11: el estado procesado no retrocede';
    END;
END;
$$;

COMMIT;
