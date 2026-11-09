import psycopg
from random import seed
from faker import Faker

# Configuración de semilla para reproducibilidad (Issue B-03)
seed(42)
fake = Faker('es_AR')
Faker.seed(42)

def ejecutar_carga_masiva():
    print("--- INICIANDO CARGA MASIVA OPTIMIZADA (Issue B-07) ---")
    
    try:
        with psycopg.connect(
            host="localhost",
            dbname="bodegas_del_atuel",
            user="postgres",
            password="080608"
        ) as conexion:
            with conexion.cursor() as cursor:
                
                # Optimización de sesión: Iniciar bloque atómico único
                print("Limpiando datos previos y reseteando secuencias en cascada...")
                cursor.execute("""
                    TRUNCATE TABLE 
                        "Stock_Deposito", "Stock_Sala", "Renglon_Transferencia",
                        "Renglon_Ingreso", "Renglon_Comprobante", "Comprobante",
                        "Transferencia", "Ingreso", "Transportista_Localidad",
                        "Vino_Maridaje", "Composicion", "Analisis", "Transportista",
                        "Permiso_Exportacion", "Lote", "Vino", "Exportador",
                        "Distribuidor", "Socio", "Parcela", "Cliente", "Empleado",
                        "Bodega", "Sala", "Finca", "Localidad", "Maridaje", "Cepa"
                    RESTART IDENTITY CASCADE;
                """)

                print("Ejecutando inserciones por orden topológico y validación de triggers...")
                
                # 1. Catálogos Base
                cursor.executemany('INSERT INTO "Cepa" (nombre, tipo) VALUES (%s, %s)', [
                    ("Malbec", "tinta"), ("Cabernet Sauvignon", "tinta"), ("Bonarda", "tinta"),
                    ("Syrah", "tinta"), ("Chardonnay", "blanca"), ("Torrontés", "blanca"), ("Sauvignon Blanc", "blanca")
                ])
                
                cursor.executemany('INSERT INTO "Maridaje" (nombre, temperatura) VALUES (%s, %s)', [
                    ("Carnes rojas asadas", 16.5), ("Quesos duros", 14.0), ("Pescados y mariscos", 10.0),
                    ("Pasta con salsa blanca", 12.0), ("Chocolate amargo", 18.0)
                ])
                
                cursor.executemany('INSERT INTO "Localidad" (codigo_postal, nombre, provincia, encargado_regional) VALUES (%s, %s, %s, %s)', [
                    ("5600", "San Rafael", "Mendoza", "Juan Pérez"),
                    ("5500", "Mendoza Capital", "Mendoza", "María Gómez"),
                    ("5570", "San Martín", "Mendoza", "Carlos López")
                ])

                cursor.executemany('INSERT INTO "Finca" (nombre, superficie, departamento, provincia) VALUES (%s, %s, %s, %s)', [
                    ("Finca El Atuel", 150.50, "San Rafael", "Mendoza"),
                    ("Finca Los Álamos", 95.00, "San Rafael", "Mendoza")
                ])

                # 2. Infraestructura y Personal
                cursor.executemany('INSERT INTO "Sala" (calle, numero, dia_cierre, localidad) VALUES (%s, %s, %s, %s)', [
                    ("San Martín", 120, "Domingo", 1), ("Av. Mitre", 450, "Lunes", 2)
                ])

                cursor.executemany('INSERT INTO "Bodega" (cuit, razon_social, domicilio) VALUES (%s, %s, %s)', [
                    ("30112233449", "Bodega Atuel S.A.", "Ruta 144 Km 650"),
                    ("30998877665", "Vinos del Sur SRL", "San Martín 890")
                ])

                cursor.executemany('INSERT INTO "Empleado" (cuit, nombre, fecha_ingreso, salario, sala) VALUES (%s, %s, %s, %s, %s)', [
                    ("20333444552", "Ana Torres", "2023-03-10", 850000.00, 1),
                    ("27444555663", "Luis Gómez", "2023-05-15", 900000.00, 2)
                ])

                # 3. Clientes y Subtipos
                clientes = [
                    ("Juan Pérez", "DNI", "30111222", "San Martín 100", 1),
                    ("Comercial Cuyo S.A.", "CUIT", "30555666779", "Belgrano 500", 2),
                    ("Global Wine Corp", "Pasaporte", "AB123456", "International Ave 300", 1)
                ]
                for c in clientes:
                    cursor.execute(
                        'INSERT INTO "Cliente" (nombre, tipo_doc, n_doc, direccion, localidad) VALUES (%s, %s, %s, %s, %s) RETURNING id_cliente', c
                    )
                    idc = cursor.fetchone()[0]
                    if idc == 1: cursor.execute('INSERT INTO "Socio" (id_cliente) VALUES (%s)', (idc,))
                    elif idc == 2: cursor.execute('INSERT INTO "Distribuidor" (id_cliente, zona, n_habilitacion) VALUES (%s, %s, %s)', (idc, "Centro", "DIST-9988"))
                    elif idc == 3: cursor.execute('INSERT INTO "Exportador" (id_cliente, pais) VALUES (%s, %s)', (idc, "Estados Unidos"))

                # 4. Producción y Vinos (con validación RN-05 integrada)
                cursor.executemany('INSERT INTO "Parcela" (finca, n_parcela, superficie, anio_plantacion, cepa) VALUES (%s, %s, %s, %s, %s)', [
                    (1, 1, 50.0, 2018, 1), (2, 1, 45.5, 2019, 2)
                ])

                cursor.executemany('INSERT INTO "Vino" (codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)', [
                    ("V-MALB-01", "Atuel Reserva Malbec", "Tinto", 2021, 750, 14.5, 4500.00, "30112233449"),
                    ("V-CABS-02", "Atuel Cabernet", "Tinto", 2022, 750, 14.0, 4200.00, "30112233449")
                ])

                cursor.executemany('INSERT INTO "Composicion" (vino, cepa, porcentaje) VALUES (%s, %s, %s)', [
                    ("V-MALB-01", 1, 100.00), ("V-CABS-02", 2, 100.00)
                ])

                # 5. Logística (Transportistas y Cobertura)
                cursor.executemany('INSERT INTO "Transportista" (codigo, razon_social, cuit, email, telefono, domicilio) VALUES (%s, %s, %s, %s, %s, %s)', [
                    ("TR-01", "Logística Cuyo SRL", "20223344556", "contacto@cuyo.com", "2614444444", "San Rafael 2300"),
                    ("TR-02", "Transportes del Sur", "27334455667", "info@delsur.com", "2615555555", "Av. Mitre 1200")
                ])
                cursor.executemany('INSERT INTO "Transportista_Localidad" (transportista, localidad) VALUES (%s, %s)', [("TR-01", 1), ("TR-02", 2)])

                # 6. Ingresos, Transferencias y Stock Previo (Cumpliendo RN-12 y RN-09)
                cursor.execute('INSERT INTO "Ingreso" (codigo, fecha, transportista, bodega_origen) VALUES (%s, %s, %s, %s)', ("ING-001", "2026-09-15", "TR-01", "30112233449"))
                cursor.execute('INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES (%s, %s, %s)', ("ING-001", "V-MALB-01", 1000))

                cursor.execute('INSERT INTO "Transferencia" (numero, fecha_confeccion, sala) VALUES (%s, %s, %s)', (5001, "2026-09-20", 1))
                cursor.execute('INSERT INTO "Renglon_Transferencia" (transferencia, vino, cantidad) VALUES (%s, %s, %s)', (5001, "V-MALB-01", 150))

                cursor.executemany('INSERT INTO "Stock_Deposito" (vino, cantidad) VALUES (%s, %s)', [("V-MALB-01", 850), ("V-CABS-02", 500)])
                cursor.executemany('INSERT INTO "Stock_Sala" (sala, vino, cantidad) VALUES (%s, %s, %s)', [(1, "V-MALB-01", 150), (2, "V-CABS-02", 200)])

                # 7. Comprobantes de Venta (Cumpliendo RN-08)
                cursor.executemany('INSERT INTO "Comprobante" (numero, fecha, cliente, sala) VALUES (%s, %s, %s, %s)', [
                    (1001, "2026-10-01", 1, 1), (1002, "2026-10-02", 2, 2)
                ])
                for comp, vino, cant, precio in [(1001, "V-MALB-01", 2, 4500.00), (1002, "V-CABS-02", 3, 4200.00)]:
                    cursor.execute(
                        'INSERT INTO "Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario) VALUES (%s, %s, %s, %s)',
                        (comp, vino, cant, precio)
                    )

                conexion.commit()
                print("\n--- ¡CARGA MASIVA FINALIZADA CON ÉXITO! ---")

    except Exception as e:
        print("\n--- ERROR EN LA CARGA MASIVA ---")
        print(e)

if __name__ == "__main__":
    ejecutar_carga_masiva()