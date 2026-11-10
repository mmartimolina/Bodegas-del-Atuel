-- Issue B-18 / I4: Insertar una nueva bodega
-- Consigna (sección 8.2, I4): incorporar una nueva bodega con datos
-- ficticios válidos (CUIT, razón social y domicilio).
--
-- Datos de prueba determinados (ficticios, no duplicados):
--   * CUIT        : 30712345678 (11 dígitos, sin guiones: formato del DOMAIN cuit_dom)
--   * Razón social: Bodega Los Cerros S.A.
--   * Domicilio   : Ruta Nacional 143 Km 42, San Rafael
--
-- Criterios de la issue #76:
--   1. Se inserta la bodega válida (tipos y restricciones correctos).
--   2. Se verifica el registro incorporado.
--   3. Se PRUEBA el rechazo de duplicados (mismo CUIT: PK + domain).
--   4. Se PRUEBA el rechazo de formatos inválidos (CUIT con guiones).
-- Las pruebas de rechazo se ejecutan en bloques DO con captura de excepción:
-- muestran el rechazo real de la base (NOTICE con el SQLSTATE) y a la vez
-- FALLAN ruidosamente si la base aceptara un dato que debe rechazar.

BEGIN;

-- 1. Insertar la bodega válida. ON CONFLICT hace el script idempotente:
--    re-ejecutarlo no duplica la fila ni falla.
INSERT INTO "Bodega" (cuit, razon_social, domicilio)
VALUES (
    '30712345678',
    'Bodega Los Cerros S.A.',
    'Ruta Nacional 143 Km 42, San Rafael'
)
ON CONFLICT (cuit) DO NOTHING;

-- 2. Verificación del registro incorporado (y de su formato de CUIT).
SELECT cuit, razon_social, domicilio,
       CASE WHEN cuit ~ '^[0-9]{11}$' THEN 'valido' ELSE 'INVALIDO' END AS formato_cuit
FROM "Bodega"
WHERE cuit = '30712345678';

-- 3. Prueba de rechazo de duplicados: el mismo CUIT debe ser rechazado por
--    la clave primaria. Se captura la excepción para mostrar el rechazo
--    sin abortar el script; si la base lo ACEPTARA, el script falla.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Bodega" (cuit, razon_social, domicilio)
        VALUES ('30712345678', 'Bodega Duplicada S.A.', 'Otra calle 123');
        RAISE EXCEPTION
            'PRUEBA FALLIDA: la base acepto un CUIT duplicado (30712345678)';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: duplicado rechazado (%)', SQLERRM;
    END;
END $$;

-- 4. Prueba de rechazo de formato inválido: un CUIT con guiones (11 caracteres
--    pero no todos numéricos) viola el CHECK del DOMAIN cuit_dom.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Bodega" (cuit, razon_social, domicilio)
        VALUES ('30-712-5678', 'Bodega Formato Invalido S.A.', 'Calle falsa 999');
        RAISE EXCEPTION
            'PRUEBA FALLIDA: la base acepto un CUIT con formato invalido (30-712-5678)';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: formato invalido rechazado (%)', SQLERRM;
    END;
END $$;

-- 5. Verificación final: la tabla no incorporó filas de las pruebas de rechazo
--    (debe existir exactamente una bodega con ese CUIT).
SELECT COUNT(*) AS bodegas_con_ese_cuit
FROM "Bodega"
WHERE cuit = '30712345678';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;
