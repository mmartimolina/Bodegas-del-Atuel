# Catálogo de pruebas de reglas de negocio

## 1. Objetivo

Este documento describe la cobertura de las pruebas automatizadas de las reglas de negocio RN-01 a RN-15 del sistema Bodegas del Atuel.

Las pruebas verifican tanto operaciones válidas como rechazos de operaciones que incumplen las reglas de integridad del modelo.

La ejecución se encuentra implementada en `run_tests.ps1`. Los casos individuales se distribuyen en archivos SQL independientes para facilitar su mantenimiento y diagnóstico.

Este archivo es un catálogo documental: no contiene una segunda implementación de las pruebas ni reemplaza al ejecutor.

## 2. Ejecución

Desde la raíz del repositorio, con Docker en funcionamiento y el contenedor PostgreSQL disponible:

```powershell
.\db\tests\run_tests.ps1
```

El ejecutor:

1. Comprueba que el contenedor `bodegas-atuel-db` esté en funcionamiento.
2. Comprueba que existan las migraciones y los casos de prueba.
3. Crea la base temporal `rn_tests_tmp`.
4. Aplica las migraciones SQL en orden.
5. Ejecuta cada caso positivo o negativo en una base temporal independiente.
6. Comprueba el código de salida y, para los casos negativos, el SQLSTATE esperado.
7. Elimina la base temporal después de cada caso.
8. Informa la cantidad de casos ejecutados, aprobados y fallidos.

La base de desarrollo `bodegas_atuel` está protegida y no se utiliza como base de pruebas.

## 3. Criterios de aceptación

- Los archivos `*.ok.sql` deben finalizar correctamente.
- Los archivos `*.fail.sql` deben producir un error.
- Cada archivo negativo debe producir el SQLSTATE configurado en el ejecutor.
- El mensaje del error debe identificar la regla de negocio correspondiente.
- Los rechazos capturados internamente mediante bloques `DO` deben permitir que el archivo finalice correctamente.
- Cada caso debe ejecutarse sobre una base temporal limpia.
- La ejecución no debe modificar la base de desarrollo.

## 4. Matriz de cobertura RN-01 a RN-15

| Regla | Cobertura positiva | Cobertura negativa | Mecanismo verificado |
|---|---|---|---|
| RN-01 | `rn01_precio.ok.sql` | `rn01_precio_rechazos.ok.sql` | Precio válido y rechazo de precios cero o negativos. |
| RN-02 | `rn02_sala_localidad.ok.sql` | `rn02_sala_localidad_rechazos.ok.sql` | Integridad referencial entre sala y localidad. |
| RN-03 | rn03_empleado_sala.ok.sql | Rechazos internos por sala NULL y sala inexistente | Pertenencia obligatoria de cada empleado a una sala válida. |
| RN-04 | `rn04_cosecha_campania.ok.sql` | `rn04_cosecha_campania_rechazos.ok.sql` | Identificación de lotes y unicidad de cosecha por campaña. |
| RN-05 | `rn05_composicion_suma.ok.sql`, `rn05_vinos_independientes.ok.sql` | `rn05_delete_incompleto.fail.sql`, `rn05_suma_mayor.fail.sql`, `rn05_suma_menor.fail.sql`, `rn05_vino_sin_composicion.fail.sql` | Composición porcentual del vino, suma del 100 % y validación diferida. |
| RN-06 | `rn06_descuentos.ok.sql` | `rn06_descuentos_rechazos.ok.sql`, `rn06_cliente_sin_subtipo.fail.sql` | Subtipos de clientes y reglas de descuentos. |
| RN-07 | `rn07_permisos.ok.sql` | `rn07_permisos_rechazos.ok.sql` | Permisos de exportación, referencias y orden de fechas. |
| RN-08 | `rn08_comprobante.ok.sql` | `rn08_comprobante_rechazos.ok.sql` | Cálculo de importes, conservación de valores históricos y protección de importes manuales. |
| RN-09 | `rn09_stock_limite.ok.sql`, `rn09_stock_ventas.ok.sql` | `rn09_stock_ventas_rechazos.ok.sql` | Límites de stock, ventas y disponibilidad. |
| RN-10 | `rn10_ingresos.ok.sql` | `rn10_transiciones_rechazos.ok.sql`, `rn10_ingreso_en_confeccion.fail.sql`, `rn10_ingreso_vacio.fail.sql`, `rn10_reproceso.fail.sql` | Estados del ingreso, procesamiento, acreditación de stock y prevención de reprocesamiento. |
| RN-11 | `rn11_transferencias.ok.sql` | `rn11_transferencias_rechazos.ok.sql`, `rn11_reproceso.fail.sql`, `rn11_stock_insuficiente.fail.sql` | Transferencias, descuento y acreditación de stock, estados y prevención de reprocesamiento. |
| RN-12 | `rn12_renglones_confeccion.ok.sql` | `rn10_transiciones_rechazos.ok.sql`, `rn11_transferencias_rechazos.ok.sql` | Modificación de renglones durante confección y protección posterior al procesamiento. |
| RN-13 | rn13_auditoria.ok.sql | Rechazos internos de INSERT, UPDATE y DELETE manuales sobre la auditoría | Registro de cambios efectivos, exclusión de cambios sin variación y trazabilidad del usuario. |
| RN-14 | rn14_protecciones.ok.sql | Rechazos internos al eliminar transportistas, bodegas y vinos con dependencias | Eliminaciones permitidas sin dependencias, integridad referencial y conservación de movimientos históricos. |
| RN-15 | rn15_rangos.ok.sql | Rechazos internos por porcentajes fuera de rango, precio negativo y graduación fuera de rango | Restricciones numéricas y porcentuales mediante CHECK. |

### 4.1. Alcance de la cobertura

La matriz identifica los archivos que intervienen en cada regla. Un archivo puede cubrir más de una regla, como ocurre con los rechazos de transiciones y la protección de renglones en RN-10, RN-11 y RN-12.

Los casos negativos con extensión `.fail.sql` esperan un error no controlado por el propio archivo. Los rechazos incluidos en archivos `.ok.sql` capturan internamente las excepciones y verifican que el rechazo se haya producido.

La existencia de un caso positivo y uno negativo no implica que se hayan probado todas las combinaciones posibles de cada regla.

## 5. SQLSTATE de los casos negativos

El ejecutor verifica explícitamente el SQLSTATE de los diez archivos `.fail.sql`.

| Archivo | SQLSTATE esperado | Significado |
|---|---|---|
| `rn05_delete_incompleto.fail.sql` | `P0001` | Excepción definida por la aplicación. |
| `rn05_suma_mayor.fail.sql` | `P0001` | Excepción definida por la aplicación. |
| `rn05_suma_menor.fail.sql` | `P0001` | Excepción definida por la aplicación. |
| `rn05_vino_sin_composicion.fail.sql` | `P0001` | Excepción definida por la aplicación. |
| `rn06_cliente_sin_subtipo.fail.sql` | `23514` | Violación de restricción CHECK. |
| `rn10_ingreso_en_confeccion.fail.sql` | `23514` | Violación de restricción CHECK. |
| `rn10_ingreso_vacio.fail.sql` | `23514` | Violación de restricción CHECK. |
| `rn10_reproceso.fail.sql` | `23514` | Violación de restricción CHECK. |
| `rn11_reproceso.fail.sql` | `23514` | Violación de restricción CHECK. |
| `rn11_stock_insuficiente.fail.sql` | `23514` | Violación de restricción CHECK. |

Además, el ejecutor comprueba que el mensaje de error mencione la regla correspondiente.

Los rechazos internos de los archivos `.ok.sql` se verifican mediante condiciones de excepción específicas de PostgreSQL, como `check_violation`, `not_null_violation`, `foreign_key_violation` y `unique_violation`, según el caso.

## 6. Transacciones y atomicidad

Los casos de procesamiento de ingresos y transferencias verifican los cambios de estado y stock.

En particular:

- `rn10_ingresos.ok.sql` comprueba que el procesamiento de un ingreso acredite el stock del depósito y que un rollback restaure el estado y las cantidades anteriores.
- `rn11_transferencias.ok.sql` comprueba que el procesamiento descuente stock del depósito y acredite stock en la sala, y que un rollback restaure las cantidades y elimine las filas nuevas de stock de sala.

Estas verificaciones utilizan puntos de restauración (`SAVEPOINT`) y `ROLLBACK TO SAVEPOINT` para comprobar que los cambios realizados dentro de la transacción pueden revertirse conjuntamente.

También existen casos independientes que verifican el rechazo de operaciones con stock insuficiente y el reprocesamiento de documentos.

El rollback voluntario de una operación exitosa demuestra la reversibilidad transaccional de los cambios comprobados; no debe confundirse con una prueba que provoque una excepción inesperada en mitad de un procedimiento.

## 7. Pruebas adicionales

El directorio incluye pruebas de funcionalidades adicionales que no forman parte del conjunto RN-01 a RN-15:

| Archivo | Alcance |
|---|---|
| `rn38_antiguedad.ok.sql` | Antigüedad y comportamiento de fechas. |
| `rn39_vistas.ok.sql` | Consultas y vistas del sistema. |
| `rn40_roles.ok.sql` | Permisos y operaciones de los roles de aplicación. |
| `rn40_roles_denegados.ok.sql` | Operaciones que deben ser denegadas a determinados roles. |

Estas pruebas se ejecutan con el mismo mecanismo de aislamiento y validación.

## 8. Resultado de ejecución

Última ejecución registrada:

| Indicador | Resultado |
|---|---:|
| Casos ejecutados | 40 |
| Casos aprobados | 40 |
| Casos fallidos | 0 |
| Base de desarrollo | Intacta |

**Resultado:** todas las pruebas ejecutadas fueron aceptadas por el runner. Los casos negativos produjeron los rechazos esperados.

Este resultado corresponde a una ejecución concreta. Para obtener un resultado actualizado, debe volver a ejecutarse `run_tests.ps1`.

## 9. Archivos del conjunto de pruebas

- `run_tests.ps1`: ejecutor automatizado.
- `*.ok.sql`: casos que deben finalizar correctamente, incluidos los que verifican rechazos capturados internamente.
- `*.fail.sql`: casos que deben producir un error con SQLSTATE y regla esperados.
- `db_tests.sql`: catálogo documental y matriz de cobertura.

