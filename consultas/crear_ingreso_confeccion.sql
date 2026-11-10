-- Issue B-20 / I6: Crear un ingreso en confección por 120 botellas
-- Consigna (sección 8.2, I6): crear un ingreso en estado 'en_confeccion'
-- por 120 botellas de un vino determinado, indicando bodega de origen y
-- transportista existentes.
--
-- Valores determinados elegidos del dataset cargado (db/seed):
--   * Vino         : V0001 "Torrontes Tradicion" (añada 2022, 750 ml)
--   * Bodega origen: 30666293880 "Bodega Martinez S.A." (la bodega del vino)
--   * Transportista: TR001 "Transportes Ramos S.R.L."
--
-- Criterios de la issue #78:
--   1. Se inserta la cabecera en estado inicial 'en_confeccion' (DEFAULT).
--   2. Se inserta el renglón por exactamente 120 botellas (RN-12 lo permite
--      porque la cabecera está en confección).
--   3. Se verifica el estado inicial y que el renglón quedó registrado.
--   4. Se verifica que el stock del depósito central NO cambia: mientras el
--      ingreso siga en confección no impacta stock (RN-10; solo
--      sp_procesar_ingreso, tras pasar a 'terminado', acredita el depósito).
--   5. Script idempotente: re-ejecutarlo no duplica filas (ON CONFLICT).

BEGIN;

-- 1. Pre-verificación: mostrar el vino, su bodega y el transportista elegidos,
--    con el stock actual del depósito para ese vino (valor de referencia).
SELECT v.codigo AS vino, v.nombre, v.anada, v.volumen_ml,
       v.bodega AS cuit_bodega, b.razon_social,
       t.codigo AS transportista, t.razon_social AS transportista_nombre,
       sd.cantidad AS stock_deposito_antes
FROM "Vino" v
JOIN "Bodega" b ON b.cuit = v.bodega
CROSS JOIN "Transportista" t
LEFT JOIN "Stock_Deposito" sd ON sd.vino = v.codigo
WHERE v.codigo = 'V0001'
  AND t.codigo = 'TR001';

-- 2. Insertar la cabecera del ingreso en estado 'en_confeccion' (DEFAULT).
--    La bodega de origen es la bodega del propio vino (el ingreso traslada
--    su producción al depósito central). ON CONFLICT lo hace idempotente.
INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen)
VALUES (
    'ING-2026-120',
    CURRENT_DATE,
    DEFAULT,                      -- 'en_confeccion'
    'TR001',
    (SELECT bodega FROM "Vino" WHERE codigo = 'V0001')
)
ON CONFLICT (codigo) DO NOTHING;

-- 3. Insertar el renglón del ingreso: 120 botellas del vino determinado.
--    Permitido por RN-12 porque la cabecera está en confección.
INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad)
VALUES ('ING-2026-120', 'V0001', 120)
ON CONFLICT (ingreso, vino) DO NOTHING;

-- 4. Verificación del estado inicial: la cabecera quedó 'en_confeccion'
--    (nunca 'procesado': ese estado solo lo establece sp_procesar_ingreso).
SELECT codigo, fecha, estado, transportista, bodega_origen
FROM "Ingreso"
WHERE codigo = 'ING-2026-120';

-- 5. Verificación del renglón: exactamente 120 botellas del vino elegido.
SELECT ingreso, vino, cantidad
FROM "Renglon_Ingreso"
WHERE ingreso = 'ING-2026-120';

-- 6. Verificación de que el stock del depósito NO cambió: debe ser igual al
--    valor de la pre-verificación (paso 1). El ingreso en confección no
--    impacta stock; lo acreditaría recién sp_procesar_ingreso (RN-10),
--    que además exige haber pasado antes a 'terminado'.
SELECT sd.vino, sd.cantidad AS stock_deposito_despues
FROM "Stock_Deposito" sd
WHERE sd.vino = 'V0001';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;

-- Nota (fuera del alcance de I6): para que el ingreso impacte el depósito:
--   UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-2026-120';
--   CALL sp_procesar_ingreso('ING-2026-120');
