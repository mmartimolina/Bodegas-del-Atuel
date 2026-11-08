-- rn11_transferencias.ok.sql
-- RN-11: en_confeccion -> terminado -> procesado via sp_procesar_transferencia
-- con dos proximos estados; descuenta del deposito y acredita la sala en la misma
-- subtransaccion; revertirla deja el estado y los stocks intactos (atomicidad).

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (303701, 'Localidad RN-11');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (303701, 303701);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777791', 'Bodega RN-11');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (303701, 'Cepa RN-11', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES
    ('B-11-V1', 'Vino transferencia A', 'tinto', 2020, '30777777791', 90.00),
    ('B-11-V2', 'Vino transferencia B', 'tinto', 2021, '30777777791', 45.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES
    ('B-11-V1', 303701, 100.00),
    ('B-11-V2', 303701, 100.00);

INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-11-V1', 100), ('B-11-V2', 50);

-- Transferencia procesada en esta prueba.
INSERT INTO "Transferencia"(numero, sala)
OVERRIDING SYSTEM VALUE VALUES (311001, 303701);

DO $$
BEGIN
    IF (SELECT fecha_confeccion FROM "Transferencia" WHERE numero = 311001) IS NULL OR
       (SELECT fecha_confeccion FROM "Transferencia" WHERE numero = 311001) <> CURRENT_DATE THEN
        RAISE EXCEPTION 'RN-11 FALLO: la fecha de confeccion no fue el dia actual';
    END IF;

    RAISE NOTICE 'OK RN-11: la fecha de confeccion se congel en el dia actual';
END;
$$;

INSERT INTO "Renglon_Transferencia"(transferencia, vino, cantidad)
VALUES (311001, 'B-11-V1', 5), (311001, 'B-11-V2', 2);

UPDATE "Transferencia" SET estado = 'terminado' WHERE numero = 311001;

SAVEPOINT rn11_antes;
CALL sp_procesar_transferencia(311001);

DO $$
DECLARE
    v_d1 BIGINT;
    v_d2 BIGINT;
    v_s1 BIGINT;
    v_s2 BIGINT;
    v_estado TEXT;
BEGIN
    SELECT cantidad INTO v_d1 FROM "Stock_Deposito" WHERE vino = 'B-11-V1';
    SELECT cantidad INTO v_d2 FROM "Stock_Deposito" WHERE vino = 'B-11-V2';
    SELECT cantidad INTO v_s1 FROM "Stock_Sala" WHERE sala = 303701 AND vino = 'B-11-V1';
    SELECT cantidad INTO v_s2 FROM "Stock_Sala" WHERE sala = 303701 AND vino = 'B-11-V2';
    SELECT estado INTO v_estado FROM "Transferencia" WHERE numero = 311001;

    IF NOT (v_d1 = 95 AND v_d2 = 48 AND v_s1 = 5 AND v_s2 = 2 AND v_estado = 'procesado') THEN
        RAISE EXCEPTION
            'RN-11 FALLO: tras procesar deposito= %/% y sala= %/% y estado % (esperado 95/48, 5/2, procesado)',
            v_d1, v_d2, v_s1, v_s2, v_estado;
    END IF;

    RAISE NOTICE 'OK RN-11: el deposito baja a 95/48 y la sala llega a 5/2 (estado procesado)';
END;
$$;

ROLLBACK TO SAVEPOINT rn11_antes;

-- Tras revertir la subtransaccion, el estado y ambos stocks vuelven al previo.
-- Como la sala no tenia stock inicial, tampoco deben quedar filas nuevas.
DO $$
DECLARE
    v_d1 BIGINT;
    v_d2 BIGINT;
    v_sala_filas BIGINT;
    v_estado TEXT;
BEGIN
    SELECT cantidad INTO v_d1
    FROM "Stock_Deposito"
    WHERE vino = 'B-11-V1';

    SELECT cantidad INTO v_d2
    FROM "Stock_Deposito"
    WHERE vino = 'B-11-V2';

    SELECT COUNT(*) INTO v_sala_filas
    FROM "Stock_Sala"
    WHERE sala = 303701
      AND vino IN ('B-11-V1', 'B-11-V2');

    SELECT estado INTO v_estado
    FROM "Transferencia"
    WHERE numero = 311001;

    IF v_d1 IS DISTINCT FROM 100
       OR v_d2 IS DISTINCT FROM 50
       OR v_sala_filas <> 0
       OR v_estado IS DISTINCT FROM 'terminado' THEN
        RAISE EXCEPTION
            'RN-11 FALLO: rollback deposito=%/%, filas_sala=%, estado=% (esperado 100/50, 0 filas, terminado)',
            v_d1, v_d2, v_sala_filas, v_estado;
    END IF;

    RAISE NOTICE 'OK RN-11: rollback restaura deposito (100/50), elimina filas de sala y mantiene estado terminado';
END;
$$;

-- Procesamiento definitivo de la transaccion del archivo.
CALL sp_procesar_transferencia(311001);

DO $$
DECLARE
    v_d1 BIGINT;
    v_d2 BIGINT;
    v_s1 BIGINT;
    v_s2 BIGINT;
    v_estado TEXT;
BEGIN
    SELECT cantidad INTO v_d1
    FROM "Stock_Deposito"
    WHERE vino = 'B-11-V1';

    SELECT cantidad INTO v_d2
    FROM "Stock_Deposito"
    WHERE vino = 'B-11-V2';

    SELECT cantidad INTO v_s1
    FROM "Stock_Sala"
    WHERE sala = 303701 AND vino = 'B-11-V1';

    SELECT cantidad INTO v_s2
    FROM "Stock_Sala"
    WHERE sala = 303701 AND vino = 'B-11-V2';

    SELECT estado INTO v_estado
    FROM "Transferencia"
    WHERE numero = 311001;

    IF v_d1 IS DISTINCT FROM 95
       OR v_d2 IS DISTINCT FROM 48
       OR v_s1 IS DISTINCT FROM 5
       OR v_s2 IS DISTINCT FROM 2
       OR v_estado IS DISTINCT FROM 'procesado' THEN
        RAISE EXCEPTION
            'RN-11 FALLO: procesamiento definitivo deposito=%/%, sala=%/%, estado=% (esperado 95/48, 5/2, procesado)',
            v_d1, v_d2, v_s1, v_s2, v_estado;
    END IF;

    RAISE NOTICE 'OK RN-11: procesamiento definitivo confirma deposito (95/48), sala (5/2) y estado procesado';
END;
$$;
COMMIT;
