-- rn15_rangos.ok.sql
-- RN-15 (combina CHECK de 002 + 010): validaciones numÃ©ricas; los porcentajes de
-- Composicion deben ser > 0 y <= 100; los rangos de precio/graduacion/cantidades
-- rechazan valores fuera de dominio (rechazos internos, exit 0).

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777831', 'Bodega RN-15');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304301, 'Cepa RN-15', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio, graduacion)
VALUES ('B-15-V1', 'Vino RN-15', 'tinto', 2016, '30777777831', 100.00, 13.5);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-15-V1', 304301, 100.00);

-- Rechazo 1: porcentaje 0.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Composicion"(vino, cepa, porcentaje)
        VALUES ('B-15-V1', 304301, 0.00);

        RAISE EXCEPTION 'RN-15 FALLO: se acepto porcentaje 0';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-15: porcentaje 0 rechazado';
    END;
END;
$$;

-- Rechazo 2: porcentaje > 100.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Composicion"(vino, cepa, porcentaje)
        VALUES ('B-15-V1', 304301, 100.01);

        RAISE EXCEPTION 'RN-15 FALLO: se acepto porcentaje mayor a 100';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-15: porcentaje mayor a 100 rechazado';
    END;
END;
$$;

-- Rechazo 3: precio negativo y fuera de rango.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
        VALUES ('B-15-PN', 'Precio negativo', 'tinto', 2016, '30777777831', -1.00);

        RAISE EXCEPTION 'RN-15 FALLO: se acepto precio negativo';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-15: precio negativo rechazado';
    END;
END;
$$;

-- Rechazo 4: graduaciÃ³n fuera del rango [5, 20].
DO $$
BEGIN
    BEGIN
        INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio, graduacion)
        VALUES ('B-15-G1', 'Graduacion baja', 'tinto', 2016, '30777777831', 50.00, 4.9);

        RAISE EXCEPTION 'RN-15 FALLO: se acepto graduacion menor a 5';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-15: graduacion menor a 5 rechazada';
    END;

    BEGIN
        INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio, graduacion)
        VALUES ('B-15-G2', 'Graduacion alta', 'tinto', 2016, '30777777831', 50.00, 20.1);

        RAISE EXCEPTION 'RN-15 FALLO: se acepto graduacion mayor a 20';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-15: graduacion mayor a 20 rechazada';
    END;
END;
$$;

-- Estado consistente: solo la fila original vlida.
DO $$
DECLARE
    v_composiciones INTEGER;
    v_vinos INTEGER;
BEGIN
    SELECT count(*) INTO v_composiciones FROM "Composicion" WHERE vino = 'B-15-V1';
    SELECT count(*) INTO v_vinos FROM "Vino" WHERE codigo LIKE 'B-15-%';

    IF v_composiciones <> 1 OR v_vinos <> 1 THEN
        RAISE EXCEPTION 'RN-15 FALLO: rechazos no dejaron estado limpio (%, %)', v_composiciones, v_vinos;
    END IF;

    RAISE NOTICE 'OK RN-15: rschezos limpios (composiciones: %, vinos: %)', v_composiciones, v_vinos;
END;
$$;

COMMIT;
