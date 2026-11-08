# A-36 — Matriz de trazabilidad de reglas de negocio RN-01 a RN-15

> **Objetivo:** relacionar cada regla de negocio con los mecanismos SQL que la implementan, las pruebas que verifican su comportamiento y la evidencia disponible.
>
> **Alcance:** esta matriz documenta las migraciones `001` a `010` y las pruebas de `db/tests`. La inspección del catálogo PostgreSQL se realizó sobre la base auxiliar `idx_tmp`, que contiene el esquema instalado con los mecanismos de las migraciones. Esa inspección no implica que la base de desarrollo `bodegas_atuel` tenga las migraciones aplicadas.

## 1. Criterios de lectura

- **Mecanismo:** restricción declarativa, función, procedimiento o trigger que implementa o complementa la regla.
- **Migración:** archivo SQL que crea el mecanismo.
- **Prueba positiva:** caso que comprueba el comportamiento permitido.
- **Prueba negativa:** caso que intenta una operación inválida y comprueba su rechazo.
- **Resultado:** se considera aprobada cuando el caso correspondiente pasó en la ejecución de la suite A35. La suite registró 40 casos aprobados de 40 ejecutados.
- Los nombres de restricciones y triggers se escriben según el catálogo inspeccionado. Los archivos de migración son la fuente de creación y mantenimiento del esquema.

## 2. Matriz consolidada

| Regla | Mecanismos implementados | Migración principal | Prueba positiva | Prueba negativa | Resultado |
|---|---|---|---|---|---|
| **RN-01 — Precio positivo del vino** | `Vino.ck_vino_precio_positivo` (`CHECK precio > 0`). | `002_constraints.sql` | `rn01_precio.ok.sql` | `rn01_precio_rechazos.ok.sql` | Cubierta: acepta precio positivo y rechaza cero o negativo. |
| **RN-02 — Sala asociada a localidad válida** | `Sala.fk_sala_localidad`, FK hacia `Localidad(id_localidad)` con `ON DELETE RESTRICT` y `ON UPDATE RESTRICT`. | `001_esquema.sql` | `rn02_sala_localidad.ok.sql` | `rn02_sala_localidad_rechazos.ok.sql` | Cubierta: verifica integridad referencial de la localidad de la sala. |
| **RN-03 — Empleado perteneciente a una sala** | `Empleado.sala NOT NULL` y `Empleado.fk_empleado_sala`, FK hacia `Sala(id_sala)`. La migración `004` documenta expresamente la reutilización de `NOT NULL` y la FK existentes. | `001_esquema.sql`; referencia explícita en `004_rn03_rn06.sql` | `rn03_empleado_sala.ok.sql` | Rechazos internos de sala `NULL` y sala inexistente en `rn03_empleado_sala.ok.sql`. | Cubierta: se comprueba la obligatoriedad y la referencia válida. |
| **RN-04 — Identificación del lote por parcela y campaña** | `Lote.pk_lote`, PK compuesta `(finca, n_parcela, campania)`; `Lote.fk_lote_parcela`, FK `(finca, n_parcela)` hacia `Parcela`. | `001_esquema.sql` | `rn04_cosecha_campania.ok.sql` | `rn04_cosecha_campania_rechazos.ok.sql` | Cubierta: la clave identifica el lote de una parcela en una campaña y evita duplicados. |
| **RN-05 — Composición porcentual del vino** | `Composicion.pk_composicion`; `ck_composicion_porcentaje_rango` (`0 < porcentaje <= 100`); constraint trigger diferido `trg_rn05_composicion_suma_100` → `fn_composicion_suma_100`; constraint trigger diferido `trg_rn05_vino_composicion_obligatoria` → `fn_vino_composicion_obligatoria`. | `001_esquema.sql`; `002_constraints.sql`; `003_rn05_composicion_deferred.sql`; complemento numérico en `010_rn15_numericas_y_funcion.sql` | `rn05_composicion_suma.ok.sql`, `rn05_vinos_independientes.ok.sql` | `rn05_delete_incompleto.fail.sql`, `rn05_suma_mayor.fail.sql`, `rn05_suma_menor.fail.sql`, `rn05_vino_sin_composicion.fail.sql` | Cubierta: se valida el rango por fila, la suma exacta del 100 % y la existencia de composición al confirmar la transacción. |
| **RN-06 — Descuento según subtipo de cliente** | `Cliente.ck_cliente_descuento_rango`; funciones `fn_descuento_cliente`, `fn_cliente_rechazar_descuento_manual`, `fn_cliente_sincronizar_descuento`, `fn_cliente_validar_cambio_descuento`, `fn_cliente_validar_descuento_final_id` y `fn_cliente_validar_descuento_final_trigger`; triggers de rechazo, sincronización y validación final en `Cliente`, `Socio`, `Distribuidor` y `Exportador`. | `004_rn03_rn06.sql` | `rn06_descuentos.ok.sql` | `rn06_descuentos_rechazos.ok.sql`, `rn06_cliente_sin_subtipo.fail.sql` | Cubierta: verifica descuentos derivados del subtipo, rango y rechazo de clientes sin subtipo válido. |
| **RN-07 — Validez temporal y titularidad del permiso de exportación** | `Permiso_Exportacion.ck_permiso_fechas_orden` (`fecha_vencimiento > fecha_emision`); `fk_permiso_exportador` hacia `Exportador(id_cliente)`. | `001_esquema.sql`; `002_constraints.sql` | `rn07_permisos.ok.sql` | `rn07_permisos_rechazos.ok.sql` | Cubierta: comprueba la referencia al exportador y el orden de fechas. |
| **RN-08 — Cálculo y protección de importes del comprobante** | Funciones `fn_comprobante_inicializar_totales`, `fn_comprobante_proteger_importes`, `fn_total_comprobante`, `fn_renglon_comprobante_calcular` y `fn_renglon_comprobante_recalcular_cabecera`; triggers de inicialización y protección en `Comprobante`, y de cálculo y recálculo en `Renglon_Comprobante`. | `005_rn08_comprobante.sql` | `rn08_comprobante.ok.sql` | `rn08_comprobante_rechazos.ok.sql` | Cubierta: comprueba cálculos automáticos, conservación de valores históricos y rechazo de importes manuales. |
| **RN-09 — Descuento de stock al vender** | Funciones `fn_stock_sala`, `fn_rn09_consumir_stock`, `fn_rn09_reponer_stock` y `fn_renglon_comprobante_aplicar_stock`; triggers `trg_comprobante_registrar_sala` y `trg_renglon_comprobante_stock`; restricciones de stock no negativo y claves de `Stock_Sala`. | `006_rn09_stock_ventas.sql`; restricciones estructurales en `001_esquema.sql` y `002_constraints.sql` | `rn09_stock_limite.ok.sql`, `rn09_stock_ventas.ok.sql` | `rn09_stock_ventas_rechazos.ok.sql` | Cubierta: verifica consumo y reposición, disponibilidad y rechazo cuando el stock no alcanza. La concurrencia al vender la última botella se verificó con dos sesiones `psql` reales (`db/concurrency/run_concurrencia.ps1`, evidencia en `concurrencia_ultima_botella.md`). |
| **RN-10 — Procesamiento de ingresos al depósito** | Procedimiento `sp_procesar_ingreso`; función `fn_estado_documento_validar_transicion`; triggers de transición de estado y protección de confección en `Ingreso`; trigger de protección de renglones en `Renglon_Ingreso`; función auxiliar `fn_bandera_proceso_activada`. | `007_rn10_rn11_procesos.sql`; protección de renglones en `008_rn12_inmutabilidad_renglones.sql` | `rn10_ingresos.ok.sql` | `rn10_transiciones_rechazos.ok.sql`, `rn10_ingreso_en_confeccion.fail.sql`, `rn10_ingreso_vacio.fail.sql`, `rn10_reproceso.fail.sql` | Cubierta: comprueba procesamiento, acreditación de stock, estados permitidos y rechazo de ingreso en confección, vacío o reprocesado. |
| **RN-11 — Procesamiento de transferencias del depósito a sala** | Procedimiento `sp_procesar_transferencia`; función `fn_estado_documento_validar_transicion`; triggers de transición de estado, protección de confección y protección de fecha en `Transferencia`; trigger de protección de renglones en `Renglon_Transferencia`; función auxiliar `fn_bandera_proceso_activada`. | `007_rn10_rn11_procesos.sql`; protección de renglones en `008_rn12_inmutabilidad_renglones.sql` | `rn11_transferencias.ok.sql` | `rn11_transferencias_rechazos.ok.sql`, `rn11_reproceso.fail.sql`, `rn11_stock_insuficiente.fail.sql` | Cubierta: comprueba descuento en depósito, acreditación en sala, estados permitidos y rechazo de reproceso o stock insuficiente. |
| **RN-12 — Inmutabilidad de ingresos y transferencias fuera de confección** | Funciones `fn_ingreso_proteger_confeccion`, `fn_renglon_ingreso_proteger_confeccion`, `fn_renglon_transferencia_proteger_confeccion` y `fn_transferencia_proteger_confeccion`; triggers de protección en cabeceras y renglones de ingreso y transferencia. | `008_rn12_inmutabilidad_renglones.sql` | `rn12_renglones_confeccion.ok.sql` | Rechazos de transición y modificación fuera de confección incluidos en `rn10_transiciones_rechazos.ok.sql` y `rn11_transferencias_rechazos.ok.sql`. | Cubierta: permite modificar durante confección y protege cabeceras/renglones después de esa etapa. |
| **RN-13 — Auditoría de cambios de precio** | Funciones `fn_vino_usuario_funcional_texto`, `fn_vino_auditar_cambio_precio` y `fn_auditoria_precio_proteger`; trigger `Vino.trg_vino_auditar_precio`; trigger `Auditoria_Precio.trg_auditoria_precio_inmutable`. | `009_rn13_auditoria_precios.sql` | `rn13_auditoria.ok.sql` | Rechazos internos de `INSERT`, `UPDATE` y `DELETE` manuales sobre `Auditoria_Precio`. | Cubierta: registra cambios efectivos y protege la tabla de auditoría frente a modificaciones ordinarias. |
| **RN-14 — Protección de entidades con dependencias** | Claves foráneas con políticas de integridad referencial, incluyendo `ON DELETE RESTRICT`, definidas en el esquema. La protección se implementa declarativamente mediante FK. | `001_esquema.sql` | `rn14_protecciones.ok.sql` | Rechazos internos al eliminar transportistas, bodegas y vinos con dependencias. | Cubierta mediante casos representativos: comprueba que no se eliminen esas entidades cuando están referenciadas y contempla eliminaciones sin dependencias. |
| **RN-15 — Rangos y valores numéricos válidos** | `CHECK` de graduación (`ck_vino_graduacion_rango`), kilos (`ck_lote_kg_positivo`), superficies (`ck_finca_superficie_positiva`, `ck_parcela_superficie_positiva`), cantidades (`ck_renglon_comprobante_cantidad_positiva`, `ck_renglon_ingreso_cantidad_positiva`, `ck_renglon_transferencia_cantidad_positiva`), stock no negativo y porcentaje por fila (`ck_composicion_porcentaje_rango`). Función `fn_antiguedad_anios` como funcionalidad numérica complementaria. | `002_constraints.sql`; `010_rn15_numericas_y_funcion.sql` | `rn15_rangos.ok.sql` | Rechazos internos por porcentajes fuera de rango y graduación fuera de rango. El rechazo de precio negativo se documenta en RN-01. | Cubierta: comprueba los rangos numéricos documentados y sus rechazos. |

## 3. Observaciones sobre la implementación

### 3.1. Restricciones declarativas y mecanismos procedurales

No todas las reglas pueden expresarse mediante un `CHECK` de una sola fila. RN-05 requiere evaluar la suma de varias filas de `Composicion`, por lo que utiliza constraint triggers diferidos. RN-06 necesita coordinar el subtipo del cliente con el descuento almacenado. RN-08 y RN-09 requieren cálculos y movimientos derivados. RN-10 y RN-11 requieren procedimientos transaccionales para procesar documentos y mover stock.

### 3.2. RN-03 y propiedades NOT NULL

La consulta de `pg_constraint` permite observar claves y restricciones registradas allí, pero no enumera por sí sola todas las propiedades `NOT NULL` de las columnas. Por eso RN-03 se documenta con la definición de `Empleado.sala` en la migración y con la FK `fk_empleado_sala`.

### 3.3. RN-14 y las claves foráneas

La protección de eliminaciones no se atribuye a una única FK genérica. Cada relación debe conservar su propia política referencial. La migración `001_esquema.sql` define las referencias y sus acciones `ON DELETE`; la prueba `rn14_protecciones.ok.sql` comprueba casos representativos.

### 3.4. Alcance de la evidencia de catálogo

La inspección de `idx_tmp` confirmó la existencia de las restricciones, funciones, procedimientos y triggers enumerados en esta matriz en esa base auxiliar. No debe interpretarse como una verificación del estado actual de `bodegas_atuel`, que fue inspeccionada por separado y se encontró sin tablas instaladas.

## 4. Evidencia de pruebas

La cobertura funcional se documenta también en:

- `docs/auditorias/pruebas_RN01_RN02_RN04_RN05_RN07.md`
- `docs/auditorias/concurrencia_ultima_botella.md`
- `db/tests/db_tests.sql`
- `db/tests/run_tests.ps1`
- Los scripts positivos y negativos individuales referenciados en la matriz.

La ejecución registrada de la suite A35 finalizó con **40/40 casos aprobados**. Esta cifra corresponde a los casos del runner, no a 40 reglas de negocio distintas.

Para RN-10 y RN-11, las pruebas positivas comprueban además que un `ROLLBACK` restaura el estado y las cantidades de stock anteriores. Esa evidencia demuestra reversibilidad transaccional de la operación probada; no equivale a simular cualquier posible error inesperado en cada instrucción interna del procedimiento.

## 5. Criterio de aceptación de A36

- [x] Las quince reglas RN-01 a RN-15 tienen una fila individual.
- [x] Cada fila identifica los mecanismos SQL asociados.
- [x] Cada fila identifica la migración principal.
- [x] Cada fila referencia pruebas positivas y negativas cuando corresponden.
- [x] Se indica el resultado de cobertura registrado.
- [x] Se distingue la inspección de la base auxiliar de la base de desarrollo.
- [x] Se documentan las limitaciones relevantes de la evidencia.

**Conclusión:** la matriz relaciona las RN-01 a RN-15 con sus mecanismos y pruebas disponibles. La cobertura funcional registrada es de 40/40 casos aprobados. La verificación del esquema instalado en `bodegas_atuel` queda fuera de esta evidencia, ya que esa base se encontró vacía durante la inspección.


