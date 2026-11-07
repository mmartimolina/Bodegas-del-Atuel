-- rn04_cosecha_campania.fail.sql
-- A20 (issue #24): RN-04 — mismo ano dos cosechas son rechazadas; parcela con cepa
-- inexistente es rechazada. Este archivo DEBE terminar sin errores (cada DO espera rechazo).
BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (1, 'Malbec', 'tinta');

INSERT INTO "Finca"(id_finca, nombre, superficie, departamento, provincia)
OVERRIDING SYSTEM VALUE VALUES (1, 'Finca El Atuel', 120.50, 'San Rafael', 'Mendoza');

INSERT INTO "Parcela"(finca, n_parcela, superficie, anio_plantacion, cepa)
OVERRIDING SYSTEM VALUE VALUES (1, 1, 10.20, 1985, 1);

INSERT INTO "Lote"(finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino)
OVERRIDING SYSTEM VALUE VALUES (1, 1, 2022, 1, '2022-03-15', 1450.00, '30712345678');

-- 1. mismo (parcela, campania) -> unique_violation sobre la PK de lote ((no se permite doble cosecha))
DO $t$
BEGIN
    INSERT INTO "Lote"(finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino)
    OVERRIDING SYSTEM VALUE VALUES (1, 1, 2022, 2, '2022-04-01', 300.00, '30712345678');
    RAISE EXCEPTION 'A20 FALLO: segundad cosecha de la misma campania fue aceptada';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'OK RN-04: segunda cosecha de la misma campania rechazada (pk_lote)';
END $t$;

-- 2. parcela con cepa inexistente -> foreign_key_violation (fk_parcela_cepa)
DO $t$
BEGIN
    INSERT INTO "Parcela"(finca, n_parcela, superficie, anio_plantacion, cepa)
    OVERRIDING SYSTEM VALUE VALUES (1, 2, 5.00, 2000, 999);
    RAISE EXCEPTION 'A20 FALLO: parcela con cepa inexistente fue aceptada';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'OK RN-04: parcela con cepa inexistente rechazada (fk_parcela_cepa)';
END $t$;
ROLLBACK;
