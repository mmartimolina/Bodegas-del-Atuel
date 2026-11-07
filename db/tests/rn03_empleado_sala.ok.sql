-- RN-03: cada empleado pertenece a exactamente una sala.
-- La FK NOT NULL existente debe aceptar la sala valida y rechazar
-- una sala inexistente o una referencia NULL.

BEGIN;

INSERT INTO "Localidad"(
    id_localidad, codigo_postal, nombre, provincia, encargado_regional
)
OVERRIDING SYSTEM VALUE
VALUES (93001, '5560', 'Localidad RN03', 'Mendoza', 'Encargado RN03');

INSERT INTO "Sala"(id_sala, calle, numero, dia_cierre, localidad)
OVERRIDING SYSTEM VALUE
VALUES (93001, 'Calle RN03', 100, 'domingo', 93001);

INSERT INTO "Empleado"(nombre, sala)
VALUES ('Empleado uno', 93001),
       ('Empleado dos', 93001);

DO $$
DECLARE
    v_cantidad INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_cantidad
      FROM "Empleado"
     WHERE sala = 93001;

    IF v_cantidad <> 2 THEN
        RAISE EXCEPTION 'RN-03 FALLO: cantidad de empleados inesperada';
    END IF;

    RAISE NOTICE 'OK RN-03: varios empleados pueden trabajar en la misma sala';

    BEGIN
        INSERT INTO "Empleado"(nombre, sala)
        VALUES ('Empleado sin sala', NULL);

        RAISE EXCEPTION 'RN-03 FALLO: se acepto un empleado sin sala';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'OK RN-03: empleado sin sala rechazado';
    END;

    BEGIN
        INSERT INTO "Empleado"(nombre, sala)
        VALUES ('Empleado con sala inexistente', 93999);

        RAISE EXCEPTION 'RN-03 FALLO: se acepto una sala inexistente';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'OK RN-03: sala inexistente rechazada';
    END;
END;
$$;

ROLLBACK;
