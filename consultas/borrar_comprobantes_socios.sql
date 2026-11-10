-- Issue B-21 / D1: Borrar comprobantes antiguos de socios
-- Consigna (sección 8.3, D1): borrar los comprobantes con más de cinco
-- años de antigüedad asociados a clientes socios del club.
--
-- Antigüedad: se calcula a partir de CURRENT_DATE (nunca con fecha fija).
-- Cascadas: la FK fk_renglon_comprobante_comprobante es ON DELETE CASCADE,
--           por lo que los renglones se borran junto con su cabecera.
--           Además, el trigger trg_renglon_comprobante_stock (RN-09) repone
--           el stock de la sala por cada renglón eliminado: borrar un
--           comprobante devuelve las botellas vendidas al stock de la sala.

BEGIN;

-- 1. Pre-verificación: comprobantes de socios con más de 5 años que serán eliminados
SELECT c.numero, c.fecha, c.cliente, c.total
FROM "Comprobante" c
JOIN "Socio" s ON s.id_cliente = c.cliente
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years';

-- 2. Pre-verificación de la cascada: renglones que se borrarán junto a las cabeceras
SELECT COUNT(*) AS renglones_afectados
FROM "Renglon_Comprobante" rc
JOIN "Comprobante" c ON c.numero = rc.comprobante
JOIN "Socio" s ON s.id_cliente = c.cliente
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years';

-- 3. Eliminación dentro de la transacción
DELETE FROM "Comprobante" c
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years'
  AND EXISTS (
      SELECT 1
      FROM "Socio" s
      WHERE s.id_cliente = c.cliente
  );

-- 4. Post-verificación de la cascada: no quedan renglones huérfanos
--    (la FK con ON DELETE CASCADE garantiza que cada renglón borrado
--     tenía su cabecera en el DELETE; este conteo debe dar 0)
SELECT COUNT(*) AS renglones_huerfanos
FROM "Renglon_Comprobante" rc
WHERE NOT EXISTS (
    SELECT 1 FROM "Comprobante" c WHERE c.numero = rc.comprobante
);

-- 5. Post-verificación: ya no existen comprobantes de socios con más de 5 años
SELECT COUNT(*) AS comprobantes_antiguos_restantes
FROM "Comprobante" c
JOIN "Socio" s ON s.id_cliente = c.cliente
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;
