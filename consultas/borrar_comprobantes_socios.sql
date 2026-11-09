-- Issue B-21: Borrar comprobantes antiguos de socios
-- Descripción: Borra comprobantes de más de cinco años asociados a clientes
-- que son socios del club, verificando previamente los registros afectados.

BEGIN;

-- 1. Pre-verificación: Listar los comprobantes antiguos de socios que serán eliminados
SELECT c.numero, c.fecha, c.cliente, c.total
FROM "Comprobante" c
JOIN "Socio" s ON s.id_cliente = c.cliente
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years';

-- 2. Ejecutar la eliminación de los comprobantes que cumplen con los criterios
DELETE FROM "Comprobante" c
WHERE c.fecha < CURRENT_DATE - INTERVAL '5 years'
  AND EXISTS (
      SELECT 1 
      FROM "Socio" s 
      WHERE s.id_cliente = c.cliente
  );

-- Confirmar transacción
COMMIT;
-- ROLLBACK;