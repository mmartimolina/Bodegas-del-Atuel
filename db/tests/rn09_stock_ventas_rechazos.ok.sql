-- rn09_stock_ventas_rechazos.ok.sql
-- RN-09 (rechazos internos, exit 0): venta sin stock suficiente, vino sin fila
-- de stock registrada, cambio de sala con renglones, y operaciones rechazadas
-- que no dejan datos parciales.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303101, 'Localidad rechazos RN-09');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303101, 303101), (303102, 303101);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777772', 'Bodega rechazos RN-09');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303101, 'Cepa rechazos', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-09-R1', 'Vino R1', 'tinto', 2017, '30777777772', 100.00),
    ('B-09-R2', 'Vino R2', 'tinto', 2018, '30777777772', 110.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-09-R1', 303101, 100.00),
    ('B-09-R2', 303101, 100.00);

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (303101, 'Cliente rechazos');

INSERT INTO "Socio"(id_cliente) VALUES (303101);

-- Stock escaso para R1 (3) y cero para R2; la sala 303102 no queda registra.
INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (303101, 'B-09-R1', 3);

INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (303101, CURRENT_DATE, 303101, 303101);

-- Rechazo 1: venta de mas unidades de las disponibles.
DO $$
DECLARE
    v_disponibles INTEGER;
BEGIN
    v_disponibles := fn_stock_sala(303101, 'B-09-R1');

    BEGIN
        INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
        VALUES (303101, 'B-09-R1', 4, 100.00);

        RAISE EXCEPTION 'RN-09 FALLO: se acepto vender mas de lo disponible';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-09: venta sin stock suficiente rechazada (disponibles: %)', v_disponibles;
    END;
END;
$$;

-- Rechazo 2: la operacion rechazada no dejo datos parciales (stock y renglones).
DO $$
DECLARE
    v_stock  INTEGER;
    v_renglones INTEGER;
BEGIN
    v_stock := fn_stock_sala(303101, 'B-09-R1');
    SELECT count(*) INTO v_renglones FROM "Renglon_Comprobante" WHERE comprobante = 303101;

    IF v_stock <> 3 OR v_renglones <> 0 THEN
        RAISE EXCEPTION
            'RN-09 FALLO: quedo estado parcial tras el rechazo (stock %, renglones %)',
            v_stock, v_renglones;
    END IF;

    RAISE NOTICE 'OK RN-09: el rechazo no dejo datos parciales';
END;
$$;

-- Rechazo 3: vino sin fila de stock registrada en la sala no es vendible.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
        VALUES (303101, 'B-09-R2', 1, 110.00);

        RAISE EXCEPTION 'RN-09 FALLO: se acepto vender un vino sin fila de stock';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-09: vino sin fila de stock registrado rechazado';
    END;
END;
$$;

-- Rechazo 4: la cabecera no cambia de sala cuando tiene renglones.
INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (303101, 'B-09-R1', 1, 100.00);

DO $$
BEGIN
    BEGIN
        UPDATE "Comprobante"
           SET sala = 303102
         WHERE numero = 303101;

        RAISE EXCEPTION 'RN-09 FALLO: se acepto mover un comprobante con renglones';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-09: cambio de sala de comprobante con renglones rechazado';
    END;
END;
$$;

-- Rechazo 5: el UPDATE de sala sigue rechazandose en intentos posteriores
-- (la cabecera conserva los renglones cargados y la sala original).
DO $$
BEGIN
    BEGIN
        UPDATE "Comprobante"
           SET sala = 303102
         WHERE numero = 303101;

        RAISE EXCEPTION 'RN-09 FALLO: se acepto mover un comprobante con renglones';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK RN-09: el intento repetido de cambio de sala siga rechazado';
    END;
END;
$$;

COMMIT;
