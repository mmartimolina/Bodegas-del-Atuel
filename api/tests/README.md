# Pruebas de API

Las pruebas HTTP de `test_api.py` usan ASGI y sustituyen la conexión/repository
para verificar rutas, validaciones, traducción de errores y parametrización sin
escribir en una base local. Ejecutar desde la raíz del proyecto:

```powershell
python -m pytest
```

La suite de reglas de negocio PostgreSQL es independiente y se ejecuta con
`db/tests/run_tests.ps1` contra una base temporal. No configurar esa suite contra
la base de desarrollo.
