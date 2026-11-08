-- rn10_ingreso_en_confeccion.fail.sql
-- RN-10 (fallo esperado): un ingreso en confeccion no se puede procesar.

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777784', 'Bodega en confeccion');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303601, 'Cepa confeccion', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-10-DC', 'Vino confeccion', 'blanco', 2022, '30777777784', 44.44);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-10-DC', 303601, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-10-DC', 0);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-10DC', 'Transportista confeccion');

INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-10-3', CURRENT_DATE, 'TR-10DC', '30777777784');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-10-3', 'B-10-DC', 1);

CALL sp_procesar_ingreso('ING-10-3');

COMMIT;
