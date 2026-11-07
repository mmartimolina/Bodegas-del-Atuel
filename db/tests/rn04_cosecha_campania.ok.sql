-- rn04_cosecha_campania.ok.sql
-- A20 (issue #24): RN-04 — una parcela tiene una sola cepa y se cosecha como
-- maximo una vez por campania. La PK de Lote (finca, n_parcela, campania)
-- (finca, n_parcela) identifica la parcela (entidad debil con FK a Cepa).
BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (1, 'Malbec', 'tinta');

INSERT INTO "Finca"(id_finca, nombre, superficie, departamento, provincia)
OVERRIDING SYSTEM VALUE VALUES (1, 'Finca El Atuel', 120.50, 'San Rafael', 'Mendoza');

INSERT INTO "Parcela"(finca, n_parcela, superficie, anio_plantacion, cepa)
OVERRIDING SYSTEM VALUE VALUES (1, 1, 10.20, 1985, 1);

-- misma parcela, campanias distintas: se aceptan dos cosechas
INSERT INTO "Lote"(finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino)
OVERRIDING SYSTEM VALUE VALUES (1, 1, 2022, 1, '2022-03-15', 1450.00, '30712345678');

DO $t$
DECLARE n INT;
BEGIN
    INSERT INTO "Lote"(finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino)
    OVERRIDING SYSTEM VALUE VALUES (1, 1, 2023, 2, '2023-03-20', 1520.00, '30712345678');
    SELECT count(*) INTO n FROM "Lote" WHERE finca = 1 AND n_parcela = 1;
    IF n <> 2 THEN RAISE EXCEPTION 'A20 FALLO: cosechas distintas = % (esperado 2)', n; END IF;
    RAISE NOTICE 'OK RN-04: campanias distintas aceptadas para la misma parcela';
END $t$;
ROLLBACK;
