-- Issue B-34 / S8: Monto total de ventas por sala en el último trimestre,
-- en orden descendente.
--
-- Trimestre relativo a CURRENT_DATE: ventana móvil de tres meses
-- (fecha >= CURRENT_DATE - INTERVAL '3 months'), nunca fechas fijas.
-- Monto según el modelo aprobado: el Comprobante mantiene los importes
-- calculados por los triggers a partir de los renglones
-- (subtotal = suma de renglones, total = subtotal - descuento), por lo
-- que el monto por sala es SUM(Comprobante.total) de sus comprobantes
-- del período. Se incluyen TODAS las salas (LEFT JOIN): la sala 25
-- (creada por insertar_sala.sql) sin ventas figura con monto 0.
-- Desempate documentado: a igual monto, menor id_sala primero.

-- 1. CONSULTA PRINCIPAL: monto total de ventas por sala en el último
--    trimestre, en orden descendente.
SELECT s.id_sala,
       s.calle,
       s.numero,
       l.nombre AS localidad,
       COUNT(c.numero) AS comprobantes,
       COALESCE(SUM(c.total), 0) AS monto_total
FROM "Sala" s
LEFT JOIN "Comprobante" c ON c.sala = s.id_sala
                        AND c.fecha >= CURRENT_DATE - INTERVAL '3 months'
LEFT JOIN "Localidad" l ON l.id_localidad = s.localidad
GROUP BY s.id_sala, s.calle, s.numero, l.nombre
ORDER BY monto_total DESC,
         s.id_sala ASC;

-- 2. Caso de control: totales globales del período. La suma de la
--    columna monto_total del paso 1 debe igualar monto_total acá.
SELECT COUNT(*) AS comprobantes_del_trimestre,
       SUM(subtotal) AS suma_subtotales,
       SUM(descuento) AS suma_descuentos,
       SUM(total) AS monto_total_del_trimestre
FROM "Comprobante"
WHERE fecha >= CURRENT_DATE - INTERVAL '3 months';

-- 3. Caso de control cruzado para la sala líder: reconstrucción del monto
--    desde los renglones. El subtotal del renglón es el importe NETO de la
--    línea (el trigger del renglón aplica el descuento del cliente y deja
--    registrado el porcentaje en la propia fila), por lo que la suma de
--    los subtotales de los renglones de la sala iguala exactamente
--    SUM(Comprobante.total); en la cabecera, además, se cumple
--    total = subtotal - descuento (el paso 2 lo verifica globalmente).
WITH lider AS (
    SELECT c.sala,
           SUM(c.total) AS monto_total
    FROM "Comprobante" c
    WHERE c.fecha >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY c.sala
    ORDER BY SUM(c.total) DESC
    LIMIT 1
)
SELECT li.sala,
       li.monto_total,
       (SELECT SUM(rc.subtotal)
          FROM "Renglon_Comprobante" rc
          JOIN "Comprobante" c ON c.numero = rc.comprobante
         WHERE c.sala = li.sala
           AND c.fecha >= CURRENT_DATE - INTERVAL '3 months') AS suma_subtotal_renglones,
       (SELECT SUM(c2.descuento)
          FROM "Comprobante" c2
         WHERE c2.sala = li.sala
           AND c2.fecha >= CURRENT_DATE - INTERVAL '3 months') AS suma_descuentos
FROM lider li;
