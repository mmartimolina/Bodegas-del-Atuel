-- 001_esquema.sql
-- A-14 (issue #17): DDL base del esquema relacional de Bodegas del Atuel.
-- Ejecutable desde una base PostgreSQL 16 vacia: crea tipos, 29 tablas, PK y FK.
-- Deja para A-16 (issue #19) los CHECK, UNIQUE adicionales, triggers, funciones,
-- procedimientos y demas minimos de etapa 2 que no son parte del DDL base.

-- Fuentes de verdad (no se inventan objetos):
--   docs/modelo/09_esquema_relacional.md  (29 tablas, 34 FK, acciones referenciales)
--   docs/modelo/10_diccionario_de_datos.md (nombres de tablas/columnas, NOT NULL, defaults)
--   docs/modelo/12_matriz_decisiones_pendientes.md (DEC-01..DEC-13 adoptadas)
--   docs/modelo/13_tipos_postgresql_enum_domain.md (tipos por columna: ENUM, DOMAIN, NUMERIC, DATE..)

-- Decisiones aplicadas:
--   DEC-01/03..09: PK adoptadas (naturales y subrogadas). DEC-02: PK de Lote compuesta
--     (finca, n_parcela, campania); FK #8 de Analisis compuesta. DEC-10:
--     subrogadas = BIGINT GENERATED ALWAYS AS IDENTITY.
--   DEC-14 (NOT NULL): criterio conservador adoptado; componentes de PK y FK
--     con participacion minima 1 respaldada textualmente, mas casos exigidos por reglas de negocio.
--   UNIQUE: ninguna adicional mas alla de las implicitas en las PK; las textuales de etapa 2
--     (Bodega.cuit, Vino triada, etc.) corresponden a A-16.
--   A-16 (pendiente): UNIQUE adicionales, CHECKs, triggers, roles, funciones, procedimientos.

-- ON DELETE / ON UPDATE: propuestos y documentados en A-09 s 7.1/7.2.
--   A-09 s 7.1 (act.) adopta acciones en TODAS las FK (ON DELETE: 26 RESTRICT y 8 CASCADE;`n--     ON UPDATE: 20 RESTRICT y 14 NO ACTION): el DDL acompana las decisiones con clausulas explicitas.`n--     Donde se adopto NO ACTION, la clausula queda implicita (multiples renglones).
--   FK con CASCADE en A-09 como defendible (#16, #18, #19, #20, #26, #29): CASCADE.
--   FK con RESTRICT en A-09: RESTRICT. ON UPDATE: sin CASCADE; RESTRICT en Bodega y subtipos.

-- DEFAULT incluidos (respaldados en A-10/A-13): Ingreso.estado y Transferencia.estado
--   = 'en_confeccion' (RN-10/RN-11 + etapa 2); Cliente.fecha_alta = CURRENT_DATE (etapa 2);
--   Transferencia.fecha_confeccion = CURRENT_DATE (RN-11: la fecha de confeccion es la actual).
-- DEFAULT pendientes omitidos: Stock_*.cantidad = 0 (AMB-11/DEC-19); Auditoria_Precio.fecha_hora
--   (trigger RN-13).
BEGIN;

-- ============================================================================
-- Tipos propios (A-13 s 2 y 3; minimos etapa 2: 1 ENUM + 1 DOMAIN)
-- ============================================================================

-- ENUM estado_documento (A-13 s 2): ciclo en_confeccion -> terminado -> procesado.
CREATE TYPE estado_documento AS ENUM ('en_confeccion', 'terminado', 'procesado');

-- DOMAIN cuit_dom (A-13 s 3): 11 caracteres numericos, sin separadores.
-- Validacion de formato determinista e IMMUTABLE; sin dIgito verificador (pendiente DEC-26).
CREATE DOMAIN cuit_dom AS VARCHAR(11)
    CONSTRAINT cuit_dom_formato CHECK (VALUE ~ '^[0-9]{11}$');

-- ============================================================================
-- Nivel 1: catalogos base sin dependencias (A-10 s 8)
-- ============================================================================

-- 1.1 Cepa (PK id; DEC-10)
CREATE TABLE "Cepa" (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  TEXT,
    tipo    TEXT                                          -- tinta / blanca (CHECK en A-16)
);

-- 1.2 Maridaje (PK id; DEC-10)
CREATE TABLE "Maridaje" (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre     TEXT,
    temperatura NUMERIC(3,1)
);

-- 1.3 Localidad (PK id_localidad; DEC-01/DEC-10)
CREATE TABLE "Localidad" (
    id_localidad        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_postal       TEXT,
    nombre              TEXT,
    provincia           TEXT,
    encargado_regional  TEXT                                   -- RN-02
);

-- 1.4 Finca (PK id_finca; DEC-10)
CREATE TABLE "Finca" (
    id_finca       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         TEXT,
    superficie     NUMERIC(8,2),                               -- > 0 (CHECK en A-16; RN-15)
    departamento   TEXT,
    provincia      TEXT
);

-- ============================================================================
-- Nivel 2: Sala, Bodega, Empleado
-- ============================================================================

-- 2.1 Sala (PK id_sala; DEC-10); FK #1 -> Localidad
CREATE TABLE "Sala" (
    id_sala     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    calle       TEXT,
    numero      INTEGER,
    dia_cierre  TEXT,                                          -- dominio Q-09 pendiente
    localidad   BIGINT NOT NULL
        CONSTRAINT fk_sala_localidad REFERENCES "Localidad" (id_localidad)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #1 (A-09 s 7.1)
);

-- 2.2 Bodega (PK cuit [R: UNIQUE de etapa 2]; DOMAIN cuit_dom per A-13)
CREATE TABLE "Bodega" (
    cuit         cuit_dom PRIMARY KEY,
    razon_social TEXT,
    domicilio    TEXT
);

-- 2.3 Empleado (PK id_empleado; DEC-09/DEC-10); FK #2 -> Sala
CREATE TABLE "Empleado" (
    id_empleado   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cuit          cuit_dom,
    nombre        TEXT,
    fecha_ingreso DATE,
    salario       NUMERIC(12,2),                               -- CHECK > 0 pendiente (Q-08)
    sala          BIGINT NOT NULL
        CONSTRAINT fk_empleado_sala REFERENCES "Sala" (id_sala)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #2
);

-- ============================================================================
-- Nivel 3: Cliente (supertipo) y Parcela (entidad debil)
-- ============================================================================

-- 3.1 Cliente (PK id_cliente; DEC-10; jerarquia DEC-11/12/13); FK #3 -> Localidad
CREATE TABLE "Cliente" (
    id_cliente  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      TEXT,                                          -- Q-04 pendiente
    tipo_doc    TEXT,
    n_doc       TEXT,
    direccion   TEXT,                                          -- Q-10 pendiente
    localidad   BIGINT
            CONSTRAINT fk_cliente_localidad REFERENCES "Localidad" (id_localidad)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #3
    ,
    fecha_alta  DATE DEFAULT CURRENT_DATE,                     -- etapa 2: fecha de alta actual
    descuento   NUMERIC(5,2)                                   -- CHECK de rango RN-06 (A-16)
);

-- 3.2 Parcela (debil de Finca): PK compuesta (finca, n_parcela); FK #4 y #5
CREATE TABLE "Parcela" (
    finca            BIGINT NOT NULL,
    n_parcela        INTEGER NOT NULL,
    superficie       NUMERIC(8,2),
    anio_plantacion  SMALLINT,
    cepa             BIGINT NOT NULL,
    CONSTRAINT pk_parcela PRIMARY KEY (finca, n_parcela),
    CONSTRAINT fk_parcela_finca FOREIGN KEY (finca) REFERENCES "Finca" (id_finca) ON DELETE RESTRICT
        ON UPDATE RESTRICT,                                     -- FK #4 (A-09 s 7.1: adoptada RESTRICT)
    CONSTRAINT fk_parcela_cepa FOREIGN KEY (cepa) REFERENCES "Cepa" (id)
        ON DELETE RESTRICT                                      -- FK #5
);

-- ============================================================================
-- Nivel 4: subtipos de la jerarquia Cliente (A-06; total y disjunta Dec-11/12).
-- CASCADE (defendible) hacia el supertipo (A-09 s 7.1 #18-20).
-- ============================================================================

CREATE TABLE "Socio" (
    id_cliente BIGINT NOT NULL PRIMARY KEY
        CONSTRAINT fk_socio_cliente REFERENCES "Cliente" (id_cliente)
        ON DELETE CASCADE ON UPDATE RESTRICT                    -- FK #18
);

CREATE TABLE "Distribuidor" (
    id_cliente     BIGINT NOT NULL PRIMARY KEY
        CONSTRAINT fk_distribuidor_cliente REFERENCES "Cliente" (id_cliente)
        ON DELETE CASCADE ON UPDATE RESTRICT                    -- FK #19
    ,
    zona           TEXT,
    n_habilitacion TEXT
);

CREATE TABLE "Exportador" (
    id_cliente BIGINT NOT NULL PRIMARY KEY
        CONSTRAINT fk_exportador_cliente REFERENCES "Cliente" (id_cliente)
        ON DELETE CASCADE ON UPDATE RESTRICT                    -- FK #20
    ,
    pais       TEXT
);

-- ============================================================================
-- Nivel 5: Vino, Lote, Permiso_Exportacion, Transportista
-- ============================================================================

-- 5.1 Vino (PK codigo; DEC-03); FK #9 -> Bodega
CREATE TABLE "Vino" (
    codigo     TEXT PRIMARY KEY,
    nombre     TEXT,
    tipo       TEXT,                                           -- dominio PEND (DEC-28)
    anada      SMALLINT,
    volumen_ml SMALLINT,                                       -- CHECK catalogo (P-8) A-16
    graduacion NUMERIC(4,1),                                    -- CHECK rango RN-15 A-16
    precio     NUMERIC(12,2),                                    -- CHECK > 0 RN-01 A-16
    bodega     cuit_dom NOT NULL
        CONSTRAINT fk_vino_bodega REFERENCES "Bodega" (cuit)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #9 (RN-14)
);

-- 5.2 Lote: PK compuesta (finca, n_parcela, campania) DEC-02; FK #6 y #7
CREATE TABLE "Lote" (
    finca          BIGINT NOT NULL,
    n_parcela      INTEGER NOT NULL,
    campania       SMALLINT NOT NULL,
    n_lote         INTEGER,                                    -- descriptivo, sin UNIQUE (DEC-02)
    fecha_cosecha  DATE,
    kg             NUMERIC(10,2),                               -- CHECK > 0 RN-15 A-16
    bodega_destino cuit_dom NOT NULL,
    CONSTRAINT pk_lote PRIMARY KEY (finca, n_parcela, campania),
    CONSTRAINT fk_lote_parcela FOREIGN KEY (finca, n_parcela) REFERENCES "Parcela" (finca, n_parcela)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #6
    ,
    CONSTRAINT fk_lote_bodega_destino FOREIGN KEY (bodega_destino) REFERENCES "Bodega" (cuit)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #7 (RN-14)
);

-- 5.3 Permiso_Exportacion (PK codigo; DEC-04); FK #21 -> Exportador
CREATE TABLE "Permiso_Exportacion" (
    codigo             TEXT PRIMARY KEY,
    exportador         BIGINT,
    fecha_emision      DATE,
    fecha_vencimiento  DATE,  -- CHECK > fecha_emision (RN-07, A-16)
    CONSTRAINT fk_permiso_exportador
        FOREIGN KEY (exportador) REFERENCES "Exportador" (id_cliente) ON DELETE RESTRICT
        ON UPDATE RESTRICT  -- FK #21 (A-09 s 7.1: adoptada RESTRICT)
);

-- 5.4 Transportista (PK codigo; DEC-08)
CREATE TABLE "Transportista" (
    codigo       TEXT PRIMARY KEY,
    razon_social TEXT,
    cuit         cuit_dom,                                     -- sin UNIQUE (DEC-08)
    email        TEXT,
    telefono     TEXT,
    domicilio    TEXT
);

-- ============================================================================
-- Nivel 6: Analisis, Composicion, Vino_Maridaje, Transportista_Localidad
-- ============================================================================

-- 6.1 Analisis (PK id_analisis; DEC-10); FK #8 COMPUESTA -> Lote (DEC-02)
CREATE TABLE "Analisis" (
    id_analisis BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    finca       BIGINT,
    n_parcela   INTEGER,
    campania    SMALLINT,                               -- AK extendida (A-16)
    fecha       DATE,
    brix        NUMERIC(5,2),
    ph          NUMERIC(3,2),
    acidez      NUMERIC(5,2),                                     -- g/L
    CONSTRAINT fk_analisis_lote FOREIGN KEY (finca, n_parcela, campania)
        REFERENCES "Lote" (finca, n_parcela, campania)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #8 compuesta (DEC-02)
);

-- 6.2 Composicion: PK (vino, cepa); FK #10 y #11
CREATE TABLE "Composicion" (
    vino       TEXT NOT NULL,
    cepa       BIGINT NOT NULL,
    porcentaje NUMERIC(5,2) NOT NULL,                            -- RN-05: suma 100 (trigger etapa 2)
    CONSTRAINT pk_composicion PRIMARY KEY (vino, cepa),
    CONSTRAINT fk_composicion_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT,                                     -- FK #10
    CONSTRAINT fk_composicion_cepa FOREIGN KEY (cepa) REFERENCES "Cepa" (id)
        ON DELETE RESTRICT                                      -- FK #11
);

-- 6.3 Vino_Maridaje: PK (vino, maridaje); FK #12 y #13
CREATE TABLE "Vino_Maridaje" (
    vino     TEXT NOT NULL,
    maridaje BIGINT NOT NULL,
    CONSTRAINT pk_vino_maridaje PRIMARY KEY (vino, maridaje),
    CONSTRAINT fk_vino_maridaje_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT,                                     -- FK #12
    CONSTRAINT fk_vino_maridaje_maridaje FOREIGN KEY (maridaje) REFERENCES "Maridaje" (id)
        ON DELETE RESTRICT                                      -- FK #13
);

-- 6.4 Transportista_Localidad: PK (transportista, localidad); FK #22 y #23
CREATE TABLE "Transportista_Localidad" (
    transportista TEXT NOT NULL,
    localidad     BIGINT,
    CONSTRAINT pk_transportista_localidad PRIMARY KEY (transportista, localidad),
    CONSTRAINT fk_transportista_localidad_transportista FOREIGN KEY (transportista)
        REFERENCES "Transportista" (codigo) ON DELETE CASCADE
        ON UPDATE RESTRICT,      -- FK #22 (A-09 s 7.1: adoptada CASCADE)
    CONSTRAINT fk_transportista_localidad_localidad FOREIGN KEY (localidad)
        REFERENCES "Localidad" (id_localidad)
        ON DELETE CASCADE ON UPDATE RESTRICT                    -- FK #23 (A-09 s 7.1: adoptada CASCADE)
);

-- ============================================================================
-- Nivel 7: Ingreso, Transferencia, Comprobante
-- ============================================================================

-- 7.1 Ingreso (PK codigo; DEC-06); FK #24 y #25; estado ENUM + default (RN-10)
CREATE TABLE "Ingreso" (
    codigo        TEXT PRIMARY KEY,
    fecha         DATE,                                        -- semantica Q-03 pendiente
    estado        estado_documento DEFAULT 'en_confeccion' NOT NULL,
    transportista TEXT NOT NULL,
    bodega_origen cuit_dom NOT NULL,
    CONSTRAINT fk_ingreso_transportista FOREIGN KEY (transportista) REFERENCES "Transportista" (codigo)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #24 (RN-14)
    ,
    CONSTRAINT fk_ingreso_bodega_origen FOREIGN KEY (bodega_origen) REFERENCES "Bodega" (cuit)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #25 (RN-14)
);

-- 7.2 Transferencia (PK numero; DEC-07); FK #28; estado ENUM (RN-11)
CREATE TABLE "Transferencia" (
    numero            BIGINT PRIMARY KEY,
    fecha_confeccion  DATE DEFAULT CURRENT_DATE NOT NULL,           -- RN-11: actual; inmodificable via trigger A-16
    estado            estado_documento DEFAULT 'en_confeccion' NOT NULL,
    sala              BIGINT NOT NULL,
    CONSTRAINT fk_transferencia_sala FOREIGN KEY (sala) REFERENCES "Sala" (id_sala)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #28
);

-- 7.3 Comprobante (PK numero; DEC-05 numeracion global); FK #14 y #15
CREATE TABLE "Comprobante" (
    numero    BIGINT PRIMARY KEY,
    fecha     DATE,
    cliente   BIGINT NOT NULL,
    sala      BIGINT NOT NULL,
    subtotal  NUMERIC(12,2),                                   -- derivado RN-08 (R-5, etapa 2)
    descuento NUMERIC(12,2),                                   -- dominio Q-05 pendiente (A-10 s 2.19)
    total     NUMERIC(12,2),
    CONSTRAINT fk_comprobante_cliente FOREIGN KEY (cliente) REFERENCES "Cliente" (id_cliente)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #14
    ,
    CONSTRAINT fk_comprobante_sala FOREIGN KEY (sala) REFERENCES "Sala" (id_sala)
        ON DELETE RESTRICT ON UPDATE RESTRICT                   -- FK #15
);

-- ============================================================================
-- Nivel 8: renglones (asociativas con detalle)
-- ============================================================================

-- 8.1 Renglon_Comprobante: PK (comprobante, vino); FK #16 CASCADE y #17
CREATE TABLE "Renglon_Comprobante" (
    comprobante     BIGINT NOT NULL,
    vino            TEXT NOT NULL,
    cantidad        INTEGER NOT NULL,                            -- CHECK > 0 RN-15 (A-16)
    precio_unitario NUMERIC(12,2) NOT NULL,                       -- valor historico (A-02 R-4)
    descuento       NUMERIC(5,2),                                 -- dominio Q-05 pendiente
    subtotal        NUMERIC(12,2),                                -- derivado RN-08
    CONSTRAINT pk_renglon_comprobante PRIMARY KEY (comprobante, vino),
    CONSTRAINT fk_renglon_comprobante_comprobante FOREIGN KEY (comprobante)
        REFERENCES "Comprobante" (numero)
        ON DELETE CASCADE,                                      -- FK #16 (patron A)
    CONSTRAINT fk_renglon_comprobante_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #17
);

-- 8.2 Renglon_Ingreso: PK (ingreso, vino); FK #26 CASCADE y #27
CREATE TABLE "Renglon_Ingreso" (
    ingreso  TEXT NOT NULL,
    vino     TEXT NOT NULL,
    cantidad INTEGER NOT NULL,
    CONSTRAINT pk_renglon_ingreso PRIMARY KEY (ingreso, vino),
    CONSTRAINT fk_renglon_ingreso_ingreso FOREIGN KEY (ingreso) REFERENCES "Ingreso" (codigo)
        ON DELETE CASCADE,                                      -- FK #26 (patron A)
    CONSTRAINT fk_renglon_ingreso_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #27
);

-- 8.3 Renglon_Transferencia: PK (transferencia, vino); FK #29 CASCADE y #30
CREATE TABLE "Renglon_Transferencia" (
    transferencia BIGINT NOT NULL,
    vino          TEXT NOT NULL,
    cantidad      INTEGER NOT NULL,
    CONSTRAINT pk_renglon_transferencia PRIMARY KEY (transferencia, vino),
    CONSTRAINT fk_renglon_transferencia_transferencia FOREIGN KEY (transferencia)
        REFERENCES "Transferencia" (numero)
        ON DELETE CASCADE,                                      -- FK #29 (patron A)
    CONSTRAINT fk_renglon_transferencia_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #30
);

-- ============================================================================
-- Nivel 9: stocks e auditoria
-- ============================================================================

-- 9.1 Stock_Sala: PK (sala, vino); FK #31 (restaurada RESTRICT, A-09 s 7.1), #32
CREATE TABLE "Stock_Sala" (
    sala     BIGINT NOT NULL,
    vino     TEXT NOT NULL,
    cantidad INTEGER NOT NULL,                                   -- CHECK >= 0 (sec. 5; A-16)
    CONSTRAINT pk_stock_sala PRIMARY KEY (sala, vino),
    CONSTRAINT fk_stock_sala_sala FOREIGN KEY (sala) REFERENCES "Sala" (id_sala) ON DELETE RESTRICT
        ON UPDATE RESTRICT,      -- FK #31 (A-09 s 7.1: adoptada RESTRICT)
    CONSTRAINT fk_stock_sala_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #32
);

-- 9.2 Stock_Deposito: PK/FK vino (DEC-03); FK #33; DEFAULT 0 pendiente (AMB-11)
CREATE TABLE "Stock_Deposito" (
    vino     TEXT NOT NULL PRIMARY KEY,
    cantidad INTEGER NOT NULL,
    CONSTRAINT fk_stock_deposito_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #33
);

-- 9.3 Auditoria_Precio (PK id_auditoria; DEC-10; RN-13); FK #34
CREATE TABLE "Auditoria_Precio" (
    id_auditoria    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vino            TEXT NOT NULL,
    precio_anterior NUMERIC(12,2) NOT NULL,
    precio_nuevo    NUMERIC(12,2) NOT NULL,
    fecha_hora      TIMESTAMP NOT NULL,                            -- DEFAULT via trigger RN-13 (A-16)
    usuario         TEXT,            -- Q-07 pendiente: usuario de BD o funcional
    CONSTRAINT fk_auditoria_precio_vino FOREIGN KEY (vino) REFERENCES "Vino" (codigo)
        ON DELETE RESTRICT                                      -- FK #34 (RN-13)
);

COMMIT;
