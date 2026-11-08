-- 010_rn15_numericas_y_funcion.sql
-- RN-15 (issue #37): validaciones numericas restantes del negocio.
-- La mayoria ya existe (002_constraints.sql): no se re-declaran los CHECK ya
-- implementados; aqui se agrega solo el CHEQUE de porcentaje por fila de
-- Composicion y se documenta la referencia de cada criterio adoptado:
--
--   - Cantidades (renglones de comprobante/ingreso/transferencia) estrictamente
--     positivas: 002 (ck_renglon_*_cantidad_positiva). Sin duplicar.
--   - Superficies de finca y parcela y kilos del lote positivos: 002
--     (ck_finca/ck_parcela/ck_lote_*). Sin duplicar.
--   - Precio positivo (RN-01) y graduacion 5..20 inclusive: 002. Sin duplicar.
--   - Existencias >= 0: stock puede ser 0 (ausencia de existencias) pero jamas
--     negativo: 002 (ck_stock_*_cantidad_no_negativa). Sin duplicar.
--   - Porcentajes de composicion: fila en 0 < porcentaje <= 100 (nuevo) y la regla
--     de suma = 100 exacta al COMMIT es el constraint trigger diferido de 003.
--
-- FUNCION REQUERIDA (issue #38): fn_antiguedad_anios: calcula los anos cumplidos
-- entre p_fecha y p_hasta (por defecto CURRENT_DATE). STABLE (usa CURRENT_DATE por
-- defecto); con fechas nulas devuelve NULL (no hay punto de partida). Devuelve el
-- numero de aniversarios completados (como la edad); fechas futuras dan 0? no:
-- dan negativo => se normaliza a 0? La consigna lo pide "anios cumplidos": una
-- fecha futura esta mal cargada; devolvemos el valor real (negativo) para no
-- ocultar errores y las consultas usan > N anios. Documentado abajo.
--
-- Casos de limite cubiertos en db/tests/rn38_antiguedad.fn.ok.sql/: dia de
-- cumpleanos exacto (cumple), el dia anterior al cumpleanos (no cumple), 29/02
-- con anios no bisiestos, fecha futura (negativo) y fechas nulas (NULL).

BEGIN;

-- =========================================================
-- RN-15: porcentaje por fila de Composicion (complemento de RN-05)
-- =========================================================

ALTER TABLE "Composicion"
    ADD CONSTRAINT ck_composicion_porcentaje_rango
    CHECK (porcentaje > 0 AND porcentaje <= 100);

COMMENT ON CONSTRAINT ck_composicion_porcentaje_rango ON "Composicion" IS
    'RN-15: cada fila aporta entre >0 y <=100; la suma 100 exacta la valida RN-05 diferido.';

-- =========================================================
-- fn_antiguedad_anios: de una fecha a otra, aniversarios cumplidos
-- =========================================================

CREATE FUNCTION fn_antiguedad_anios(p_fecha DATE, p_hasta DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
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

COMMENT ON FUNCTION fn_antiguedad_anios(DATE, DATE) IS
    'Issue #38: anios cumplidos entre p_fecha y p_hasta (defecto CURRENT_DATE); NULL si alguna fecha es NULL; -1 si la fecha es futura.';

COMMIT;
