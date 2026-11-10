-- Issue B-11: U3 - Incrementar 13% el precio de vinos de una bodega


BEGIN;

-- 1. Visualizar vinos y precios ANTES del incremento para la Bodega Atuel S.A.
SELECT 
    v.codigo, 
    v.nombre, 
    v.bodega, 
    v.precio AS precio_anterior
FROM "Vino" v
WHERE v.bodega = '30112233449';

-- 2. Ejecutar UPDATE (Aumento del 13%)
UPDATE "Vino"
SET precio = ROUND(precio * 1.13, 2)
WHERE bodega = '30112233449';

-- 3. Visualizar vinos y precios DESPUÉS del incremento
SELECT 
    v.codigo, 
    v.nombre, 
    v.bodega, 
    v.precio AS precio_actualizado
FROM "Vino" v
WHERE v.bodega = '30112233449';

-- 4. Comprobar auditoría automática del trigger (RN-13)
SELECT * 
FROM "Auditoria_Precio" 
ORDER BY fecha_hora DESC 
LIMIT 5;

-- Confirmar los cambios definitivamente:
COMMIT;
-- ROLLBACK;