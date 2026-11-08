-- rn01_precio.fail.sql
-- A17 (issue #20): RN-01 — valores no positivos son rechazados (CHECK ck_vino_precio_positivo).
-- Este archivo debe finalizar correctamente: captura los rechazos esperados
-- mediante bloques DO y verifica precios cero y negativos.BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

DO $t$
BEGIN
    INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
    VALUES ('VINO1', 'Malbec Reserva', 'tinto', 2023, 750, 13.5, 0, '30712345678');
    RAISE EXCEPTION 'A17 FALLO: el precio 0 fue aceptado (RN-01 no se cumplio)';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'OK RN-01: precio cero rechazado por ck_vino_precio_positivo';
END $t$;

DO $t$
BEGIN
    INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
    VALUES ('VINO2', 'Malbec Reserva', 'tinto', 2023, 750, 13.5, -10.50, '30712345678');
    RAISE EXCEPTION 'A17 FALLO: el precio negativo fue aceptado (RN-01 no se cumplio)';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'OK RN-01: precio negativo rechazado por ck_vino_precio_positivo';
END $t$;

COMMIT;
