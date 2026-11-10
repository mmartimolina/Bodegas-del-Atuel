BEGIN;

DO $$
DECLARE
    v_cliente BIGINT;
    v_descuento NUMERIC(5,2);
BEGIN
    INSERT INTO "Cliente" (nombre, tipo_doc, n_doc, fecha_alta)
    VALUES ('Exportador U6 test', 'DNI', 'U6-TEST-1', CURRENT_DATE)
    RETURNING id_cliente INTO v_cliente;

    INSERT INTO "Exportador" (id_cliente, pais)
    VALUES (v_cliente, 'Argentina');

    INSERT INTO "Permiso_Exportacion" (codigo, exportador, fecha_emision, fecha_vencimiento)
    VALUES
        ('U6-TEST-1', v_cliente, CURRENT_DATE, CURRENT_DATE + 1),
        ('U6-TEST-2', v_cliente, CURRENT_DATE, CURRENT_DATE + 1),
        ('U6-TEST-3', v_cliente, CURRENT_DATE, CURRENT_DATE + 1);

    SELECT descuento INTO v_descuento
      FROM "Cliente" WHERE id_cliente = v_cliente;
    IF v_descuento <> 30.00 THEN
        RAISE EXCEPTION 'U6: esperado 30%% con tres permisos, recibido %', v_descuento;
    END IF;

    INSERT INTO "Permiso_Exportacion" (codigo, exportador, fecha_emision, fecha_vencimiento)
    VALUES ('U6-TEST-4', v_cliente, CURRENT_DATE, CURRENT_DATE + 1);

    SELECT descuento INTO v_descuento
      FROM "Cliente" WHERE id_cliente = v_cliente;
    IF v_descuento <> 35.00 THEN
        RAISE EXCEPTION 'U6: esperado 35%% con cuatro permisos, recibido %', v_descuento;
    END IF;

    DELETE FROM "Permiso_Exportacion" WHERE codigo = 'U6-TEST-4';

    SELECT descuento INTO v_descuento
      FROM "Cliente" WHERE id_cliente = v_cliente;
    IF v_descuento <> 30.00 THEN
        RAISE EXCEPTION 'U6: esperado 30%% luego de volver a tres permisos, recibido %', v_descuento;
    END IF;
END;
$$;

ROLLBACK;
