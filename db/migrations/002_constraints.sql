-- 002_constraints.sql
-- A-16 (issue #19): restricciones estructurales.
--
-- Se agregan restricciones respaldadas por la consigna
-- y por las reglas de negocio documentadas.
--
-- No se modifican PK ni nulabilidad de columnas.
-- No se agregan UNIQUE sin respaldo documental.

BEGIN;

-- ============================================================
-- 1. UNIQUE
-- ============================================================

-- Etapa 2: unicidad de la combinación nombre, añada y volumen.
ALTER TABLE "Vino"
    ADD CONSTRAINT uq_vino_nombre_anada_volumen
    UNIQUE (nombre, anada, volumen_ml);


-- ============================================================
-- Decisiones de dominio adoptadas para completar el minimo UNIQUE:
-- Un documento identifica un registro de Cliente.
ALTER TABLE "Cliente"
    ADD CONSTRAINT uq_cliente_tipo_doc_n_doc
    UNIQUE (tipo_doc, n_doc);

-- Un CUIT identifica un unico Transportista.
ALTER TABLE "Transportista"
    ADD CONSTRAINT uq_transportista_cuit
    UNIQUE (cuit);

-- Un CUIT identifica un unico Empleado.
ALTER TABLE "Empleado"
    ADD CONSTRAINT uq_empleado_cuit
    UNIQUE (cuit);
-- 2. CHECK: PRECIOS Y GRADUACIÓN
-- ============================================================

-- RN-01: el precio del vino debe ser positivo.
ALTER TABLE "Vino"
    ADD CONSTRAINT ck_vino_precio_positivo
    CHECK (precio > 0);

-- RN-15: graduación alcohólica entre 5 y 20.
ALTER TABLE "Vino"
    ADD CONSTRAINT ck_vino_graduacion_rango
    CHECK (graduacion BETWEEN 5 AND 20);


-- ============================================================
-- 3. CHECK: SUPERFICIES Y KILOS
-- ============================================================

-- RN-15: los kilos del lote deben ser positivos.
ALTER TABLE "Lote"
    ADD CONSTRAINT ck_lote_kg_positivo
    CHECK (kg > 0);

-- RN-15: la superficie de la finca debe ser positiva.
ALTER TABLE "Finca"
    ADD CONSTRAINT ck_finca_superficie_positiva
    CHECK (superficie > 0);

-- RN-15: la superficie de la parcela debe ser positiva.
ALTER TABLE "Parcela"
    ADD CONSTRAINT ck_parcela_superficie_positiva
    CHECK (superficie > 0);


-- ============================================================
-- 4. CHECK: CANTIDADES DE RENGLONES
-- ============================================================

-- RN-15: cantidad positiva en comprobantes.
ALTER TABLE "Renglon_Comprobante"
    ADD CONSTRAINT ck_renglon_comprobante_cantidad_positiva
    CHECK (cantidad > 0);

-- RN-15: cantidad positiva en ingresos.
ALTER TABLE "Renglon_Ingreso"
    ADD CONSTRAINT ck_renglon_ingreso_cantidad_positiva
    CHECK (cantidad > 0);

-- RN-15: cantidad positiva en transferencias.
ALTER TABLE "Renglon_Transferencia"
    ADD CONSTRAINT ck_renglon_transferencia_cantidad_positiva
    CHECK (cantidad > 0);


-- ============================================================
-- 5. CHECK: STOCK
-- ============================================================

-- Se permite stock cero, pero no stock negativo.
ALTER TABLE "Stock_Sala"
    ADD CONSTRAINT ck_stock_sala_cantidad_no_negativa
    CHECK (cantidad >= 0);

ALTER TABLE "Stock_Deposito"
    ADD CONSTRAINT ck_stock_deposito_cantidad_no_negativa
    CHECK (cantidad >= 0);


-- ============================================================
-- 6. CHECK: COMPARACIÓN ENTRE COLUMNAS
-- ============================================================

-- RN-07: el vencimiento debe ser posterior a la emisión.
-- No se utiliza CURRENT_DATE ni funciones no determinísticas.
ALTER TABLE "Permiso_Exportacion"
    ADD CONSTRAINT ck_permiso_fechas_orden
    CHECK (fecha_vencimiento > fecha_emision);

COMMIT;
