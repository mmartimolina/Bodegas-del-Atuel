# Bocetos de las pantallas

Los bocetos describen los cinco flujos de interfaz antes de los detalles
visuales. Los datos y las decisiones de stock/importes pertenecen a la API y a
PostgreSQL; el navegador solo recoge entradas y representa respuestas.

## 1. Catálogo de vinos

```text
+ Bodegas del Atuel ─ Catálogo | Vinos | Venta | Transferencias | Indicadores
  Filtros: [Tipo] [Cepa] [Bodega] [Añada] [Filtrar] [Limpiar]
  [Agregar vino]
  Vino                 Tipo     Añada  Volumen  Precio  Bodega       Acciones
  ...                                                                  [Detalle]
  [Anterior]                         Página / total                  [Siguiente]
  Detalle: composición, maridajes y existencias informadas por la API
```

Endpoints: `GET /vinos` (filtros y paginación) y `GET /vinos/{codigo}`.

## 2. Alta y edición de vino

```text
  Código [________] Nombre [________________] Tipo [________] Añada [____]
  Volumen [____] Graduación [____] Precio [____] Bodega [seleccionar]
  Composición: [Cepa ▼] [Porcentaje] [Quitar] [+ Agregar cepa]
  Maridajes: [ ] ... [ ] ...
  [Guardar] [Cancelar]
  Errores de validación devueltos por la API se muestran sin ocultar el motivo.
```

Endpoints: `POST /vinos`, `GET /vinos/{codigo}` y `PUT /vinos/{codigo}`.
La suma de la composición y las restricciones relacionales se validan en
PostgreSQL.

## 3. Nueva venta

```text
  Cliente [buscar por nombre o documento] [seleccionar resultado]
  Sala [seleccionar]
  Productos: [Vino ▼] [Cantidad] [Quitar] [+ Agregar vino]
  [Registrar venta]
  Comprobante: número, renglones y total calculado por el servidor
  Error: mostrar rechazo de stock; la venta completa queda sin aplicar.
```

Endpoints: `GET /clientes?q=...`, `GET /salas`, `GET /vinos` y
`POST /comprobantes`.

## 4. Transferencias

```text
  Sala destino [seleccionar] [Crear transferencia]
  Transferencia #... · Estado: en_confeccion
  Renglones: [Vino ▼] [Cantidad] [+ Agregar vino]
  [Guardar renglones] [Terminar] [Procesar]
  Acciones habilitadas según el estado devuelto por la API.
```

Endpoints: `POST /transferencias`,
`POST /transferencias/{numero}/renglones`,
`POST /transferencias/{numero}/terminar` y
`POST /transferencias/{numero}/procesar`.

## 5. Tablero de indicadores

```text
  [Actualizar]
  Diez vinos más vendidos       Ventas por sala · trimestre
  Vino | Botellas               Sala | Importe y barras comparativas
  Vinos sin stock para sala [▼]
  Código | Vino | Stock en depósito
```

Endpoints: `GET /reportes/top-vinos`, `GET /reportes/ventas-por-sala` y
`GET /reportes/vinos-sin-stock?sala=...`.
