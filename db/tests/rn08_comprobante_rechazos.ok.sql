-- RN-08: se rechaza la carga manual de importes derivados.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE
VALUES (980101, 'Localidad rechazo RN-08');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE
VALUES (980101, 980101);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('20987654321', 'Bodega rechazo RN-08');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE
VALUES (980101, 'Cepa RN-08 rechazo', 'tinta');

INSERT INTO "Vino"(codigo, nombre, bodega, precio)
VALUES ('RN08-R', 'Vino rechazo', '20987654321', 100.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('RN08-R', 980101, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE
VALUES (980101, 'Cliente socio rechazo RN-08');

INSERT INTO "Socio"(id_cliente)
VALUES (980101);

-- Rechazo de importes manuales al crear la cabecera.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Comprobante"
            (numero, fecha, cliente, sala, subtotal, descuento, total)
        VALUES
            (980199, CURRENT_DATE, 980101, 980101, 100.00, 10.00, 90.00);

        RAISE EXCEPTION 'RN-08 FALLO: se aceptaron importes manuales en cabecera';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-08: importes manuales en alta de cabecera rechazados';
    END;
END;
$$;

-- RN-09: stock inicial del vino vendido en esta prueba (sala 980101).
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (980101, 'RN08-R', 999);

INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (980101, CURRENT_DATE, 980101, 980101);

INSERT INTO "Renglon_Comprobante"
    (comprobante, vino, cantidad, precio_unitario)
VALUES (980101, 'RN08-R', 1, 100.00);

-- Rechazo de actualizacion manual de importes de cabecera.
DO $$
BEGIN
    BEGIN
        UPDATE "Comprobante"
           SET total = 1.00
         WHERE numero = 980101;

        RAISE EXCEPTION 'RN-08 FALLO: se acepto modificar el total manualmente';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-08: actualizacion manual de cabecera rechazada';
    END;

    -- Rechazo de descuento y subtotal manuales al insertar un renglon.
    BEGIN
        INSERT INTO "Renglon_Comprobante"
            (comprobante, vino, cantidad, precio_unitario, descuento, subtotal)
        VALUES
            (980101, 'RN08-R2', 1, 100.00, 10.00, 90.00);

        RAISE EXCEPTION 'RN-08 FALLO: se aceptaron importes manuales en renglon';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-08: importes manuales en alta de renglon rechazados';
    END;

    -- Rechazo de modificacion manual del descuento historico.
    BEGIN
        UPDATE "Renglon_Comprobante"
           SET descuento = 20.00
         WHERE comprobante = 980101 AND vino = 'RN08-R';

        RAISE EXCEPTION 'RN-08 FALLO: se acepto modificar descuento historico';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-08: modificacion manual del descuento rechazada';
    END;

    -- Rechazo de modificacion manual del subtotal del renglon.
    BEGIN
        UPDATE "Renglon_Comprobante"
           SET subtotal = 1.00
         WHERE comprobante = 980101 AND vino = 'RN08-R';

        RAISE EXCEPTION 'RN-08 FALLO: se acepto modificar subtotal del renglon';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-08: modificacion manual del subtotal rechazada';
    END;
END;
$$;

COMMIT;