-- Issue B-35 / S9: Ficha de un vino: cepas con sus porcentajes, bodega
-- elaboradora, maridajes y stock total (depósito más salas).
--
-- Vino elegido del dataset: V0076 (Malbec Coleccion, tinto), un vino con
-- TRES cepas en su composición y TRES maridajes (la issue pide probar un
-- vino con más de una cepa y más de un maridaje).
-- Herramientas (las exige la issue): joins (Vino-Bodega, y los de los
-- pasos de detalle), agregación (string_agg de cepas y maridajes) y la
-- VISTA v_stock_total_vino (stock por vino entre depósito y salas,
-- creada en la migración 011_vistas.sql).
-- Para no multiplicar cantidades por los joins N:M (composición ×
-- maridajes), las cepas y los maridajes se resuelven como subconsultas
-- escalares agregadas por vino: la ficha no distorsiona el stock.

-- 1. CONSULTA PRINCIPAL: la ficha del vino V0076 en una sola fila.
SELECT v.codigo,
       v.nombre,
       v.tipo,
       v.anada,
       v.volumen_ml,
       v.graduacion,
       v.precio,
       b.razon_social AS bodega_elaboradora,
       st.stock_deposito,
       st.stock_salas,
       st.stock_deposito + st.stock_salas AS stock_total,
       (SELECT string_agg(cp.nombre || ' (' || co.porcentaje || '%)', ', '
                          ORDER BY co.porcentaje DESC)
          FROM "Composicion" co
          JOIN "Cepa" cp ON cp.id = co.cepa
         WHERE co.vino = v.codigo) AS cepas_con_porcentaje,
       (SELECT string_agg(m.nombre || ' (a ' || m.temperatura || ' °C)', ', '
                          ORDER BY m.nombre)
          FROM "Vino_Maridaje" vm
          JOIN "Maridaje" m ON m.id = vm.maridaje
         WHERE vm.vino = v.codigo) AS maridajes
FROM "Vino" v
JOIN "Bodega" b ON b.cuit = v.bodega
JOIN v_stock_total_vino st ON st.vino = v.codigo
WHERE v.codigo = 'V0076';

-- 2. Detalle de la composición (una fila por cepa con su porcentaje;
--    RN-15 garantiza que sumen 100%).
SELECT co.vino,
       cp.nombre AS cepa,
       cp.tipo AS tipo_cepa,
       co.porcentaje
FROM "Composicion" co
JOIN "Cepa" cp ON cp.id = co.cepa
WHERE co.vino = 'V0076'
ORDER BY co.porcentaje DESC;

-- 3. Detalle de maridajes (una fila por maridaje con su temperatura).
SELECT m.nombre AS maridaje,
       m.temperatura AS temperatura_servicio
FROM "Vino_Maridaje" vm
JOIN "Maridaje" m ON m.id = vm.maridaje
WHERE vm.vino = 'V0076'
ORDER BY m.nombre;

-- 4. Verificación del stock de la vista: desglose por sala (la suma de
--    este listado debe igualar la columna stock_salas del paso 1).
SELECT ss.sala,
       ss.cantidad AS botellas_en_sala
FROM "Stock_Sala" ss
WHERE ss.vino = 'V0076'
  AND ss.cantidad > 0
ORDER BY ss.cantidad DESC, ss.sala;

-- 5. Verificación del stock del depósito central (columna
--    stock_deposito del paso 1).
SELECT cantidad AS botellas_en_deposito
FROM "Stock_Deposito"
WHERE vino = 'V0076';
