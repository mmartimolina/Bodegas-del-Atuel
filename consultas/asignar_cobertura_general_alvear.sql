-- Issue B-15: Resolver I1 - Asignar cobertura de General Alvear
-- Descripción: Asigna la localidad 'General Alvear' al transportista que 
-- menor cantidad de ingresos haya realizado durante el último trimestre.

BEGIN;

-- 1. Determinar el transportista con menor cantidad de ingresos en el último trimestre
WITH trimestre_actual AS (
    SELECT 
        CURRENT_DATE - INTERVAL '3 months' AS fecha_inicio,
        CURRENT_DATE AS fecha_fin
),
transportista_con_menos_ingresos AS (
    SELECT t.codigo AS transportista_codigo
    FROM "Transportista" t
    LEFT JOIN "Ingreso" i ON t.codigo = i.transportista
    CROSS JOIN trimestre_actual ta
    WHERE i.fecha >= ta.fecha_inicio AND i.fecha <= ta.fecha_fin
    GROUP BY t.codigo
    ORDER BY COUNT(i.codigo) ASC
    LIMIT 1
)
-- 2. Insertar la cobertura utilizando las columnas correctas (transportista, localidad)
INSERT INTO "Transportista_Localidad" (transportista, localidad)
SELECT 
    t.transportista_codigo,
    l.id_localidad
FROM transportista_con_menos_ingresos t
CROSS JOIN "Localidad" l
WHERE l.nombre ILIKE '%General Alvear%'
ON CONFLICT DO NOTHING; -- Previene duplicados tal como exige la consigna

-- 3. Verificación de la asignación realizada
SELECT tl.transportista, t.razon_social, l.nombre AS localidad_nombre
FROM "Transportista_Localidad" tl
JOIN "Transportista" t ON tl.transportista = t.codigo
JOIN "Localidad" l ON tl.localidad = l.id_localidad
WHERE l.nombre ILIKE '%General Alvear%';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;