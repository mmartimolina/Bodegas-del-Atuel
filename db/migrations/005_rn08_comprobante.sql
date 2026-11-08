-- 005_rn08_comprobante.sql
-- RN-08: calculo automatico de importes de comprobantes y renglones.
-- DEC-23: descuentos historicos por renglon; importes almacenados.
--
-- Comprobante.subtotal: suma de importes brutos.
-- Comprobante.descuento: suma de descuentos monetarios por renglon.
-- Comprobante.total: suma de subtotales netos de los renglones.
--
-- Renglon_Comprobante.subtotal: importe bruto menos descuento monetario.
-- Los importes derivados no se aceptan como carga manual.

BEGIN;

-- =========================================================
-- RN-08: proteccion de importes derivados de Comprobante
-- =========================================================

CREATE FUNCTION fn_comprobante_proteger_importes()
RETURNS trigger
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

CREATE TRIGGER trg_comprobante_importes_no_manuales
BEFORE INSERT OR UPDATE OF subtotal, descuento, total
ON "Comprobante"
FOR EACH ROW
EXECUTE FUNCTION fn_comprobante_proteger_importes();


-- =========================================================
-- RN-08: funcion central de calculo de cabecera
-- =========================================================

CREATE FUNCTION fn_total_comprobante(p_numero BIGINT)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
VOLATILE
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


-- =========================================================
-- RN-08: inicializacion automatica de cabecera
-- =========================================================

CREATE FUNCTION fn_comprobante_inicializar_totales()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM fn_total_comprobante(NEW.numero);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_comprobante_inicializar_totales
AFTER INSERT ON "Comprobante"
FOR EACH ROW
EXECUTE FUNCTION fn_comprobante_inicializar_totales();


-- =========================================================
-- RN-08: descuento historico y subtotal neto del renglon
-- =========================================================

CREATE FUNCTION fn_renglon_comprobante_calcular()
RETURNS trigger
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

CREATE TRIGGER trg_renglon_comprobante_calcular
BEFORE INSERT OR UPDATE ON "Renglon_Comprobante"
FOR EACH ROW
EXECUTE FUNCTION fn_renglon_comprobante_calcular();


-- =========================================================
-- RN-08: recalculo de cabecera ante cambios de renglones
-- =========================================================

CREATE FUNCTION fn_renglon_comprobante_recalcular_cabecera()
RETURNS trigger
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

CREATE TRIGGER trg_renglon_comprobante_recalcular_cabecera
AFTER INSERT OR UPDATE OR DELETE ON "Renglon_Comprobante"
FOR EACH ROW
EXECUTE FUNCTION fn_renglon_comprobante_recalcular_cabecera();


COMMENT ON FUNCTION fn_total_comprobante(BIGINT) IS
    'RN-08: recalcula subtotal bruto, descuento monetario y total neto de un comprobante.';

COMMENT ON FUNCTION fn_renglon_comprobante_calcular() IS
    'RN-08: copia el descuento historico del cliente y calcula el subtotal neto del renglon.';

COMMIT;