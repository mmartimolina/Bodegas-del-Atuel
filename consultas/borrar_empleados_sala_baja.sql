-- Issue B-23 / D3: eliminar empleados de sala dada de baja
-- Consigna (sección 8.3, D3): la sala de una localidad determinada fue
-- dada de baja: eliminar los empleados de esa sala que trabajaron menos
-- de dos años.
--
-- Sala concreta elegida del dataset: sala 19 (Av. 8 3958, San Rafael,
-- localidad 1). Escenario: la sala fue dada de baja y se libera al
-- personal con menos de dos años de antigüedad; el personal más antiguo
-- permanece para ser reasignado a otras salas.
--
-- Antigüedad: se calcula con la función del esquema
-- fn_antiguedad_anios(fecha_ingreso) (años cumplidos respecto de
-- CURRENT_DATE), nunca con fechas fijas.
--
-- Estado del dataset: los 120 empleados tienen 2 o más años de antigüedad
-- (el ingreso más reciente es del 2024-10-09), por lo que dentro de la
-- misma transacción se incorporan DOS empleados demostrativos en la sala
-- 19: uno con 1 año de antigüedad (debe eliminarse) y otro con 4 años
-- cumplidos (debe permanecer, para demostrar que el filtro no se pasa de
-- largo). El veterano demostrativo se retira al final (paso 7) para no
-- dejar datos de prueba en la base.

BEGIN;

-- 1. Pre-verificación: empleados actuales de la sala 19 con su antigüedad.
SELECT e.id_empleado, e.nombre, e.fecha_ingreso,
       fn_antiguedad_anios(e.fecha_ingreso) AS antiguedad_anios
FROM "Empleado" e
WHERE e.sala = 19
ORDER BY e.fecha_ingreso DESC;

-- 2. Empleados demostrativos de la sala 19 (dentro de la transacción):
--    uno con 1 año de antigüedad y otro con alta hace 5 años (4 años
--    cumplidos: no alcanza el quinto aniversario hasta mañana).
INSERT INTO "Empleado" (cuit, nombre, fecha_ingreso, salario, sala)
VALUES
    ('99999999901', 'Empleado Demo Joven (sala 19 dada de baja)',
     CURRENT_DATE - 365, 350000.00, 19),
    ('99999999902', 'Empleado Demo Veterano (sala 19 dada de baja)',
     CURRENT_DATE - 1825, 480000.00, 19);

-- 3. Pre-verificación del conjunto afectado: empleados de la sala 19 con
--    menos de 2 años. Debe incluir SOLO al demostrativo joven.
SELECT e.id_empleado, e.nombre, e.fecha_ingreso,
       fn_antiguedad_anios(e.fecha_ingreso) AS antiguedad_anios
FROM "Empleado" e
WHERE e.sala = 19
  AND fn_antiguedad_anios(e.fecha_ingreso) < 2;

-- 4. Eliminación dentro de la transacción: solo empleados de la sala 19
--    con menos de dos años de antigüedad.
DELETE FROM "Empleado" e
WHERE e.sala = 19
  AND fn_antiguedad_anios(e.fecha_ingreso) < 2;

-- 5. Post-verificación: el joven fue eliminado y el veterano permanece
--    junto a los 7 empleados originales de la sala.
SELECT e.nombre, e.fecha_ingreso,
       fn_antiguedad_anios(e.fecha_ingreso) AS antiguedad_anios
FROM "Empleado" e
WHERE e.sala = 19
ORDER BY e.fecha_ingreso DESC;

-- 6. Post-verificación adicional: los empleados de OTRAS salas no fueron
--    afectados (siguen siendo 120).
SELECT COUNT(*) AS empleados_otros_total
FROM "Empleado" e
WHERE e.sala <> 19;

-- 7. Limpieza del dato demostrativo veterano (fuera del alcance del
--    borrado pedido por la consigna: solo se retira para no dejar datos
--    de prueba en la base).
DELETE FROM "Empleado"
WHERE cuit IN ('99999999901', '99999999902');

-- 8. Verificación final: la sala 19 queda exactamente con sus 7
--    empleados originales.
SELECT COUNT(*) AS empleados_sala_19 FROM "Empleado" WHERE sala = 19;

-- Confirmar transacción
COMMIT;
-- ROLLBACK;
