-- rn02_sala_localidad.ok.sql
-- A18 (issue #21): RN-02 — una sala pertenece a una sola localidad y el encargado
-- regional es atributo de la Localidad (dependencia funcional localidad -> encargado,
-- etapa 1 paso 4 / 3FN): una sola fila por localidad garantiza un encargado unico,
-- sin repetirlo ni contradecirlo por sala.
BEGIN;

INSERT INTO "Localidad"(id_localidad, codigo_postal, nombre, provincia, encargado_regional)
OVERRIDING SYSTEM VALUE VALUES (1, '5560', 'General Alvear', 'Mendoza', 'Juan Perez');

-- dos salas de la misma localidad: ambas leen el mismo encargado via FK
INSERT INTO "Sala"(id_sala, calle, numero, dia_cierre, localidad)
OVERRIDING SYSTEM VALUE VALUES (1, 'Av Mitre', 410, 'domingo', 1),
                               (2, 'Belgrano', 33,  'lunes',   1);

DO $t$
DECLARE e1 TEXT; e2 TEXT;
BEGIN
    SELECT l.encargado_regional INTO e1 FROM "Sala" s
           JOIN "Localidad" l ON l.id_localidad = s.localidad WHERE s.id_sala = 1;
    SELECT l.encargado_regional INTO e2 FROM "Sala" s
           JOIN "Localidad" l ON l.id_localidad = s.localidad WHERE s.id_sala = 2;
    IF e1 IS DISTINCT FROM e2 OR e1 IS NULL THEN
        RAISE EXCEPTION 'A18 FALLO: encargados contradictorios o nulos para salas de una localidad';
    END IF;
    RAISE NOTICE 'OK RN-02: salas 1 y 2 de la misma localidad comparten encargado %', e1;
END $t$;
ROLLBACK;
