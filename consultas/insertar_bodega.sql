-- Issue B-18: Insertar una nueva bodega
-- Descripción: Incorpora una nueva bodega con datos ficticios válidos,
-- previniendo duplicados y verificando su correcta inserción.

BEGIN;

-- 1. Insertar una nueva bodega con CUIT de 11 dígitos sin guiones
INSERT INTO "Bodega" (cuit, razon_social, domicilio)
VALUES (
    '30712345678', 
    'Bodega Los Cerros S.A.', 
    'Ruta Nacional 143 Km 420, San Rafael'
)
ON CONFLICT (cuit) DO NOTHING; -- Evita errores si se ejecuta más de una vez

-- 2. Verificación del registro incorporado
SELECT cuit, razon_social, domicilio
FROM "Bodega"
WHERE cuit = '30712345678';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;