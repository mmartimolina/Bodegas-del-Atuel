-- rn10_reproceso.fail.sql
-- RN-10 (fallo esperado): procesar dos veces el mismo ingreso es rechazado;
-- la segunda llamada ve estado procesado y aborta (el stock no cambia de nuevo).

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777783', 'Bodega reproceso');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303501, 'Cepa reproceso', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-10-RP', 'Vino reproceso', 'tinto', 2019, '30777777783', 60.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-10-RP', 303501, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-10-RP', 0);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-10RP', 'Transportista reproceso');

INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-10-2', CURRENT_DATE, 'TR-10RP', '30777777783');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-10-2', 'B-10-RP', 2);

UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-10-2';

CALL sp_procesar_ingreso('ING-10-2');

CALL sp_procesar_ingreso('ING-10-2');

COMMIT;
