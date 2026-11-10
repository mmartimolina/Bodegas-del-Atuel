-- Issue B-17 / I3: crear comprobante con exactamente tres renglones.
-- Bloquea la tabla para asignar el siguiente numero sin colisiones concurrentes.

BEGIN;

LOCK TABLE "Comprobante" IN EXCLUSIVE MODE;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "Cliente") THEN
        RAISE EXCEPTION 'I3: se requiere al menos un cliente.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM "Sala" WHERE id_sala = 1) THEN
        RAISE EXCEPTION 'I3: no existe la sala 1.';
    END IF;
    IF (
        SELECT COUNT(*)
        FROM "Vino" v
        JOIN "Stock_Sala" ss ON ss.vino = v.codigo
        WHERE ss.sala = 1 AND ss.cantidad >= 2
    ) < 3 THEN
        RAISE EXCEPTION 'I3: se requieren tres vinos distintos con stock suficiente en sala 1.';
    END IF;
END;
$$;

INSERT INTO "Comprobante" (numero, fecha, cliente, sala)
VALUES (
    (SELECT COALESCE(MAX(numero), 0) + 1 FROM "Comprobante"),
    CURRENT_DATE,
    (SELECT id_cliente FROM "Cliente" ORDER BY id_cliente LIMIT 1),
    1
);

INSERT INTO "Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario)
SELECT (SELECT MAX(numero) FROM "Comprobante"),
       v.codigo,
       2,
       v.precio
FROM "Vino" v
JOIN "Stock_Sala" ss ON ss.vino = v.codigo
WHERE ss.sala = 1
  AND ss.cantidad >= 2
ORDER BY v.codigo
LIMIT 3;

DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM "Renglon_Comprobante"
        WHERE comprobante = (SELECT MAX(numero) FROM "Comprobante")
    ) <> 3 THEN
        RAISE EXCEPTION 'I3: el comprobante no tiene exactamente tres renglones.';
    END IF;
END;
$$;

SELECT numero, fecha, cliente, sala, subtotal, descuento, total
FROM "Comprobante"
WHERE numero = (SELECT MAX(numero) FROM "Comprobante");

SELECT comprobante, vino, cantidad, precio_unitario, descuento, subtotal
FROM "Renglon_Comprobante"
WHERE comprobante = (SELECT MAX(numero) FROM "Comprobante")
ORDER BY vino;

COMMIT;
