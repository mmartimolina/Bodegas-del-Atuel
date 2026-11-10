-- Issue B-11: U3 - Incrementar 13% el precio de vinos de una bodega


BEGIN;

-- 1. Elegir de forma determinista una bodega existente y mostrar sus vinos.
SELECT v.codigo, v.nombre, v.bodega, v.precio AS precio_anterior
FROM "Vino" v
WHERE v.bodega = (SELECT cuit FROM "Bodega" ORDER BY cuit LIMIT 1)
ORDER BY v.codigo;

-- 2. Ejecutar UPDATE (Aumento del 13%)
UPDATE "Vino" v
SET precio = ROUND(v.precio * 1.13, 2)
WHERE v.bodega = (SELECT cuit FROM "Bodega" ORDER BY cuit LIMIT 1);

-- 3. Visualizar vinos y precios DESPUÉS del incremento
SELECT 
    v.codigo, 
    v.nombre, 
    v.bodega, 
    v.precio AS precio_actualizado
FROM "Vino" v
WHERE v.bodega = (SELECT cuit FROM "Bodega" ORDER BY cuit LIMIT 1)
ORDER BY v.codigo;

-- 4. Comprobar auditoría automática del trigger (RN-13)
SELECT * 
FROM "Auditoria_Precio" 
ORDER BY fecha_hora DESC 
LIMIT 5;

-- El trigger RN-13 tambien queda sujeto al rollback de esta prueba.
ROLLBACK;