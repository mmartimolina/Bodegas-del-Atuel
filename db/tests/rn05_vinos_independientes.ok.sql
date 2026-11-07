-- rn05_suma_cero_vinos_otros.ok.sql
-- A21 (issue #25): RN-05 — vinos independientes se validan por separado y
-- composiciones de varios vinos en una misma transaccion no se mezclan.
BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (1, 'Malbec', 'tinta'), (2, 'Chardonnay', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
VALUES ('VT', 'Tinto Reserva', 'tinto', 2023, 750, 14.0, 234.50, '30712345678'),
       ('VB', 'Blanco Reserva', 'blanco', 2023, 750, 12.0, 180.00, '30712345678');

INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE VALUES ('VT', 1, 100.00), ('VB', 2, 100.00);

COMMIT;
