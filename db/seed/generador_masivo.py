import psycopg
from random import seed
from faker import Faker

# Configurar semilla para reproducibilidad (Issue B-03)
seed(42)
fake = Faker('es_AR')
Faker.seed(42)

def ejecutar_carga_masiva():
    print("--- INICIANDO LA CARGA MASIVA DE DATOS DE PRUEBA (B-01 a B-05) ---")
    
    try:
        # Conexión a la base de datos PostgreSQL con tus credenciales reales
        with psycopg.connect(
            host="localhost",
            dbname="bodegas_del_atuel",
            user="postgres",
            password="080608"
        ) as conexion:
            with conexion.cursor() as cursor:
                
                # 0. Limpiar tablas y reiniciar secuencias de ID de forma limpia
                print("Limpiando datos previos y reiniciando secuencias...")
                cursor.execute("""
                    TRUNCATE TABLE 
                        "Comprobante", 
                        "Exportador", 
                        "Distribuidor", 
                        "Socio", 
                        "Cliente", 
                        "Finca", 
                        "Empleado", 
                        "Sala", 
                        "Localidad", 
                        "Maridaje", 
                        "Cepa" 
                    RESTART IDENTITY CASCADE;
                """)

                # 1. Insertar Cepas (Tabla "Cepa")
                print("Generando Cepas...")
                cepas_data = [
                    ("Malbec", "tinta"),
                    ("Cabernet Sauvignon", "tinta"),
                    ("Bonarda", "tinta"),
                    ("Syrah", "tinta"),
                    ("Chardonnay", "blanca"),
                    ("Torrontés", "blanca"),
                    ("Sauvignon Blanc", "blanca")
                ]
                cursor.executemany(
                    'INSERT INTO "Cepa" (nombre, tipo) VALUES (%s, %s)',
                    cepas_data
                )
                
                # 2. Insertar Maridajes (Tabla "Maridaje")
                print("Generando Maridajes...")
                maridajes_data = [
                    ("Carnes rojas asadas", 16.5),
                    ("Quesos duros", 14.0),
                    ("Pescados y mariscos", 10.0),
                    ("Pasta con salsa blanca", 12.0),
                    ("Chocolate amargo", 18.0)
                ]
                cursor.executemany(
                    'INSERT INTO "Maridaje" (nombre, temperatura) VALUES (%s, %s)',
                    maridajes_data
                )
                
                # 3. Insertar Localidades (Tabla "Localidad")
                print("Generando Localidades...")
                localidades_data = [
                    ("5600", "San Rafael", "Mendoza", "Juan Pérez"),
                    ("5500", "Mendoza Capital", "Mendoza", "María Gómez"),
                    ("5570", "San Martín", "Mendoza", "Carlos López")
                ]
                cursor.executemany(
                    'INSERT INTO "Localidad" (codigo_postal, nombre, provincia, encargado_regional) VALUES (%s, %s, %s, %s)',
                    localidades_data
                )

                # 4. Insertar Salas (Tabla "Sala") - Depende de Localidad (ID 1 y 2)
                print("Generando Salas...")
                salas_data = [
                    ("San Martín", 120, "Domingo", 1),
                    ("Av. Mitre", 450, "Lunes", 2)
                ]
                cursor.executemany(
                    'INSERT INTO "Sala" (calle, numero, dia_cierre, localidad) VALUES (%s, %s, %s, %s)',
                    salas_data
                )

                # 5. Insertar Empleados (Tabla "Empleado") - Depende de Sala
                print("Generando Empleados...")
                empleados_data = [
                    ("20333444552", "Ana Torres", "2023-03-10", 850000.00, 1),
                    ("27444555663", "Luis Gómez", "2023-05-15", 900000.00, 2)
                ]
                cursor.executemany(
                    'INSERT INTO "Empleado" (cuit, nombre, fecha_ingreso, salario, sala) VALUES (%s, %s, %s, %s, %s)',
                    empleados_data
                )

                # 6. Insertar Fincas (Tabla "Finca")
                print("Generando Fincas...")
                fincas_data = [
                    ("Finca El Atuel", 150.50, "San Rafael", "Mendoza"),
                    ("Finca Los Álamos", 95.00, "San Rafael", "Mendoza")
                ]
                cursor.executemany(
                    'INSERT INTO "Finca" (nombre, superficie, departamento, provincia) VALUES (%s, %s, %s, %s)',
                    fincas_data
                )

                # 7. Insertar Clientes (Tabla "Cliente" y sus subtipos - RN-06)
                print("Generando Clientes...")
                clientes_data = [
                    ("Juan Pérez", "DNI", "30111222", "San Martín 100", 1),
                    ("Comercial Cuyo S.A.", "CUIT", "30555666779", "Belgrano 500", 2),
                    ("Global Wine Corp", "Pasaporte", "AB123456", "International Ave 300", 1)
                ]
                
                for nombre, tipo_doc, n_doc, direccion, localidad in clientes_data:
                    cursor.execute(
                        'INSERT INTO "Cliente" (nombre, tipo_doc, n_doc, direccion, localidad) VALUES (%s, %s, %s, %s, %s) RETURNING id_cliente',
                        (nombre, tipo_doc, n_doc, direccion, localidad)
                    )
                    id_cliente = cursor.fetchone()[0]
                    
                    if id_cliente == 1:
                        cursor.execute('INSERT INTO "Socio" (id_cliente) VALUES (%s)', (id_cliente,))
                    elif id_cliente == 2:
                        cursor.execute('INSERT INTO "Distribuidor" (id_cliente, zona, n_habilitacion) VALUES (%s, %s, %s)', (id_cliente, "Centro", "DIST-9988"))
                    elif id_cliente == 3:
                        cursor.execute('INSERT INTO "Exportador" (id_cliente, pais) VALUES (%s, %s)', (id_cliente, "Estados Unidos"))

                # 8. Insertar Comprobantes (Tabla "Comprobante" - RN-08: importes calculados por trigger)
                print("Generando Comprobantes...")
                comprobantes_data = [
                    (1001, "2026-10-01", 1, 1),
                    (1002, "2026-10-02", 2, 2)
                ]
                cursor.executemany(
                    'INSERT INTO "Comprobante" (numero, fecha, cliente, sala) VALUES (%s, %s, %s, %s)',
                    comprobantes_data
                )

                # Confirmar cambios en la base de datos
                conexion.commit()
                print("\n--- ¡CARGA MASIVA B-05 FINALIZADA CON ÉXITO! ---")

    except Exception as e:
        print("\n--- ERROR EN LA CARGA MASIVA ---")
        print(e)
        print("-" * 32)

if __name__ == "__main__":
    ejecutar_carga_masiva()