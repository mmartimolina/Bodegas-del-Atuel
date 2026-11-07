-- rn07_permisos.fail.sql
-- A23 (issue #27): RN-07 — no se acepta vencimiento anterior o igual a la emision,
-- y el permiso exige un exportador existente. Este archivo DEBE terminar sin errores.
BEGIN;

INSERT INTO "Localidad"(id_localidad, codigo_postal, nombre, provincia, encargado_regional)
OVERRIDING SYSTEM VALUE VALUES (1, '5560', 'General Alvear', 'Mendoza', 'Juan Perez');

INSERT INTO "Cliente"(id_cliente, nombre, tipo_doc, n_doc, localidad, fecha_alta, descuento)
OVERRIDING SYSTEM VALUE VALUES (2, 'Export Andes SA', 'CUIT', '30712345678', 1, '2024-01-15', 30.00);

INSERT INTO "Exportador"(id_cliente, pais)
OVERRIDING SYSTEM VALUE VALUES (2, 'Brasil');

-- 1. vencimiento anterior a la emision (CHECK ck_permiso_fechas_orden)
DO $t$
BEGIN
    INSERT INTO "Permiso_Exportacion"(codigo, exportador, fecha_emision, fecha_vencimiento)
    VALUES ('PEX-BAD1', 2, '2025-06-01', '2025-01-10');
    RAISE EXCEPTION 'A23 FALLO: vencimiento anterior a emision fue aceptado';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'OK RN-07: vencimiento anterior a emision rechazado (ck_permiso_fechas_orden)';
END $t$;

-- 2. vencimiento igual a la emision
DO $t$
BEGIN
    INSERT INTO "Permiso_Exportacion"(codigo, exportador, fecha_emision, fecha_vencimiento)
    VALUES ('PEX-BAD2', 2, '2025-06-01', '2025-06-01');
    RAISE EXCEPTION 'A23 FALLO: vencimiento igual a emision fue aceptado';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'OK RN-07: vencimiento igual a emision rechazado (ck_permiso_fechas_orden)';
END $t$;

-- 3. permiso de un exportador inexistente (fk_permiso_exportador)
DO $t$
BEGIN
    INSERT INTO "Permiso_Exportacion"(codigo, exportador, fecha_emision, fecha_vencimiento)
    VALUES ('PEX-BAD3', 999, '2025-06-01', '2026-06-01');
    RAISE EXCEPTION 'A23 FALLO: permiso de exportador inexistente fue aceptado';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'OK RN-07: permiso con exportador inexistente rechazado (fk_permiso_exportador)';
END $t$;
ROLLBACK;
