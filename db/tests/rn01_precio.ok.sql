-- rn01_precio.ok.sql
-- A17 (issue #20): RN-01 — precio unico por vino en toda la red y > 0.
-- Casos positivos: se acepta el alta con precio valido. Se demuestra tambien que el
-- precio vive solo en Vino (una fila por vino -> un unico precio para toda la red)
-- y que Stock_Sala no tiene precio.
BEGIN;

INSERT INTO "Localidad"(id_localidad, codigo_postal, nombre, provincia, encargado_regional)
OVERRIDING SYSTEM VALUE VALUES (1, '5560', 'General Alvear', 'Mendoza', 'Juan Perez');

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE
VALUES (1, 'Malbec', 'tinta'),
       (2, 'Chardonnay', 'blanca');
INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
VALUES ('VINO1', 'Malbec Reserva', 'tinto', 2023, 750, 13.5, 123.45, '30712345678'),
       ('VINO2', 'Chardonnay',     'blanco', 2023, 750, 12.0, 87.30,  '30712345678');

-- Cada vino tiene al menos una cepa y su suma es 100.
INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE
VALUES ('VINO1', 1, 100.00),
       ('VINO2', 2, 100.00);
-- una sola fila por vino: el precio se administra una vez, sin copias por sala
DO $t$
DECLARE n INT; c INT;
BEGIN
    SELECT count(*) INTO n FROM "Vino" WHERE codigo = 'VINO1';
    IF n <> 1 THEN RAISE EXCEPTION 'RN-01 FALLO: filas de VINO1 = % (esperado 1)', n; END IF;
    SELECT count(*) INTO c FROM information_schema.columns
    WHERE table_name='Stock_Sala' AND column_name='precio';
    IF c <> 0 THEN RAISE EXCEPTION 'RN-01 FALLO: Stock_Sala tiene columna de precio'; END IF;
    RAISE NOTICE 'OK RN-01: precio almacenado solo en Vino (una fila por vino)';
END $t$;
COMMIT;
