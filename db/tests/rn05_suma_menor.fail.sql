-- rn05_suma_menor.fail.sql
-- A21 (issue #25): RN-05 — caso negativo por COMMIT: suma 90 (inferior a 100).
-- Este archivo DEBE fallar en el COMMIT con el error del constraint trigger diferido.
BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (1, 'Malbec', 'tinta'), (2, 'Syrah', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
VALUES ('VINO1', 'Corte Reserva', 'tinto', 2023, 750, 14.0, 234.50, '30712345678');

INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE VALUES ('VINO1', 1, 60.00), ('VINO1', 2, 30.00);

COMMIT;
