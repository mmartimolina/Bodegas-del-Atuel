-- a37_retirar_check.sql
-- Comparacion controlada sin SELECT ... FOR UPDATE (issue #43 / A-37).
-- Unicamente en la base temporal independiente: se retira la segunda linea
-- de defensa (CHECK de stock no negativo) para mostrar el defecto completo
-- de la venta concurrente sin bloqueo. La base de produccion no se toca.

ALTER TABLE "Stock_Sala" DROP CONSTRAINT ck_stock_sala_cantidad_no_negativa;
