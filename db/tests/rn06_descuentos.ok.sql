-- RN-06: descuentos base por subtipo y sincronizacion del atributo.
-- Socio 10 %, Distribuidor 20 %, Exportador 30 %.

BEGIN;

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE
VALUES (950001, 'Cliente socio'),
       (950002, 'Cliente distribuidor'),
       (950003, 'Cliente exportador');

INSERT INTO "Socio"(id_cliente) VALUES (950001);
INSERT INTO "Distribuidor"(id_cliente) VALUES (950002);
INSERT INTO "Exportador"(id_cliente) VALUES (950003);

DO $$
DECLARE
    v_funcion NUMERIC(5,2);
    v_columna NUMERIC(5,2);
BEGIN
    v_funcion := fn_descuento_cliente(950001);
    SELECT descuento INTO v_columna FROM "Cliente" WHERE id_cliente = 950001;
    IF v_funcion <> 10 OR v_columna <> 10 THEN
        RAISE EXCEPTION 'RN-06 FALLO: descuento de Socio incorrecto';
    END IF;
    RAISE NOTICE 'OK RN-06: Socio recibe 10 %% y el atributo queda sincronizado';

    v_funcion := fn_descuento_cliente(950002);
    SELECT descuento INTO v_columna FROM "Cliente" WHERE id_cliente = 950002;
    IF v_funcion <> 20 OR v_columna <> 20 THEN
        RAISE EXCEPTION 'RN-06 FALLO: descuento de Distribuidor incorrecto';
    END IF;
    RAISE NOTICE 'OK RN-06: Distribuidor recibe 20 %% y el atributo queda sincronizado';

    v_funcion := fn_descuento_cliente(950003);
    SELECT descuento INTO v_columna FROM "Cliente" WHERE id_cliente = 950003;
    IF v_funcion <> 30 OR v_columna <> 30 THEN
        RAISE EXCEPTION 'RN-06 FALLO: descuento de Exportador incorrecto';
    END IF;
    RAISE NOTICE 'OK RN-06: Exportador recibe 30 %% y el atributo queda sincronizado';
END;
$$;

COMMIT;
