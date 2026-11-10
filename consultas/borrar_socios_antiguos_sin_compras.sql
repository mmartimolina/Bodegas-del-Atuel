-- Issue B-24 / D4: borrar socios antiguos sin compras
-- Consigna (sección 8.3, D4): borrar los clientes socios que nunca
-- compraron y se dieron de alta hace más de 5 años.
--
-- Condiciones (todas obligatorias):
--   * es socio: existe su fila en "Socio";
--   * nunca compró: no tiene comprobantes;
--   * alta antigua: fecha_alta < CURRENT_DATE - 5 años (nunca fecha fija).
--
-- Cascadas y protecciones:
--   * fk_socio_cliente es ON DELETE CASCADE: borrar el Cliente arrastra
--     su fila de Socio.
--   * fk_comprobante_cliente es ON DELETE RESTRICT: como el borrado
--     filtra socios SIN comprobantes, ninguna venta lo bloquea.
--   * El trigger diferido trg_socio_descuento_final (RN-06) tolera el
--     borrado: fn_cliente_validar_descuento_final_id comprueba si el
--     cliente sigue existiendo y no valida los ya eliminados.

BEGIN;

-- 1. Pre-verificación: socios afectados (nunca compraron y alta con más
--    de 5 años). En el dataset actual son 8 clientes.
SELECT c.id_cliente, c.nombre, c.fecha_alta, c.localidad
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.fecha_alta < CURRENT_DATE - INTERVAL '5 years'
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 2. Pre-verificación de contraste: socios sin compras pero con alta
--    reciente (menos de 5 años) NO deben borrarse.
SELECT c.id_cliente, c.nombre, c.fecha_alta
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.fecha_alta >= CURRENT_DATE - INTERVAL '5 years'
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 3. Eliminación dentro de la transacción.
DELETE FROM "Cliente" c
WHERE c.fecha_alta < CURRENT_DATE - INTERVAL '5 years'
  AND EXISTS (SELECT 1 FROM "Socio" s WHERE s.id_cliente = c.id_cliente)
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 4. Post-verificación: no quedan socios sin compras con más de 5 años
--    de alta.
SELECT COUNT(*) AS socios_antiguos_sin_compras_restantes
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.fecha_alta < CURRENT_DATE - INTERVAL '5 years'
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 5. Post-verificación de la cascada: no quedan filas de Socio huérfanas.
SELECT COUNT(*) AS socios_huerfanos
FROM "Socio" s
WHERE NOT EXISTS (SELECT 1 FROM "Cliente" c WHERE c.id_cliente = s.id_cliente);

-- 6. Post-verificación: los socios sin compras de alta reciente (paso 2)
--    siguen presentes.
SELECT COUNT(*) AS socios_recientes_sin_compras
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.fecha_alta >= CURRENT_DATE - INTERVAL '5 years'
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- Confirmar transacción
COMMIT;
-- ROLLBACK;
