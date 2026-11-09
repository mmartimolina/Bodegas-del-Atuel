-- Issue B-20: Crear ingreso en confección por 120 botellas
-- Descripción: Crea un ingreso en estado 'en_confeccion' con 120 botellas
-- de un vino determinado, utilizando bodega y transportista existentes.

BEGIN;

-- 1. Insertar la cabecera del ingreso en estado 'en_confeccion'
INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen)
VALUES (
    'ING-2026-001',
    CURRENT_DATE,
    'en_confeccion',
    (SELECT codigo FROM "Transportista" LIMIT 1),
    (SELECT cuit FROM "Bodega" LIMIT 1)
);

-- 2. Insertar el renglón de ingreso con 120 botellas de un vino existente
INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad)
VALUES (
    'ING-2026-001',
    (SELECT codigo FROM "Vino" LIMIT 1),
    120
);

-- 3. Verificación de la cabecera y su estado inicial
SELECT codigo, fecha, estado, transportista, bodega_origen
FROM "Ingreso"
WHERE codigo = 'ING-2026-001';

-- 4. Verificación del renglón asociado
SELECT ingreso, vino, cantidad
FROM "Renglon_Ingreso"
WHERE ingreso = 'ING-2026-001';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;