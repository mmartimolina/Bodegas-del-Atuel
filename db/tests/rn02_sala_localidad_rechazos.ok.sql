-- rn02_sala_localidad.fail.sql
-- A18 (issue #21): RN-02 — no puede existir una sala sin localidad valida.
-- Este archivo DEBE terminar sin errores: cada DO espera el rechazo (FK y NOT NULL).
BEGIN;

INSERT INTO "Localidad"(id_localidad, codigo_postal, nombre, provincia, encargado_regional)
OVERRIDING SYSTEM VALUE VALUES (1, '5560', 'General Alvear', 'Mendoza', 'Juan Perez');

-- 1. sala con localidad inexistente -> foreign_key_violation (fk_sala_localidad)
DO $t$
BEGIN
    INSERT INTO "Sala"(calle, numero, dia_cierre, localidad)
    VALUES ('Av Mitre', 410, 'domingo', 999);
    RAISE EXCEPTION 'A18 FALLO: sala con localidad inexistente fue aceptada';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'OK RN-02: sala con localidad inexistente rechazada (fk_sala_localidad)';
END $t$;

-- 2. sala sin localidad -> not_null_violation (obligatoriedad RN-02)
DO $t$
BEGIN
    INSERT INTO "Sala"(calle, numero, dia_cierre, localidad)
    VALUES ('Av Mitre', 410, 'domingo', NULL);
    RAISE EXCEPTION 'A18 FALLO: sala sin localidad fue aceptada';
EXCEPTION WHEN not_null_violation THEN
    RAISE NOTICE 'OK RN-02: sala sin localidad rechazada (NOT NULL)';
END $t$;
ROLLBACK;
