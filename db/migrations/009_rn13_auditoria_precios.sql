-- 009_rn13_auditoria_precios.sql
-- RN-13 (issue #35): todo cambio de precio de un vino queda auditado
-- (vino, precio anterior, precio nuevo, fecha/hora, usuario).
--
-- Registro: trigger AFTER UPDATE OF precio ON Vino con OLD.precio IS DISTINCT
-- FROM NEW.precio (solo cambios efectivos; valores iguales no generan filas).
--
-- Decisiones adoptadas (documentadas en docs/modelo/12):
--  - usuario: current_user (usuario de conexion de la base). La aplicacion todavia
--    no dispone de mecanismo propio de autenticacion funcional; se documento el
--    limite: para registrar un usuario funcional la API puede usar
--    SET LOCAL bodegas.usuario_funcional = '...'; si la bandera esta presente se
--    adjunta al registro como sufijo "<conex>:<usuario_funcional>". Sin bandera se
--    registra unicamente el usuario de conexion.
--  - Valores nulos: precio_anterior y precio_nuevo son NOT NULL en el modelo;
--    la transicion que involucra un precio nulo no se audita (no incluye un valor
--    comparable) y, por coherencia con RN-01, actualizar el precio al valor no nulo
--    desde un NULL no se audita... permaneciendo el precio de alta obligatorio en el
--    INSERT. La carga inicial del precio se hace en la propia fila del vino y no
--    genera registro de auditoria (no hay valor anterior).
--    Regla adoptada de UPDATE: si OLD.precio IS NOT NULL y NEW.precio IS NOT NULL
--    y distintos -> se audita. Si OLD.precio IS NULL y NEW.precio <> NULL -> no se
--    audita porque no hay precio anterior que conservar (el modelo NO admite fila
--    con precio_anterior nulo); por decision adoptada se documenta la limitacion de
--    crear el vino con su precio correcto en el INSERT (no en un UPDATE posterior).
--  - Imposibilidad de manipulacion accidental desde operaciones ordinarias: un
--    trigger BEFORE INSERT OR UPDATE OR DELETE en Auditoria_Precio rechaza toda
--    operacion manual; el acceso de escritura se detiene por defecto con roles,
--    quedando como via administrativa explicita el owner/DBA que desactive el
--    trigger (etapa administrativa documentada en docs/roles 012).

BEGIN;

CREATE OR REPLACE FUNCTION fn_vino_usuario_funcional_texto()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF COALESCE(current_setting('bodegas.usuario_funcional', true), '') <> '' THEN
        RETURN current_user || '::' || current_setting('bodegas.usuario_funcional', true);
    END IF;

    RETURN current_user::TEXT;
END;
$$;

COMMENT ON FUNCTION fn_vino_usuario_funcional_texto() IS
    'RN-13: devuelve "<conexion>:<usuario funcional>" o solo el usuario de conexion.';

-- =========================================================
-- Generacion de filas de auditoria por cambio de precio
-- =========================================================

CREATE OR REPLACE FUNCTION fn_vino_auditar_cambio_precio()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER      -- RN-13: la fila la genero el sistema, no el actor que cambia el precio
SET search_path = public
AS $$
BEGIN
    IF NEW.precio IS DISTINCT FROM OLD.precio THEN
        IF OLD.precio IS NULL OR NEW.precio IS NULL THEN
            -- El precio de alta se carga en el INSERT (sin valor anterior); los
            -- UPDATE que incluyan NULL en una punta no quedan auditados por el
            -- modelo (precio_anterior/precio_nuevo son NOT NULL) y se rechaza
            -- ese caso para evitar perder informacion silenciosamente.
            RAISE EXCEPTION
                'RN-13: la transicion del precio de % involucra nulos: cargue el precio inicial en el INSERT del vino, o actualice a un valor concreto (no nulo)',
                NEW.codigo
                USING ERRCODE = '23514';
        END IF;

        -- Solo el propio trigger puede insertar: la ventana de la bandera
        -- (a nivel de transaccion) se abre y se cierra alrededor del INSERT,
        -- bloqueando los INSERT manuales del resto de la sesion.
        PERFORM set_config('bodegas.auditoria_interna', '1', true);

        INSERT INTO "Auditoria_Precio"
            (vino, precio_anterior, precio_nuevo, fecha_hora, usuario)
        VALUES
            (NEW.codigo, OLD.precio, NEW.precio, clock_timestamp(),
             fn_vino_usuario_funcional_texto());

        PERFORM set_config('bodegas.auditoria_interna', '0', true);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_vino_auditar_precio
    AFTER UPDATE OF precio ON "Vino"
    FOR EACH ROW
    EXECUTE FUNCTION fn_vino_auditar_cambio_precio();

COMMENT ON TRIGGER trg_vino_auditar_precio ON "Vino" IS
    'RN-13: registra cada cambio efectivo de precio (anterior, nuevo, fecha/hora, usuario).';

-- =========================================================
-- La auditoria no se altera desde operaciones ordinarias
-- =========================================================

CREATE OR REPLACE FUNCTION fn_auditoria_precio_proteger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT'
       AND COALESCE(current_setting('bodegas.auditoria_interna', true), '') = '1' THEN
        RETURN NEW; -- INSERT generado por trg_vino_auditar_precio
    END IF;

    RAISE EXCEPTION
        'RN-13: "Auditoria_Precio" solo acepta filas generadas por trg_vino_auditar_precio (operacion % rechazada)',
        TG_OP
        USING ERRCODE = '42804';
END;
$$;

CREATE TRIGGER trg_auditoria_precio_inmutable
    BEFORE INSERT OR UPDATE OR DELETE ON "Auditoria_Precio"
    FOR EACH ROW
    EXECUTE FUNCTION fn_auditoria_precio_proteger();

COMMENT ON TRIGGER trg_auditoria_precio_inmutable ON "Auditoria_Precio" IS
    'RN-13: la tabla de auditoria es de solo lectura para las operaciones ordinarias.';

COMMIT;
