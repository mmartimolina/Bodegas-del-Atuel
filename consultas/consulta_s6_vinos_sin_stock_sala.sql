-- Issue B-32 / S6: Para una sala determinada, los vinos sin stock en la
-- sala pero con stock en el depósito central.
--
-- Sala determinada elegida del dataset: sala 1 (Blv. Salta 6128, San
-- Rafael).
-- Diseño del stock: Stock_Sala tiene PK (sala, vino) y admite cantidad 0;
-- un vino puede además NO tener fila en la sala. Ambos casos son "sin
-- stock en la sala": la condición usa NOT EXISTS (cantidad > 0), que
-- trata la ausencia de fila como stock cero (lo exige la issue).
-- "Con stock en el depósito central": fila en Stock_Deposito con
-- cantidad > 0.
-- Sobre el dataset: 22 vinos cumplen la condición para la sala 1.

-- 1. Contexto: la sala elegida y panorama de su inventario.
SELECT s.id_sala, s.calle, s.numero, s.dia_cierre, l.nombre AS localidad
FROM "Sala" s
JOIN "Localidad" l ON l.id_localidad = s.localidad
WHERE s.id_sala = 1;

SELECT (SELECT COUNT(*) FROM "Vino") AS vinos_del_catalogo,
       (SELECT COUNT(*) FROM "Stock_Sala" ss WHERE ss.sala = 1 AND ss.cantidad > 0) AS vinos_con_stock_sala_1;

-- 2. CONSULTA PRINCIPAL: vinos sin stock en la sala 1 (fila ausente o
--    cantidad 0) y con stock positivo en el depósito central. Se muestra
--    el stock de sala (0) para evidenciar la condición.
SELECT v.codigo,
       v.nombre,
       v.tipo,
       v.anada,
       COALESCE(ss.cantidad, 0) AS stock_sala,
       sd.cantidad AS stock_deposito
FROM "Vino" v
JOIN "Stock_Deposito" sd ON sd.vino = v.codigo AND sd.cantidad > 0
LEFT JOIN "Stock_Sala" ss ON ss.sala = 1 AND ss.vino = v.codigo
WHERE COALESCE(ss.cantidad, 0) = 0
ORDER BY sd.cantidad DESC,
         v.codigo;

-- 3. Prueba de contraste: vinos sin stock NI en la sala NI en el
--    depósito (deben quedar excluidos del listado del paso 2).
SELECT COUNT(*) AS vinos_sin_stock_en_ambos
FROM "Vino" v
WHERE NOT EXISTS (SELECT 1 FROM "Stock_Sala" ss
                  WHERE ss.sala = 1 AND ss.vino = v.codigo AND ss.cantidad > 0)
  AND NOT EXISTS (SELECT 1 FROM "Stock_Deposito" sd
                  WHERE sd.vino = v.codigo AND sd.cantidad > 0);
