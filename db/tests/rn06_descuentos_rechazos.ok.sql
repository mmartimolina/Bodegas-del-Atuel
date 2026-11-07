-- RN-06: comprobaciones negativas de la funcion, el rango
-- y la consistencia del atributo almacenado.

BEGIN;

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE
VALUES (951001, 'Cliente socio'),
       (951002, 'Cliente sin subtipo');

INSERT INTO "Socio"(id_cliente) VALUES (951001);

DO $$
DECLARE
    v_dummy NUMERIC(5,2);
BEGIN
    -- Cliente inexistente.
    BEGIN
        v_dummy := fn_descuento_cliente(959999);
        RAISE EXCEPTION 'RN-06 FALLO: se acepto un cliente inexistente';
    EXCEPTION WHEN no_data_found THEN
        RAISE NOTICE 'OK RN-06: cliente inexistente rechazado';
    END;

    -- Cliente sin subtipo.
    BEGIN
        v_dummy := fn_descuento_cliente(951002);
        RAISE EXCEPTION 'RN-06 FALLO: se acepto un cliente sin subtipo';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-06: cliente sin subtipo rechazado por la funcion';
    END;

    -- Cliente perteneciente a dos subtipos.
    BEGIN
        INSERT INTO "Distribuidor"(id_cliente) VALUES (951001);
        RAISE EXCEPTION 'RN-06 FALLO: se aceptaron dos subtipos';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-06: segundo subtipo rechazado';
    END;

    -- No se puede cambiar manualmente el descuento de un socio.
    BEGIN
        UPDATE "Cliente"
           SET descuento = 20
         WHERE id_cliente = 951001;

        RAISE EXCEPTION 'RN-06 FALLO: se acepto descuento inconsistente';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-06: descuento manual inconsistente rechazado';
    END;

    -- El rango se controla mediante el CHECK de Cliente.
    BEGIN
        UPDATE "Cliente"
           SET descuento = 101
         WHERE id_cliente = 951001;

        RAISE EXCEPTION 'RN-06 FALLO: se acepto descuento fuera de rango';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-06: descuento fuera de rango rechazado';
    END;

    -- El descuento no se carga manualmente en el alta del cliente.
    BEGIN
        INSERT INTO "Cliente"(id_cliente, nombre, descuento)
        OVERRIDING SYSTEM VALUE
        VALUES (951003, 'Descuento manual', 10);

        RAISE EXCEPTION 'RN-06 FALLO: se acepto descuento manual al crear Cliente';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-06: descuento manual en alta rechazado';
    END;
END;
$$;

ROLLBACK;
