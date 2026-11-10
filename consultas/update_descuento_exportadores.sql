-- Issue B-14: U6 - Descuento de exportadores con más de tres permisos
-- Criterio / Decisión documentada (Ambigüedad RN-06/U6):
-- Se establece el descuento absoluto al 35.00% para aquellos exportadores 
-- que posean estrictamente más de 3 permisos de exportación registrados.

BEGIN;

-- 1. Visualizar los exportadores con más de 3 permisos ANTES de actualizar
SELECT e.id_cliente, e.pais, c.descuento, COUNT(p.*) AS total_permisos
FROM "Exportador" e
JOIN "Cliente" c ON e.id_cliente = c.id_cliente
JOIN "Permiso_Exportacion" p ON e.id_cliente = p.exportador
GROUP BY e.id_cliente, e.pais, c.descuento
HAVING COUNT(p.*) > 3;

-- 2. Recalcular el descuento derivado de acuerdo con RN-06/U6.
UPDATE "Cliente"
SET descuento = fn_descuento_cliente(id_cliente)
WHERE id_cliente IN (
    SELECT e.id_cliente
    FROM "Exportador" e
    JOIN "Permiso_Exportacion" p ON e.id_cliente = p.exportador
    GROUP BY e.id_cliente
    HAVING COUNT(p.*) > 3
);

-- 3. Verificar los cambios DESPUÉS de la actualización
SELECT c.id_cliente, c.descuento, e.pais
FROM "Cliente" c
JOIN "Exportador" e ON c.id_cliente = e.id_cliente
WHERE c.id_cliente IN (
    SELECT e.id_cliente
    FROM "Exportador" e
    JOIN "Permiso_Exportacion" p ON e.id_cliente = p.exportador
    GROUP BY e.id_cliente
    HAVING COUNT(p.*) > 3
);

ROLLBACK;