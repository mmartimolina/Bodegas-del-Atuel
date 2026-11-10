# API REST

La API FastAPI genera su especificación OpenAPI desde las rutas y los modelos
Pydantic. En ejecución, consultar Swagger UI en `/docs`, ReDoc en `/redoc` y el
documento JSON en `/openapi.json`. La raíz de API local predeterminada es
`http://localhost:8000`.

## Endpoints

| Método | Ruta | Uso |
|---|---|---|
| `GET` | `/salud` | Disponibilidad de la base conectada. |
| `GET`, `POST` | `/vinos` | Listado filtrable/paginado y alta de vino. |
| `GET`, `PUT`, `DELETE` | `/vinos/{codigo}` | Detalle, edición y baja sujeta a FK. |
| `GET`, `POST` | `/clientes` | Listado/búsqueda y alta del cliente con subtipo. |
| `GET`, `PUT`, `DELETE` | `/clientes/{customer_id}` | Detalle, edición y baja sujeta a FK. |
| `GET` | `/salas`, `/catalogos` | Referencias para formularios. |
| `POST` | `/comprobantes` | Crear una venta completa en una transacción. |
| `GET` | `/comprobantes/{numero}` | Consultar comprobante y renglones. |
| `POST`, `GET` | `/transferencias`, `/transferencias/{numero}` | Crear y consultar transferencias. |
| `POST` | `/transferencias/{numero}/renglones` | Agregar renglones durante confección. |
| `POST` | `/transferencias/{numero}/terminar` | Cerrar confección. |
| `POST` | `/transferencias/{numero}/procesar` | Procesar mediante procedimiento PostgreSQL. |
| `POST`, `GET` | `/ingresos`, `/ingresos/{codigo}` | Crear y consultar ingresos. |
| `POST` | `/ingresos/{codigo}/renglones` | Agregar renglones durante confección. |
| `POST` | `/ingresos/{codigo}/terminar` | Cerrar confección. |
| `POST` | `/ingresos/{codigo}/procesar` | Procesar mediante procedimiento PostgreSQL. |
| `GET` | `/reportes/top-vinos` | Ranking de ventas; `limit` admite 1–100 y por defecto 10. |
| `GET` | `/reportes/ventas-por-sala` | Totales del trimestre hasta la fecha actual. |
| `GET` | `/reportes/vinos-sin-stock?sala=...` | Vinos disponibles en depósito y sin stock en la sala. |
| `GET` | `/reportes/transportista-activo` | Actividad del último mes. |
| `GET` | `/reportes/trazabilidad/{codigo}` | Ingresos, transferencias y ventas de un vino. |

El listado de vinos acepta `limit` (1–500; predeterminado 20), `offset`
(predeterminado 0), `tipo`, `cepa`, `bodega` y `anada`. El listado de clientes
acepta `limit` (1–100), `offset`, `subtipo` (`Socio`, `Distribuidor` o
`Exportador`) y `q` para buscar por nombre o documento. Los límites y tipos
también están descritos en OpenAPI.

## Ejemplos

Alta válida de vino:

```json
{
  "codigo": "VINO-001",
  "nombre": "Reserva",
  "tipo": "Tinto",
  "anada": 2022,
  "volumen_ml": 750,
  "graduacion": 13.5,
  "precio": 12000,
  "bodega": "30700000001",
  "composicion": [{"cepa": 1, "porcentaje": 100}],
  "maridajes": []
}
```

Venta de varias etiquetas:

```json
{
  "cliente": 1,
  "sala": 1,
  "renglones": [
    {"vino": "VINO-001", "cantidad": 2},
    {"vino": "VINO-002", "cantidad": 1}
  ]
}
```

Una venta con cantidad cero, sin renglones o con el mismo vino repetido es
inválida. La disponibilidad de stock, los descuentos y los importes se calculan
y verifican en PostgreSQL; ante un error la transacción completa se revierte.
Una composición cuya suma no sea 100 % también se rechaza al confirmar la
transacción.

## Errores

Las respuestas de error usan JSON `{"detail": "..."}`. Los detalles internos de
PostgreSQL no se devuelven al cliente.

| SQLSTATE | HTTP | Significado |
|---|---:|---|
| `23505` | 409 | Clave o recurso duplicado. |
| `23503` | 409 | Referencia inexistente o entidad protegida. |
| `23514`, `P0001` | 422 | Regla de negocio o restricción incumplida, incluido stock o transición inválida. |
| `23502`, `22P02` | 422 | Dato obligatorio o formato inválido. |
| `P0002` | 404 | Recurso inexistente. |
| `40001`, `40P01` | 503 | Conflicto concurrente; respuesta incluye `Retry-After: 1`. |
| Error de conexión | 503 | PostgreSQL no disponible; respuesta incluye `Retry-After: 1`. |
| Otro error SQL no clasificado | 500 | Error genérico; el detalle se registra solo en el servidor. |
