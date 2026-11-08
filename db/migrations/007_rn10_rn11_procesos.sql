-- 007_rn10_rn11_procesos.sql
-- RN-10 (issue #32): procesamiento de ingresos al deposito central.
-- RN-11 (issue #33): procesamiento de transferencias de deposito a sala.
--
-- Ciclo de estado (ENUM estado_documento): en_confeccion -> terminado -> procesado.
-- Transiciones rechazadas por triggers: cualquier salto invalido o retroceso,
-- entre otros procesado -> cualquier estado y en_confeccion -> procesado.
--
-- Atomicidad: sp_procesar_* se ejecuta en la transaccion del llamador: validacion,
-- bloqueos, movimiento de stock y cambio de estado se confirman juntos o se
-- revierten juntos (cualquier violacion aborta COMMIT sin datos parciales).
--
-- Concurrencia: dos llamadas concurrentes se serializan por el bloqueo de fila de
-- la cabecera (SELECT ... FOR UPDATE): la segunda espera el COMMIT de la primera,
-- luego ve el estado 'procesado' y es rechazada (nunca se procesa dos veces).
-- El stock se actualiza bloqueando primero las filas de inventario en orden
-- ascendente por vino; para las transferencias el orden global es: cabecera ->
-- stock de deposito (orden por vino) -> stock de sala (orden por vino); ese orden
-- consistente evita interbloqueos entre dos procesamientos concurrentes.
--
-- RN-11 ademas congela fecha_confeccion (nunca se modifica tras insertar).

BEGIN;

-- =========================================================
-- Bandera de sesion: los triggers admiten el paso a procesado y
-- la proteccion de confeccion solo cuando el sistema (los
-- procedimientos sp_procesar_*) la activa. La API/usuario directo
-- no la necesita y las reglas siguen validas sin ella.
-- =========================================================

CREATE OR REPLACE FUNCTION fn_bandera_proceso_activada()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN COALESCE(current_setting('bodegas.fuente_sistema', true), '') = 'proceso';
END;
$$;

COMMENT ON FUNCTION fn_bandera_proceso_activada() IS
    'Auxiliar RN-10/RN-11: refleja si la sesion se identifica como maquinaria del proceso.';

-- =========================================================
-- RN-10 / RN-11: control de transiciones de estado
-- =========================================================

CREATE OR REPLACE FUNCTION fn_estado_documento_validar_transicion()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Sin cambio real de estado: operacion legitima, se permite.
    IF NEW.estado = OLD.estado THEN
        RETURN NEW;
    END IF;

    -- El paso a procesado solo lo establece la maquinaria (sp_procesar_*).
    IF NEW.estado = 'procesado' AND NOT fn_bandera_proceso_activada() THEN
        RAISE EXCEPTION
            'RN-10/11: el estado procesado solo se alcanza via sp_procesar_ingreso / sp_procesar_transferencia'
            USING ERRCODE = '23514';
    END IF;

    IF NOT (
        (OLD.estado = 'en_confeccion' AND NEW.estado = 'terminado')
        OR (OLD.estado = 'terminado' AND NEW.estado = 'procesado'
            AND fn_bandera_proceso_activada())
    ) THEN
        RAISE EXCEPTION
            'RN-10/11: transicion de estado invalida (% -> %). Permitidas: en_confeccion -> terminado (manual) y terminado -> procesado (con sp_procesar_*)',
            OLD.estado, NEW.estado
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ingreso_estado_transiciones
    BEFORE UPDATE OF estado ON "Ingreso"
    FOR EACH ROW
    EXECUTE FUNCTION fn_estado_documento_validar_transicion();

CREATE TRIGGER trg_transferencia_estado_transiciones
    BEFORE UPDATE OF estado ON "Transferencia"
    FOR EACH ROW
    EXECUTE FUNCTION fn_estado_documento_validar_transicion();

COMMENT ON TRIGGER trg_ingreso_estado_transiciones ON "Ingreso" IS
    'RN-10: solo en_confeccion->terminado (manual) y terminado->procesado (via procedure).';

COMMENT ON TRIGGER trg_transferencia_estado_transiciones ON "Transferencia" IS
    'RN-11: solo en_confeccion->terminado (manual) y terminado->procesado (via procedure).';

-- =========================================================
-- RN-11: la fecha de confeccion no se modifica
-- =========================================================

CREATE OR REPLACE FUNCTION fn_transferencia_proteger_fecha_confeccion()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_confeccion IS DISTINCT FROM OLD.fecha_confeccion THEN
        RAISE EXCEPTION
            'RN-11: la fecha de confeccion de una transferencia no se puede modificar'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_transferencia_fecha_confeccion
    BEFORE UPDATE OF fecha_confeccion ON "Transferencia"
    FOR EACH ROW
    EXECUTE FUNCTION fn_transferencia_proteger_fecha_confeccion();

COMMENT ON TRIGGER trg_transferencia_fecha_confeccion ON "Transferencia" IS
    'RN-11: congela la fecha de confeccion (la fija el DEFAULT al crear la fila).';

-- =========================================================
-- RN-10: procedimiento de procesamiento de ingresos
-- =========================================================

CREATE PROCEDURE sp_procesar_ingreso(p_codigo TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado          estado_documento;
    v_renglones       INTEGER;
    v_fuente_anterior TEXT;
BEGIN
    -- Bloqueo de la cabecera: serializa procesamientos concurrentes.
    SELECT estado INTO v_estado
      FROM "Ingreso"
     WHERE codigo = p_codigo
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RN-10: no existe el ingreso %', p_codigo
            USING ERRCODE = 'P0002';
    END IF;

    IF v_estado <> 'terminado' THEN
        RAISE EXCEPTION
            'RN-10: el ingreso % debe estar terminado (estado actual: %). En confeccion no impacta stock y procesado no se repite/revierte',
            p_codigo, v_estado
            USING ERRCODE = '23514';
    END IF;

    SELECT count(*) INTO v_renglones
      FROM "Renglon_Ingreso" WHERE ingreso = p_codigo;

    IF v_renglones = 0 THEN
        RAISE EXCEPTION
            'RN-10: el ingreso % no tiene renglones; no se procesa un ingreso vacio',
            p_codigo
            USING ERRCODE = '23514';
    END IF;

    v_fuente_anterior := COALESCE(current_setting('bodegas.fuente_sistema', true), '');
    PERFORM set_config('bodegas.fuente_sistema', 'proceso', true);

    UPDATE "Stock_Deposito" d
       SET cantidad = d.cantidad + r.total
      FROM (
            SELECT vino, SUM(cantidad)::BIGINT AS total
              FROM "Renglon_Ingreso"
             WHERE ingreso = p_codigo
             GROUP BY vino
             ORDER BY vino
           ) r
     WHERE d.vino = r.vino;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'RN-10: el deposito no tiene stock registrado para el vino del ingreso'
            USING ERRCODE = '23514';
    END IF;

    UPDATE "Ingreso"
       SET estado = 'procesado'
     WHERE codigo = p_codigo;

    PERFORM set_config('bodegas.fuente_sistema', v_fuente_anterior, true);
END;
$$;

COMMENT ON PROCEDURE sp_procesar_ingreso(TEXT) IS
    'RN-10: acredita el deposito con los renglones y marca procesado, atomicamente.';

-- =========================================================
-- RN-11: procedimiento de procesamiento de transferencias
-- =========================================================

CREATE PROCEDURE sp_procesar_transferencia(p_numero BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado          estado_documento;
    v_sala            BIGINT;
    v_renglones       INTEGER;
    v_disponible      BIGINT;
    v_afectadas       BIGINT;
    v_fuente_anterior TEXT;
    reg               RECORD;
BEGIN
    -- Bloqueo de la cabecera: serializa procesamientos concurrentes.
    SELECT estado, sala INTO v_estado, v_sala
      FROM "Transferencia"
     WHERE numero = p_numero
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RN-11: no existe la transferencia %', p_numero
            USING ERRCODE = 'P0002';
    END IF;

    IF v_estado <> 'terminado' THEN
        RAISE EXCEPTION
            'RN-11: la transferencia % debe estar terminada (estado actual: %). En confeccion no impacta stock y procesado no se repite',
            p_numero, v_estado
            USING ERRCODE = '23514';
    END IF;

    SELECT count(*) INTO v_renglones
      FROM "Renglon_Transferencia" WHERE transferencia = p_numero;

    IF v_renglones = 0 THEN
        RAISE EXCEPTION
            'RN-11: la transferencia % no tiene renglones; no se procesa una transferencia vacia',
            p_numero
            USING ERRCODE = '23514';
    END IF;

    v_fuente_anterior := COALESCE(current_setting('bodegas.fuente_sistema', true), '');
    PERFORM set_config('bodegas.fuente_sistema', 'proceso', true);

    -- Verificacion y bloqueo del stock de origen (deposito) en orden por vino:
    -- orden consistente entre procesamientos concurrentes (anti-deadlock) y
    -- mensajes de error con detalle de stock insuficiente.
    FOR reg IN
        SELECT r.vino, SUM(r.cantidad)::BIGINT AS requerido
          FROM "Renglon_Transferencia" r
         WHERE r.transferencia = p_numero
         GROUP BY r.vino
         ORDER BY r.vino
    LOOP
        SELECT cantidad INTO v_disponible
          FROM "Stock_Deposito"
         WHERE vino = reg.vino
         FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'RN-11: el deposito no tiene stock registrado para el vino %',
                reg.vino
                USING ERRCODE = '23514';
        END IF;

        IF v_disponible < reg.requerido THEN
            RAISE EXCEPTION
                'RN-11: stock insuficiente en el deposito para el vino % (disponible: %, requerido: %)',
                reg.vino, v_disponible, reg.requerido
                USING ERRCODE = '23514';
        END IF;
    END LOOP;

    UPDATE "Stock_Deposito" d
       SET cantidad = d.cantidad - r.total
      FROM (
            SELECT vino, SUM(cantidad)::BIGINT AS total
              FROM "Renglon_Transferencia"
             WHERE transferencia = p_numero
             GROUP BY vino
           ) r
     WHERE d.vino = r.vino;

    -- La fila de stock de la sala puede no existir aun: se inicializa en 0.
    INSERT INTO "Stock_Sala" (sala, vino, cantidad)
    SELECT v_sala, x.vino, 0
      FROM (SELECT DISTINCT vino FROM "Renglon_Transferencia"
             WHERE transferencia = p_numero) x
      ON CONFLICT (sala, vino) DO NOTHING;

    UPDATE "Stock_Sala" s
       SET cantidad = s.cantidad + r.total
      FROM (
            SELECT vino, SUM(cantidad)::BIGINT AS total
              FROM "Renglon_Transferencia"
             WHERE transferencia = p_numero
             GROUP BY vino
           ) r
     WHERE s.sala = v_sala AND s.vino = r.vino;

    GET DIAGNOSTICS v_afectadas = ROW_COUNT;

    IF v_afectadas = 0 THEN
        RAISE EXCEPTION
            'RN-11: no se pudo acreditar el stock de la sala % para la transferencia %',
            v_sala, p_numero
            USING ERRCODE = '23514';
    END IF;

    UPDATE "Transferencia"
       SET estado = 'procesado'
     WHERE numero = p_numero;

    PERFORM set_config('bodegas.fuente_sistema', v_fuente_anterior, true);
END;
$$;

COMMENT ON PROCEDURE sp_procesar_transferencia(BIGINT) IS
    'RN-11: descuenta del deposito, acredita la sala y marca procesado, atomicamente.';

-- =========================================================
-- Guardia documental RN-11
-- En este modelo una transferencia siempre cruza de deposito a sala
-- (Transferencia.sala NOT NULL + FK #28): es imposible "hacia el mismo
-- origen" y no se agrega un mecanismo redundante.
-- =========================================================

COMMIT;
