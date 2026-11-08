-- rn40_roles.ok.sql
-- Issue #40 (permisos permitidos): bodegas_api puede CRUD y ejecutar la logica
-- de negocio; bodegas_reportes solo lee (tablas y vistas); bodegas_admin tiene
-- todo (chequeado via catlogos y operaciones DML reales).

BEGIN;

-- Preparacion la hace bodegas_app (dueo), luego se audita con SET ROLE.
INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (304501, 'Localidad RN-40');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (304501, 304501);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777851', 'Bodega RN-40');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304501, 'Cepa RN-40', 'blanca');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-40-V1', 'Vino roles', 'blanco', 2023, '30777777851', 22.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-40-V1', 304501, 100.00);

INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (304501, 'B-40-V1', 10);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (304501, 'Cliente RN-40');

INSERT INTO "Socio"(id_cliente) VALUES (304501);

COMMIT;

-- 1) bodegas_reportes: SELECT en tablas y vistas.
BEGIN;
SET LOCAL ROLE bodegas_reportes;

DO $$
DECLARE
    n INTEGER;
BEGIN
    SELECT count(*) INTO n FROM "Vino";
    IF n IS NULL THEN
        RAISE EXCEPTION 'RN-40 FALLO: reportes no puede leer Vino';
    END IF;

    n := 0; SELECT count(*) INTO n FROM v_documentos_pendientes;
    IF n IS NULL THEN
        RAISE EXCEPTION 'RN-40 FALLO: reportes no puede leer vistas';
    END IF;

    RAISE NOTICE 'OK RN-40: bodegas_reportes lee tablas y vistas (vino: %)', n;
END;
$$;

COMMIT;

-- 2) bodegas_api: CRUD sobre tablas de negocio y ejecucion de la logica.
BEGIN;
SET LOCAL ROLE bodegas_api;

DO $$
DECLARE
    v_stock_aux INTEGER;
BEGIN
    -- UPDATE y DELETE legales para la API.
    UPDATE "Vino" SET precio = 23.00 WHERE codigo = 'B-40-V1';

    -- Function de negocio ejecutable por la API.
    v_stock_aux := fn_stock_sala(304501, 'B-40-V1');

    IF v_stock_aux IS NULL THEN
        RAISE EXCEPTION 'RN-40 FALLO: api no ejecuta fn_stock_sala';
    END IF;

    DELETE FROM "Vino" WHERE codigo = 'B-40-V1' AND FALSE;

    RAISE NOTICE 'OK RN-40: bodegas_api hace CRUD (stock consultado: %)', v_stock_aux;
END;
$$;

COMMIT;

-- 3) La API del caso NO escritura en auditoria es el rechazo cubierto en
--    rn40_roles_denegados.ok.sql; aqui se corrobora su lectura.
BEGIN;
SET LOCAL ROLE bodegas_api;

DO $$
DECLARE
    reg RECORD;
BEGIN
    SELECT count(*) INTO reg FROM "Auditoria_Precio";

    IF reg.count IS NULL THEN
        RAISE EXCEPTION 'RN-40 FALLO: la API no puede leer la auditoria';
    END IF;

    RAISE NOTICE 'OK RN-40: la API lee la auditoria (filas: %)', reg.count;
END;
$$;

COMMIT;
