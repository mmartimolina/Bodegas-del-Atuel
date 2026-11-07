-- rn07_permisos.ok.sql
-- A23 (issue #27): RN-07 — un exportador puede tener varios permisos, cada uno con
-- fecha_vencimiento posterior a la fecha_emision (CHECK ck_permiso_fechas_orden).
BEGIN;

INSERT INTO "Localidad"(id_localidad, codigo_postal, nombre, provincia, encargado_regional)
OVERRIDING SYSTEM VALUE VALUES (1, '5560', 'General Alvear', 'Mendoza', 'Juan Perez');

INSERT INTO "Cliente"(id_cliente, nombre, tipo_doc, n_doc, localidad, fecha_alta)
OVERRIDING SYSTEM VALUE VALUES (2, 'Export Andes SA', 'CUIT', '30712345678', 1, '2024-01-15');

INSERT INTO "Exportador"(id_cliente, pais)
OVERRIDING SYSTEM VALUE VALUES (2, 'Brasil');

-- varios permisos del mismo exportador: se aceptan
INSERT INTO "Permiso_Exportacion"(codigo, exportador, fecha_emision, fecha_vencimiento)
OVERRIDING SYSTEM VALUE VALUES
    ('PEX-0001', 2, '2025-01-10', '2025-12-31'),
    ('PEX-0002', 2, '2025-02-01', '2026-01-31'),
    ('PEX-0003', 2, '2025-03-01', '2027-03-01');

DO $t$
DECLARE n INT; e BIGINT;
BEGIN
    SELECT exportador INTO e FROM "Permiso_Exportacion" WHERE codigo = 'PEX-0002';
    SELECT count(*) INTO n FROM "Permiso_Exportacion" WHERE exportador = 2;
    IF n <> 3 OR e <> 2 THEN
        RAISE EXCEPTION 'A23 FALLO: permisos del exportador = % (esperado 3)', n;
    END IF;
    RAISE NOTICE 'OK RN-07: exportador aceptado con % permisos', n;
END $t$;
ROLLBACK;
