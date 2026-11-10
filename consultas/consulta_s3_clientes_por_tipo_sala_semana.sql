-- Issue B-29 / S3: Cantidad de clientes de cada tipo que compraron en una
-- sala determinada en la última semana.
--
-- Sala determinada elegida del dataset: sala 20 (Diagonal 5 7488, General
-- Alvear), la sala con más comprobantes de la última semana (el paso 1
-- muestra la elección con datos).
-- "Última semana": ventana móvil de 7 días desde CURRENT_DATE
-- (fecha >= CURRENT_DATE - 7), nunca fechas fijas.
-- "Cliente de cada tipo": Cliente es un supertipo con tres subtipos
-- disjuntos (Socio, Distribuidor, Exportador; el paso 2 verifica la
-- disjointness: la suma de subtipos iguala el total de clientes).
-- Un cliente que compró varias veces en la semana cuenta UNA sola vez:
-- el CTE toma DISTINCT cliente antes de clasificar por tipo.

-- 1. Contexto: elección de la sala (comprobantes de la última semana por sala).
SELECT c.sala,
       COUNT(*) AS comprobantes_ultima_semana
FROM "Comprobante" c
WHERE c.fecha >= CURRENT_DATE - 7
GROUP BY c.sala
ORDER BY comprobantes_ultima_semana DESC
LIMIT 5;

-- 2. Contexto: la sala elegida y verificación de subtipos disjuntos.
SELECT s.id_sala, s.calle, s.numero, s.dia_cierre, l.nombre AS localidad
FROM "Sala" s
JOIN "Localidad" l ON l.id_localidad = s.localidad
WHERE s.id_sala = 20;

SELECT (SELECT COUNT(*) FROM "Cliente") AS clientes_totales,
       (SELECT COUNT(*) FROM "Socio") AS socios,
       (SELECT COUNT(*) FROM "Distribuidor") AS distribuidores,
       (SELECT COUNT(*) FROM "Exportador") AS exportadores;

-- 3. CONSULTA PRINCIPAL: compradores de la sala 20 en la última semana,
--    contados por tipo de cliente.
WITH compradores AS (
    SELECT DISTINCT c.cliente
    FROM "Comprobante" c
    WHERE c.sala = 20
      AND c.fecha >= CURRENT_DATE - 7
)
SELECT t.tipo_cliente,
       COUNT(*) AS cantidad_clientes
FROM compradores cp
JOIN (
    SELECT id_cliente, 'socio' AS tipo_cliente FROM "Socio"
    UNION ALL
    SELECT id_cliente, 'distribuidor' AS tipo_cliente FROM "Distribuidor"
    UNION ALL
    SELECT id_cliente, 'exportador' AS tipo_cliente FROM "Exportador"
) t ON t.id_cliente = cp.cliente
GROUP BY t.tipo_cliente
ORDER BY cantidad_clientes DESC, t.tipo_cliente;

-- 4. Prueba de no duplicación: compradores con más de un comprobante en
--    la sala/semana (siguen contando una sola vez en el paso 3).
SELECT c.cliente,
       COUNT(*) AS comprobantes
FROM "Comprobante" c
WHERE c.sala = 20
  AND c.fecha >= CURRENT_DATE - 7
GROUP BY c.cliente
HAVING COUNT(*) > 1
ORDER BY comprobantes DESC, c.cliente;

-- 5. Verificación: el total por tipos del paso 3 debe igualar la cantidad
--    de compradores distintos de la sala/semana.
SELECT COUNT(DISTINCT cliente) AS compradores_distintos
FROM "Comprobante" c
WHERE c.sala = 20
  AND c.fecha >= CURRENT_DATE - 7;
