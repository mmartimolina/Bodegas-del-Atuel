-- a37_seed_ultima_botella.sql
-- Datos minimos para el escenario A37: una sala con exactamente una unidad
-- del vino 'A37-V1' en Stock_Sala. Se aplica sobre la base temporal cuyo
-- esquema fue instalado con las migraciones 001 a 012.
-- Todo el seed se ejecuta dentro de una transaccion: los CONSTRAINT TRIGGER
-- diferidos de RN-05 validan la suma de composicion recien al COMMIT.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (777701, 'Localidad A37');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (777701, 777701);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777771', 'Bodega A37');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (777701, 'Cepa A37', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('A37-V1', 'Vino ultima botella A37', 'blanco', 2021, '30777777771', 123.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('A37-V1', 777701, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (777701, 'Cliente A37');

INSERT INTO "Socio"(id_cliente) VALUES (777701);

-- La ultima botella disponible:
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (777701, 'A37-V1', 1);

-- Comprobante de la venta (cabecera ya registrada; cada sesion inserta el
-- renglon que dispara el consumo de stock de RN-09):
INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (777701, CURRENT_DATE, 777701, 777701);

COMMIT;

SELECT 'semilla: stock inicial = ' || cantidad AS estado
  FROM "Stock_Sala" WHERE sala = 777701 AND vino = 'A37-V1';
