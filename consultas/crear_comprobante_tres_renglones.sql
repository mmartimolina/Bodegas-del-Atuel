-- Issue B-17: Crear comprobante con tres renglones
-- Descripción: Crea un comprobante para un cliente dado en la sala ID 1,
-- con tres renglones, dentro de una transacción y usando funciones automáticas.

BEGIN;

-- 1. Insertar la cabecera del comprobante para el primer cliente disponible y sala ID 1
INSERT INTO "Comprobante" (numero, fecha, cliente, sala)
VALUES (
    (SELECT COALESCE(MAX(numero), 0) + 1 FROM "Comprobante"),
    CURRENT_DATE,
    (SELECT id_cliente FROM "Cliente" LIMIT 1),
    1
);

-- 2. Insertar 3 renglones tomando 3 vinos que tengan stock suficiente en la Sala 1.
INSERT INTO "Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario)
SELECT 
    (SELECT MAX(numero) FROM "Comprobante"),
    v.codigo,
    2 AS cantidad,               -- Cantidad de prueba
    v.precio AS precio_unitario  -- Precio obtenido de la tabla "Vino"
FROM "Vino" v
JOIN "Stock_Sala" ss ON ss.vino = v.codigo
WHERE ss.sala = 1 
  AND ss.cantidad >= 2
LIMIT 3;

-- 3. Verificación de la cabecera del comprobante creado y sus totales
SELECT numero, fecha, cliente, sala, subtotal, descuento, total
FROM "Comprobante"
WHERE numero = (SELECT MAX(numero) FROM "Comprobante");

-- 4. Verificación de los renglones asociados
SELECT comprobante, vino, cantidad, precio_unitario, descuento, subtotal
FROM "Renglon_Comprobante"
WHERE comprobante = (SELECT MAX(numero) FROM "Comprobante");

-- Confirmar transacción
COMMIT;
-- ROLLBACK;