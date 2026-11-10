-- Issue B-37 / S11: Ranking de vinos dentro de cada sala por botellas
-- vendidas, y ventas acumuladas mensuales por sala.
-- Herramientas exigidas por la consigna: RANK() OVER (PARTITION BY ...)
-- y suma acumulada con ventana.
--
-- Parte 1 (RANK): el ranking de vinos se calcula por sala con
-- RANK() OVER (PARTITION BY sala ORDER BY botellas DESC): el puesto se
-- REINICIA en cada sala (partición) y los empates de botellas comparten
-- puesto (semántica de RANK, a diferencia de ROW_NUMBER; por eso una
-- sala puede mostrar más de cinco filas si hay empates en el corte).
-- Para un informe legible se muestran los primeros cinco puestos de
-- cada sala; el ranking se computa sobre TODOS los vinos vendidos en la
-- sala (histórico completo de la red).
--
-- Parte 2 (ventana acumulada): ventas acumuladas mensuales por sala
-- usando la VISTA v_ventas_mensuales_sala (migración 011_vistas.sql) y
-- SUM(...) OVER (PARTITION BY sala ORDER BY anio_mes ROWS BETWEEN
-- UNBOUNDED PRECEDING AND CURRENT ROW): el acumulado respeta el orden
-- temporal desde el PRIMER mes del histórico (2023-11). Para un informe
-- legible se muestran los últimos 6 meses (período móvil); el filtro se
-- aplica FUERA de la ventana para no truncar el acumulado.

-- 1. CONSULTA PRINCIPAL (parte 1): ranking de vinos por sala (primeros
--    cinco puestos de cada sala).
WITH ventas_sala_vino AS (
    SELECT c.sala,
           rc.vino,
           SUM(rc.cantidad) AS botellas
    FROM "Comprobante" c
    JOIN "Renglon_Comprobante" rc ON rc.comprobante = c.numero
    GROUP BY c.sala, rc.vino
),
ranking AS (
    SELECT sala,
           vino,
           botellas,
           RANK() OVER (PARTITION BY sala ORDER BY botellas DESC) AS ranking
    FROM ventas_sala_vino
)
SELECT r.sala,
       r.vino,
       v.nombre,
       r.botellas,
       r.ranking
FROM ranking r
JOIN "Vino" v ON v.codigo = r.vino
WHERE r.ranking <= 5
ORDER BY r.sala, r.ranking, r.vino;

-- 2. CONSULTA PRINCIPAL (parte 2): ventas mensuales por sala con el
--    acumulado histórico (últimos 6 meses; el acumulado arranca en el
--    primer mes del histórico).
WITH acumulado AS (
    SELECT sala,
           anio_mes,
           comprobantes,
           unidades_vendidas,
           importe_neto,
           SUM(importe_neto) OVER (
               PARTITION BY sala
               ORDER BY anio_mes
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS importe_acumulado
    FROM v_ventas_mensuales_sala
)
SELECT sala,
       anio_mes,
       comprobantes,
       unidades_vendidas,
       importe_neto,
       importe_acumulado
FROM acumulado
WHERE anio_mes >= to_char(CURRENT_DATE - INTERVAL '6 months', 'YYYY-MM')
ORDER BY sala, anio_mes;

-- 3. Verificación del reinicio del ranking por sala: máximo y mínimo
--    puesto presente en cada partición (el 1 es el mínimo de todas).
SELECT sala,
       MIN(ranking) AS mejor_puesto,
       MAX(ranking) AS ultimo_puesto,
       COUNT(*) AS vinos_rankeados
FROM (
    SELECT sala,
           RANK() OVER (PARTITION BY sala ORDER BY SUM(rc.cantidad) DESC) AS ranking
    FROM "Comprobante" c
    JOIN "Renglon_Comprobante" rc ON rc.comprobante = c.numero
    GROUP BY c.sala, rc.vino
) t
GROUP BY sala
ORDER BY sala;

-- 4. Verificación del orden temporal del acumulado: para una sala de
--    ejemplo (la 1), el acumulado del último mes mostrado debe igualar
--    el importe neto histórico completo de esa sala.
SELECT SUM(importe_neto) AS importe_neto_historico_sala_1
FROM v_ventas_mensuales_sala
WHERE sala = 1;
