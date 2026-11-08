-- rn40_roles_denegados.ok.sql
-- Issue #40 (permisos denegados, exit 0): reportes no escribe; reportes no
-- ejecuta procedimientos; la API no escribe Auditoria_Precio; PUBLIC no tiene
-- acceso a las tablas.

BEGIN;

-- 1) bodegas_reportes no escribe.
BEGIN;
SET LOCAL ROLE bodegas_reportes;

DO $$
BEGIN
    BEGIN
        UPDATE "Vino" SET precio = 1.00;
        RAISE EXCEPTION 'RN-40 FALLO: reportes pudo escribir';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'OK RN-40: bodegas_reportes no escribe tablas';
    END;

    BEGIN
        INSERT INTO "Cliente"(id_cliente, nombre) OVERRIDING SYSTEM VALUE VALUES (999999, 'X');
        RAISE EXCEPTION 'RN-40 FALLO: reportes pudo insertar';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'OK RN-40: bodegas_reportes no inserta';
    END;
END;
$$;

ROLLBACK;

-- 2) bodegas_reportes no ejecuta los procedimientos de negocio.
BEGIN;
SET LOCAL ROLE bodegas_reportes;

DO $$
BEGIN
    BEGIN
        CALL sp_procesar_ingreso('ING-INEXISTENTE-999');
        RAISE EXCEPTION 'RN-40 FALLO: reportes ejecuto procedure';
    EXCEPTION
        WHEN insufficient_privilege THEN RAISE NOTICE 'OK RN-40: reportes no ejecuta procedures';
        WHEN no_data_found THEN      RAISE NOTICE 'OK RN-40: reportes no ejecuta procedures (inexistente)';
    END;
END;
$$;

ROLLBACK;

-- 3) bodegas_api no escribe Auditoria_Precio (solo la lee).
BEGIN;
SET LOCAL ROLE bodegas_api;

DO $$
BEGIN
    BEGIN
        UPDATE "Auditoria_Precio" SET precio_nuevo = 0.00;
        RAISE EXCEPTION 'RN-40 FALLO: api pudo escribir la auditoria';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'OK RN-40: la API no escribe Auditoria_Precio';
    END;
END;
$$;

ROLLBACK;

-- 4) PUBLIC no tiene acceso a las tablas del esquema.
DO $$
DECLARE
    v_public_select BOOLEAN;
BEGIN
    SELECT has_table_privilege('public', '"Sala"', 'SELECT')
      INTO v_public_select;

    IF v_public_select THEN
        RAISE EXCEPTION 'RN-40 FALLO: PUBLIC conserva acceso de lectura a Sala';
    END IF;

    RAISE NOTICE 'OK RN-40: PUBLIC sin privilegios sobre las tablas del negocio';
END;
$$;
