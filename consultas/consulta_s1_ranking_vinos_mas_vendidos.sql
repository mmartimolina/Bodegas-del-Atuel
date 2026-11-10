-- Issue B-27 / S1: Ranking de los diez vinos con mayor cantidad de botellas
-- vendidas en toda la red de salas.
--
-- Total vendido: suma de las cantidades de los renglones de TODOS los
-- comprobantes de la red (sin filtro temporal: la consigna pide el
-- acumulado histórico de la red completa).
-- Desempate documentado: a igual cantidad de botellas, orden alfabético
-- por código de vino (resultado determinístico).
--
-- Resultado esperado sobre el dataset cargado: el primer puesto es
-- V0011 (Semillon clasico) con 17161 botellas.

-- 1. CONSULTA PRINCIPAL: ranking de los diez vinos más vendidos.
SELECT v.codigo,
       v.nombre,
       v.tipo,
       SUM(rc.cantidad) AS botellas_vendidas
FROM "Renglon_Comprobante" rc
JOIN "Vino" v ON v.codigo = rc.vino
GROUP BY v.codigo, v.nombre, v.tipo
ORDER BY botellas_vendidas DESC,
         v.codigo ASC
LIMIT 10;

-- 2. Caso de control: total de botellas vendidas en toda la red y
--    cantidad de renglones que lo componen (verifica la magnitud del
--    ranking: la suma de las diez filas no puede superar este total).
SELECT COUNT(*) AS renglones_de_venta,
       SUM(rc.cantidad) AS botellas_totales_red
FROM "Renglon_Comprobante" rc;

-- 3. Control del primer puesto con datos conocidos: botellas vendidas
--    de V0011 por propia suma de sus renglones.
SELECT SUM(rc.cantidad) AS botellas_V0011
FROM "Renglon_Comprobante" rc
WHERE rc.vino = 'V0011';
