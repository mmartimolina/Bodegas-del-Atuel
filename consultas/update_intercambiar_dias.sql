-- Issue B-12: U4 - Intercambiar días de cierre (Lunes <-> Miércoles)

BEGIN;

-- 1. Visualizar estado ANTES del intercambio
SELECT id_sala, calle, numero, dia_cierre FROM "Sala" ORDER BY id_sala;

-- 2. Ejecutar UPDATE en una sola sentencia usando CASE para evitar sobreescritura
UPDATE "Sala"
SET dia_cierre = CASE 
    WHEN dia_cierre = 'Lunes' THEN 'Miercoles'
    WHEN dia_cierre = 'Miercoles' THEN 'Lunes'
    ELSE dia_cierre
END
WHERE dia_cierre IN ('Lunes', 'Miercoles');

-- 3. Visualizar estado DESPUÉS del intercambio
SELECT id_sala, calle, numero, dia_cierre FROM "Sala" ORDER BY id_sala;

ROLLBACK;