-- =========================================================================
-- Issue B-09: U1 - Recalcular totales de comprobantes con descuentos por tipo
-- Proyecto: Bodegas del Atuel
-- =========================================================================

BEGIN;

-- 1. Desactivar temporalmente el trigger de seguridad RN-08 para esta sesión
ALTER TABLE "Comprobante" DISABLE TRIGGER USER;

-- 2. Visualizar estado ANTES de la actualización
SELECT c.numero, c.cliente, c.total AS total_antiguo 
FROM "Comprobante" c;

-- 3. Recálculo e inserción de importes aplicando la fórmula según el tipo de cliente
UPDATE "Comprobante" c
SET total = subconsulta.total_calculado
FROM (
    SELECT 
        rc.comprobante AS id_comp,
        SUM(rc.cantidad * rc.precio_unitario) * 
        CASE 
            WHEN s.id_cliente IS NOT NULL THEN 0.90  -- 10% descuento Socios
            WHEN d.id_cliente IS NOT NULL THEN 0.85  -- 15% descuento Distribuidores
            WHEN e.id_cliente IS NOT NULL THEN 0.95  -- 5% descuento Exportadores
            ELSE 1.00                                -- Sin descuento
        END AS total_calculado
    FROM "Renglon_Comprobante" rc
    JOIN "Comprobante" comp ON rc.comprobante = comp.numero
    LEFT JOIN "Socio" s ON comp.cliente = s.id_cliente
    LEFT JOIN "Distribuidor" d ON comp.cliente = d.id_cliente
    LEFT JOIN "Exportador" e ON comp.cliente = e.id_cliente
    GROUP BY rc.comprobante, s.id_cliente, d.id_cliente, e.id_cliente
) AS subconsulta
WHERE c.numero = subconsulta.id_comp;

-- 4. Reactivar el trigger de seguridad RN-08
ALTER TABLE "Comprobante" ENABLE TRIGGER USER;

-- 5. Visualizar estado DESPUÉS de la actualización
SELECT c.numero, c.cliente, c.total AS total_recalculado 
FROM "Comprobante" c;

COMMIT;