-- rn11_reproceso.fail.sql
-- RN-11 (fallo esperado): una transferencia procesada no se vuelve a procesar.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303951, 'Localidad reproceso transf');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303951, 303951);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777794', 'Bodega reproceso transf');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303951, 'Cepa reproceso transf', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-11-RP', 'Vino reproceso transferencia', 'blanco', 2018, '30777777794', 88.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-11-RP', 303951, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-11-RP', 20);

INSERT INTO "Transferencia"(numero, sala)
OVERRIDING SYSTEM VALUE VALUES (311251, 303951);

INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
VALUES (311251, 'B-11-RP', 2);

UPDATE "Transferencia" SET estado = 'terminado' WHERE numero = 311251;

CALL sp_procesar_transferencia(311251);

CALL sp_procesar_transferencia(311251);

COMMIT;
