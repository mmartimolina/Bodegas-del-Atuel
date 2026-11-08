-- rn10_ingreso_vacio.fail.sql
-- RN-10 (fallo esperado): un ingreso terminado sin renglones no se procesa.

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777785', 'Bodega ingreso vacio');

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-10V', 'Transportista vacio');

INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-10-4', CURRENT_DATE, 'TR-10V', '30777777785');

UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-10-4';

CALL sp_procesar_ingreso('ING-10-4');

COMMIT;
