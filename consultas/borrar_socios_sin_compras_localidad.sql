-- Issue B-26 / D6: borrar socios sin compras de localidad específica
-- Consigna (sección 8.3, D6): borrar los clientes socios sin compras que
-- viven en una localidad específica.
--
-- Localidad elegida del dataset: San Rafael (id_localidad 1).
--
-- Condiciones (todas obligatorias):
--   * es socio (fila en "Socio");
--   * nunca compró (sin comprobantes);
--   * vive en la localidad elegida (Cliente.localidad = 1).
-- Nota: a diferencia de D4 (B-24), acá NO se filtra por fecha de alta.
--
-- Cascadas y protecciones: igual que en D4, fk_socio_cliente es ON DELETE
-- CASCADE y fk_comprobante_cliente es ON DELETE RESTRICT (irrelevante:
-- los socios elegidos no tienen comprobantes).

BEGIN;

-- 1. Pre-verificación: socios sin compras de San Rafael (los afectados).
SELECT c.id_cliente, c.nombre, c.fecha_alta, c.localidad
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.localidad = 1
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 2. Pre-verificación de contraste: socios sin compras de OTRAS
--    localidades NO deben borrarse.
SELECT c.id_cliente, c.fecha_alta, l.nombre AS localidad
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
JOIN "Localidad" l ON l.id_localidad = c.localidad
WHERE c.localidad <> 1
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 3. Eliminación dentro de la transacción.
DELETE FROM "Cliente" c
WHERE c.localidad = 1
  AND EXISTS (SELECT 1 FROM "Socio" s WHERE s.id_cliente = c.id_cliente)
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 4. Post-verificación: no quedan socios sin compras en San Rafael.
SELECT COUNT(*) AS socios_sin_compras_san_rafael
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
WHERE c.localidad = 1
  AND NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente);

-- 5. Post-verificación de la cascada: no quedan filas de Socio huérfanas.
SELECT COUNT(*) AS socios_huerfanos
FROM "Socio" s
WHERE NOT EXISTS (SELECT 1 FROM "Cliente" c WHERE c.id_cliente = s.id_cliente);

-- 6. Post-verificación: los socios sin compras de otras localidades
--    siguen presentes.
SELECT l.nombre AS localidad, COUNT(*) AS socios_sin_compras
FROM "Cliente" c
JOIN "Socio" s ON s.id_cliente = c.id_cliente
JOIN "Localidad" l ON l.id_localidad = c.localidad
WHERE NOT EXISTS (SELECT 1 FROM "Comprobante" co WHERE co.cliente = c.id_cliente)
GROUP BY l.nombre
ORDER BY l.nombre;

-- Confirmar transacción
COMMIT;
-- ROLLBACK;
