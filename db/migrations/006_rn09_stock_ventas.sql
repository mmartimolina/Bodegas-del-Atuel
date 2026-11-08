-- 006_rn09_stock_ventas.sql
-- RN-09 (issue #31): el stock de la sala se descuenta al vender (con cada renglon
-- de Comprobante) y no se puede vender sin stock suficiente; el stock nunca queda
-- negativo (ademas respaldado por ck_stock_sala_cantidad_no_negativa de 002).
--
-- Decision adoptada (documentada en docs/modelo/12): el descuento ocurre dentro
-- de las misma transaccion en que se ingresa/modifica/quita un renglon. INSERT
-- consume; UPDATE aplica solo la diferencia (delta), por lo que un reintento o
-- re-update sin cambio no vuelve a descontar; DELETE repone (incluido el borrado
-- en cascada de la cabecera, cubierto por un registro temporal del par sala/vino
-- que se hace en el trigger BEFORE DELETE de Comprobante).
--
-- Concurrencia: cada consumo/reposicion toma primero un bloqueo de fila
-- SELECT ... FOR UPDATE sobre la fila de Stock_Sala clave (sala, vino); dos
-- transacciones que compiten por la misma fila se serializan y siempre re-leyen
-- el valor ya bloqueado (suficiente con READ COMMITTED). En operaciones de
-- movimiento de renglon entre salas/vinos se toman las dos filas en orden
-- ascendente (sala, vino) para evitar interbloqueos entre cruces de sentido
-- inverso. Demostracion reproducible: db/tests/concurrency_rn09_demo.ps1.

BEGIN;

-- =========================================================
-- fn_stock_sala: stock disponible de un vino en una sala
-- (funcion requerida por el minimo de 4 funciones de la consigna;
-- llamada de ejemplo from U6/Q1: SELECT fn_stock_sala(1, 'VINO1');)
-- =========================================================

CREATE FUNCTION fn_stock_sala(p_sala BIGINT, p_vino TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_vino_existe BOOLEAN;
    v_resultado   INTEGER;
BEGIN
    SELECT EXISTS(SELECT 1 FROM "Vino" WHERE codigo = p_vino)
      INTO v_vino_existe;

    IF NOT v_vino_existe THEN
        RAISE EXCEPTION 'RN-09: el vino % no existe', p_vino
            USING ERRCODE = 'P0002';
    END IF;

    -- Sin fila de stock no hay unidades vendibles: se informa 0.
    SELECT cantidad INTO v_resultado
      FROM "Stock_Sala"
     WHERE sala = p_sala AND vino = p_vino;

    RETURN COALESCE(v_resultado, 0);
END;
$$;

COMMENT ON FUNCTION fn_stock_sala(BIGINT, TEXT) IS
    'RN-09: stock disponible del vino p_vino en la sala p_sala (0 si no hay fila).';

-- =========================================================
-- Helpers de consumo y reposicion con bloqueo de fila
-- =========================================================

CREATE FUNCTION fn_rn09_consumir_stock(p_sala BIGINT, p_vino TEXT, p_cantidad INTEGER)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_cantidad INTEGER;
    v_restante INTEGER;
BEGIN
    SELECT cantidad INTO v_cantidad
      FROM "Stock_Sala"
     WHERE sala = p_sala AND vino = p_vino
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'RN-09: no hay stock registrado en la sala % para el vino %',
            p_sala, p_vino
            USING ERRCODE = '23514';
    END IF;

    v_restante := v_cantidad - p_cantidad;

    IF v_restante < 0 THEN
        RAISE EXCEPTION
            'RN-09: stock insuficiente en la sala % para el vino % (disponible: %, requerido: %)',
            p_sala, p_vino, v_cantidad, p_cantidad
            USING ERRCODE = '23514';
    END IF;

    UPDATE "Stock_Sala"
       SET cantidad = v_restante
     WHERE sala = p_sala AND vino = p_vino;
END;
$$;

CREATE FUNCTION fn_rn09_reponer_stock(p_sala BIGINT, p_vino TEXT, p_cantidad INTEGER)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_cantidad INTEGER;
    v_restante INTEGER;
BEGIN
    SELECT cantidad INTO v_cantidad
      FROM "Stock_Sala"
     WHERE sala = p_sala AND vino = p_vino
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'RN-09: no hay stock registrado en la sala % para el vino %',
            p_sala, p_vino
            USING ERRCODE = '23514';
    END IF;

    v_restante := v_cantidad + p_cantidad;

    UPDATE "Stock_Sala"
       SET cantidad = v_restante
     WHERE sala = p_sala AND vino = p_vino;
END;
$$;

COMMENT ON FUNCTION fn_rn09_consumir_stock(BIGINT, TEXT, INTEGER) IS
    'RN-09: consume p_cantidad unidades bajo bloqueo de fila; rechaza si el stock no alcanza.';

COMMENT ON FUNCTION fn_rn09_reponer_stock(BIGINT, TEXT, INTEGER) IS
    'RN-09: repone p_cantidad unidades bajo bloqueo de fila (para DELETE o movimientos).';

-- =========================================================
-- Registro de la sala de la cabecera antes de su borrado
-- (necesario para reponer stock cuando la cabecera se elimina
-- y el borrado en cascada elimina los renglones: para ese instante
-- la fila de Comprobante ya no es visible para el subconsulta)
-- =========================================================

CREATE FUNCTION fn_comprobante_registrar_sala()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS t_rn09_sala_comprobante (
        numero BIGINT PRIMARY KEY,
        sala   BIGINT
    ) ON COMMIT DROP;

    INSERT INTO t_rn09_sala_comprobante (numero, sala)
    VALUES (OLD.numero, OLD.sala)
    ON CONFLICT (numero) DO NOTHING;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_comprobante_registrar_sala
    BEFORE DELETE ON "Comprobante"
    FOR EACH ROW
    EXECUTE FUNCTION fn_comprobante_registrar_sala();

COMMENT ON TRIGGER trg_comprobante_registrar_sala ON "Comprobante" IS
    'RN-09: conserva (sala) en temp ON COMMIT DROP para el borrado en cascada de renglones.';

-- =========================================================
-- Aplicacion del efecto de stock al renglon de comprobante
-- =========================================================

CREATE FUNCTION fn_renglon_comprobante_aplicar_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_sala_vieja  BIGINT;
    v_sala_nueva  BIGINT;
    v_vino_viejo  TEXT;
    v_vino_nuevo  TEXT;
    v_delta       INTEGER;
    v_reservado   integer;
BEGIN
    IF TG_OP <> 'DELETE' THEN
        -- Bloqueo de la cabecera: serializa contra cambios concurrentes de sala.
        SELECT sala INTO v_sala_nueva
          FROM "Comprobante" WHERE numero = NEW.comprobante FOR SHARE;
        v_vino_nuevo := NEW.vino;
    END IF;

    IF TG_OP <> 'INSERT' THEN
        IF TG_OP = 'DELETE' THEN
            -- Durante el borrado en cascada la cabecera ya no es visible para
            -- consultas: se usa el registro de sala hecho por
            -- trg_comprobante_registrar_sala al inicio de la instruccion.
            IF to_regclass('t_rn09_sala_comprobante') IS NOT NULL THEN
                SELECT sala INTO v_sala_vieja
                  FROM t_rn09_sala_comprobante WHERE numero = OLD.comprobante;
            END IF;

            IF v_sala_vieja IS NULL THEN
                SELECT sala INTO v_sala_vieja
                  FROM "Comprobante" WHERE numero = OLD.comprobante FOR SHARE;
            END IF;
        ELSE
            SELECT sala INTO v_sala_vieja
              FROM "Comprobante" WHERE numero = OLD.comprobante FOR SHARE;
        END IF;
        v_vino_viejo := OLD.vino;
    END IF;

    -- Caso 1: alta; se consumen las unidades vendidas.
    IF TG_OP = 'INSERT' THEN
        PERFORM fn_rn09_consumir_stock(v_sala_nueva, v_vino_nuevo, NEW.cantidad);
        RETURN NEW;
    END IF;

    -- Caso 2: modificacion. La operacion aplica la diferencia sobre el valor
    -- de stock vigente (ya afectado por operaciones previas): no hay doble descuento.
    IF TG_OP = 'UPDATE' THEN
        IF (v_sala_vieja, v_vino_viejo) IS DISTINCT FROM (v_sala_nueva, v_vino_nuevo) THEN
            -- Movimiento a otra sala/vino: bloqueo en orden (sala, vino) para
            -- evitar interbloqueos con la operacion inversa; luego repone/consume.
            IF (v_sala_vieja, v_vino_viejo) < (v_sala_nueva, v_vino_nuevo) THEN
                SELECT 0 INTO v_reservado FROM "Stock_Sala"
                 WHERE sala = v_sala_vieja AND vino = v_vino_viejo FOR UPDATE;
                SELECT 0 INTO v_reservado FROM "Stock_Sala"
                 WHERE sala = v_sala_nueva AND vino = v_vino_nuevo FOR UPDATE;
            ELSE
                SELECT 0 INTO v_reservado FROM "Stock_Sala"
                 WHERE sala = v_sala_nueva AND vino = v_vino_nuevo FOR UPDATE;
                SELECT 0 INTO v_reservado FROM "Stock_Sala"
                 WHERE sala = v_sala_vieja AND vino = v_vino_viejo FOR UPDATE;
            END IF;

            PERFORM fn_rn09_reponer_stock(v_sala_vieja, v_vino_viejo, OLD.cantidad);
            PERFORM fn_rn09_consumir_stock(v_sala_nueva, v_vino_nuevo, NEW.cantidad);
        ELSE
            v_delta := NEW.cantidad - OLD.cantidad;
            IF v_delta > 0 THEN
                PERFORM fn_rn09_consumir_stock(v_sala_nueva, v_vino_nuevo, v_delta);
            ELSIF v_delta < 0 THEN
                PERFORM fn_rn09_reponer_stock(v_sala_nueva, v_vino_nuevo, -v_delta);
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- Caso 3: baja (incluido borrado en cascada de la cabecera): repone unidades.
    PERFORM fn_rn09_reponer_stock(v_sala_vieja, v_vino_viejo, OLD.cantidad);
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_renglon_comprobante_stock
    BEFORE INSERT OR UPDATE OR DELETE ON "Renglon_Comprobante"
    FOR EACH ROW
    EXECUTE FUNCTION fn_renglon_comprobante_aplicar_stock();

COMMENT ON TRIGGER trg_renglon_comprobante_stock ON "Renglon_Comprobante" IS
    'RN-09: consume/restaura stock de la sala con bloqueo de fila; stock nunca negativo.';

-- =========================================================
-- Cabecera no cambia de sala cuando ya tiene renglones
-- =========================================================

CREATE FUNCTION fn_comprobante_proteger_sala()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_renglones INTEGER;
BEGIN
    SELECT count(*) INTO v_renglones
      FROM "Renglon_Comprobante"
     WHERE comprobante = NEW.numero;

    IF v_renglones > 0 THEN
        RAISE EXCEPTION
            'RN-09: la sala de un comprobante con renglones no se modifica (hay % renglones)',
            v_renglones
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_comprobante_sala_con_renglones
    BEFORE UPDATE OF sala ON "Comprobante"
    FOR EACH ROW
    EXECUTE FUNCTION fn_comprobante_proteger_sala();

COMMENT ON TRIGGER trg_comprobante_sala_con_renglones ON "Comprobante" IS
    'RN-09: la sala de un comprobante con renglones no cambia (evita reposiciones ambiguas).';

COMMENT ON FUNCTION fn_comprobante_proteger_sala() IS
    'RN-09: impide el traslado de sala de un comprobante con renglones ya cargados.';

COMMIT;
