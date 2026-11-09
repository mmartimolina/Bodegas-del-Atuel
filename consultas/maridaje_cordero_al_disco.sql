-- Issue B-16: Crear y asociar maridaje "Cordero al disco"
-- Descripción: Si existe algún vino tinto con graduación de 14° o más, 
-- crea el maridaje «Cordero al disco» y lo asocia a todos los vinos que 
-- cumplan la condición.

BEGIN;

-- 1. Insertar el maridaje solo si existe al menos un vino tinto con graduación >= 14
-- y asegurando que el maridaje no exista previamente en la tabla.
INSERT INTO "Maridaje" (nombre)
SELECT 'Cordero al disco'
WHERE EXISTS (
    SELECT 1 
    FROM "Vino" v
    WHERE v.tipo ILIKE '%tinto%' 
      AND v.graduacion >= 14.0
)
AND NOT EXISTS (
    SELECT 1 
    FROM "Maridaje" m 
    WHERE m.nombre ILIKE 'Cordero al disco'
);

-- 2. Asociar el maridaje "Cordero al disco" a todos los vinos tintos con graduación >= 14
INSERT INTO "Vino_Maridaje" (vino, maridaje)
SELECT v.codigo, m.id
FROM "Vino" v
CROSS JOIN "Maridaje" m
WHERE m.nombre ILIKE 'Cordero al disco'
  AND v.tipo ILIKE '%tinto%'
  AND v.graduacion >= 14.0
ON CONFLICT DO NOTHING; -- Previene duplicados en la clave primaria compuesta (vino, maridaje)

-- 3. Verificación de los resultados obtenidos
SELECT v.codigo AS vino_codigo, v.nombre AS vino_nombre, v.graduacion, m.nombre AS maridaje_nombre
FROM "Vino_Maridaje" vm
JOIN "Vino" v ON vm.vino = v.codigo
JOIN "Maridaje" m ON vm.maridaje = m.id
WHERE m.nombre ILIKE 'Cordero al disco';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;