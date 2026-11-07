-- 003_rn05_composicion_deferred.sql
-- A21 (issue #25): RN-05 — los porcentajes de corte de un vino suman exactamente 100.
--
-- Mecanismo exigido por la consigna (seccion 4, RN-05: "Constraint trigger diferido"):
-- un CONSTRAINT TRIGGER DEFERRABLE INITIALLY DEFERRED que, al confirmar la transaccion,
-- valida que la suma de porcentajes de cada vino afectado sea exactamente 100.
--
-- No se usa un CHECK de fila: la regla es agregada sobre varias filas de "Composicion"
-- (A-10 s 6.1; A-11; decidida por la consigna, no por el equipo).
-- Dentro de la transaccion las sumas intermedias pueden ser otras; solo importa el estado
-- al COMMIT (por eso DEFERRABLE INITIALLY DEFERRED, con la propiedad probada en
-- db/tests/rn05_composicion_suma.ok.sql y los archivos .fail de la misma carpeta).

BEGIN;

-- validacion de un vino: la suma de sus porcentajes debe ser exactamente 100
CREATE FUNCTION fn_composicion_validar_vino(v_vino TEXT)
RETURNS void
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

CREATE OR REPLACE FUNCTION fn_composicion_suma_100()
RETURNS trigger
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

CREATE CONSTRAINT TRIGGER trg_rn05_composicion_suma_100
    AFTER INSERT OR UPDATE OR DELETE ON "Composicion"
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_composicion_suma_100();

COMMENT ON FUNCTION fn_composicion_suma_100() IS
    'RN-05 (A-21): valida al COMMIT que la suma de porcentajes del vino sea 100.';
COMMENT ON TRIGGER trg_rn05_composicion_suma_100 ON "Composicion" IS
    'RN-05 (A-21): constraint trigger diferido; evalua la suma por vino al confirmar.';

-- RN-05: todo vino confirmado debe tener al menos una cepa
-- y una suma de porcentajes exactamente igual a 100.
-- La validación es diferida para permitir insertar Vino y
-- Composicion dentro de la misma transacción.

CREATE OR REPLACE FUNCTION fn_vino_composicion_obligatoria()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Si el vino sigue existiendo al confirmar la transacción,
    -- debe tener una composición válida.
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

CREATE CONSTRAINT TRIGGER trg_rn05_vino_composicion_obligatoria
    AFTER INSERT ON "Vino"
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_vino_composicion_obligatoria();

COMMENT ON FUNCTION fn_vino_composicion_obligatoria() IS
    'RN-05: impide confirmar un vino sin composicion porcentual valida.';

COMMENT ON TRIGGER trg_rn05_vino_composicion_obligatoria ON "Vino" IS
    'RN-05: valida al COMMIT la existencia de composicion con suma 100.';

COMMIT;
