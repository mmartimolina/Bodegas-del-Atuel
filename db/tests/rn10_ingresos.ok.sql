-- rn10_ingresos.ok.sql
-- RN-10: transicion en_confeccion -> terminado -> procesado via sp_procesar_ingreso,
-- acredita el deposito y es atomica (rollback deja el estado y el stock intactos).

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777781', 'Bodega RN-10');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303301, 'Cepa RN-10', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-10-V1', 'Vino ingreso A', 'tinto', 2020, '30777777781', 75.00),
    ('B-10-V2', 'Vino ingreso B', 'tinto', 2020, '30777777781', 65.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-10-V1', 303301, 100.00),
    ('B-10-V2', 303301, 100.00);

-- Stock de deposito inicial en 0: el ingreso lo acredita.
INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-10-V1', 0), ('B-10-V2', 0);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-10', 'Transportista RN-10');

-- Ingreso procesado en esta prueba.
INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES ('ING-10-1', CURRENT_DATE, 'TR-10', '30777777781');

-- Un renglon por vino: Renglon_Ingreso tiene PK (ingreso, vino).
INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-10-1', 'B-10-V1', 3), ('ING-10-1', 'B-10-V2', 4);

UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-10-1';

-- El procesamiento en una subtransaccion cambia stock y estado juntos;
-- revertir la subtransaccion deja el estado y el stock intactos (atomicidad).
SAVEPOINT rn10_antes;
CALL sp_procesar_ingreso('ING-10-1');

DO $$
DECLARE
    v_estado TEXT;
    v_stock1 BIGINT;
    v_stock2 BIGINT;
BEGIN
    SELECT estado INTO v_estado FROM "Ingreso" WHERE codigo = 'ING-10-1';
    SELECT cantidad INTO v_stock1 FROM "Stock_Deposito" WHERE vino = 'B-10-V1';
    SELECT cantidad INTO v_stock2 FROM "Stock_Deposito" WHERE vino = 'B-10-V2';

    IF v_estado <> 'procesado' OR v_stock1 <> 3 OR v_stock2 <> 4 THEN
        RAISE EXCEPTION
            'RN-10 FALLO: tras procesar el estado es % y el stock de deposito %/% (esperado procesado/3/4)',
            v_estado, v_stock1, v_stock2;
    END IF;

    RAISE NOTICE 'OK RN-10: el ingreso terminado acredito el deposito (3/4)';
END;
$$;

ROLLBACK TO SAVEPOINT rn10_antes;

DO $$
DECLARE
    v_estado TEXT;
    v_stock1 BIGINT;
    v_stock2 BIGINT;
BEGIN
    SELECT estado INTO v_estado
    FROM "Ingreso"
    WHERE codigo = 'ING-10-1';

    SELECT cantidad INTO v_stock1
    FROM "Stock_Deposito"
    WHERE vino = 'B-10-V1';

    SELECT cantidad INTO v_stock2
    FROM "Stock_Deposito"
    WHERE vino = 'B-10-V2';

    IF v_estado IS DISTINCT FROM 'terminado'
       OR v_stock1 IS DISTINCT FROM 0
       OR v_stock2 IS DISTINCT FROM 0 THEN
        RAISE EXCEPTION
            'RN-10 FALLO: rollback dejo estado=% y stocks=%/% (esperado terminado/0/0)',
            v_estado, v_stock1, v_stock2;
    END IF;

    RAISE NOTICE 'OK RN-10: rollback restaura estado terminado y ambos stocks en 0';
END;
$$;

-- Procesamiento definitivo de la transaccion del archivo.
CALL sp_procesar_ingreso('ING-10-1');

DO $$
DECLARE
    v_estado TEXT;
    v_stock1 BIGINT;
    v_stock2 BIGINT;
BEGIN
    SELECT estado INTO v_estado
    FROM "Ingreso"
    WHERE codigo = 'ING-10-1';

    SELECT cantidad INTO v_stock1
    FROM "Stock_Deposito"
    WHERE vino = 'B-10-V1';

    SELECT cantidad INTO v_stock2
    FROM "Stock_Deposito"
    WHERE vino = 'B-10-V2';

    IF v_estado IS DISTINCT FROM 'procesado'
       OR v_stock1 IS DISTINCT FROM 3
       OR v_stock2 IS DISTINCT FROM 4 THEN
        RAISE EXCEPTION
            'RN-10 FALLO: procesamiento definitivo dejo estado=% y stocks=%/% (esperado procesado/3/4)',
            v_estado, v_stock1, v_stock2;
    END IF;

    RAISE NOTICE 'OK RN-10: procesamiento definitivo confirma estado procesado y stocks 3/4';
END;
$$;

COMMIT;
