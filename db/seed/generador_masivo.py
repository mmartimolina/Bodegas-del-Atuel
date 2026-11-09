import psycopg
from random import seed
from faker import Faker

# Configurar semilla para reproducibilidad (Issue B-03)
seed(42)
fake = Faker('es_AR')
Faker.seed(42)

def ejecutar_carga_masiva():
    print("--- INICIANDO LA CARGA MASIVA DE DATOS DE PRUEBA ---")
    
    try:
        # Conexión a la base de datos PostgreSQL con tus credenciales reales
        with psycopg.connect(
            host="localhost",
            dbname="bodegas_del_atuel",
            user="postgres",
            password="080608"
        ) as conexion:
            with conexion.cursor() as cursor:
                
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

                # Confirmar cambios en la base de datos
                conexion.commit()
                print("\n--- ¡CARGA MASIVA FINALIZADA CON ÉXITO! ---")

    except Exception as e:
        print("\n--- ERROR EN LA CARGA MASIVA ---")
        print(e)
        print("-" * 32)

if __name__ == "__main__":
    ejecutar_carga_masiva()