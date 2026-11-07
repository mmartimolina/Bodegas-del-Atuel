-- 004_rn03_rn06.sql
-- RN-03: se reutiliza Empleado.sala NOT NULL + FK existente (#2).
-- RN-06: descuento por subtipo de Cliente.
-- DEC-32: alternativa A adoptada; atributo almacenado sincronizado
-- mediante fn_descuento_cliente.
-- U6 (35 % para exportadores con mas de 3 permisos) sigue pendiente.

BEGIN;

-- =========================================================
-- RN-06: rango del descuento
-- =========================================================

ALTER TABLE "Cliente"
    ADD CONSTRAINT ck_cliente_descuento_rango
    CHECK (descuento BETWEEN 0 AND 100);


-- =========================================================
-- RN-06: funcion de descuento segun subtipo
-- =========================================================

CREATE FUNCTION fn_descuento_cliente(p_id_cliente BIGINT)
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql
VOLATILE
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


-- =========================================================
-- RN-06: sincronizacion del atributo Cliente.descuento
-- =========================================================

CREATE FUNCTION fn_cliente_sincronizar_descuento()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "Cliente"
       SET descuento = fn_descuento_cliente(NEW.id_cliente)
     WHERE id_cliente = NEW.id_cliente;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_socio_sincronizar_descuento
AFTER INSERT ON "Socio"
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_sincronizar_descuento();

CREATE TRIGGER trg_distribuidor_sincronizar_descuento
AFTER INSERT ON "Distribuidor"
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_sincronizar_descuento();

CREATE TRIGGER trg_exportador_sincronizar_descuento
AFTER INSERT ON "Exportador"
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_sincronizar_descuento();


-- =========================================================
-- RN-06: evitar asignaciones manuales inconsistentes
-- =========================================================

CREATE FUNCTION fn_cliente_validar_cambio_descuento()
RETURNS trigger
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

CREATE TRIGGER trg_cliente_validar_descuento
BEFORE UPDATE OF descuento ON "Cliente"
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_validar_cambio_descuento();


-- =========================================================
-- RN-06: el descuento no se carga manualmente al crear Cliente
-- =========================================================

CREATE FUNCTION fn_cliente_rechazar_descuento_manual()
RETURNS trigger
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

CREATE TRIGGER trg_cliente_descuento_derivado
BEFORE INSERT ON "Cliente"
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_rechazar_descuento_manual();


-- =========================================================
-- RN-06: validacion diferida de la jerarquia y el descuento
-- =========================================================

CREATE FUNCTION fn_cliente_validar_descuento_final_id(p_id_cliente BIGINT)
RETURNS void
LANGUAGE plpgsql
VOLATILE
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

CREATE FUNCTION fn_cliente_validar_descuento_final_trigger()
RETURNS trigger
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

CREATE CONSTRAINT TRIGGER trg_cliente_descuento_final
AFTER INSERT OR UPDATE ON "Cliente"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_validar_descuento_final_trigger();

CREATE CONSTRAINT TRIGGER trg_socio_descuento_final
AFTER INSERT OR UPDATE OR DELETE ON "Socio"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_validar_descuento_final_trigger();

CREATE CONSTRAINT TRIGGER trg_distribuidor_descuento_final
AFTER INSERT OR UPDATE OR DELETE ON "Distribuidor"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_validar_descuento_final_trigger();

CREATE CONSTRAINT TRIGGER trg_exportador_descuento_final
AFTER INSERT OR UPDATE OR DELETE ON "Exportador"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fn_cliente_validar_descuento_final_trigger();


COMMENT ON FUNCTION fn_descuento_cliente(BIGINT) IS
    'RN-06: devuelve 10 para Socio, 20 para Distribuidor y 30 para Exportador. U6 permanece pendiente.';

COMMIT;