-- RN-08: calculo automatico de importes.
-- Prueba altas, modificaciones, bajas y redondeo por renglon.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE
VALUES (980001, 'Localidad prueba RN-08');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE
VALUES (980001, 980001);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('20123456789', 'Bodega prueba RN-08');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE
VALUES (980001, 'Cepa RN-08', 'tinta');

INSERT INTO "Vino"(codigo, nombre, bodega, precio)
VALUES
    ('RN08-A', 'Vino A prueba', '20123456789', 100.00),
    ('RN08-B', 'Vino B prueba', '20123456789', 55.55);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('RN08-A', 980001, 100.00),
    ('RN08-B', 980001, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE
VALUES (980001, 'Cliente socio RN-08');

-- RN-09: stock inicial de la sala para los vinos vendidos en esta prueba.
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (980001, 'RN08-A', 999), (980001, 'RN08-B', 999);

INSERT INTO "Socio"(id_cliente)
VALUES (980001);

INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (980001, CURRENT_DATE, 980001, 980001);

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 0 OR v_descuento <> 0 OR v_total <> 0 THEN
        RAISE EXCEPTION 'RN-08 FALLO: cabecera nueva no inicializada en cero';
    END IF;

    RAISE NOTICE 'OK RN-08: cabecera nueva inicializada en cero';
END;
$$;

-- Alta de dos renglones: descuento de Socio = 10 %.
INSERT INTO "Renglon_Comprobante"
    (comprobante, vino, cantidad, precio_unitario)
VALUES
    (980001, 'RN08-A', 3, 100.00),
    (980001, 'RN08-B', 2, 55.55);

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
    v_desc_linea NUMERIC(5,2);
    v_sub_linea  NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 411.10 OR v_descuento <> 41.11 OR v_total <> 369.99 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: importes iniciales incorrectos (%, %, %)',
            v_subtotal, v_descuento, v_total;
    END IF;

    SELECT descuento, subtotal
      INTO v_desc_linea, v_sub_linea
      FROM "Renglon_Comprobante"
     WHERE comprobante = 980001 AND vino = 'RN08-B';

    IF v_desc_linea <> 10.00 OR v_sub_linea <> 99.99 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: calculo inicial de renglon incorrecto (%, %)',
            v_desc_linea, v_sub_linea;
    END IF;

    RAISE NOTICE 'OK RN-08: altas, descuento historico y redondeo por renglon';
END;
$$;

-- Modificacion de cantidad.
UPDATE "Renglon_Comprobante"
   SET cantidad = 3
 WHERE comprobante = 980001 AND vino = 'RN08-B';

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 466.65 OR v_descuento <> 46.67 OR v_total <> 419.98 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: recalculo por cantidad incorrecto (%, %, %)',
            v_subtotal, v_descuento, v_total;
    END IF;

    RAISE NOTICE 'OK RN-08: modificacion de cantidad recalcula la cabecera';
END;
$$;

-- Modificacion de precio historico.
UPDATE "Renglon_Comprobante"
   SET precio_unitario = 60.00
 WHERE comprobante = 980001 AND vino = 'RN08-B';

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 480.00 OR v_descuento <> 48.00 OR v_total <> 432.00 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: recalculo por precio incorrecto (%, %, %)',
            v_subtotal, v_descuento, v_total;
    END IF;

    RAISE NOTICE 'OK RN-08: modificacion de precio recalcula la cabecera';
END;
$$;

-- Baja de un renglon.
DELETE FROM "Renglon_Comprobante"
WHERE comprobante = 980001 AND vino = 'RN08-A';

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 180.00 OR v_descuento <> 18.00 OR v_total <> 162.00 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: recalculo al eliminar renglon incorrecto (%, %, %)',
            v_subtotal, v_descuento, v_total;
    END IF;

    RAISE NOTICE 'OK RN-08: baja de renglon recalcula la cabecera';
END;
$$;

-- Al eliminar el ultimo renglon, la cabecera queda en cero.
DELETE FROM "Renglon_Comprobante"
WHERE comprobante = 980001 AND vino = 'RN08-B';

DO $$
DECLARE
    v_subtotal  NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total     NUMERIC(12,2);
BEGIN
    SELECT subtotal, descuento, total
      INTO v_subtotal, v_descuento, v_total
      FROM "Comprobante"
     WHERE numero = 980001;

    IF v_subtotal <> 0 OR v_descuento <> 0 OR v_total <> 0 THEN
        RAISE EXCEPTION
            'RN-08 FALLO: comprobante sin renglones no queda en cero';
    END IF;

    RAISE NOTICE 'OK RN-08: comprobante sin renglones queda en cero';
END;
$$;

COMMIT;