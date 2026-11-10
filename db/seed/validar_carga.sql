-- Issue B-64: valida volumenes minimos y referencias del dataset cargado.
-- Es de solo lectura y puede ejecutarse con psql en la base a verificar.

\set ON_ERROR_STOP on

DO $$
DECLARE
    r RECORD;
    v_total BIGINT;
    v_join TEXT;
    v_not_null TEXT;
    v_query TEXT;
BEGIN
    FOR r IN
        SELECT *
        FROM (VALUES
            ('Cepa', 1::BIGINT),
            ('Maridaje', 1),
            ('Localidad', 1),
            ('Finca', 1),
            ('Sala', 1),
            ('Bodega', 1),
            ('Empleado', 1),
            ('Cliente', 20000),
            ('Parcela', 1),
            ('Socio', 1),
            ('Distribuidor', 1),
            ('Exportador', 1),
            ('Vino', 1),
            ('Lote', 1),
            ('Permiso_Exportacion', 1),
            ('Transportista', 1),
            ('Analisis', 1),
            ('Composicion', 1),
            ('Vino_Maridaje', 1),
            ('Transportista_Localidad', 1),
            ('Ingreso', 1),
            ('Transferencia', 1),
            ('Comprobante', 150000),
            ('Renglon_Comprobante', 500000),
            ('Renglon_Ingreso', 1),
            ('Renglon_Transferencia', 1),
            ('Stock_Sala', 1),
            ('Stock_Deposito', 1),
            ('Auditoria_Precio', 1)
        ) AS expected(table_name, minimum_rows)
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM public.%I', r.table_name)
           INTO v_total;

        RAISE NOTICE '%: % filas (minimo: %)',
            r.table_name, v_total, r.minimum_rows;

        IF v_total < r.minimum_rows THEN
            RAISE EXCEPTION
                'B-64: % tiene % filas; se requieren al menos %',
                r.table_name, v_total, r.minimum_rows;
        END IF;
    END LOOP;

    FOR r IN
        SELECT c.conname,
               c.conrelid::REGCLASS AS child_table,
               c.confrelid::REGCLASS AS parent_table,
               array_agg(quote_ident(child_attribute.attname)
                         ORDER BY child_key.ordinality) AS child_columns,
               array_agg(quote_ident(parent_attribute.attname)
                         ORDER BY child_key.ordinality) AS parent_columns
        FROM pg_constraint c
        CROSS JOIN LATERAL
             unnest(c.conkey) WITH ORDINALITY AS child_key(attnum, ordinality)
        JOIN LATERAL
             unnest(c.confkey) WITH ORDINALITY AS parent_key(attnum, ordinality)
          ON parent_key.ordinality = child_key.ordinality
        JOIN pg_attribute child_attribute
          ON child_attribute.attrelid = c.conrelid
         AND child_attribute.attnum = child_key.attnum
        JOIN pg_attribute parent_attribute
          ON parent_attribute.attrelid = c.confrelid
         AND parent_attribute.attnum = parent_key.attnum
        WHERE c.contype = 'f'
          AND c.convalidated
          AND c.connamespace = 'public'::REGNAMESPACE
        GROUP BY c.conname, c.conrelid, c.confrelid
    LOOP
        SELECT string_agg(
                   format('src.%s = dst.%s', child_column, parent_column),
                   ' AND '
               ),
               string_agg(format('src.%s IS NOT NULL', child_column), ' AND ')
          INTO v_join, v_not_null
          FROM unnest(r.child_columns, r.parent_columns)
               AS keys(child_column, parent_column);

        v_query := format(
            'SELECT COUNT(*) FROM %s src WHERE (%s) ' ||
            'AND NOT EXISTS (SELECT 1 FROM %s dst WHERE %s)',
            r.child_table, v_not_null, r.parent_table, v_join
        );
        EXECUTE v_query INTO v_total;

        IF v_total <> 0 THEN
            RAISE EXCEPTION
                'B-64: % filas huérfanas en FK % (% -> %)',
                v_total, r.conname, r.child_table, r.parent_table;
        END IF;
    END LOOP;

    RAISE NOTICE 'B-64: conteos minimos y claves foraneas validados.';
END;
$$;
