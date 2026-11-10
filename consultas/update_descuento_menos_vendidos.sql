-- Issue B-13: U5 - 15% de descuento a los diez vinos menos vendidos


BEGIN;

-- 1. Visualizar los vinos menos vendidos ANTES del descuento
SELECT v.codigo, v.nombre, v.precio, 
       COALESCE(SUM(r.cantidad), 0) AS total_vendido
FROM "Vino" v
LEFT JOIN "Renglon_Comprobante" r ON v.codigo = r.vino
GROUP BY v.codigo, v.nombre, v.precio
ORDER BY total_vendido ASC, v.codigo ASC
LIMIT 10;

-- 2. Aplicar el 15% de descuento a los 10 vinos seleccionados
UPDATE "Vino"
SET precio = ROUND(precio * 0.85, 2)
WHERE codigo IN (
    SELECT v.codigo
    FROM "Vino" v
    LEFT JOIN "Renglon_Comprobante" r ON v.codigo = r.vino
    GROUP BY v.codigo
    ORDER BY COALESCE(SUM(r.cantidad), 0) ASC, v.codigo ASC
    LIMIT 10
);

-- 3. Verificar los precios actualizados DESPUÉS del descuento
SELECT v.codigo, v.nombre, v.precio
FROM "Vino" v
WHERE v.codigo IN (
    SELECT v.codigo
    FROM "Vino" v
    LEFT JOIN "Renglon_Comprobante" r ON v.codigo = r.vino
    GROUP BY v.codigo
    ORDER BY COALESCE(SUM(r.cantidad), 0) ASC, v.codigo ASC
    LIMIT 10
);

-- 4. Consultar la auditoría de precios generada (sin forzar el nombre de columna de fecha)
SELECT * FROM "Auditoria_Precio"
LIMIT 10;

ROLLBACK;