--
-- PostgreSQL database dump
--

\restrict srMAXqJUFO1duXg1qa76d8nlzVTGEjWkOmdQ9Va43dx8v8eDqm3tteeIDQBFcAy

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cuit_dom; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.cuit_dom AS character varying(11)
	CONSTRAINT cuit_dom_formato CHECK (((VALUE)::text ~ '^[0-9]{11}$'::text));


ALTER DOMAIN public.cuit_dom OWNER TO postgres;

--
-- Name: estado_documento; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_documento AS ENUM (
    'en_confeccion',
    'terminado',
    'procesado'
);


ALTER TYPE public.estado_documento OWNER TO postgres;

--
-- Name: fn_antiguedad_anios(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date DEFAULT CURRENT_DATE) RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_anios   INTEGER;
BEGIN
    IF p_fecha IS NULL OR p_hasta IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_fecha > p_hasta THEN
        -- Fecha fuera de rango: devuelve -1 para no confundir "recien cumplido"
        -- con un dato falso; las consultas filtran > N y no cuentan fechas
        -- futuras. Documentado como decision (un V2 de "aumento de salario"
        -- con fecha futura deberia revisar el dato, no lo ocultar).
        RETURN -1;
    END IF;

    v_anios := date_part('year', age(p_hasta, p_fecha))::INTEGER;

    RETURN v_anios;
END;
$$;


ALTER FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date) OWNER TO postgres;

--
-- Name: FUNCTION fn_antiguedad_anios(p_fecha date, p_hasta date); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date) IS 'Issue #38: anios cumplidos entre p_fecha y p_hasta (defecto CURRENT_DATE); NULL si alguna fecha es NULL; -1 si la fecha es futura.';


--
-- Name: fn_auditoria_precio_proteger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_auditoria_precio_proteger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT'
       AND COALESCE(current_setting('bodegas.auditoria_interna', true), '') = '1' THEN
        RETURN NEW; -- INSERT generado por trg_vino_auditar_precio
    END IF;

    RAISE EXCEPTION
        'RN-13: "Auditoria_Precio" solo acepta filas generadas por trg_vino_auditar_precio (operacion % rechazada)',
        TG_OP
        USING ERRCODE = '42804';
END;
$$;


ALTER FUNCTION public.fn_auditoria_precio_proteger() OWNER TO postgres;

--
-- Name: fn_bandera_proceso_activada(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_bandera_proceso_activada() RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN COALESCE(current_setting('bodegas.fuente_sistema', true), '') = 'proceso';
END;
$$;


ALTER FUNCTION public.fn_bandera_proceso_activada() OWNER TO postgres;

--
-- Name: FUNCTION fn_bandera_proceso_activada(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_bandera_proceso_activada() IS 'Auxiliar RN-10/RN-11: refleja si la sesion se identifica como maquinaria del proceso.';


--
-- Name: fn_cliente_rechazar_descuento_manual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cliente_rechazar_descuento_manual() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.descuento IS NOT NULL THEN
        RAISE EXCEPTION
            'RN-06: el descuento se determina por el subtipo del cliente'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_cliente_rechazar_descuento_manual() OWNER TO postgres;

--
-- Name: fn_cliente_sincronizar_descuento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cliente_sincronizar_descuento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Cliente"
       SET descuento = fn_descuento_cliente(NEW.id_cliente)
     WHERE id_cliente = NEW.id_cliente;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_cliente_sincronizar_descuento() OWNER TO postgres;

--
-- Name: fn_cliente_validar_cambio_descuento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cliente_validar_cambio_descuento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_esperado NUMERIC(5,2);
BEGIN
    IF NEW.descuento IS NOT DISTINCT FROM OLD.descuento THEN
        RETURN NEW;
    END IF;

    -- Se deja actuar al CHECK de rango si el valor sale de 0..100.
    IF NEW.descuento IS NOT NULL
       AND (NEW.descuento < 0 OR NEW.descuento > 100) THEN
        RETURN NEW;
    END IF;

    v_esperado := fn_descuento_cliente(OLD.id_cliente);

    IF NEW.descuento IS DISTINCT FROM v_esperado THEN
        RAISE EXCEPTION
            'RN-06: descuento inconsistente para cliente %. Esperado: %, recibido: %',
            OLD.id_cliente, v_esperado, NEW.descuento
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_cliente_validar_cambio_descuento() OWNER TO postgres;

--
-- Name: fn_cliente_validar_descuento_final_id(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cliente_validar_descuento_final_id(p_id_cliente bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_esperado NUMERIC(5,2);
    v_actual   NUMERIC(5,2);
BEGIN
    -- Si el cliente fue eliminado, no queda nada que validar.
    IF NOT EXISTS (
        SELECT 1 FROM "Cliente" WHERE id_cliente = p_id_cliente
    ) THEN
        RETURN;
    END IF;

    v_esperado := fn_descuento_cliente(p_id_cliente);

    SELECT descuento
      INTO v_actual
      FROM "Cliente"
     WHERE id_cliente = p_id_cliente;

    IF v_actual IS DISTINCT FROM v_esperado THEN
        RAISE EXCEPTION
            'RN-06: descuento almacenado inconsistente para cliente %. Esperado: %, almacenado: %',
            p_id_cliente, v_esperado, v_actual
            USING ERRCODE = '23514';
    END IF;
END;
$$;


ALTER FUNCTION public.fn_cliente_validar_descuento_final_id(p_id_cliente bigint) OWNER TO postgres;

--
-- Name: fn_cliente_validar_descuento_final_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cliente_validar_descuento_final_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_TABLE_NAME = 'Cliente' THEN
        PERFORM fn_cliente_validar_descuento_final_id(NEW.id_cliente);
    ELSE
        IF TG_OP <> 'INSERT' THEN
            PERFORM fn_cliente_validar_descuento_final_id(OLD.id_cliente);
        END IF;

        IF TG_OP <> 'DELETE' THEN
            PERFORM fn_cliente_validar_descuento_final_id(NEW.id_cliente);
        END IF;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_cliente_validar_descuento_final_trigger() OWNER TO postgres;

--
-- Name: fn_composicion_suma_100(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_composicion_suma_100() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    reg TEXT;
BEGIN
    IF TG_OP <> 'DELETE' THEN
        reg := NEW.vino;
        PERFORM fn_composicion_validar_vino(reg);
    END IF;
    IF TG_OP <> 'INSERT' THEN
        reg := OLD.vino;
        PERFORM fn_composicion_validar_vino(reg);
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_composicion_suma_100() OWNER TO postgres;

--
-- Name: FUNCTION fn_composicion_suma_100(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_composicion_suma_100() IS 'RN-05 (A-21): valida al COMMIT que la suma de porcentajes del vino sea 100.';


--
-- Name: fn_composicion_validar_vino(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_composicion_validar_vino(v_vino text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    total NUMERIC;
BEGIN
    IF v_vino IS NOT NULL THEN
        SELECT COALESCE(SUM(porcentaje), 0) INTO total
        FROM "Composicion" WHERE vino = v_vino;
        IF total <> 100 THEN
            RAISE EXCEPTION 'RN-05: la suma de porcentajes del vino % debe ser 100 (suma actual %)',
                v_vino, total;
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_composicion_validar_vino(v_vino text) OWNER TO postgres;

--
-- Name: fn_comprobante_inicializar_totales(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_comprobante_inicializar_totales() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM fn_total_comprobante(NEW.numero);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_comprobante_inicializar_totales() OWNER TO postgres;

--
-- Name: fn_comprobante_proteger_importes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_comprobante_proteger_importes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(
        current_setting('bodegas.rn08_recalculando', true), ''
    ) = 'on' THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.subtotal IS NOT NULL
           OR NEW.descuento IS NOT NULL
           OR NEW.total IS NOT NULL THEN
            RAISE EXCEPTION
                'RN-08: subtotal, descuento y total no se cargan manualmente'
                USING ERRCODE = '23514';
        END IF;
    ELSE
        IF NEW.subtotal IS DISTINCT FROM OLD.subtotal
           OR NEW.descuento IS DISTINCT FROM OLD.descuento
           OR NEW.total IS DISTINCT FROM OLD.total THEN
            RAISE EXCEPTION
                'RN-08: subtotal, descuento y total son importes derivados'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_comprobante_proteger_importes() OWNER TO postgres;

--
-- Name: fn_comprobante_proteger_sala(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_comprobante_proteger_sala() RETURNS trigger
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


ALTER FUNCTION public.fn_comprobante_proteger_sala() OWNER TO postgres;

--
-- Name: FUNCTION fn_comprobante_proteger_sala(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_comprobante_proteger_sala() IS 'RN-09: impide el traslado de sala de un comprobante con renglones ya cargados.';


--
-- Name: fn_comprobante_registrar_sala(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_comprobante_registrar_sala() RETURNS trigger
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


ALTER FUNCTION public.fn_comprobante_registrar_sala() OWNER TO postgres;

--
-- Name: fn_descuento_cliente(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_socio       BOOLEAN;
    v_distribuidor BOOLEAN;
    v_exportador  BOOLEAN;
    v_cantidad    INTEGER;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM "Cliente"
        WHERE id_cliente = p_id_cliente
    ) THEN
        RAISE EXCEPTION
            'RN-06: el cliente % no existe', p_id_cliente
            USING ERRCODE = 'P0002';
    END IF;

    SELECT
        EXISTS (SELECT 1 FROM "Socio" WHERE id_cliente = p_id_cliente),
        EXISTS (SELECT 1 FROM "Distribuidor" WHERE id_cliente = p_id_cliente),
        EXISTS (SELECT 1 FROM "Exportador" WHERE id_cliente = p_id_cliente)
    INTO v_socio, v_distribuidor, v_exportador;

    v_cantidad :=
        (CASE WHEN v_socio THEN 1 ELSE 0 END) +
        (CASE WHEN v_distribuidor THEN 1 ELSE 0 END) +
        (CASE WHEN v_exportador THEN 1 ELSE 0 END);

    IF v_cantidad <> 1 THEN
        RAISE EXCEPTION
            'RN-06: el cliente % debe pertenecer a exactamente un subtipo (encontrados: %)',
            p_id_cliente, v_cantidad
            USING ERRCODE = '23514';
    END IF;

    IF v_socio THEN
        RETURN 10.00;
    ELSIF v_distribuidor THEN
        RETURN 20.00;
    ELSE
        RETURN 30.00;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) OWNER TO postgres;

--
-- Name: FUNCTION fn_descuento_cliente(p_id_cliente bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) IS 'RN-06: devuelve 10 para Socio, 20 para Distribuidor y 30 para Exportador. U6 permanece pendiente.';


--
-- Name: fn_estado_documento_validar_transicion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_estado_documento_validar_transicion() RETURNS trigger
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


ALTER FUNCTION public.fn_estado_documento_validar_transicion() OWNER TO postgres;

--
-- Name: fn_ingreso_proteger_confeccion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_ingreso_proteger_confeccion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.estado <> 'en_confeccion' THEN
        IF NEW.codigo IS DISTINCT FROM OLD.codigo
           OR NEW.fecha IS DISTINCT FROM OLD.fecha
           OR NEW.bodega_origen IS DISTINCT FROM OLD.bodega_origen
           OR NEW.transportista IS DISTINCT FROM OLD.transportista THEN
            RAISE EXCEPTION
                'RN-12: la cabecera de ingreso % solo admite cambios de estado',
                OLD.codigo
                USING ERRCODE = '23514';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_ingreso_proteger_confeccion() OWNER TO postgres;

--
-- Name: fn_renglon_comprobante_aplicar_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_renglon_comprobante_aplicar_stock() RETURNS trigger
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


ALTER FUNCTION public.fn_renglon_comprobante_aplicar_stock() OWNER TO postgres;

--
-- Name: fn_renglon_comprobante_calcular(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_renglon_comprobante_calcular() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cliente   BIGINT;
    v_bruto     NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.descuento IS NOT NULL OR NEW.subtotal IS NOT NULL THEN
            RAISE EXCEPTION
                'RN-08: descuento y subtotal del renglon no se cargan manualmente'
                USING ERRCODE = '23514';
        END IF;

        SELECT cliente
          INTO v_cliente
          FROM "Comprobante"
         WHERE numero = NEW.comprobante;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'RN-08: no existe el comprobante %', NEW.comprobante
                USING ERRCODE = '23503';
        END IF;

        -- Se copia el porcentaje vigente al crear el renglon.
        -- El valor queda historico aunque luego cambie el cliente.
        NEW.descuento := fn_descuento_cliente(v_cliente);

    ELSE
        IF NEW.descuento IS DISTINCT FROM OLD.descuento THEN
            RAISE EXCEPTION
                'RN-08: el descuento historico del renglon no se modifica manualmente'
                USING ERRCODE = '23514';
        END IF;

        IF NEW.subtotal IS DISTINCT FROM OLD.subtotal THEN
            RAISE EXCEPTION
                'RN-08: el subtotal del renglon es un importe derivado'
                USING ERRCODE = '23514';
        END IF;

        NEW.descuento := OLD.descuento;
    END IF;

    v_bruto := ROUND(
        NEW.cantidad::NUMERIC * NEW.precio_unitario, 2
    );

    v_descuento := ROUND(
        v_bruto * NEW.descuento / 100, 2
    );

    NEW.subtotal := v_bruto - v_descuento;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_renglon_comprobante_calcular() OWNER TO postgres;

--
-- Name: FUNCTION fn_renglon_comprobante_calcular(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_renglon_comprobante_calcular() IS 'RN-08: copia el descuento historico del cliente y calcula el subtotal neto del renglon.';


--
-- Name: fn_renglon_comprobante_recalcular_cabecera(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_renglon_comprobante_recalcular_cabecera() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM fn_total_comprobante(OLD.comprobante);
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM fn_total_comprobante(OLD.comprobante);

        IF NEW.comprobante IS DISTINCT FROM OLD.comprobante THEN
            PERFORM fn_total_comprobante(NEW.comprobante);
        END IF;

        RETURN NEW;

    ELSE
        PERFORM fn_total_comprobante(NEW.comprobante);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_renglon_comprobante_recalcular_cabecera() OWNER TO postgres;

--
-- Name: fn_renglon_ingreso_proteger_confeccion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_renglon_ingreso_proteger_confeccion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado estado_documento;
    v_codigo TEXT;
BEGIN
    v_codigo := CASE WHEN TG_OP = 'DELETE' THEN OLD.ingreso ELSE NEW.ingreso END;

    SELECT e.estado INTO v_estado
      FROM "Ingreso" e
     WHERE e.codigo = v_codigo
     FOR SHARE;

    IF v_estado IS NULL THEN
        RAISE EXCEPTION 'RN-12: no existe la cabecera de ingreso %', v_codigo
            USING ERRCODE = '23503';
    END IF;

    IF v_estado <> 'en_confeccion' THEN
        RAISE EXCEPTION
            'RN-12: el renglon de ingreso no admite la operacion %: la cabecera % ya no esta en confeccion (estado %)',
            lower(TG_OP), v_codigo, v_estado
            USING ERRCODE = '23514';
    END IF;

    IF TG_OP = 'UPDATE' AND v_codigo <> OLD.ingreso THEN
        RETURN NULL; -- el reingreso de la cabecera se controla por su trigger (no-op aqui)
    END IF;

    -- En DELETE debe devolverse OLD (NEW esta vacio y cancelaria el borrado);
    -- en INSERT/UPDATE, NEW.
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_renglon_ingreso_proteger_confeccion() OWNER TO postgres;

--
-- Name: FUNCTION fn_renglon_ingreso_proteger_confeccion(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_renglon_ingreso_proteger_confeccion() IS 'RN-12: no permite INSERT/UPDATE/DELETE de renglones de ingreso fuera de en_confeccion.';


--
-- Name: fn_renglon_transferencia_proteger_confeccion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_renglon_transferencia_proteger_confeccion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado estado_documento;
    v_numero BIGINT;
BEGIN
    v_numero := CASE WHEN TG_OP = 'DELETE' THEN OLD.transferencia ELSE NEW.transferencia END;

    SELECT t.estado INTO v_estado
      FROM "Transferencia" t
     WHERE t.numero = v_numero
     FOR SHARE;

    IF v_estado IS NULL THEN
        RAISE EXCEPTION 'RN-12: no existe la cabecera de transferencia %', v_numero
            USING ERRCODE = '23503';
    END IF;

    IF v_estado <> 'en_confeccion' THEN
        RAISE EXCEPTION
            'RN-12: el renglon de transferencia no admite la operacion %: la cabecera % ya no esta en confeccion (estado %)',
            lower(TG_OP), v_numero, v_estado
            USING ERRCODE = '23514';
    END IF;

    IF TG_OP = 'UPDATE' AND v_numero <> OLD.transferencia THEN
        RETURN NULL; -- el reingreso de la cabecera se controla por su trigger (no-op aqui)
    END IF;

    -- En DELETE debe devolverse OLD (NEW esta vacio y cancelaria el borrado);
    -- en INSERT/UPDATE, NEW.
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_renglon_transferencia_proteger_confeccion() OWNER TO postgres;

--
-- Name: FUNCTION fn_renglon_transferencia_proteger_confeccion(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_renglon_transferencia_proteger_confeccion() IS 'RN-12: no permite INSERT/UPDATE/DELETE de renglones de transferencia fuera de en_confeccion.';


--
-- Name: fn_rn09_consumir_stock(bigint, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) RETURNS void
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


ALTER FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) OWNER TO postgres;

--
-- Name: FUNCTION fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) IS 'RN-09: consume p_cantidad unidades bajo bloqueo de fila; rechaza si el stock no alcanza.';


--
-- Name: fn_rn09_reponer_stock(bigint, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) RETURNS void
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


ALTER FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) OWNER TO postgres;

--
-- Name: FUNCTION fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) IS 'RN-09: repone p_cantidad unidades bajo bloqueo de fila (para DELETE o movimientos).';


--
-- Name: fn_stock_sala(bigint, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) RETURNS integer
    LANGUAGE plpgsql STABLE
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


ALTER FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) OWNER TO postgres;

--
-- Name: FUNCTION fn_stock_sala(p_sala bigint, p_vino text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) IS 'RN-09: stock disponible del vino p_vino en la sala p_sala (0 si no hay fila).';


--
-- Name: fn_total_comprobante(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_total_comprobante(p_numero bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal       NUMERIC(12,2);
    v_descuento      NUMERIC(12,2);
    v_total          NUMERIC(12,2);
    v_flag_anterior  TEXT;
BEGIN
    -- Serializa recalculos concurrentes del mismo comprobante.
    PERFORM 1
      FROM "Comprobante"
     WHERE numero = p_numero
     FOR UPDATE;

    -- Puede ocurrir al eliminar una cabecera con borrado en cascada.
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT
        COALESCE(
            SUM(ROUND(cantidad::NUMERIC * precio_unitario, 2)), 0
        )::NUMERIC(12,2),
        COALESCE(
            SUM(
                ROUND(
                    ROUND(cantidad::NUMERIC * precio_unitario, 2)
                    * COALESCE(descuento, 0) / 100,
                    2
                )
            ), 0
        )::NUMERIC(12,2),
        COALESCE(SUM(subtotal), 0)::NUMERIC(12,2)
    INTO v_subtotal, v_descuento, v_total
    FROM "Renglon_Comprobante"
    WHERE comprobante = p_numero;

    -- Permite que solo esta funcion actualice los importes de cabecera.
    v_flag_anterior := current_setting(
        'bodegas.rn08_recalculando', true
    );

    PERFORM set_config('bodegas.rn08_recalculando', 'on', true);

    UPDATE "Comprobante"
       SET subtotal = v_subtotal,
           descuento = v_descuento,
           total = v_total
     WHERE numero = p_numero;

    PERFORM set_config(
        'bodegas.rn08_recalculando',
        COALESCE(v_flag_anterior, ''),
        true
    );

    RETURN v_total;
END;
$$;


ALTER FUNCTION public.fn_total_comprobante(p_numero bigint) OWNER TO postgres;

--
-- Name: FUNCTION fn_total_comprobante(p_numero bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_total_comprobante(p_numero bigint) IS 'RN-08: recalcula subtotal bruto, descuento monetario y total neto de un comprobante.';


--
-- Name: fn_transferencia_proteger_confeccion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_transferencia_proteger_confeccion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.estado <> 'en_confeccion' THEN
        IF NEW.sala IS DISTINCT FROM OLD.sala THEN
            RAISE EXCEPTION
                'RN-12: la cabecera de transferencia % solo admite cambios de estado',
                OLD.numero
                USING ERRCODE = '23514';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_transferencia_proteger_confeccion() OWNER TO postgres;

--
-- Name: fn_transferencia_proteger_fecha_confeccion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_transferencia_proteger_fecha_confeccion() RETURNS trigger
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


ALTER FUNCTION public.fn_transferencia_proteger_fecha_confeccion() OWNER TO postgres;

--
-- Name: fn_vino_auditar_cambio_precio(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_vino_auditar_cambio_precio() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NEW.precio IS DISTINCT FROM OLD.precio THEN
        IF OLD.precio IS NULL OR NEW.precio IS NULL THEN
            -- El precio de alta se carga en el INSERT (sin valor anterior); los
            -- UPDATE que incluyan NULL en una punta no quedan auditados por el
            -- modelo (precio_anterior/precio_nuevo son NOT NULL) y se rechaza
            -- ese caso para evitar perder informacion silenciosamente.
            RAISE EXCEPTION
                'RN-13: la transicion del precio de % involucra nulos: cargue el precio inicial en el INSERT del vino, o actualice a un valor concreto (no nulo)',
                NEW.codigo
                USING ERRCODE = '23514';
        END IF;

        -- Solo el propio trigger puede insertar: la ventana de la bandera
        -- (a nivel de transaccion) se abre y se cierra alrededor del INSERT,
        -- bloqueando los INSERT manuales del resto de la sesion.
        PERFORM set_config('bodegas.auditoria_interna', '1', true);

        INSERT INTO "Auditoria_Precio"
            (vino, precio_anterior, precio_nuevo, fecha_hora, usuario)
        VALUES
            (NEW.codigo, OLD.precio, NEW.precio, clock_timestamp(),
             fn_vino_usuario_funcional_texto());

        PERFORM set_config('bodegas.auditoria_interna', '0', true);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_vino_auditar_cambio_precio() OWNER TO postgres;

--
-- Name: fn_vino_composicion_obligatoria(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_vino_composicion_obligatoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Si el vino sigue existiendo al confirmar la transacciÃ³n,
    -- debe tener una composiciÃ³n vÃ¡lida.
    IF EXISTS (
        SELECT 1
        FROM "Vino"
        WHERE codigo = NEW.codigo
    ) THEN
        PERFORM fn_composicion_validar_vino(NEW.codigo);
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_vino_composicion_obligatoria() OWNER TO postgres;

--
-- Name: FUNCTION fn_vino_composicion_obligatoria(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_vino_composicion_obligatoria() IS 'RN-05: impide confirmar un vino sin composicion porcentual valida.';


--
-- Name: fn_vino_usuario_funcional_texto(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_vino_usuario_funcional_texto() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    IF COALESCE(current_setting('bodegas.usuario_funcional', true), '') <> '' THEN
        RETURN current_user || '::' || current_setting('bodegas.usuario_funcional', true);
    END IF;

    RETURN current_user::TEXT;
END;
$$;


ALTER FUNCTION public.fn_vino_usuario_funcional_texto() OWNER TO postgres;

--
-- Name: FUNCTION fn_vino_usuario_funcional_texto(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_vino_usuario_funcional_texto() IS 'RN-13: devuelve "<conexion>:<usuario funcional>" o solo el usuario de conexion.';


--
-- Name: sp_procesar_ingreso(text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_procesar_ingreso(IN p_codigo text)
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


ALTER PROCEDURE public.sp_procesar_ingreso(IN p_codigo text) OWNER TO postgres;

--
-- Name: PROCEDURE sp_procesar_ingreso(IN p_codigo text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.sp_procesar_ingreso(IN p_codigo text) IS 'RN-10: acredita el deposito con los renglones y marca procesado, atomicamente.';


--
-- Name: sp_procesar_transferencia(bigint); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint)
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


ALTER PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint) OWNER TO postgres;

--
-- Name: PROCEDURE sp_procesar_transferencia(IN p_numero bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint) IS 'RN-11: descuenta del deposito, acredita la sala y marca procesado, atomicamente.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Analisis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Analisis" (
    id_analisis bigint NOT NULL,
    finca bigint,
    n_parcela integer,
    campania smallint,
    fecha date,
    brix numeric(5,2),
    ph numeric(3,2),
    acidez numeric(5,2)
);


ALTER TABLE public."Analisis" OWNER TO postgres;

--
-- Name: Analisis_id_analisis_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Analisis" ALTER COLUMN id_analisis ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Analisis_id_analisis_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Auditoria_Precio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Auditoria_Precio" (
    id_auditoria bigint NOT NULL,
    vino text NOT NULL,
    precio_anterior numeric(12,2) NOT NULL,
    precio_nuevo numeric(12,2) NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    usuario text
);


ALTER TABLE public."Auditoria_Precio" OWNER TO postgres;

--
-- Name: Auditoria_Precio_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Auditoria_Precio" ALTER COLUMN id_auditoria ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Auditoria_Precio_id_auditoria_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Bodega; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Bodega" (
    cuit public.cuit_dom NOT NULL,
    razon_social text,
    domicilio text
);


ALTER TABLE public."Bodega" OWNER TO postgres;

--
-- Name: Cepa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Cepa" (
    id bigint NOT NULL,
    nombre text,
    tipo text
);


ALTER TABLE public."Cepa" OWNER TO postgres;

--
-- Name: Cepa_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Cepa" ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Cepa_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Cliente" (
    id_cliente bigint NOT NULL,
    nombre text,
    tipo_doc text,
    n_doc text,
    direccion text,
    localidad bigint,
    fecha_alta date DEFAULT CURRENT_DATE,
    descuento numeric(5,2),
    CONSTRAINT ck_cliente_descuento_rango CHECK (((descuento >= (0)::numeric) AND (descuento <= (100)::numeric)))
);


ALTER TABLE public."Cliente" OWNER TO postgres;

--
-- Name: Cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Cliente" ALTER COLUMN id_cliente ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Cliente_id_cliente_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Composicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Composicion" (
    vino text NOT NULL,
    cepa bigint NOT NULL,
    porcentaje numeric(5,2) NOT NULL,
    CONSTRAINT ck_composicion_porcentaje_rango CHECK (((porcentaje > (0)::numeric) AND (porcentaje <= (100)::numeric)))
);


ALTER TABLE public."Composicion" OWNER TO postgres;

--
-- Name: CONSTRAINT ck_composicion_porcentaje_rango ON "Composicion"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT ck_composicion_porcentaje_rango ON public."Composicion" IS 'RN-15: cada fila aporta entre >0 y <=100; la suma 100 exacta la valida RN-05 diferido.';


--
-- Name: Comprobante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Comprobante" (
    numero bigint NOT NULL,
    fecha date,
    cliente bigint NOT NULL,
    sala bigint NOT NULL,
    subtotal numeric(12,2),
    descuento numeric(12,2),
    total numeric(12,2)
);


ALTER TABLE public."Comprobante" OWNER TO postgres;

--
-- Name: Distribuidor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Distribuidor" (
    id_cliente bigint NOT NULL,
    zona text,
    n_habilitacion text
);


ALTER TABLE public."Distribuidor" OWNER TO postgres;

--
-- Name: Empleado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Empleado" (
    id_empleado bigint NOT NULL,
    cuit public.cuit_dom,
    nombre text,
    fecha_ingreso date,
    salario numeric(12,2),
    sala bigint NOT NULL
);


ALTER TABLE public."Empleado" OWNER TO postgres;

--
-- Name: Empleado_id_empleado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Empleado" ALTER COLUMN id_empleado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Empleado_id_empleado_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Exportador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Exportador" (
    id_cliente bigint NOT NULL,
    pais text
);


ALTER TABLE public."Exportador" OWNER TO postgres;

--
-- Name: Finca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Finca" (
    id_finca bigint NOT NULL,
    nombre text,
    superficie numeric(8,2),
    departamento text,
    provincia text,
    CONSTRAINT ck_finca_superficie_positiva CHECK ((superficie > (0)::numeric))
);


ALTER TABLE public."Finca" OWNER TO postgres;

--
-- Name: Finca_id_finca_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Finca" ALTER COLUMN id_finca ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Finca_id_finca_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Ingreso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Ingreso" (
    codigo text NOT NULL,
    fecha date,
    estado public.estado_documento DEFAULT 'en_confeccion'::public.estado_documento NOT NULL,
    transportista text NOT NULL,
    bodega_origen public.cuit_dom NOT NULL
);


ALTER TABLE public."Ingreso" OWNER TO postgres;

--
-- Name: Localidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Localidad" (
    id_localidad bigint NOT NULL,
    codigo_postal text,
    nombre text,
    provincia text,
    encargado_regional text
);


ALTER TABLE public."Localidad" OWNER TO postgres;

--
-- Name: Localidad_id_localidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Localidad" ALTER COLUMN id_localidad ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Localidad_id_localidad_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Lote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Lote" (
    finca bigint NOT NULL,
    n_parcela integer NOT NULL,
    campania smallint NOT NULL,
    n_lote integer,
    fecha_cosecha date,
    kg numeric(10,2),
    bodega_destino public.cuit_dom NOT NULL,
    CONSTRAINT ck_lote_kg_positivo CHECK ((kg > (0)::numeric))
);


ALTER TABLE public."Lote" OWNER TO postgres;

--
-- Name: Maridaje; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Maridaje" (
    id bigint NOT NULL,
    nombre text,
    temperatura numeric(3,1)
);


ALTER TABLE public."Maridaje" OWNER TO postgres;

--
-- Name: Maridaje_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Maridaje" ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Maridaje_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Parcela; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Parcela" (
    finca bigint NOT NULL,
    n_parcela integer NOT NULL,
    superficie numeric(8,2),
    anio_plantacion smallint,
    cepa bigint NOT NULL,
    CONSTRAINT ck_parcela_superficie_positiva CHECK ((superficie > (0)::numeric))
);


ALTER TABLE public."Parcela" OWNER TO postgres;

--
-- Name: Permiso_Exportacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Permiso_Exportacion" (
    codigo text NOT NULL,
    exportador bigint,
    fecha_emision date,
    fecha_vencimiento date,
    CONSTRAINT ck_permiso_fechas_orden CHECK ((fecha_vencimiento > fecha_emision))
);


ALTER TABLE public."Permiso_Exportacion" OWNER TO postgres;

--
-- Name: Renglon_Comprobante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Renglon_Comprobante" (
    comprobante bigint NOT NULL,
    vino text NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    descuento numeric(5,2),
    subtotal numeric(12,2),
    CONSTRAINT ck_renglon_comprobante_cantidad_positiva CHECK ((cantidad > 0))
);


ALTER TABLE public."Renglon_Comprobante" OWNER TO postgres;

--
-- Name: Renglon_Ingreso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Renglon_Ingreso" (
    ingreso text NOT NULL,
    vino text NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT ck_renglon_ingreso_cantidad_positiva CHECK ((cantidad > 0))
);


ALTER TABLE public."Renglon_Ingreso" OWNER TO postgres;

--
-- Name: Renglon_Transferencia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Renglon_Transferencia" (
    transferencia bigint NOT NULL,
    vino text NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT ck_renglon_transferencia_cantidad_positiva CHECK ((cantidad > 0))
);


ALTER TABLE public."Renglon_Transferencia" OWNER TO postgres;

--
-- Name: Sala; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Sala" (
    id_sala bigint NOT NULL,
    calle text,
    numero integer,
    dia_cierre text,
    localidad bigint NOT NULL
);


ALTER TABLE public."Sala" OWNER TO postgres;

--
-- Name: Sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Sala" ALTER COLUMN id_sala ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Sala_id_sala_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: Socio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Socio" (
    id_cliente bigint NOT NULL
);


ALTER TABLE public."Socio" OWNER TO postgres;

--
-- Name: Stock_Deposito; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Stock_Deposito" (
    vino text NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT ck_stock_deposito_cantidad_no_negativa CHECK ((cantidad >= 0))
);


ALTER TABLE public."Stock_Deposito" OWNER TO postgres;

--
-- Name: Stock_Sala; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Stock_Sala" (
    sala bigint NOT NULL,
    vino text NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT ck_stock_sala_cantidad_no_negativa CHECK ((cantidad >= 0))
);


ALTER TABLE public."Stock_Sala" OWNER TO postgres;

--
-- Name: Transferencia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Transferencia" (
    numero bigint NOT NULL,
    fecha_confeccion date DEFAULT CURRENT_DATE NOT NULL,
    estado public.estado_documento DEFAULT 'en_confeccion'::public.estado_documento NOT NULL,
    sala bigint NOT NULL
);


ALTER TABLE public."Transferencia" OWNER TO postgres;

--
-- Name: Transportista; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Transportista" (
    codigo text NOT NULL,
    razon_social text,
    cuit public.cuit_dom,
    email text,
    telefono text,
    domicilio text
);


ALTER TABLE public."Transportista" OWNER TO postgres;

--
-- Name: Transportista_Localidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Transportista_Localidad" (
    transportista text NOT NULL,
    localidad bigint NOT NULL
);


ALTER TABLE public."Transportista_Localidad" OWNER TO postgres;

--
-- Name: Vino; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Vino" (
    codigo text NOT NULL,
    nombre text,
    tipo text,
    anada smallint,
    volumen_ml smallint,
    graduacion numeric(4,1),
    precio numeric(12,2),
    bodega public.cuit_dom NOT NULL,
    CONSTRAINT ck_vino_graduacion_rango CHECK (((graduacion >= (5)::numeric) AND (graduacion <= (20)::numeric))),
    CONSTRAINT ck_vino_precio_positivo CHECK ((precio > (0)::numeric))
);


ALTER TABLE public."Vino" OWNER TO postgres;

--
-- Name: Vino_Maridaje; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Vino_Maridaje" (
    vino text NOT NULL,
    maridaje bigint NOT NULL
);


ALTER TABLE public."Vino_Maridaje" OWNER TO postgres;

--
-- Name: v_documentos_pendientes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_documentos_pendientes AS
 SELECT 'INGRESO'::text AS tipo,
    i.codigo AS documento,
    i.fecha,
    i.estado
   FROM public."Ingreso" i
  WHERE (i.estado <> 'procesado'::public.estado_documento)
UNION ALL
 SELECT 'TRANSFERENCIA'::text AS tipo,
    (t.numero)::text AS documento,
    t.fecha_confeccion AS fecha,
    t.estado
   FROM public."Transferencia" t
  WHERE (t.estado <> 'procesado'::public.estado_documento);


ALTER VIEW public.v_documentos_pendientes OWNER TO postgres;

--
-- Name: VIEW v_documentos_pendientes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_documentos_pendientes IS 'Issue #39: ingreso/transferencias sin procesar para bandeja de pendientes.';


--
-- Name: v_stock_total_vino; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_stock_total_vino AS
 SELECT v.codigo AS vino,
    COALESCE(dp.cantidad, 0) AS stock_deposito,
    COALESCE(sl.cantidad, (0)::bigint) AS stock_salas
   FROM ((public."Vino" v
     LEFT JOIN public."Stock_Deposito" dp ON ((dp.vino = v.codigo)))
     LEFT JOIN ( SELECT "Stock_Sala".vino,
            sum("Stock_Sala".cantidad) AS cantidad
           FROM public."Stock_Sala"
          GROUP BY "Stock_Sala".vino) sl ON ((sl.vino = v.codigo)));


ALTER VIEW public.v_stock_total_vino OWNER TO postgres;

--
-- Name: VIEW v_stock_total_vino; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_stock_total_vino IS 'Issue #39: stock total por vino (deposito + salas).';


--
-- Name: v_ventas_mensuales_sala; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_ventas_mensuales_sala AS
 SELECT c.sala,
    to_char((c.fecha)::timestamp with time zone, 'YYYY-MM'::text) AS anio_mes,
    count(DISTINCT r.comprobante) AS comprobantes,
    sum(r.cantidad) AS unidades_vendidas,
    sum(r.subtotal) AS importe_neto
   FROM (public."Comprobante" c
     JOIN public."Renglon_Comprobante" r ON ((r.comprobante = c.numero)))
  GROUP BY c.sala, (to_char((c.fecha)::timestamp with time zone, 'YYYY-MM'::text));


ALTER VIEW public.v_ventas_mensuales_sala OWNER TO postgres;

--
-- Name: VIEW v_ventas_mensuales_sala; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_ventas_mensuales_sala IS 'Issue #39: ventas mensuales por sala (unidades e importe neto por renglones).';


--
-- Data for Name: Analisis; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Analisis" (id_analisis, finca, n_parcela, campania, fecha, brix, ph, acidez) FROM stdin;
\.


--
-- Data for Name: Auditoria_Precio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Auditoria_Precio" (id_auditoria, vino, precio_anterior, precio_nuevo, fecha_hora, usuario) FROM stdin;
\.


--
-- Data for Name: Bodega; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Bodega" (cuit, razon_social, domicilio) FROM stdin;
30112233449	Bodega Atuel S.A.	Ruta 144 Km 650
30998877665	Vinos del Sur SRL	San Martín 890
\.


--
-- Data for Name: Cepa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Cepa" (id, nombre, tipo) FROM stdin;
1	Malbec	tinta
2	Cabernet Sauvignon	tinta
3	Bonarda	tinta
4	Syrah	tinta
5	Chardonnay	blanca
6	Torrontés	blanca
7	Sauvignon Blanc	blanca
\.


--
-- Data for Name: Cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Cliente" (id_cliente, nombre, tipo_doc, n_doc, direccion, localidad, fecha_alta, descuento) FROM stdin;
1	Juan Pérez	DNI	30111222	San Martín 100	1	2026-11-09	10.00
2	Comercial Cuyo S.A.	CUIT	30555666779	Belgrano 500	2	2026-11-09	20.00
3	Global Wine Corp	Pasaporte	AB123456	International Ave 300	1	2026-11-09	30.00
\.


--
-- Data for Name: Composicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Composicion" (vino, cepa, porcentaje) FROM stdin;
V-MALB-01	1	100.00
V-CABS-02	2	100.00
\.


--
-- Data for Name: Comprobante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Comprobante" (numero, fecha, cliente, sala, subtotal, descuento, total) FROM stdin;
1001	2026-10-01	1	1	9000.00	900.00	8100.00
1002	2026-10-02	2	2	12600.00	2520.00	10080.00
\.


--
-- Data for Name: Distribuidor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Distribuidor" (id_cliente, zona, n_habilitacion) FROM stdin;
2	Centro	DIST-9988
\.


--
-- Data for Name: Empleado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Empleado" (id_empleado, cuit, nombre, fecha_ingreso, salario, sala) FROM stdin;
1	20333444552	Ana Torres	2023-03-10	850000.00	1
2	27444555663	Luis Gómez	2023-05-15	900000.00	2
\.


--
-- Data for Name: Exportador; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Exportador" (id_cliente, pais) FROM stdin;
3	Estados Unidos
\.


--
-- Data for Name: Finca; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Finca" (id_finca, nombre, superficie, departamento, provincia) FROM stdin;
1	Finca El Atuel	150.50	San Rafael	Mendoza
2	Finca Los Álamos	95.00	San Rafael	Mendoza
\.


--
-- Data for Name: Ingreso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Ingreso" (codigo, fecha, estado, transportista, bodega_origen) FROM stdin;
ING-001	2026-09-15	en_confeccion	TR-01	30112233449
\.


--
-- Data for Name: Localidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Localidad" (id_localidad, codigo_postal, nombre, provincia, encargado_regional) FROM stdin;
1	5600	San Rafael	Mendoza	Juan Pérez
2	5500	Mendoza Capital	Mendoza	María Gómez
3	5570	San Martín	Mendoza	Carlos López
\.


--
-- Data for Name: Lote; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Lote" (finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino) FROM stdin;
\.


--
-- Data for Name: Maridaje; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Maridaje" (id, nombre, temperatura) FROM stdin;
1	Carnes rojas asadas	16.5
2	Quesos duros	14.0
3	Pescados y mariscos	10.0
4	Pasta con salsa blanca	12.0
5	Chocolate amargo	18.0
\.


--
-- Data for Name: Parcela; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Parcela" (finca, n_parcela, superficie, anio_plantacion, cepa) FROM stdin;
1	1	50.00	2018	1
2	1	45.50	2019	2
\.


--
-- Data for Name: Permiso_Exportacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Permiso_Exportacion" (codigo, exportador, fecha_emision, fecha_vencimiento) FROM stdin;
\.


--
-- Data for Name: Renglon_Comprobante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario, descuento, subtotal) FROM stdin;
1001	V-MALB-01	2	4500.00	10.00	8100.00
1002	V-CABS-02	3	4200.00	20.00	10080.00
\.


--
-- Data for Name: Renglon_Ingreso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Renglon_Ingreso" (ingreso, vino, cantidad) FROM stdin;
ING-001	V-MALB-01	1000
\.


--
-- Data for Name: Renglon_Transferencia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Renglon_Transferencia" (transferencia, vino, cantidad) FROM stdin;
5001	V-MALB-01	150
\.


--
-- Data for Name: Sala; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Sala" (id_sala, calle, numero, dia_cierre, localidad) FROM stdin;
1	San Martín	120	Domingo	1
2	Av. Mitre	450	Lunes	2
\.


--
-- Data for Name: Socio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Socio" (id_cliente) FROM stdin;
1
\.


--
-- Data for Name: Stock_Deposito; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Stock_Deposito" (vino, cantidad) FROM stdin;
V-MALB-01	850
V-CABS-02	500
\.


--
-- Data for Name: Stock_Sala; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Stock_Sala" (sala, vino, cantidad) FROM stdin;
1	V-MALB-01	148
2	V-CABS-02	197
\.


--
-- Data for Name: Transferencia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Transferencia" (numero, fecha_confeccion, estado, sala) FROM stdin;
5001	2026-09-20	en_confeccion	1
\.


--
-- Data for Name: Transportista; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Transportista" (codigo, razon_social, cuit, email, telefono, domicilio) FROM stdin;
TR-01	Logística Cuyo SRL	20223344556	contacto@cuyo.com	2614444444	San Rafael 2300
TR-02	Transportes del Sur	27334455667	info@delsur.com	2615555555	Av. Mitre 1200
\.


--
-- Data for Name: Transportista_Localidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Transportista_Localidad" (transportista, localidad) FROM stdin;
TR-01	1
TR-02	2
\.


--
-- Data for Name: Vino; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Vino" (codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega) FROM stdin;
V-MALB-01	Atuel Reserva Malbec	Tinto	2021	750	14.5	4500.00	30112233449
V-CABS-02	Atuel Cabernet	Tinto	2022	750	14.0	4200.00	30112233449
\.


--
-- Data for Name: Vino_Maridaje; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Vino_Maridaje" (vino, maridaje) FROM stdin;
\.


--
-- Name: Analisis_id_analisis_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Analisis_id_analisis_seq"', 1, false);


--
-- Name: Auditoria_Precio_id_auditoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Auditoria_Precio_id_auditoria_seq"', 1, false);


--
-- Name: Cepa_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Cepa_id_seq"', 7, true);


--
-- Name: Cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Cliente_id_cliente_seq"', 3, true);


--
-- Name: Empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Empleado_id_empleado_seq"', 2, true);


--
-- Name: Finca_id_finca_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Finca_id_finca_seq"', 2, true);


--
-- Name: Localidad_id_localidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Localidad_id_localidad_seq"', 3, true);


--
-- Name: Maridaje_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Maridaje_id_seq"', 5, true);


--
-- Name: Sala_id_sala_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Sala_id_sala_seq"', 2, true);


--
-- Name: Analisis Analisis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Analisis"
    ADD CONSTRAINT "Analisis_pkey" PRIMARY KEY (id_analisis);


--
-- Name: Auditoria_Precio Auditoria_Precio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Auditoria_Precio"
    ADD CONSTRAINT "Auditoria_Precio_pkey" PRIMARY KEY (id_auditoria);


--
-- Name: Bodega Bodega_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bodega"
    ADD CONSTRAINT "Bodega_pkey" PRIMARY KEY (cuit);


--
-- Name: Cepa Cepa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cepa"
    ADD CONSTRAINT "Cepa_pkey" PRIMARY KEY (id);


--
-- Name: Cliente Cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cliente"
    ADD CONSTRAINT "Cliente_pkey" PRIMARY KEY (id_cliente);


--
-- Name: Comprobante Comprobante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Comprobante"
    ADD CONSTRAINT "Comprobante_pkey" PRIMARY KEY (numero);


--
-- Name: Distribuidor Distribuidor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Distribuidor"
    ADD CONSTRAINT "Distribuidor_pkey" PRIMARY KEY (id_cliente);


--
-- Name: Empleado Empleado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Empleado"
    ADD CONSTRAINT "Empleado_pkey" PRIMARY KEY (id_empleado);


--
-- Name: Exportador Exportador_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Exportador"
    ADD CONSTRAINT "Exportador_pkey" PRIMARY KEY (id_cliente);


--
-- Name: Finca Finca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Finca"
    ADD CONSTRAINT "Finca_pkey" PRIMARY KEY (id_finca);


--
-- Name: Ingreso Ingreso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Ingreso"
    ADD CONSTRAINT "Ingreso_pkey" PRIMARY KEY (codigo);


--
-- Name: Localidad Localidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Localidad"
    ADD CONSTRAINT "Localidad_pkey" PRIMARY KEY (id_localidad);


--
-- Name: Maridaje Maridaje_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Maridaje"
    ADD CONSTRAINT "Maridaje_pkey" PRIMARY KEY (id);


--
-- Name: Permiso_Exportacion Permiso_Exportacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Permiso_Exportacion"
    ADD CONSTRAINT "Permiso_Exportacion_pkey" PRIMARY KEY (codigo);


--
-- Name: Sala Sala_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Sala"
    ADD CONSTRAINT "Sala_pkey" PRIMARY KEY (id_sala);


--
-- Name: Socio Socio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Socio"
    ADD CONSTRAINT "Socio_pkey" PRIMARY KEY (id_cliente);


--
-- Name: Stock_Deposito Stock_Deposito_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock_Deposito"
    ADD CONSTRAINT "Stock_Deposito_pkey" PRIMARY KEY (vino);


--
-- Name: Transferencia Transferencia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transferencia"
    ADD CONSTRAINT "Transferencia_pkey" PRIMARY KEY (numero);


--
-- Name: Transportista Transportista_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transportista"
    ADD CONSTRAINT "Transportista_pkey" PRIMARY KEY (codigo);


--
-- Name: Vino Vino_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino"
    ADD CONSTRAINT "Vino_pkey" PRIMARY KEY (codigo);


--
-- Name: Composicion pk_composicion; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Composicion"
    ADD CONSTRAINT pk_composicion PRIMARY KEY (vino, cepa);


--
-- Name: Lote pk_lote; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Lote"
    ADD CONSTRAINT pk_lote PRIMARY KEY (finca, n_parcela, campania);


--
-- Name: Parcela pk_parcela; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Parcela"
    ADD CONSTRAINT pk_parcela PRIMARY KEY (finca, n_parcela);


--
-- Name: Renglon_Comprobante pk_renglon_comprobante; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Comprobante"
    ADD CONSTRAINT pk_renglon_comprobante PRIMARY KEY (comprobante, vino);


--
-- Name: Renglon_Ingreso pk_renglon_ingreso; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Ingreso"
    ADD CONSTRAINT pk_renglon_ingreso PRIMARY KEY (ingreso, vino);


--
-- Name: Renglon_Transferencia pk_renglon_transferencia; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Transferencia"
    ADD CONSTRAINT pk_renglon_transferencia PRIMARY KEY (transferencia, vino);


--
-- Name: Stock_Sala pk_stock_sala; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock_Sala"
    ADD CONSTRAINT pk_stock_sala PRIMARY KEY (sala, vino);


--
-- Name: Transportista_Localidad pk_transportista_localidad; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transportista_Localidad"
    ADD CONSTRAINT pk_transportista_localidad PRIMARY KEY (transportista, localidad);


--
-- Name: Vino_Maridaje pk_vino_maridaje; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino_Maridaje"
    ADD CONSTRAINT pk_vino_maridaje PRIMARY KEY (vino, maridaje);


--
-- Name: Cliente uq_cliente_tipo_doc_n_doc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cliente"
    ADD CONSTRAINT uq_cliente_tipo_doc_n_doc UNIQUE (tipo_doc, n_doc);


--
-- Name: Empleado uq_empleado_cuit; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Empleado"
    ADD CONSTRAINT uq_empleado_cuit UNIQUE (cuit);


--
-- Name: Transportista uq_transportista_cuit; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transportista"
    ADD CONSTRAINT uq_transportista_cuit UNIQUE (cuit);


--
-- Name: Vino uq_vino_nombre_anada_volumen; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino"
    ADD CONSTRAINT uq_vino_nombre_anada_volumen UNIQUE (nombre, anada, volumen_ml);


--
-- Name: idx_auditoria_precio_vino_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auditoria_precio_vino_fecha ON public."Auditoria_Precio" USING btree (vino, fecha_hora DESC);


--
-- Name: idx_comprobante_fecha_sala; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comprobante_fecha_sala ON public."Comprobante" USING btree (fecha, sala);


--
-- Name: idx_ingreso_estado_pendiente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ingreso_estado_pendiente ON public."Ingreso" USING btree (estado) WHERE (estado <> 'procesado'::public.estado_documento);


--
-- Name: idx_renglon_comprobante_vino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_renglon_comprobante_vino ON public."Renglon_Comprobante" USING btree (vino);


--
-- Name: idx_renglon_ingreso_vino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_renglon_ingreso_vino ON public."Renglon_Ingreso" USING btree (vino);


--
-- Name: idx_renglon_transferencia_vino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_renglon_transferencia_vino ON public."Renglon_Transferencia" USING btree (vino);


--
-- Name: idx_stock_sala_vino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stock_sala_vino ON public."Stock_Sala" USING btree (vino);


--
-- Name: idx_transferencia_estado_pendiente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transferencia_estado_pendiente ON public."Transferencia" USING btree (estado) WHERE (estado <> 'procesado'::public.estado_documento);


--
-- Name: Auditoria_Precio trg_auditoria_precio_inmutable; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_precio_inmutable BEFORE INSERT OR DELETE OR UPDATE ON public."Auditoria_Precio" FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_precio_proteger();


--
-- Name: TRIGGER trg_auditoria_precio_inmutable ON "Auditoria_Precio"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_auditoria_precio_inmutable ON public."Auditoria_Precio" IS 'RN-13: la tabla de auditoria es de solo lectura para las operaciones ordinarias.';


--
-- Name: Cliente trg_cliente_descuento_derivado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cliente_descuento_derivado BEFORE INSERT ON public."Cliente" FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_rechazar_descuento_manual();


--
-- Name: Cliente trg_cliente_descuento_final; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_cliente_descuento_final AFTER INSERT OR UPDATE ON public."Cliente" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_validar_descuento_final_trigger();


--
-- Name: Cliente trg_cliente_validar_descuento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cliente_validar_descuento BEFORE UPDATE OF descuento ON public."Cliente" FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_validar_cambio_descuento();


--
-- Name: Comprobante trg_comprobante_importes_no_manuales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_comprobante_importes_no_manuales BEFORE INSERT OR UPDATE OF subtotal, descuento, total ON public."Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_comprobante_proteger_importes();


--
-- Name: Comprobante trg_comprobante_inicializar_totales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_comprobante_inicializar_totales AFTER INSERT ON public."Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_comprobante_inicializar_totales();


--
-- Name: Comprobante trg_comprobante_registrar_sala; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_comprobante_registrar_sala BEFORE DELETE ON public."Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_comprobante_registrar_sala();


--
-- Name: TRIGGER trg_comprobante_registrar_sala ON "Comprobante"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_comprobante_registrar_sala ON public."Comprobante" IS 'RN-09: conserva (sala) en temp ON COMMIT DROP para el borrado en cascada de renglones.';


--
-- Name: Comprobante trg_comprobante_sala_con_renglones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_comprobante_sala_con_renglones BEFORE UPDATE OF sala ON public."Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_comprobante_proteger_sala();


--
-- Name: TRIGGER trg_comprobante_sala_con_renglones ON "Comprobante"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_comprobante_sala_con_renglones ON public."Comprobante" IS 'RN-09: la sala de un comprobante con renglones no cambia (evita reposiciones ambiguas).';


--
-- Name: Distribuidor trg_distribuidor_descuento_final; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_distribuidor_descuento_final AFTER INSERT OR DELETE OR UPDATE ON public."Distribuidor" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_validar_descuento_final_trigger();


--
-- Name: Distribuidor trg_distribuidor_sincronizar_descuento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_distribuidor_sincronizar_descuento AFTER INSERT ON public."Distribuidor" FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_sincronizar_descuento();


--
-- Name: Exportador trg_exportador_descuento_final; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_exportador_descuento_final AFTER INSERT OR DELETE OR UPDATE ON public."Exportador" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_validar_descuento_final_trigger();


--
-- Name: Exportador trg_exportador_sincronizar_descuento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_exportador_sincronizar_descuento AFTER INSERT ON public."Exportador" FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_sincronizar_descuento();


--
-- Name: Ingreso trg_ingreso_confeccion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ingreso_confeccion BEFORE UPDATE ON public."Ingreso" FOR EACH ROW EXECUTE FUNCTION public.fn_ingreso_proteger_confeccion();


--
-- Name: TRIGGER trg_ingreso_confeccion ON "Ingreso"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_ingreso_confeccion ON public."Ingreso" IS 'RN-12: la cabecera fuera de confeccion solo cambia su estado.';


--
-- Name: Ingreso trg_ingreso_estado_transiciones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ingreso_estado_transiciones BEFORE UPDATE OF estado ON public."Ingreso" FOR EACH ROW EXECUTE FUNCTION public.fn_estado_documento_validar_transicion();


--
-- Name: TRIGGER trg_ingreso_estado_transiciones ON "Ingreso"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_ingreso_estado_transiciones ON public."Ingreso" IS 'RN-10: solo en_confeccion->terminado (manual) y terminado->procesado (via procedure).';


--
-- Name: Renglon_Comprobante trg_renglon_comprobante_calcular; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_renglon_comprobante_calcular BEFORE INSERT OR UPDATE ON public."Renglon_Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_renglon_comprobante_calcular();


--
-- Name: Renglon_Comprobante trg_renglon_comprobante_recalcular_cabecera; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_renglon_comprobante_recalcular_cabecera AFTER INSERT OR DELETE OR UPDATE ON public."Renglon_Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_renglon_comprobante_recalcular_cabecera();


--
-- Name: Renglon_Comprobante trg_renglon_comprobante_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_renglon_comprobante_stock BEFORE INSERT OR DELETE OR UPDATE ON public."Renglon_Comprobante" FOR EACH ROW EXECUTE FUNCTION public.fn_renglon_comprobante_aplicar_stock();


--
-- Name: TRIGGER trg_renglon_comprobante_stock ON "Renglon_Comprobante"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_renglon_comprobante_stock ON public."Renglon_Comprobante" IS 'RN-09: consume/restaura stock de la sala con bloqueo de fila; stock nunca negativo.';


--
-- Name: Renglon_Ingreso trg_renglon_ingreso_confeccion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_renglon_ingreso_confeccion BEFORE INSERT OR DELETE OR UPDATE ON public."Renglon_Ingreso" FOR EACH ROW EXECUTE FUNCTION public.fn_renglon_ingreso_proteger_confeccion();


--
-- Name: TRIGGER trg_renglon_ingreso_confeccion ON "Renglon_Ingreso"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_renglon_ingreso_confeccion ON public."Renglon_Ingreso" IS 'RN-12: bloqueo compartido sobre la cabecera; operaciones solo en confeccion.';


--
-- Name: Renglon_Transferencia trg_renglon_transferencia_confeccion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_renglon_transferencia_confeccion BEFORE INSERT OR DELETE OR UPDATE ON public."Renglon_Transferencia" FOR EACH ROW EXECUTE FUNCTION public.fn_renglon_transferencia_proteger_confeccion();


--
-- Name: TRIGGER trg_renglon_transferencia_confeccion ON "Renglon_Transferencia"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_renglon_transferencia_confeccion ON public."Renglon_Transferencia" IS 'RN-12: bloqueo compartido sobre la cabecera; operaciones solo en confeccion.';


--
-- Name: Composicion trg_rn05_composicion_suma_100; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_rn05_composicion_suma_100 AFTER INSERT OR DELETE OR UPDATE ON public."Composicion" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_composicion_suma_100();


--
-- Name: TRIGGER trg_rn05_composicion_suma_100 ON "Composicion"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_rn05_composicion_suma_100 ON public."Composicion" IS 'RN-05 (A-21): constraint trigger diferido; evalua la suma por vino al confirmar.';


--
-- Name: Vino trg_rn05_vino_composicion_obligatoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_rn05_vino_composicion_obligatoria AFTER INSERT ON public."Vino" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_vino_composicion_obligatoria();


--
-- Name: TRIGGER trg_rn05_vino_composicion_obligatoria ON "Vino"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_rn05_vino_composicion_obligatoria ON public."Vino" IS 'RN-05: valida al COMMIT la existencia de composicion con suma 100.';


--
-- Name: Socio trg_socio_descuento_final; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_socio_descuento_final AFTER INSERT OR DELETE OR UPDATE ON public."Socio" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_validar_descuento_final_trigger();


--
-- Name: Socio trg_socio_sincronizar_descuento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_socio_sincronizar_descuento AFTER INSERT ON public."Socio" FOR EACH ROW EXECUTE FUNCTION public.fn_cliente_sincronizar_descuento();


--
-- Name: Transferencia trg_transferencia_confeccion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transferencia_confeccion BEFORE UPDATE ON public."Transferencia" FOR EACH ROW EXECUTE FUNCTION public.fn_transferencia_proteger_confeccion();


--
-- Name: TRIGGER trg_transferencia_confeccion ON "Transferencia"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_transferencia_confeccion ON public."Transferencia" IS 'RN-12: la cabecera fuera de confeccion solo cambia su estado.';


--
-- Name: Transferencia trg_transferencia_estado_transiciones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transferencia_estado_transiciones BEFORE UPDATE OF estado ON public."Transferencia" FOR EACH ROW EXECUTE FUNCTION public.fn_estado_documento_validar_transicion();


--
-- Name: TRIGGER trg_transferencia_estado_transiciones ON "Transferencia"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_transferencia_estado_transiciones ON public."Transferencia" IS 'RN-11: solo en_confeccion->terminado (manual) y terminado->procesado (via procedure).';


--
-- Name: Transferencia trg_transferencia_fecha_confeccion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transferencia_fecha_confeccion BEFORE UPDATE OF fecha_confeccion ON public."Transferencia" FOR EACH ROW EXECUTE FUNCTION public.fn_transferencia_proteger_fecha_confeccion();


--
-- Name: TRIGGER trg_transferencia_fecha_confeccion ON "Transferencia"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_transferencia_fecha_confeccion ON public."Transferencia" IS 'RN-11: congela la fecha de confeccion (la fija el DEFAULT al crear la fila).';


--
-- Name: Vino trg_vino_auditar_precio; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_vino_auditar_precio AFTER UPDATE OF precio ON public."Vino" FOR EACH ROW EXECUTE FUNCTION public.fn_vino_auditar_cambio_precio();


--
-- Name: TRIGGER trg_vino_auditar_precio ON "Vino"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_vino_auditar_precio ON public."Vino" IS 'RN-13: registra cada cambio efectivo de precio (anterior, nuevo, fecha/hora, usuario).';


--
-- Name: Analisis fk_analisis_lote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Analisis"
    ADD CONSTRAINT fk_analisis_lote FOREIGN KEY (finca, n_parcela, campania) REFERENCES public."Lote"(finca, n_parcela, campania) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Auditoria_Precio fk_auditoria_precio_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Auditoria_Precio"
    ADD CONSTRAINT fk_auditoria_precio_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Cliente fk_cliente_localidad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cliente"
    ADD CONSTRAINT fk_cliente_localidad FOREIGN KEY (localidad) REFERENCES public."Localidad"(id_localidad) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Composicion fk_composicion_cepa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Composicion"
    ADD CONSTRAINT fk_composicion_cepa FOREIGN KEY (cepa) REFERENCES public."Cepa"(id) ON DELETE RESTRICT;


--
-- Name: Composicion fk_composicion_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Composicion"
    ADD CONSTRAINT fk_composicion_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Comprobante fk_comprobante_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Comprobante"
    ADD CONSTRAINT fk_comprobante_cliente FOREIGN KEY (cliente) REFERENCES public."Cliente"(id_cliente) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Comprobante fk_comprobante_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Comprobante"
    ADD CONSTRAINT fk_comprobante_sala FOREIGN KEY (sala) REFERENCES public."Sala"(id_sala) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Distribuidor fk_distribuidor_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Distribuidor"
    ADD CONSTRAINT fk_distribuidor_cliente FOREIGN KEY (id_cliente) REFERENCES public."Cliente"(id_cliente) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: Empleado fk_empleado_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Empleado"
    ADD CONSTRAINT fk_empleado_sala FOREIGN KEY (sala) REFERENCES public."Sala"(id_sala) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Exportador fk_exportador_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Exportador"
    ADD CONSTRAINT fk_exportador_cliente FOREIGN KEY (id_cliente) REFERENCES public."Cliente"(id_cliente) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: Ingreso fk_ingreso_bodega_origen; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Ingreso"
    ADD CONSTRAINT fk_ingreso_bodega_origen FOREIGN KEY (bodega_origen) REFERENCES public."Bodega"(cuit) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Ingreso fk_ingreso_transportista; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Ingreso"
    ADD CONSTRAINT fk_ingreso_transportista FOREIGN KEY (transportista) REFERENCES public."Transportista"(codigo) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Lote fk_lote_bodega_destino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Lote"
    ADD CONSTRAINT fk_lote_bodega_destino FOREIGN KEY (bodega_destino) REFERENCES public."Bodega"(cuit) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Lote fk_lote_parcela; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Lote"
    ADD CONSTRAINT fk_lote_parcela FOREIGN KEY (finca, n_parcela) REFERENCES public."Parcela"(finca, n_parcela) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Parcela fk_parcela_cepa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Parcela"
    ADD CONSTRAINT fk_parcela_cepa FOREIGN KEY (cepa) REFERENCES public."Cepa"(id) ON DELETE RESTRICT;


--
-- Name: Parcela fk_parcela_finca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Parcela"
    ADD CONSTRAINT fk_parcela_finca FOREIGN KEY (finca) REFERENCES public."Finca"(id_finca) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Permiso_Exportacion fk_permiso_exportador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Permiso_Exportacion"
    ADD CONSTRAINT fk_permiso_exportador FOREIGN KEY (exportador) REFERENCES public."Exportador"(id_cliente) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Renglon_Comprobante fk_renglon_comprobante_comprobante; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Comprobante"
    ADD CONSTRAINT fk_renglon_comprobante_comprobante FOREIGN KEY (comprobante) REFERENCES public."Comprobante"(numero) ON DELETE CASCADE;


--
-- Name: Renglon_Comprobante fk_renglon_comprobante_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Comprobante"
    ADD CONSTRAINT fk_renglon_comprobante_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Renglon_Ingreso fk_renglon_ingreso_ingreso; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Ingreso"
    ADD CONSTRAINT fk_renglon_ingreso_ingreso FOREIGN KEY (ingreso) REFERENCES public."Ingreso"(codigo) ON DELETE CASCADE;


--
-- Name: Renglon_Ingreso fk_renglon_ingreso_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Ingreso"
    ADD CONSTRAINT fk_renglon_ingreso_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Renglon_Transferencia fk_renglon_transferencia_transferencia; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Transferencia"
    ADD CONSTRAINT fk_renglon_transferencia_transferencia FOREIGN KEY (transferencia) REFERENCES public."Transferencia"(numero) ON DELETE CASCADE;


--
-- Name: Renglon_Transferencia fk_renglon_transferencia_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Renglon_Transferencia"
    ADD CONSTRAINT fk_renglon_transferencia_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Sala fk_sala_localidad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Sala"
    ADD CONSTRAINT fk_sala_localidad FOREIGN KEY (localidad) REFERENCES public."Localidad"(id_localidad) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Socio fk_socio_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Socio"
    ADD CONSTRAINT fk_socio_cliente FOREIGN KEY (id_cliente) REFERENCES public."Cliente"(id_cliente) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: Stock_Deposito fk_stock_deposito_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock_Deposito"
    ADD CONSTRAINT fk_stock_deposito_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Stock_Sala fk_stock_sala_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock_Sala"
    ADD CONSTRAINT fk_stock_sala_sala FOREIGN KEY (sala) REFERENCES public."Sala"(id_sala) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Stock_Sala fk_stock_sala_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock_Sala"
    ADD CONSTRAINT fk_stock_sala_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: Transferencia fk_transferencia_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transferencia"
    ADD CONSTRAINT fk_transferencia_sala FOREIGN KEY (sala) REFERENCES public."Sala"(id_sala) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Transportista_Localidad fk_transportista_localidad_localidad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transportista_Localidad"
    ADD CONSTRAINT fk_transportista_localidad_localidad FOREIGN KEY (localidad) REFERENCES public."Localidad"(id_localidad) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: Transportista_Localidad fk_transportista_localidad_transportista; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transportista_Localidad"
    ADD CONSTRAINT fk_transportista_localidad_transportista FOREIGN KEY (transportista) REFERENCES public."Transportista"(codigo) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: Vino fk_vino_bodega; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino"
    ADD CONSTRAINT fk_vino_bodega FOREIGN KEY (bodega) REFERENCES public."Bodega"(cuit) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Vino_Maridaje fk_vino_maridaje_maridaje; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino_Maridaje"
    ADD CONSTRAINT fk_vino_maridaje_maridaje FOREIGN KEY (maridaje) REFERENCES public."Maridaje"(id) ON DELETE RESTRICT;


--
-- Name: Vino_Maridaje fk_vino_maridaje_vino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vino_Maridaje"
    ADD CONSTRAINT fk_vino_maridaje_vino FOREIGN KEY (vino) REFERENCES public."Vino"(codigo) ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO bodegas_admin;
GRANT USAGE ON SCHEMA public TO bodegas_api;
GRANT USAGE ON SCHEMA public TO bodegas_reportes;


--
-- Name: FUNCTION fn_antiguedad_anios(p_fecha date, p_hasta date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_antiguedad_anios(p_fecha date, p_hasta date) TO bodegas_api;


--
-- Name: FUNCTION fn_auditoria_precio_proteger(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_auditoria_precio_proteger() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_auditoria_precio_proteger() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_auditoria_precio_proteger() TO bodegas_api;


--
-- Name: FUNCTION fn_bandera_proceso_activada(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_bandera_proceso_activada() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_bandera_proceso_activada() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_bandera_proceso_activada() TO bodegas_api;


--
-- Name: FUNCTION fn_cliente_rechazar_descuento_manual(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cliente_rechazar_descuento_manual() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cliente_rechazar_descuento_manual() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_cliente_rechazar_descuento_manual() TO bodegas_api;


--
-- Name: FUNCTION fn_cliente_sincronizar_descuento(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cliente_sincronizar_descuento() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cliente_sincronizar_descuento() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_cliente_sincronizar_descuento() TO bodegas_api;


--
-- Name: FUNCTION fn_cliente_validar_cambio_descuento(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cliente_validar_cambio_descuento() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cliente_validar_cambio_descuento() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_cliente_validar_cambio_descuento() TO bodegas_api;


--
-- Name: FUNCTION fn_cliente_validar_descuento_final_id(p_id_cliente bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cliente_validar_descuento_final_id(p_id_cliente bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cliente_validar_descuento_final_id(p_id_cliente bigint) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_cliente_validar_descuento_final_id(p_id_cliente bigint) TO bodegas_api;


--
-- Name: FUNCTION fn_cliente_validar_descuento_final_trigger(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cliente_validar_descuento_final_trigger() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cliente_validar_descuento_final_trigger() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_cliente_validar_descuento_final_trigger() TO bodegas_api;


--
-- Name: FUNCTION fn_composicion_suma_100(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_composicion_suma_100() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_composicion_suma_100() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_composicion_suma_100() TO bodegas_api;


--
-- Name: FUNCTION fn_composicion_validar_vino(v_vino text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_composicion_validar_vino(v_vino text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_composicion_validar_vino(v_vino text) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_composicion_validar_vino(v_vino text) TO bodegas_api;


--
-- Name: FUNCTION fn_comprobante_inicializar_totales(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_comprobante_inicializar_totales() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_comprobante_inicializar_totales() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_comprobante_inicializar_totales() TO bodegas_api;


--
-- Name: FUNCTION fn_comprobante_proteger_importes(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_comprobante_proteger_importes() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_comprobante_proteger_importes() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_comprobante_proteger_importes() TO bodegas_api;


--
-- Name: FUNCTION fn_comprobante_proteger_sala(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_comprobante_proteger_sala() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_comprobante_proteger_sala() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_comprobante_proteger_sala() TO bodegas_api;


--
-- Name: FUNCTION fn_comprobante_registrar_sala(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_comprobante_registrar_sala() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_comprobante_registrar_sala() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_comprobante_registrar_sala() TO bodegas_api;


--
-- Name: FUNCTION fn_descuento_cliente(p_id_cliente bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_descuento_cliente(p_id_cliente bigint) TO bodegas_api;


--
-- Name: FUNCTION fn_estado_documento_validar_transicion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_estado_documento_validar_transicion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_estado_documento_validar_transicion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_estado_documento_validar_transicion() TO bodegas_api;


--
-- Name: FUNCTION fn_ingreso_proteger_confeccion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_ingreso_proteger_confeccion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_ingreso_proteger_confeccion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_ingreso_proteger_confeccion() TO bodegas_api;


--
-- Name: FUNCTION fn_renglon_comprobante_aplicar_stock(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_renglon_comprobante_aplicar_stock() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_aplicar_stock() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_aplicar_stock() TO bodegas_api;


--
-- Name: FUNCTION fn_renglon_comprobante_calcular(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_renglon_comprobante_calcular() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_calcular() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_calcular() TO bodegas_api;


--
-- Name: FUNCTION fn_renglon_comprobante_recalcular_cabecera(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_renglon_comprobante_recalcular_cabecera() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_recalcular_cabecera() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_renglon_comprobante_recalcular_cabecera() TO bodegas_api;


--
-- Name: FUNCTION fn_renglon_ingreso_proteger_confeccion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_renglon_ingreso_proteger_confeccion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_renglon_ingreso_proteger_confeccion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_renglon_ingreso_proteger_confeccion() TO bodegas_api;


--
-- Name: FUNCTION fn_renglon_transferencia_proteger_confeccion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_renglon_transferencia_proteger_confeccion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_renglon_transferencia_proteger_confeccion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_renglon_transferencia_proteger_confeccion() TO bodegas_api;


--
-- Name: FUNCTION fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_rn09_consumir_stock(p_sala bigint, p_vino text, p_cantidad integer) TO bodegas_api;


--
-- Name: FUNCTION fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_rn09_reponer_stock(p_sala bigint, p_vino text, p_cantidad integer) TO bodegas_api;


--
-- Name: FUNCTION fn_stock_sala(p_sala bigint, p_vino text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_stock_sala(p_sala bigint, p_vino text) TO bodegas_api;


--
-- Name: FUNCTION fn_total_comprobante(p_numero bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_total_comprobante(p_numero bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_total_comprobante(p_numero bigint) TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_total_comprobante(p_numero bigint) TO bodegas_api;


--
-- Name: FUNCTION fn_transferencia_proteger_confeccion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_transferencia_proteger_confeccion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_transferencia_proteger_confeccion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_transferencia_proteger_confeccion() TO bodegas_api;


--
-- Name: FUNCTION fn_transferencia_proteger_fecha_confeccion(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_transferencia_proteger_fecha_confeccion() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_transferencia_proteger_fecha_confeccion() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_transferencia_proteger_fecha_confeccion() TO bodegas_api;


--
-- Name: FUNCTION fn_vino_auditar_cambio_precio(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_vino_auditar_cambio_precio() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_vino_auditar_cambio_precio() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_vino_auditar_cambio_precio() TO bodegas_api;


--
-- Name: FUNCTION fn_vino_composicion_obligatoria(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_vino_composicion_obligatoria() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_vino_composicion_obligatoria() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_vino_composicion_obligatoria() TO bodegas_api;


--
-- Name: FUNCTION fn_vino_usuario_funcional_texto(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_vino_usuario_funcional_texto() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_vino_usuario_funcional_texto() TO bodegas_admin;
GRANT ALL ON FUNCTION public.fn_vino_usuario_funcional_texto() TO bodegas_api;


--
-- Name: PROCEDURE sp_procesar_ingreso(IN p_codigo text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.sp_procesar_ingreso(IN p_codigo text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.sp_procesar_ingreso(IN p_codigo text) TO bodegas_admin;
GRANT ALL ON PROCEDURE public.sp_procesar_ingreso(IN p_codigo text) TO bodegas_api;


--
-- Name: PROCEDURE sp_procesar_transferencia(IN p_numero bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint) TO bodegas_admin;
GRANT ALL ON PROCEDURE public.sp_procesar_transferencia(IN p_numero bigint) TO bodegas_api;


--
-- Name: TABLE "Analisis"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Analisis" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Analisis" TO bodegas_api;
GRANT SELECT ON TABLE public."Analisis" TO bodegas_reportes;


--
-- Name: SEQUENCE "Analisis_id_analisis_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Analisis_id_analisis_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Analisis_id_analisis_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Analisis_id_analisis_seq" TO bodegas_reportes;


--
-- Name: TABLE "Auditoria_Precio"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Auditoria_Precio" TO bodegas_admin;
GRANT SELECT ON TABLE public."Auditoria_Precio" TO bodegas_api;
GRANT SELECT ON TABLE public."Auditoria_Precio" TO bodegas_reportes;


--
-- Name: SEQUENCE "Auditoria_Precio_id_auditoria_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Auditoria_Precio_id_auditoria_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Auditoria_Precio_id_auditoria_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Auditoria_Precio_id_auditoria_seq" TO bodegas_reportes;


--
-- Name: TABLE "Bodega"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Bodega" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Bodega" TO bodegas_api;
GRANT SELECT ON TABLE public."Bodega" TO bodegas_reportes;


--
-- Name: TABLE "Cepa"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Cepa" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Cepa" TO bodegas_api;
GRANT SELECT ON TABLE public."Cepa" TO bodegas_reportes;


--
-- Name: SEQUENCE "Cepa_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Cepa_id_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Cepa_id_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Cepa_id_seq" TO bodegas_reportes;


--
-- Name: TABLE "Cliente"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Cliente" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Cliente" TO bodegas_api;
GRANT SELECT ON TABLE public."Cliente" TO bodegas_reportes;


--
-- Name: SEQUENCE "Cliente_id_cliente_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Cliente_id_cliente_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Cliente_id_cliente_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Cliente_id_cliente_seq" TO bodegas_reportes;


--
-- Name: TABLE "Composicion"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Composicion" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Composicion" TO bodegas_api;
GRANT SELECT ON TABLE public."Composicion" TO bodegas_reportes;


--
-- Name: TABLE "Comprobante"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Comprobante" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Comprobante" TO bodegas_api;
GRANT SELECT ON TABLE public."Comprobante" TO bodegas_reportes;


--
-- Name: TABLE "Distribuidor"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Distribuidor" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Distribuidor" TO bodegas_api;
GRANT SELECT ON TABLE public."Distribuidor" TO bodegas_reportes;


--
-- Name: TABLE "Empleado"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Empleado" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Empleado" TO bodegas_api;
GRANT SELECT ON TABLE public."Empleado" TO bodegas_reportes;


--
-- Name: SEQUENCE "Empleado_id_empleado_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Empleado_id_empleado_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Empleado_id_empleado_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Empleado_id_empleado_seq" TO bodegas_reportes;


--
-- Name: TABLE "Exportador"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Exportador" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Exportador" TO bodegas_api;
GRANT SELECT ON TABLE public."Exportador" TO bodegas_reportes;


--
-- Name: TABLE "Finca"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Finca" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Finca" TO bodegas_api;
GRANT SELECT ON TABLE public."Finca" TO bodegas_reportes;


--
-- Name: SEQUENCE "Finca_id_finca_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Finca_id_finca_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Finca_id_finca_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Finca_id_finca_seq" TO bodegas_reportes;


--
-- Name: TABLE "Ingreso"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Ingreso" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Ingreso" TO bodegas_api;
GRANT SELECT ON TABLE public."Ingreso" TO bodegas_reportes;


--
-- Name: TABLE "Localidad"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Localidad" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Localidad" TO bodegas_api;
GRANT SELECT ON TABLE public."Localidad" TO bodegas_reportes;


--
-- Name: SEQUENCE "Localidad_id_localidad_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Localidad_id_localidad_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Localidad_id_localidad_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Localidad_id_localidad_seq" TO bodegas_reportes;


--
-- Name: TABLE "Lote"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Lote" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Lote" TO bodegas_api;
GRANT SELECT ON TABLE public."Lote" TO bodegas_reportes;


--
-- Name: TABLE "Maridaje"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Maridaje" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Maridaje" TO bodegas_api;
GRANT SELECT ON TABLE public."Maridaje" TO bodegas_reportes;


--
-- Name: SEQUENCE "Maridaje_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Maridaje_id_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Maridaje_id_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Maridaje_id_seq" TO bodegas_reportes;


--
-- Name: TABLE "Parcela"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Parcela" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Parcela" TO bodegas_api;
GRANT SELECT ON TABLE public."Parcela" TO bodegas_reportes;


--
-- Name: TABLE "Permiso_Exportacion"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Permiso_Exportacion" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Permiso_Exportacion" TO bodegas_api;
GRANT SELECT ON TABLE public."Permiso_Exportacion" TO bodegas_reportes;


--
-- Name: TABLE "Renglon_Comprobante"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Renglon_Comprobante" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Renglon_Comprobante" TO bodegas_api;
GRANT SELECT ON TABLE public."Renglon_Comprobante" TO bodegas_reportes;


--
-- Name: TABLE "Renglon_Ingreso"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Renglon_Ingreso" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Renglon_Ingreso" TO bodegas_api;
GRANT SELECT ON TABLE public."Renglon_Ingreso" TO bodegas_reportes;


--
-- Name: TABLE "Renglon_Transferencia"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Renglon_Transferencia" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Renglon_Transferencia" TO bodegas_api;
GRANT SELECT ON TABLE public."Renglon_Transferencia" TO bodegas_reportes;


--
-- Name: TABLE "Sala"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Sala" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Sala" TO bodegas_api;
GRANT SELECT ON TABLE public."Sala" TO bodegas_reportes;


--
-- Name: SEQUENCE "Sala_id_sala_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Sala_id_sala_seq" TO bodegas_admin;
GRANT USAGE ON SEQUENCE public."Sala_id_sala_seq" TO bodegas_api;
GRANT SELECT ON SEQUENCE public."Sala_id_sala_seq" TO bodegas_reportes;


--
-- Name: TABLE "Socio"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Socio" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Socio" TO bodegas_api;
GRANT SELECT ON TABLE public."Socio" TO bodegas_reportes;


--
-- Name: TABLE "Stock_Deposito"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Stock_Deposito" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Stock_Deposito" TO bodegas_api;
GRANT SELECT ON TABLE public."Stock_Deposito" TO bodegas_reportes;


--
-- Name: TABLE "Stock_Sala"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Stock_Sala" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Stock_Sala" TO bodegas_api;
GRANT SELECT ON TABLE public."Stock_Sala" TO bodegas_reportes;


--
-- Name: TABLE "Transferencia"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Transferencia" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Transferencia" TO bodegas_api;
GRANT SELECT ON TABLE public."Transferencia" TO bodegas_reportes;


--
-- Name: TABLE "Transportista"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Transportista" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Transportista" TO bodegas_api;
GRANT SELECT ON TABLE public."Transportista" TO bodegas_reportes;


--
-- Name: TABLE "Transportista_Localidad"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Transportista_Localidad" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Transportista_Localidad" TO bodegas_api;
GRANT SELECT ON TABLE public."Transportista_Localidad" TO bodegas_reportes;


--
-- Name: TABLE "Vino"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Vino" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Vino" TO bodegas_api;
GRANT SELECT ON TABLE public."Vino" TO bodegas_reportes;


--
-- Name: TABLE "Vino_Maridaje"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Vino_Maridaje" TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."Vino_Maridaje" TO bodegas_api;
GRANT SELECT ON TABLE public."Vino_Maridaje" TO bodegas_reportes;


--
-- Name: TABLE v_documentos_pendientes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_documentos_pendientes TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_documentos_pendientes TO bodegas_api;
GRANT SELECT ON TABLE public.v_documentos_pendientes TO bodegas_reportes;


--
-- Name: TABLE v_stock_total_vino; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_stock_total_vino TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_stock_total_vino TO bodegas_api;
GRANT SELECT ON TABLE public.v_stock_total_vino TO bodegas_reportes;


--
-- Name: TABLE v_ventas_mensuales_sala; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_ventas_mensuales_sala TO bodegas_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_ventas_mensuales_sala TO bodegas_api;
GRANT SELECT ON TABLE public.v_ventas_mensuales_sala TO bodegas_reportes;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: bodegas_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public GRANT USAGE ON SEQUENCES TO bodegas_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public GRANT USAGE ON SEQUENCES TO bodegas_api;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: bodegas_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO bodegas_api;
ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public GRANT SELECT ON TABLES TO bodegas_reportes;


--
-- PostgreSQL database dump complete
--

\unrestrict srMAXqJUFO1duXg1qa76d8nlzVTGEjWkOmdQ9Va43dx8v8eDqm3tteeIDQBFcAy

