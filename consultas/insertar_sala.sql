-- Issue B-19: Insertar una nueva sala de venta
-- Descripción: Inserta una nueva sala ubicada en una localidad existente,
-- cumpliendo con la clave foránea y verificando su correcta incorporación.

BEGIN;

-- 1. Insertar una nueva sala vinculada a una localidad existente
INSERT INTO "Sala" (calle, numero, dia_cierre, localidad)
VALUES (
    'Avenida Mitre', 
    1500, 
    'Lunes', 
    (SELECT id_localidad FROM "Localidad" LIMIT 1)
);

-- 2. Verificación del registro incorporado (última sala creada)
SELECT id_sala, calle, numero, dia_cierre, localidad
FROM "Sala"
ORDER BY id_sala DESC
LIMIT 1;

-- Confirmar transacción
COMMIT;
-- ROLLBACK;