
-- verify_a15.sql
-- A-15 (issue #18): verificacion del DDL base 001_esquema.sql contra el catalogo
-- de PostgreSQL. Correr sobre una base vacia despues de aplicar 001_esquema.sql.
-- Cada control falla mediante RAISE EXCEPTION si no se cumple lo esperado.

-- 1. Deben existir exactamente 29 tablas.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE';

    IF n <> 29 THEN
        RAISE EXCEPTION '1. TABLAS: % (esperado 29)', n;
    END IF;

    RAISE NOTICE '1. TABLAS: OK (29)';
END $$;

-- 2. ENUM y DOMAIN: verificar definiciones exactas.

DO $$
DECLARE
    n int;
BEGIN
    SELECT count(DISTINCT e.enumlabel) INTO n
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    JOIN pg_namespace ns ON ns.oid = t.typnamespace
    WHERE ns.nspname = 'public'
      AND t.typname = 'estado_documento'
      AND e.enumlabel IN ('en_confeccion', 'terminado', 'procesado');

    IF n <> 3 THEN
        RAISE EXCEPTION '2. ENUM estado_documento: % etiquetas esperadas encontradas (3)', n;
    END IF;

    IF (
        SELECT count(*)
        FROM pg_enum e
        JOIN pg_type t ON t.oid = e.enumtypid
        JOIN pg_namespace ns ON ns.oid = t.typnamespace
        WHERE ns.nspname = 'public'
          AND t.typname = 'estado_documento'
    ) <> 3 THEN
        RAISE EXCEPTION '2. ENUM estado_documento: contiene etiquetas adicionales';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.domains
        WHERE domain_schema = 'public'
          AND domain_name = 'cuit_dom'
          AND data_type = 'character varying'
          AND character_maximum_length = 11
    ) THEN
        RAISE EXCEPTION '2. DOMAIN cuit_dom: definicion incorrecta o inexistente';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_type t ON t.oid = c.contypid
        JOIN pg_namespace ns ON ns.oid = t.typnamespace
        WHERE ns.nspname = 'public'
          AND t.typname = 'cuit_dom'
          AND c.conname = 'cuit_dom_formato'
    ) THEN
        RAISE EXCEPTION '2. DOMAIN cuit_dom: falta constraint cuit_dom_formato';
    END IF;

    RAISE NOTICE '2. ENUM y DOMAIN: OK';
END $$;

-- 3. Deben existir 29 PK, de las cuales 9 son compuestas.
DO $$
DECLARE
    n int;
    n_comp int;
BEGIN
    SELECT count(*) INTO n
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND constraint_type = 'PRIMARY KEY';

    IF n <> 29 THEN
        RAISE EXCEPTION '3. PK: % tablas con PK (esperado 29)', n;
    END IF;

    SELECT count(*) INTO n_comp
    FROM (
        SELECT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON kcu.constraint_schema = tc.constraint_schema
         AND kcu.constraint_name = tc.constraint_name
         AND kcu.table_name = tc.table_name
        WHERE tc.table_schema = 'public'
          AND tc.constraint_type = 'PRIMARY KEY'
        GROUP BY tc.table_name, tc.constraint_name
        HAVING count(*) > 1
    ) AS pk_compuestas;

    IF n_comp <> 9 THEN
        RAISE EXCEPTION '3. PK compuestas: % (esperado 9)', n_comp;
    END IF;

    RAISE NOTICE '3. PRIMARY KEY: OK (29; 9 compuestas)';
END $$;

-- 4. Deben existir 34 FK y las dos FK compuestas deben tener la aridad esperada.
DO $$
DECLARE
    n int;
    n_bad int;
BEGIN
    SELECT count(*) INTO n
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND constraint_type = 'FOREIGN KEY';

    IF n <> 34 THEN
        RAISE EXCEPTION '4. FKs: % (esperado 34)', n;
    END IF;

    SELECT count(*) INTO n_bad
    FROM information_schema.key_column_usage k
    WHERE k.table_schema = 'public'
      AND k.constraint_name = 'fk_analisis_lote'
      AND k.table_name = 'Analisis';

    IF n_bad <> 3 THEN
        RAISE EXCEPTION '4. FK fk_analisis_lote: % columnas (esperado 3)', n_bad;
    END IF;

    SELECT count(*) INTO n_bad
    FROM information_schema.key_column_usage k
    WHERE k.table_schema = 'public'
      AND k.constraint_name = 'fk_lote_parcela'
      AND k.table_name = 'Lote';

    IF n_bad <> 2 THEN
        RAISE EXCEPTION '4. FK fk_lote_parcela: % columnas (esperado 2)', n_bad;
    END IF;

    RAISE NOTICE '4. FOREIGN KEY: OK (34; compuestas verificadas)';
END $$;

-- 5. Tipos de datos clave y tipos definidos por el modelo.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM (
        VALUES
            ('Localidad','id_localidad','bigint'),
            ('Sala','id_sala','bigint'),
            ('Empleado','id_empleado','bigint'),
            ('Finca','id_finca','bigint'),
            ('Cepa','id','bigint'),
            ('Maridaje','id','bigint'),
            ('Cliente','id_cliente','bigint'),
            ('Analisis','id_analisis','bigint'),
            ('Auditoria_Precio','id_auditoria','bigint'),
            ('Vino','codigo','text'),
            ('Permiso_Exportacion','codigo','text'),
            ('Comprobante','numero','bigint'),
            ('Comprobante','fecha','date'),
            ('Comprobante','cliente','bigint'),
            ('Comprobante','sala','bigint'),
            ('Comprobante','subtotal','numeric'),
            ('Comprobante','descuento','numeric'),
            ('Comprobante','total','numeric'),
            ('Transferencia','numero','bigint'),
            ('Ingreso','codigo','text'),
            ('Transportista','codigo','text'),
            ('Lote','campania','smallint'),
            ('Analisis','campania','smallint'),
            ('Parcela','n_parcela','integer'),
            ('Auditoria_Precio','fecha_hora','timestamp without time zone'),
            ('Vino','precio','numeric'),
            ('Vino','graduacion','numeric')
    ) AS esperado(table_name, column_name, data_type)
    LEFT JOIN information_schema.columns c
      ON c.table_schema = 'public'
     AND c.table_name = esperado.table_name
     AND c.column_name = esperado.column_name
    WHERE c.column_name IS NULL
       OR c.data_type <> esperado.data_type;

    IF n <> 0 THEN
        RAISE EXCEPTION '5. TIPOS: % columnas faltantes o incorrectas', n;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'Bodega'
          AND column_name = 'cuit'
          AND domain_schema = 'public'
          AND domain_name = 'cuit_dom'
    ) THEN
        RAISE EXCEPTION '5. Bodega.cuit: no utiliza DOMAIN cuit_dom';
    END IF;

    IF (
        SELECT count(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name IN ('Ingreso', 'Transferencia')
          AND column_name = 'estado'
          AND udt_name = 'estado_documento'
    ) <> 2 THEN
        RAISE EXCEPTION '5. estado: Ingreso y Transferencia deben utilizar estado_documento';
    END IF;

    RAISE NOTICE '5. TIPOS DE DATOS: OK';
END $$;

-- 6. NOT NULL: obligatoriedad fisica segun A-09 y criterio conservador
-- propuesto para DEC-14, aun pendiente de ratificacion.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND is_nullable = 'YES'
      AND (
        (table_name = 'Sala' AND column_name = 'localidad') OR
        (table_name = 'Empleado' AND column_name = 'sala') OR
        (table_name = 'Parcela' AND column_name IN ('finca','cepa','n_parcela')) OR
        (table_name = 'Lote' AND column_name IN ('finca','n_parcela','campania','bodega_destino')) OR
        (table_name = 'Vino' AND column_name = 'bodega') OR
        (table_name = 'Comprobante' AND column_name IN ('cliente','sala')) OR
        (table_name = 'Ingreso' AND column_name IN ('transportista','bodega_origen','estado')) OR
        (table_name = 'Transferencia' AND column_name IN ('sala','estado','fecha_confeccion')) OR
        (table_name = 'Composicion' AND column_name = 'porcentaje') OR
        (table_name = 'Auditoria_Precio' AND column_name IN ('vino','precio_anterior','precio_nuevo','fecha_hora','usuario')) OR
        (column_name = 'cantidad' AND table_name IN ('Renglon_Comprobante','Renglon_Ingreso','Renglon_Transferencia','Stock_Sala','Stock_Deposito')) OR
        (column_name = 'precio_unitario' AND table_name = 'Renglon_Comprobante')
      );

    IF n <> 0 THEN
        RAISE EXCEPTION '6. NOT NULL: % columnas obligatorias permiten NULL', n;
    END IF;

    RAISE NOTICE '6. NOT NULL: OK';
END $$;

-- 7. Verificar los cuatro DEFAULT esperados.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM (
        VALUES
            ('Cliente', 'fecha_alta', 'CURRENT_DATE'),
            ('Ingreso', 'estado', '''en_confeccion''::estado_documento'),
            ('Transferencia', 'estado', '''en_confeccion''::estado_documento'),
            ('Transferencia', 'fecha_confeccion', 'CURRENT_DATE')
    ) AS esperado(table_name, column_name, column_default)
    LEFT JOIN information_schema.columns c
      ON c.table_schema = 'public'
     AND c.table_name = esperado.table_name
     AND c.column_name = esperado.column_name
    WHERE c.column_name IS NULL
       OR c.column_default IS DISTINCT FROM esperado.column_default;

    IF n <> 0 THEN
        RAISE EXCEPTION '7. DEFAULTS: % columnas faltantes o con expresión incorrecta', n;
    END IF;

    SELECT count(*) INTO n
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_default IS NOT NULL;

    IF n <> 4 THEN
        RAISE EXCEPTION '7. DEFAULTS: existen % columnas con DEFAULT (esperado 4)', n;
    END IF;

    RAISE NOTICE '7. DEFAULTS: OK (4)';
END $$;


-- 8. Verificar las acciones ON DELETE de las 34 FK.
DO $$
DECLARE
    n int;
BEGIN
    -- 5 FK con NO ACTION y 6 FK con CASCADE.
    SELECT count(*) INTO n
    FROM (
        VALUES
            ('fk_parcela_finca', 'a'),
            ('fk_permiso_exportador', 'a'),
            ('fk_transportista_localidad_transportista', 'a'),
            ('fk_transportista_localidad_localidad', 'a'),
            ('fk_stock_sala_sala', 'a'),
            ('fk_renglon_comprobante_comprobante', 'c'),
            ('fk_renglon_ingreso_ingreso', 'c'),
            ('fk_renglon_transferencia_transferencia', 'c'),
            ('fk_socio_cliente', 'c'),
            ('fk_distribuidor_cliente', 'c'),
            ('fk_exportador_cliente', 'c')
    ) AS esperado(constraint_name, delete_action)
    LEFT JOIN pg_constraint c
      ON c.conname = esperado.constraint_name
     AND c.contype = 'f'
     AND c.connamespace = 'public'::regnamespace
    WHERE c.oid IS NULL
       OR c.confdeltype::text <> esperado.delete_action;

    IF n <> 0 THEN
        RAISE EXCEPTION '8. ON DELETE: % restricciones especiales faltantes o incorrectas', n;
    END IF;

    -- Deben existir exactamente 34 FK.
    SELECT count(*) INTO n
    FROM pg_constraint
    WHERE contype = 'f'
      AND connamespace = 'public'::regnamespace;

    IF n <> 34 THEN
        RAISE EXCEPTION '8. ON DELETE: % FKs encontradas (esperado 34)', n;
    END IF;

    -- Las 23 FK restantes deben utilizar RESTRICT.
    SELECT count(*) INTO n
    FROM pg_constraint
    WHERE contype = 'f'
      AND connamespace = 'public'::regnamespace
      AND conname NOT IN (
          'fk_parcela_finca',
          'fk_permiso_exportador',
          'fk_transportista_localidad_transportista',
          'fk_transportista_localidad_localidad',
          'fk_stock_sala_sala',
          'fk_renglon_comprobante_comprobante',
          'fk_renglon_ingreso_ingreso',
          'fk_renglon_transferencia_transferencia',
          'fk_socio_cliente',
          'fk_distribuidor_cliente',
          'fk_exportador_cliente'
      )
      AND confdeltype <> 'r';

    IF n <> 0 THEN
        RAISE EXCEPTION '8. ON DELETE: % FKs restantes no usan RESTRICT', n;
    END IF;

    RAISE NOTICE '8. ON DELETE: OK (34 FKs)';
END $$;


-- 9. Verificar que todas las FK apunten a tablas del esquema public.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM pg_constraint c
    JOIN pg_class tabla_referenciada
      ON tabla_referenciada.oid = c.confrelid
    JOIN pg_namespace esquema_referenciado
      ON esquema_referenciado.oid = tabla_referenciada.relnamespace
    WHERE c.contype = 'f'
      AND c.connamespace = 'public'::regnamespace
      AND esquema_referenciado.nspname <> 'public';

    IF n <> 0 THEN
        RAISE EXCEPTION '9. FK: % referencias apuntan fuera del esquema public', n;
    END IF;

    SELECT count(*) INTO n
    FROM pg_constraint
    WHERE contype = 'f'
      AND connamespace = 'public'::regnamespace
      AND confrelid = 0;

    IF n <> 0 THEN
        RAISE EXCEPTION '9. FK: % referencias sin tabla destino', n;
    END IF;

    RAISE NOTICE '9. INTEGRIDAD FK: OK';
END $$;


-- 10. Verificar que existan exactamente las 29 tablas esperadas.
DO $$
DECLARE
    n int;
BEGIN
    -- Detectar tablas esperadas que faltan.
    SELECT count(*) INTO n
    FROM (
        VALUES
            ('Localidad'),
            ('Sala'),
            ('Empleado'),
            ('Finca'),
            ('Parcela'),
            ('Cepa'),
            ('Lote'),
            ('Analisis'),
            ('Bodega'),
            ('Vino'),
            ('Composicion'),
            ('Maridaje'),
            ('Vino_Maridaje'),
            ('Cliente'),
            ('Socio'),
            ('Distribuidor'),
            ('Exportador'),
            ('Permiso_Exportacion'),
            ('Comprobante'),
            ('Renglon_Comprobante'),
            ('Transportista'),
            ('Transportista_Localidad'),
            ('Ingreso'),
            ('Renglon_Ingreso'),
            ('Transferencia'),
            ('Renglon_Transferencia'),
            ('Stock_Sala'),
            ('Stock_Deposito'),
            ('Auditoria_Precio')
    ) AS esperado(table_name)
    LEFT JOIN information_schema.tables t
      ON t.table_schema = 'public'
     AND t.table_type = 'BASE TABLE'
     AND t.table_name = esperado.table_name
    WHERE t.table_name IS NULL;

    IF n <> 0 THEN
        RAISE EXCEPTION '10. TABLAS: faltan % tablas esperadas', n;
    END IF;

    -- Detectar tablas públicas que no pertenecen al modelo.
    SELECT count(*) INTO n
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND table_name NOT IN (
          'Localidad',
          'Sala',
          'Empleado',
          'Finca',
          'Parcela',
          'Cepa',
          'Lote',
          'Analisis',
          'Bodega',
          'Vino',
          'Composicion',
          'Maridaje',
          'Vino_Maridaje',
          'Cliente',
          'Socio',
          'Distribuidor',
          'Exportador',
          'Permiso_Exportacion',
          'Comprobante',
          'Renglon_Comprobante',
          'Transportista',
          'Transportista_Localidad',
          'Ingreso',
          'Renglon_Ingreso',
          'Transferencia',
          'Renglon_Transferencia',
          'Stock_Sala',
          'Stock_Deposito',
          'Auditoria_Precio'
      );

    IF n <> 0 THEN
        RAISE EXCEPTION '10. TABLAS: existen % tablas inesperadas', n;
    END IF;

    RAISE NOTICE '10. TABLAS: OK (29)';
END $$;
-- 11. Verificar cantidad total de columnas del modelo.
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name IN (
          'Localidad', 'Sala', 'Empleado', 'Finca', 'Parcela',
          'Cepa', 'Lote', 'Analisis', 'Bodega', 'Vino',
          'Composicion', 'Maridaje', 'Vino_Maridaje', 'Cliente',
          'Socio', 'Distribuidor', 'Exportador', 'Permiso_Exportacion',
          'Comprobante', 'Renglon_Comprobante', 'Transportista',
          'Transportista_Localidad', 'Ingreso', 'Renglon_Ingreso',
          'Transferencia', 'Renglon_Transferencia', 'Stock_Sala',
          'Stock_Deposito', 'Auditoria_Precio'
      );

    IF n <> 128 THEN
        RAISE EXCEPTION '11. COLUMNAS: % encontradas (esperado 128)', n;
    END IF;

    RAISE NOTICE '11. COLUMNAS: OK (128)';
END $$;