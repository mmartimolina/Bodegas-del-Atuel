-- rn12_renglones_confeccion.ok.sql
-- RN-12: durante la confeccion (estado en_confeccion) los renglones admiten
-- INSERT, UPDATE y DELETE; la protección solo aplica fuera de ese estado
-- (los rechazos post-confeccion se cubren en rn10/rn11 *_rechazos).

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (304001, 'Localidad RN-12');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (304001, 304001);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777801', 'Bodega RN-12');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304001, 'Cepa RN-12', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-12-V1', 'Vino confeccion A', 'blanco', 2021, '30777777801', 70.00),
    ('B-12-V2', 'Vino confeccion B', 'blanco', 2021, '30777777801', 55.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-12-V1', 304001, 100.00),
    ('B-12-V2', 304001, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-12-V1', 100), ('B-12-V2', 100);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-12', 'Transportista RN-12');

-- Ingreso en confeccion: altas, modificaciones y bajas permitidas.
INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-12-1', CURRENT_DATE, 'TR-12', '30777777801');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-12-1', 'B-12-V1', 1);

UPDATE "Renglon_Ingreso" SET cantidad = 5 WHERE ingreso = 'ING-12-1';

UPDATE "Renglon_Ingreso" SET vino = 'B-12-V2' WHERE ingreso = 'ING-12-1';

DELETE FROM "Renglon_Ingreso" WHERE ingreso = 'ING-12-1';

-- Transferencia en confeccion: ciclo completo permitido.
INSERT INTO "Transferencia"(numero, sala)
OVERRIDING SYSTEM VALUE VALUES (312001, 304001);

INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
VALUES (312001, 'B-12-V2', 3);

UPDATE "Renglon_Transferencia" SET cantidad = 2 WHERE transferencia = 312001;

DELETE FROM "Renglon_Transferencia" WHERE transferencia = 312001;

DO $$
DECLARE
    v_ri INTEGER;
    v_rt INTEGER;
BEGIN
    SELECT count(*) INTO v_ri FROM "Renglon_Ingreso"  WHERE ingreso = 'ING-12-1';
    SELECT count(*) INTO v_rt FROM "Renglon_Transferencia" WHERE transferencia = 312001;

    IF v_ri <> 0 OR v_rt <> 0 THEN
        RAISE EXCEPTION 'RN-12 FALLO: quedaron renglones tras el delete de prueba';
    END IF;

    RAISE NOTICE 'OK RN-12: confeccion admite INSERT/UPDATE/DELETE de renglones (ingreso y transferencia)';
END;
$$;

COMMIT;
