-- Issue B-36 / S10: Rendimiento en kg por hectárea de cada parcela y
-- campaña, e identificación de las parcelas que rinden menos que el
-- promedio de su finca.
--
-- Rendimiento de una parcela en una campaña: suma de los kg cosechados
-- (Lote, que registra la cosecha por parcela y campaña) dividido por la
-- superficie de la parcela en HECTÁREAS (Parcela.superficie, en ha según
-- el diccionario de datos). Una parcela-campaña sin cosecha no tiene
-- rendimiento que calcular y no aparece.
-- Promedio de la finca: promedio de los rendimientos de las parcelas de
-- la MISMA finca en la MISMA campaña (comparación agronómicamente
-- significativa; decisión documentada).
-- Herramientas exigidas por la issue: CTE (rendimiento) + subconsulta
-- correlacionada (el promedio de la finca se calcula por fila contra el
-- CTE).
-- Sobre el dataset: 112 parcelas en 5 campañas (2021-2025), 229
-- parcela-campaña con cosecha.

-- 1. Contexto: fincas, parcelas y campañas cosechadas.
SELECT (SELECT COUNT(*) FROM "Finca") AS fincas,
       (SELECT COUNT(*) FROM "Parcela") AS parcelas,
       (SELECT COUNT(DISTINCT campania) FROM "Lote") AS campanias,
       (SELECT COUNT(*) FROM "Lote") AS lotes;

-- 2. CONSULTA PRINCIPAL: rendimiento por parcela y campaña con el
--    promedio de su finca (subconsulta correlacionada) y la diferencia.
WITH rendimiento AS (
    SELECT p.finca,
           p.n_parcela,
           l.campania,
           p.superficie,
           SUM(l.kg) AS kg_cosechados,
           ROUND(SUM(l.kg) / p.superficie, 2) AS kg_por_hectarea
    FROM "Parcela" p
    JOIN "Lote" l ON l.finca = p.finca AND l.n_parcela = p.n_parcela
    GROUP BY p.finca, p.n_parcela, l.campania, p.superficie
),
comparativa AS (
    SELECT r.*,
           (SELECT ROUND(AVG(r2.kg_por_hectarea), 2)
              FROM rendimiento r2
             WHERE r2.finca = r.finca
               AND r2.campania = r.campania) AS promedio_finca
    FROM rendimiento r
)
SELECT x.finca,
       f.nombre AS finca_nombre,
       x.n_parcela,
       x.campania,
       x.superficie,
       x.kg_cosechados,
       x.kg_por_hectarea,
       x.promedio_finca,
       ROUND(x.kg_por_hectarea - x.promedio_finca, 2) AS diferencia_con_promedio,
       CASE WHEN x.kg_por_hectarea < x.promedio_finca
            THEN 'por debajo del promedio de su finca'
            ELSE 'en o sobre el promedio de su finca' END AS comparacion
FROM comparativa x
JOIN "Finca" f ON f.id_finca = x.finca
ORDER BY x.finca, x.campania, x.n_parcela;

-- 3. CONSULTA DE IDENTIFICACIÓN: solo las parcelas-campaña que rinden
--    MENOS que el promedio de su finca (lo que pide la consigna).
WITH rendimiento AS (
    SELECT p.finca,
           p.n_parcela,
           l.campania,
           p.superficie,
           SUM(l.kg) AS kg_cosechados,
           ROUND(SUM(l.kg) / p.superficie, 2) AS kg_por_hectarea
    FROM "Parcela" p
    JOIN "Lote" l ON l.finca = p.finca AND l.n_parcela = p.n_parcela
    GROUP BY p.finca, p.n_parcela, l.campania, p.superficie
),
comparativa AS (
    SELECT r.*,
           (SELECT ROUND(AVG(r2.kg_por_hectarea), 2)
              FROM rendimiento r2
             WHERE r2.finca = r.finca
               AND r2.campania = r.campania) AS promedio_finca
    FROM rendimiento r
)
SELECT x.finca,
       f.nombre AS finca_nombre,
       x.n_parcela,
       x.campania,
       x.kg_por_hectarea,
       x.promedio_finca,
       ROUND(x.kg_por_hectarea - x.promedio_finca, 2) AS diferencia_con_promedio
FROM comparativa x
JOIN "Finca" f ON f.id_finca = x.finca
WHERE x.kg_por_hectarea < x.promedio_finca
ORDER BY x.campania, x.finca, x.n_parcela;

-- 4. Resumen de control: cuántas parcela-campaña quedaron por debajo del
--    promedio de su finca sobre el total de parcela-campaña cosechadas.
WITH rendimiento AS (
    SELECT p.finca, p.n_parcela, l.campania, p.superficie,
           ROUND(SUM(l.kg) / p.superficie, 2) AS kg_por_hectarea
    FROM "Parcela" p
    JOIN "Lote" l ON l.finca = p.finca AND l.n_parcela = p.n_parcela
    GROUP BY p.finca, p.n_parcela, l.campania, p.superficie
)
SELECT COUNT(*) AS parcela_campania_cosechadas,
       COUNT(*) FILTER (WHERE r.kg_por_hectarea <
           (SELECT AVG(r2.kg_por_hectarea) FROM rendimiento r2
             WHERE r2.finca = r.finca AND r2.campania = r.campania)) AS por_debajo_del_promedio
FROM rendimiento r;
