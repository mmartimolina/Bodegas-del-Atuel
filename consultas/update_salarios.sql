-- Issue B-10: U2 - Aumentar 20% el salario por antigüedad (> 5 años)

BEGIN;

-- 1. Visualizar empleados y salarios ANTES de la actualización (antigüedad > 5 años)
SELECT 
    e.id_empleado AS empleado, 
    e.nombre, 
    e.fecha_ingreso, 
    AGE(CURRENT_DATE, e.fecha_ingreso) AS antiguedad,
    e.salario AS salario_antiguo
FROM "Empleado" e
WHERE AGE(CURRENT_DATE, e.fecha_ingreso) > INTERVAL '5 years';

-- 2. Ejecución del UPDATE masivo (Aumento del 20%)
UPDATE "Empleado"
SET salario = salario * 1.20
WHERE AGE(CURRENT_DATE, fecha_ingreso) > INTERVAL '5 years';

-- 3. Visualizar empleados y salarios DESPUÉS de la actualización para verificar filas afectadas
SELECT 
    e.id_empleado AS empleado, 
    e.nombre, 
    e.salario AS salario_actualizado
FROM "Empleado" e
WHERE AGE(CURRENT_DATE, e.fecha_ingreso) > INTERVAL '5 years';

-- Descomentar COMMIT para confirmar los cambios definitivamente, o ROLLBACK para cancelar:
 COMMIT;
-- ROLLBACK;