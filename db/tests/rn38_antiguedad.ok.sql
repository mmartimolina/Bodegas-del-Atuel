-- rn38_antiguedad.ok.sql
-- Issue #38: fn_antiguedad_anios(FECHA, CALCULO) devuelve los anios cumplidos,
-- maneja NULL y fechas futuras; es STABLE e inmutable ante renglones.

BEGIN;

DO $$
DECLARE
    v1 INTEGER;
    v2 INTEGER;
    v3 INTEGER;
    v4 INTEGER;
BEGIN
    -- Cumpleanios ya pasado: edad completa.
    v1 := fn_antiguedad_anios(DATE '2020-01-15', DATE '2026-03-01');
    IF v1 <> 6 THEN
        RAISE EXCEPTION 'RN-38 FALLO: fn_antiguedad_anios(2020-01-15, 2026-03-01) = % (esperado 6)', v1;
    END IF;

    -- Cumpleanios aun no llega: un anio menos.
    v2 := fn_antiguedad_anios(DATE '2020-06-30', DATE '2026-03-01');
    IF v2 <> 5 THEN
        RAISE EXCEPTION 'RN-38 FALLO: fn_antiguedad_anios(2020-06-30, 2026-03-01) = % (esperado 5)', v2;
    END IF;

    -- Cumplir justo el dia del calculo: cuenta el anio.
    v3 := fn_antiguedad_anios(DATE '2020-03-01', DATE '2026-03-01');
    IF v3 <> 6 THEN
        RAISE EXCEPTION 'RN-38 FALLO: fn_antiguedad_anios(2020-03-01, 2026-03-01) = % (esperado 6)', v3;
    END IF;

    RAISE NOTICE 'OK RN-38: anios cumplidos, cumple hijo sin llegar y dia exacto (6/5/6)';
END;
$$;

DO $$
DECLARE
    v_futura INTEGER;
BEGIN
    -- Fecha NULL no computa: NULL.
    IF fn_antiguedad_anios(NULL, DATE '2026-03-01') IS NOT NULL THEN
        RAISE EXCEPTION 'RN-38 FALLO: fecha NULL no devolvio NULL';
    END IF;

    -- Fecha futura: -1 (sin anios de antiguedad).
    v_futura := fn_antiguedad_anios(DATE '2027-01-01', DATE '2026-03-01');
    IF v_futura <> -1 THEN
        RAISE EXCEPTION 'RN-38 FALLO: fecha futura = % (esperado -1)', v_futura;
    END IF;

    RAISE NOTICE 'OK RN-38: fecha NULL -> NULL y fecha futura -> -1';
END;
$$;

DO $$
DECLARE
    v1 INTEGER;
    v2 INTEGER;
BEGIN
    -- El segundo argumento es opcional (default CURRENT_DATE) y STABLE.
    v1 := fn_antiguedad_anios(DATE '2000-01-01');
    v2 := fn_antiguedad_anios(DATE '2000-01-01');

    IF v1 IS NULL OR v1 < 20 OR v1 <> v2 THEN
        RAISE EXCEPTION 'RN-38 FALLO: default de fecha inconsistente (%, %)', v1, v2;
    END IF;

    RAISE NOTICE 'OK RN-38: default CURRENT_DATE y comportamiento STABLE (edad: %)', v1;
END;
$$;

-- Volatilidad declarada STABLE (chequeo de catalogo).
DO $$
DECLARE
    v_volatilidad TEXT;
BEGIN
    SELECT provolatile INTO v_volatilidad
      FROM pg_proc WHERE proname = 'fn_antiguedad_anios';

    IF v_volatilidad <> 's' THEN
        RAISE EXCEPTION 'RN-38 FALLO: fn_antiguedad_anios no es STABLE';
    END IF;

    RAISE NOTICE 'OK RN-38: volatilidad STABLE declarada';
END;
$$;
