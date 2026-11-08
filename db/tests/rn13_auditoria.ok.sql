-- rn13_auditoria.ok.sql
-- RN-13: cambios efectivos de precio se auditan (vino, anterior, nuevo, fecha/hora,
-- usuario); valores iguales no generan filas; la tabla no se altera manualmente.

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777811', 'Bodega RN-13');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304101, 'Cepa RN-13', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-13-V1', 'Vino auditado',  'tinto',   2015, '30777777811', 100.00),
    ('B-13-NUL', 'Vino sin precio', 'tinto', 2016, '30777777811', NULL);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-13-V1', 304101, 100.00),
    ('B-13-NUL', 304101, 100.00);

-- Cambio de precio efectivo: genera 1 fila.
UPDATE "Vino" SET precio = 120.00 WHERE codigo = 'B-13-V1';

DO $$
DECLARE
    v_pa NUMERIC;
    v_pn NUMERIC;
    v_fh TIMESTAMP;
    v_u  TEXT;
BEGIN
    SELECT precio_anterior, precio_nuevo, fecha_hora, usuario
      INTO v_pa, v_pn, v_fh, v_u
      FROM "Auditoria_Precio"
     WHERE vino = 'B-13-V1'
     ORDER BY fecha_hora DESC
     LIMIT 1;

    IF v_pa <> 100.00 OR v_pn <> 120.00 THEN
        RAISE EXCEPTION 'RN-13 FALLO: importes de auditoria incorrectos (% -> %)', v_pa, v_pn;
    END IF;

    IF v_fh IS NULL OR v_u IS NULL THEN
        RAISE EXCEPTION 'RN-13 FALLO: fecha_hora/usuario no registrados';
    END IF;

    RAISE NOTICE 'OK RN-13: cambio efectivo auditado (% -> %, %, %)', v_pa, v_pn, v_fh, v_u;
END;
$$;

-- Cambio del precio al mismo valor: NO genera fila de auditoria.
UPDATE "Vino" SET precio = 120.00 WHERE codigo = 'B-13-V1';

DO $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT count(*) INTO v_total FROM "Auditoria_Precio" WHERE vino = 'B-13-V1';

    IF v_total <> 1 THEN
        RAISE EXCEPTION 'RN-13 FALLO: un valor igual genero fila de auditoria (total: %)', v_total;
    END IF;

    RAISE NOTICE 'OK RN-13: precio igual no genera fila';
END;
$$;

-- La auditoria no acepta escrituras manuales (INSERT/UPDATE/DELETE).
DO $$
BEGIN
    BEGIN
        INSERT INTO "Auditoria_Precio"(vino, precio_anterior, precio_nuevo, fecha_hora, usuario)
        VALUES ('B-13-V1', 1.00, 2.00, CURRENT_TIMESTAMP, 'fake');

        RAISE EXCEPTION 'RN-13 FALLO: se permitio insertar en la auditoria';
    EXCEPTION WHEN SQLSTATE '42804' THEN
        RAISE NOTICE 'OK RN-13: INSERT manual en auditoria rechazado';
    END;

    BEGIN
        UPDATE "Auditoria_Precio" SET precio_nuevo = 999.00 WHERE vino = 'B-13-V1';

        RAISE EXCEPTION 'RN-13 FALLO: se permitio modificar la auditoria';
    EXCEPTION WHEN SQLSTATE '42804' THEN
        RAISE NOTICE 'OK RN-13: UPDATE manual en auditoria rechazado';
    END;

    BEGIN
        DELETE FROM "Auditoria_Precio" WHERE vino = 'B-13-V1';

        RAISE EXCEPTION 'RN-13 FALLO: se permitio borrar la auditoria';
    EXCEPTION WHEN SQLSTATE '42804' THEN
        RAISE NOTICE 'OK RN-13: DELETE manual en auditoria rechazado';
    END;
END;
$$;

-- Segundo cambio: historial acumulativo (reconstruye quien/cuando/cuenta).
SET LOCAL bodegas.usuario_funcional = 'api_front';

UPDATE "Vino" SET precio = 135.00 WHERE codigo = 'B-13-V1';

DO $$
DECLARE
    v_u TEXT;
BEGIN
    SELECT usuario INTO v_u
      FROM "Auditoria_Precio" WHERE vino = 'B-13-V1'
     ORDER BY fecha_hora DESC LIMIT 1;

    IF v_u IS NULL OR v_u NOT LIKE 'bodegas_app::api_front' THEN
        RAISE EXCEPTION 'RN-13 FALLO: el usuario funcional no quedo registrado (%)', v_u;
    END IF;

    RAISE NOTICE 'OK RN-13: usuario funcional registrado (%)', v_u;
END;
$$;

COMMIT;
