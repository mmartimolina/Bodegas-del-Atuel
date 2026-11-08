-- 008_rn12_inmutabilidad_renglones.sql
-- RN-12 (issue #34): un ingreso o una transferencia que ya no esta en confeccion
-- no admite agregar, modificar ni quitar renglones.
--
-- Concurrencia: el trigger toma un bloqueo de fila compartido (FOR SHARE) sobre la
-- cabecera antes de leer su estado; una transaccion que este cambiando el estado
-- mantiene FOR UPDATE sobre la misma fila, de modo que no hay ventana en la que una
-- modificacion concurrente de cabecera valide un renglon fuera del estado permitido.
-- Sin recursividad ni efectos laterales (solo lecturas y excepciones).
--
-- Complemento documentado: la cabecera que ya esta fuera de en_confeccion solo
-- admite el cambio de estado (y fecha_confeccion la maneja RN-11).

BEGIN;

-- =========================================================
-- Renglones de Ingreso
-- =========================================================

CREATE FUNCTION fn_renglon_ingreso_proteger_confeccion()
RETURNS trigger
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

COMMENT ON FUNCTION fn_renglon_ingreso_proteger_confeccion() IS
    'RN-12: no permite INSERT/UPDATE/DELETE de renglones de ingreso fuera de en_confeccion.';

CREATE TRIGGER trg_renglon_ingreso_confeccion
    BEFORE INSERT OR UPDATE OR DELETE ON "Renglon_Ingreso"
    FOR EACH ROW
    EXECUTE FUNCTION fn_renglon_ingreso_proteger_confeccion();

-- =========================================================
-- Renglones de Transferencia
-- =========================================================

CREATE FUNCTION fn_renglon_transferencia_proteger_confeccion()
RETURNS trigger
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

COMMENT ON FUNCTION fn_renglon_transferencia_proteger_confeccion() IS
    'RN-12: no permite INSERT/UPDATE/DELETE de renglones de transferencia fuera de en_confeccion.';

CREATE TRIGGER trg_renglon_transferencia_confeccion
    BEFORE INSERT OR UPDATE OR DELETE ON "Renglon_Transferencia"
    FOR EACH ROW
    EXECUTE FUNCTION fn_renglon_transferencia_proteger_confeccion();

-- =========================================================
-- Cabeceras fuera de confeccion: solo cambian su estado
-- (la fecha de confeccion de la transferencia ya la congela RN-11)
-- =========================================================

CREATE FUNCTION fn_ingreso_proteger_confeccion()
RETURNS trigger
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

CREATE TRIGGER trg_ingreso_confeccion
    BEFORE UPDATE ON "Ingreso"
    FOR EACH ROW
    EXECUTE FUNCTION fn_ingreso_proteger_confeccion();

CREATE FUNCTION fn_transferencia_proteger_confeccion()
RETURNS trigger
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

CREATE TRIGGER trg_transferencia_confeccion
    BEFORE UPDATE ON "Transferencia"
    FOR EACH ROW
    EXECUTE FUNCTION fn_transferencia_proteger_confeccion();

COMMENT ON TRIGGER trg_renglon_ingreso_confeccion ON "Renglon_Ingreso" IS
    'RN-12: bloqueo compartido sobre la cabecera; operaciones solo en confeccion.';

COMMENT ON TRIGGER trg_renglon_transferencia_confeccion ON "Renglon_Transferencia" IS
    'RN-12: bloqueo compartido sobre la cabecera; operaciones solo en confeccion.';

COMMENT ON TRIGGER trg_ingreso_confeccion ON "Ingreso" IS
    'RN-12: la cabecera fuera de confeccion solo cambia su estado.';

COMMENT ON TRIGGER trg_transferencia_confeccion ON "Transferencia" IS
    'RN-12: la cabecera fuera de confeccion solo cambia su estado.';

COMMIT;
