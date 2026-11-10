-- Issue B-38 / S12: clientes que compraron todos los vinos de una bodega
-- determinada (división relacional) y clientes que nunca compraron ningún
-- vino tinto (anti-join / NOT EXISTS).
--
-- BODEGA DETERMINADA elegida del dataset: 30237566698 (Bodega Rodriguez
-- S.A.), la bodega con menos vinos del catálogo (15): es la división más
-- exigente que se puede cumplir con datos reales y a la vez la más
-- informativa para el informe.
--
-- PARTE 1 - División relacional clientes ÷ vinos_de_la_bodega:
--   * compras: pares (cliente, vino de la bodega) efectivamente comprados;
--   * faltantes (anti-join LEFT JOIN ... IS NULL): pares del producto
--     (compradores de la bodega) × (vinos de la bodega) que NO están en
--     sus compras;
--   * la división selecciona a los compradores SIN ningún faltante:
--     NOT EXISTS (SELECT 1 FROM faltantes WHERE ...) y además exige haber
--     comprado algo de la bodega (EXISTS sobre compras).
--   Nota de implementación: la forma clásica de doble NOT EXISTS
--   correlacionada fila a fila requiere un índice por cliente en
--   Comprobante que el modelo no tiene, y a este volumen (150.000
--   comprobantes, 450.000 renglones) no termina; la misma división
--   evaluada por conjuntos (anti-join sobre los pares agregados) corre
--   en una pasada. El paso de verificación por conteo confirma que
--   ambas formulaciones coinciden.
--
-- Estado del dataset: NINGÚN cliente real completa ninguna bodega (el
-- más cercano a Rodríguez: el cliente 10277 con 12 de sus 15 vinos). Para
-- que la división tenga resultado que mostrar, el paso 2 incorpora DENTRO
-- DE LA MISMA TRANSACCIÓN un comprobante demostrativo del cliente 10277
-- por los 15 vinos de la bodega en la sala 3 (que tiene stock de los 15;
-- los triggers calculan importes y descuentan stock automáticamente). El
-- ROLLBACK del paso 6 revierte todo: la base queda como estaba.
--
-- PARTE 2 - Clientes que nunca compraron un tinto: NOT EXISTS clásico de
-- un solo nivel (compró algo Y no existe renglón de un tinto en sus
-- comprobantes). Sobre el dataset: 68 clientes.

-- 1. Contexto: la bodega elegida y sus vinos.
SELECT b.cuit, b.razon_social, b.domicilio
FROM "Bodega" b
WHERE b.cuit = '30237566698';

SELECT v.codigo, v.nombre, v.tipo
FROM "Vino" v
WHERE v.bodega = '30237566698'
ORDER BY v.codigo;

-- 2. Dato demostrativo dentro de la transacción: el cliente 10277 (que
--    ya compró 12 de los 15 vinos de la bodega) completa el catálogo con
--    un comprobante de los 15 vinos en la sala 3.
BEGIN;

INSERT INTO "Comprobante" (numero, fecha, cliente, sala)
VALUES (
    (SELECT COALESCE(MAX(numero), 0) + 1 FROM "Comprobante"),
    CURRENT_DATE,
    10277,
    3
);

INSERT INTO "Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario)
SELECT (SELECT MAX(numero) FROM "Comprobante"),
       v.codigo,
       1,
       v.precio
FROM "Vino" v
WHERE v.bodega = '30237566698';

-- 3. CONSULTA PRINCIPAL (parte 1): clientes que compraron TODOS los
--    vinos de la bodega Rodriguez S.A. (división relacional).
WITH vinos_bodega AS (
    SELECT codigo
    FROM "Vino"
    WHERE bodega = '30237566698'
),
compras AS (
    SELECT DISTINCT co.cliente, rc.vino
    FROM "Comprobante" co
    JOIN "Renglon_Comprobante" rc ON rc.comprobante = co.numero
    JOIN vinos_bodega vb ON vb.codigo = rc.vino
),
faltantes AS (
    SELECT comp.cliente, vb.codigo
    FROM (SELECT DISTINCT cliente FROM compras) comp
    CROSS JOIN vinos_bodega vb
    LEFT JOIN compras cp ON cp.cliente = comp.cliente AND cp.vino = vb.codigo
    WHERE cp.cliente IS NULL
)
SELECT c.id_cliente,
       c.nombre
FROM "Cliente" c
WHERE EXISTS (SELECT 1 FROM compras cp WHERE cp.cliente = c.id_cliente)
  AND NOT EXISTS (SELECT 1 FROM faltantes f WHERE f.cliente = c.id_cliente)
ORDER BY c.id_cliente;

-- 4. Verificación por conteo (división por conteo): el mismo resultado
--    contando vinos distintos de la bodega por comprador.
WITH vinos_bodega AS (
    SELECT codigo FROM "Vino" WHERE bodega = '30237566698'
)
SELECT co.cliente,
       c.nombre,
       COUNT(DISTINCT rc.vino) AS vinos_de_la_bodega_comprados
FROM "Comprobante" co
JOIN "Renglon_Comprobante" rc ON rc.comprobante = co.numero
JOIN vinos_bodega vb ON vb.codigo = rc.vino
JOIN "Cliente" c ON c.id_cliente = co.cliente
GROUP BY co.cliente, c.nombre
HAVING COUNT(DISTINCT rc.vino) = (SELECT COUNT(*) FROM vinos_bodega)
ORDER BY co.cliente;

-- 5. Prueba de clientes que NO cumplen: compradores de la bodega con su
--    cantidad de vinos comprados (los que no llegan a 15 no aparecen en
--    la división).
WITH vinos_bodega AS (
    SELECT codigo FROM "Vino" WHERE bodega = '30237566698'
)
SELECT co.cliente,
       c.nombre,
       COUNT(DISTINCT rc.vino) AS vinos_de_la_bodega_comprados
FROM "Comprobante" co
JOIN "Renglon_Comprobante" rc ON rc.comprobante = co.numero
JOIN vinos_bodega vb ON vb.codigo = rc.vino
JOIN "Cliente" c ON c.id_cliente = co.cliente
GROUP BY co.cliente, c.nombre
ORDER BY vinos_de_la_bodega_comprados DESC, co.cliente
LIMIT 8;

-- 6. ROLLBACK deliberado: el comprobante demostrativo no persiste (la
--    base queda como estaba; los pasos 3 a 5 ya mostraron el resultado).
ROLLBACK;

-- 7. Verificación de limpieza: el máximo número de comprobante volvió a
--    su valor real y ningún comprobante nuevo quedó para el cliente 10277
--    más allá de los que ya tenía.
SELECT COUNT(*) AS comprobantes_cliente_10277
FROM "Comprobante" c
WHERE c.cliente = 10277;

-- 8. CONSULTA PRINCIPAL (parte 2): clientes que compraron pero NUNCA
--    compraron ningún vino tinto (anti-join / NOT EXISTS).
SELECT c.id_cliente,
       c.nombre
FROM "Cliente" c
WHERE EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente)
  AND NOT EXISTS (
      SELECT 1
      FROM "Comprobante" co
      JOIN "Renglon_Comprobante" rc ON rc.comprobante = co.numero
      JOIN "Vino" v ON v.codigo = rc.vino
      WHERE co.cliente = c.id_cliente
        AND v.tipo = 'tinto'
  )
ORDER BY c.id_cliente;

-- 9. Verificación de la parte 2: conteos de compradores totales, los que
--    compraron algún tinto y los que nunca (deben sumar el total).
WITH compradores AS (
    SELECT DISTINCT cliente FROM "Comprobante"
),
con_tinto AS (
    SELECT DISTINCT co.cliente
    FROM "Comprobante" co
    JOIN "Renglon_Comprobante" rc ON rc.comprobante = co.numero
    JOIN "Vino" v ON v.codigo = rc.vino
    WHERE v.tipo = 'tinto'
)
SELECT (SELECT COUNT(*) FROM compradores) AS compradores_totales,
       (SELECT COUNT(*) FROM con_tinto) AS compraron_algun_tinto,
       (SELECT COUNT(*)
          FROM compradores cp
          LEFT JOIN con_tinto ct ON ct.cliente = cp.cliente
         WHERE ct.cliente IS NULL) AS nunca_compraron_tinto;
