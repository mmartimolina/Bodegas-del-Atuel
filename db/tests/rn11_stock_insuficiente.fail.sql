-- rn11_stock_insuficiente.fail.sql
-- RN-11 (fallo esperado): procesar una transferencia sin stock en el deposito
-- es rechazado antes de mover nada (la transaccion no deja datos parciales).

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303901, 'Localidad stock insuf');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303901, 303901);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777793', 'Bodega stock insuficiente');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303901, 'Cepa stock insuf', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-11-SI', 'Vino stock insuficiente', 'tinto', 2020, '30777777793', 100.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-11-SI', 303901, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-11-SI', 1);

INSERT INTO "Transferencia"(numero, sala)
OVERRIDING SYSTEM VALUE VALUES (311201, 303901);

INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
VALUES (311201, 'B-11-SI', 5);

UPDATE "Transferencia" SET estado = 'terminado' WHERE numero = 311201;

CALL sp_procesar_transferencia(311201);

COMMIT;
