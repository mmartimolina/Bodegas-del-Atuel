# -*- coding: utf-8 -*-
"""
Generador masivo de datos - Bodegas del Atuel (issues B-01, B-04, B-05).

Etapas de la consigna cubiertas:
  * Catalogos cargados desde CSV (Anexo B): no se inventan al azar.
  * Volumenes exigidos: 20.000 clientes, 150.000 comprobantes,
    500.000+ renglones de comprobante; todas las tablas con al menos una fila.
  * Semilla fija (B-03): dos ejecuciones el mismo dia generan los mismos datos.
  * Orden de carga segun dependencias FK (ver README).
  * Carga eficiente con COPY/executemany y comparacion fila-a-fila vs lotes.
  * Manejo de triggers documentado: la cadena productiva (ingresos y
    transferencias) se carga con los triggers ACTIVOS usando los procedures
    reales sp_procesar_ingreso / sp_procesar_transferencia; solo el historial
    de ventas (150k comprobantes / 500k+ renglones) se carga con los triggers
    de Comprobante/Renglon_Comprobante desactivados, y el resultado se
    controla con consultas de verificacion (importes, descuentos y stock).
  * Conexion por variables de entorno (PGPASSWORD nunca se escribe aca).

Ejecucion:
    python db/seed/generador_masivo.py [--sin-benchmark]
"""

import csv
import os
import random
import sys
import time
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

import psycopg
from faker import Faker

# ---------------------------------------------------------------------------
# Configuracion general
# ---------------------------------------------------------------------------

SEED = 42
random.seed(SEED)
Faker.seed(SEED)
fake = Faker("es_AR")

BASE = Path(__file__).resolve().parent
CATALOGOS = BASE / "catalogos"
RESULTADOS = BASE / "resultados"

HOY = date.today()

# Volumenes exigidos por la consigna (seccion 3.3 / issue B-05).
N_CLIENTES = 20_000
N_COMPROBANTES = 150_000
N_RENGLONES_MIN = 500_000

# Volumenes de diseno del resto del dataset.
N_BODEGAS = 8
N_FINCAS = 30
N_SALAS = 24
N_TRANSPORTISTAS = 15
N_VINOS = 140
N_INGRESOS = 1_200
N_TRANSFERENCIAS = 900
N_EMPLEADOS = 120

CAMPANIAS = [2021, 2022, 2023, 2024, 2025]
VOLUMENES = [187, 375, 750, 1500, 3000]
PESOS_VOLUMEN = [1, 2, 6, 1, 1]  # 750 ml es la presentacion mas frecuente.
DIAS_CIERRE = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]
PAISES = ["Brasil", "Estados Unidos", "Espania", "Chile", "Uruguay", "Mexico",
          "Canada", "Reino Unido", "Alemania", "Paises Bajos", "Japon", "China"]
SUFIJOS_VINO = ["Reserva", "Gran Reserva", "clasico", "Estate", "Coleccion",
                "Roble", "Barrica", "Premium", "Joven", "Crianza", "Seleccion",
                "Privado", "Tradicion", "Finca Unica", "Microcuvee"]

TABLAS = ["Analisis", "Auditoria_Precio", "Bodega", "Cepa", "Cliente",
          "Composicion", "Comprobante", "Distribuidor", "Empleado", "Exportador",
          "Finca", "Ingreso", "Localidad", "Lote", "Maridaje", "Parcela",
          "Permiso_Exportacion", "Renglon_Comprobante", "Renglon_Ingreso",
          "Renglon_Transferencia", "Sala", "Socio", "Stock_Deposito",
          "Stock_Sala", "Transferencia", "Transportista",
          "Transportista_Localidad", "Vino", "Vino_Maridaje"]

TIMES = []          # (fase, segundos, filas)
LOG_REPORT = []     # lineas volcadas al reporte final


def log(msg: str) -> None:
    print(msg)
    LOG_REPORT.append(msg)


def r2(x) -> Decimal:
    """Redondeo a 2 decimales, half-up (misma semantica que ROUND de PostgreSQL)."""
    return Decimal(x).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def cronometro(fase):
    """Decorador: registra duracion y filas devueltas por cada fase."""
    def decorador(f):
        def envoltura(*args, **kwargs):
            t0 = time.perf_counter()
            resultado = f(*args, **kwargs)
            dt = time.perf_counter() - t0
            filas = resultado if isinstance(resultado, int) else 0
            TIMES.append((fase, dt, filas))
            log(f"[{fase}] {filas if filas else '-'} filas en {dt:.1f}s")
            return resultado
        return envoltura
    return decorador


def leer_csv(nombre):
    with open(CATALOGOS / nombre, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def cargar_env():
    """Carga db/seed/.env (gitignored) sin sobreescribir variables ya definidas."""
    archivo = BASE / ".env"
    if not archivo.exists():
        return
    for linea in archivo.read_text(encoding="utf-8-sig").splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#") or "=" not in linea:
            continue
        clave, valor = linea.split("=", 1)
        os.environ.setdefault(clave.strip(), valor.strip())


def conectar():
    password = os.environ.get("PGPASSWORD")
    if not password:
        sys.exit("Falta PGPASSWORD. Definila en el entorno o creando db/seed/.env "
                 "(ver .env.example). La clave nunca se escribe en este script.")
    return psycopg.connect(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5432"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "bodegas_del_atuel"),
        password=password,
    )


def fecha_aleatoria(desde: date, hasta: date) -> date:
    dias = max((hasta - desde).days, 0)
    return desde + timedelta(days=random.randint(0, dias))


# ---------------------------------------------------------------------------
# Fase 1: catalogos desde CSV (Anexo B) - issue B-01
# ---------------------------------------------------------------------------

@cronometro("catalogos CSV")
def fase_catalogos(cur):
    cur.execute('TRUNCATE TABLE ' + ", ".join(f'"{t}"' for t in TABLAS) +
                " RESTART IDENTITY CASCADE")

    cepas = leer_csv("cepas.csv")
    cur.executemany('INSERT INTO "Cepa" (nombre, tipo) VALUES (%s, %s)',
                    [(c["nombre"], c["tipo"]) for c in cepas])

    maridajes = leer_csv("maridajes.csv")
    cur.executemany('INSERT INTO "Maridaje" (nombre, temperatura) VALUES (%s, %s)',
                    [(m["nombre"], Decimal(m["temperatura"])) for m in maridajes])

    localidades = leer_csv("localidades.csv")
    cur.executemany(
        'INSERT INTO "Localidad" (nombre, codigo_postal, provincia, encargado_regional) '
        "VALUES (%s, %s, %s, %s)",
        [(l["nombre"], l["codigo_postal"], l["provincia"], l["encargado_regional"])
         for l in localidades])

    cur.execute('SELECT id, nombre, tipo FROM "Cepa" ORDER BY id')
    cepas_bd = {n: (i, t) for i, n, t in cur.fetchall()}
    cur.execute('SELECT id, nombre FROM "Maridaje" ORDER BY id')
    maridajes_bd = {n: i for i, n in cur.fetchall()}
    cur.execute('SELECT id_localidad, nombre FROM "Localidad" ORDER BY id_localidad')
    locs = cur.fetchall()
    return len(cepas) + len(maridajes) + len(localidades), cepas_bd, maridajes_bd, locs


# ---------------------------------------------------------------------------
# Fase 2: bodegas, fincas, parcelas, lotes y analisis - issue B-04
# ---------------------------------------------------------------------------

@cronometro("produccion (bodegas/fincas/parcelas/lotes/analisis)")
def fase_produccion(cur):
    # Bodegas: CUIT ficticio de 11 digitos, unico.
    cuits_usados = set()
    bodegas = []
    while len(bodegas) < N_BODEGAS:
        cuit = "30" + f"{random.randint(10_000_000, 99_999_999)}{random.randint(0, 9)}"
        if cuit in cuits_usados:
            continue
        cuits_usados.add(cuit)
        bodegas.append((cuit, f"Bodega {fake.last_name()} {random.choice(['S.A.', 'S.R.L.', 'e Hijos'])}",
                        f"{fake.street_name()} {random.randint(100, 3500)}, Mendoza"))
    cur.executemany('INSERT INTO "Bodega" (cuit, razon_social, domicilio) VALUES (%s, %s, %s)',
                    bodegas)
    bodega_cuits = [b[0] for b in bodegas]

    # Fincas en departamentos del catalogo (Anexo B.3).
    cur.execute('SELECT nombre FROM "Localidad"')
    departamentos = [r[0] for r in cur.fetchall()]
    fincas = [(f"Finca {fake.last_name()}", r2(random.uniform(5, 300)), d, "Mendoza")
              for d in random.choices(departamentos, k=N_FINCAS)]
    cur.executemany(
        'INSERT INTO "Finca" (nombre, superficie, departamento, provincia) VALUES (%s, %s, %s, %s)',
        fincas)
    cur.execute('SELECT id_finca FROM "Finca"')
    finca_ids = [r[0] for r in cur.fetchall()]

    # Parcelas: entidad debil de finca, con cepa del catalogo.
    cur.execute('SELECT id FROM "Cepa"')
    cepa_ids = [r[0] for r in cur.fetchall()]
    parcelas = []          # (finca, n_parcela, superficie, anio, cepa)
    for finca in finca_ids:
        for n in range(1, random.randint(3, 7)):
            parcelas.append((finca, n, r2(random.uniform(1, 40)),
                             random.randint(1995, 2020), random.choice(cepa_ids)))
    cur.executemany(
        'INSERT INTO "Parcela" (finca, n_parcela, superficie, anio_plantacion, cepa) '
        "VALUES (%s, %s, %s, %s, %s)", parcelas)

    # Lotes: por parcela se eligen campanias SIN repetir (PK compuesta).
    # Coherencia RN-04: cosecha entre febrero y abril de la campania.
    n_lote = 1
    lotes = []
    for finca, n_parcela, *_ in parcelas:
        for campania in random.sample(CAMPANIAS, random.randint(1, 3)):
            cosecha = date(campania, random.choice([2, 3, 4]), random.randint(1, 28))
            lotes.append((finca, n_parcela, campania, n_lote, cosecha,
                          r2(random.uniform(3_000, 40_000)), random.choice(bodega_cuits)))
            n_lote += 1
    cur.executemany(
        'INSERT INTO "Lote" (finca, n_parcela, campania, n_lote, fecha_cosecha, kg, bodega_destino) '
        "VALUES (%s, %s, %s, %s, %s, %s, %s)", lotes)

    # Analisis de calidad: 1 a 3 por lote, fechas alrededor de la cosecha.
    analisis = []
    for finca, n_parcela, campania, _n, cosecha, _kg, _bd in lotes:
        for _ in range(random.randint(1, 3)):
            analisis.append((finca, n_parcela, campania,
                             cosecha + timedelta(days=random.randint(-10, 10)),
                             r2(random.uniform(18, 26)), r2(random.uniform(3.1, 3.7)),
                             r2(random.uniform(4, 7))))
    cur.executemany(
        'INSERT INTO "Analisis" (finca, n_parcela, campania, fecha, brix, ph, acidez) '
        "VALUES (%s, %s, %s, %s, %s, %s, %s)", analisis)

    return len(bodegas) + len(fincas) + len(parcelas) + len(lotes) + len(analisis), bodega_cuits


# ---------------------------------------------------------------------------
# Fase 3: vinos, composicion y maridajes (porcentajes que suman 100) - issue B-04
# ---------------------------------------------------------------------------

MARIDAJES_POR_TIPO = {
    "tinto": ["Carnes rojas", "Quesos duros", "Pastas con salsa roja"],
    "blanco": ["Carnes blancas", "Quesos blandos", "Pescados y mariscos"],
    "rosado": ["Entradas y fiambres", "Carnes blancas"],
    "espumante": ["Postres", "Entradas y fiambres"],
}


@cronometro("vinos/composicion/maridajes + auditoria de precios")
def fase_vinos(cur, cepas_bd, maridajes_bd, bodega_cuits):
    tipos_catalogo = [t["tipo"] for t in leer_csv("tipos_vino.csv")]
    presentaciones = [int(p["volumen_ml"]) for p in leer_csv("presentaciones.csv")]
    assert all(t in tipos_catalogo for t in ["tinto", "blanco", "rosado", "espumante"])
    cepas_nombres = list(cepas_bd.keys())
    usados = set()   # (nombre, anada, volumen) -> respeta UNIQUE de Vino
    vinos = []       # (codigo, nombre, tipo, anada, volumen, graduacion, precio, bodega)
    composiciones = []
    maridajes_vino = []
    for i in range(1, N_VINOS + 1):
        cepa = random.choice(cepas_nombres)
        anada = random.choice(CAMPANIAS)
        volumen = random.choices(presentaciones, weights=PESOS_VOLUMEN)[0]
        for intento, sufijo in enumerate(random.sample(SUFIJOS_VINO, len(SUFIJOS_VINO))):
            nombre = f"{cepa} {sufijo}" + (f" {intento}" if intento else "")
            if (nombre, anada, volumen) not in usados:
                break
        usados.add((nombre, anada, volumen))
        tipo_cepa = cepas_bd[cepa][1]
        if tipo_cepa == "tinta":
            tipo = random.choices(["tinto", "rosado", "espumante"], weights=[85, 10, 5])[0]
        else:
            tipo = random.choices(["blanco", "espumante"], weights=[85, 15])[0]
        codigo = f"V{i:04d}"
        vinos.append((codigo, nombre, tipo, anada, volumen,
                      Decimal(str(round(random.uniform(11.5, 15.5), 1))),
                      Decimal(random.randint(3_500, 42_000)), random.choice(bodega_cuits)))

        # Composicion: 1 a 3 cepas del catalogo con porcentajes que suman 100.
        n_cepas = random.choices([1, 2, 3], weights=[60, 30, 10])[0]
        elegidas = random.sample(cepas_nombres, n_cepas)
        if n_cepas == 1:
            porcentajes = [Decimal("100.00")]
        elif n_cepas == 2:
            a = random.randrange(55, 86, 5)
            porcentajes = [Decimal(a), Decimal(100 - a)]
        else:
            a = random.randrange(40, 61, 5)
            b = random.randrange(20, min(36, 101 - a), 5)
            porcentajes = [Decimal(a), Decimal(b), Decimal(100 - a - b)]
        composiciones.extend((codigo, cepas_bd[c][0], p) for c, p in zip(elegidas, porcentajes))

        # Maridajes sugeridos por tipo de vino (catalogo B.2).
        for m in random.sample(MARIDAJES_POR_TIPO[tipo], random.randint(1, len(MARIDAJES_POR_TIPO[tipo]))):
            maridajes_vino.append((codigo, maridajes_bd[m]))

    cur.executemany(
        'INSERT INTO "Vino" (codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega) '
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", vinos)
    cur.executemany('INSERT INTO "Composicion" (vino, cepa, porcentaje) VALUES (%s, %s, %s)',
                    composiciones)
    cur.executemany('INSERT INTO "Vino_Maridaje" (vino, maridaje) VALUES (%s, %s)',
                    maridajes_vino)

    # Auditoria de precios (RN-13): 5 cambios de precio via trigger real.
    cur.execute('SELECT codigo FROM "Vino" ORDER BY codigo LIMIT 5')
    auditados = [r[0] for r in cur.fetchall()]
    for codigo in auditados:
        cur.execute('UPDATE "Vino" SET precio = precio * %s WHERE codigo = %s',
                    (Decimal("1.10"), codigo))
    cur.execute('SELECT codigo, nombre, precio FROM "Vino" ORDER BY codigo')
    vinos_bd = {c: (n, p) for c, n, p in cur.fetchall()}
    return len(vinos) + len(composiciones) + len(maridajes_vino), vinos_bd, auditados


# ---------------------------------------------------------------------------
# Fase 4: salas, empleados, transportistas y cobertura - issue B-04
# ---------------------------------------------------------------------------

@cronometro("salas/empleados/transportistas/cobertura")
def fase_comercial(cur):
    cur.execute('SELECT id_localidad FROM "Localidad" ORDER BY id_localidad')
    loc_ids = [r[0] for r in cur.fetchall()]
    salas = []
    for i in range(N_SALAS):
        salas.append((fake.street_name(), random.randint(100, 9_999),
                      random.choice(DIAS_CIERRE), loc_ids[i % len(loc_ids)]))
    cur.executemany(
        'INSERT INTO "Sala" (calle, numero, dia_cierre, localidad) VALUES (%s, %s, %s, %s)',
        salas)
    cur.execute('SELECT id_sala FROM "Sala" ORDER BY id_sala')
    sala_ids = [r[0] for r in cur.fetchall()]

    cuits = set()
    empleados = []
    while len(empleados) < N_EMPLEADOS:
        cuit = "20" + f"{random.randint(10_000_000, 99_999_999)}{random.randint(0, 9)}"
        if cuit in cuits:
            continue
        cuits.add(cuit)
        empleados.append((cuit, fake.name(), fecha_aleatoria(date(2015, 1, 1), date(2024, 12, 31)),
                           Decimal(random.randint(400_000, 1_500_000)),
                           random.choice(sala_ids)))
    cur.executemany(
        'INSERT INTO "Empleado" (cuit, nombre, fecha_ingreso, salario, sala) '
        "VALUES (%s, %s, %s, %s, %s)", empleados)

    transportistas = []
    cuits_tr = set()
    i = 0
    while len(transportistas) < N_TRANSPORTISTAS:
        i += 1
        cuit = "34" + f"{random.randint(10_000_000, 99_999_999)}{random.randint(0, 9)}"
        while cuit in cuits_tr:
            cuit = "34" + f"{random.randint(10_000_000, 99_999_999)}{random.randint(0, 9)}"
        cuits_tr.add(cuit)
        transportistas.append((f"TR{i:03d}", f"Transportes {fake.last_name()} S.R.L.", cuit,
                               f"logistica{random.randint(1, 999)}@transporte.com.ar",
                               f"02627-{random.randint(40, 99)}-{random.randint(1000, 9999)}",
                               f"{fake.street_name()} {random.randint(100, 2500)}, Mendoza"))
    cur.executemany(
        'INSERT INTO "Transportista" (codigo, razon_social, cuit, email, telefono, domicilio) '
        "VALUES (%s, %s, %s, %s, %s, %s)", transportistas)
    tr_codes = [t[0] for t in transportistas]

    # Cobertura: cada transportista cubre 2 a 4 localidades; toda localidad queda cubierta.
    cobertura = set()
    for tr in tr_codes:
        for loc in random.sample(loc_ids, random.randint(2, 4)):
            cobertura.add((tr, loc))
    cubiertas = {loc for _tr, loc in cobertura}
    for loc in loc_ids:
        if loc not in cubiertas:
            cobertura.add((random.choice(tr_codes), loc))
    cur.executemany(
        'INSERT INTO "Transportista_Localidad" (transportista, localidad) VALUES (%s, %s)',
        sorted(cobertura))
    return len(salas) + len(empleados) + len(transportistas) + len(cobertura), sala_ids, tr_codes


# ---------------------------------------------------------------------------
# Fase 5: stock inicial, ingresos y transferencias (procedures reales, RN-10/RN-11)
# ---------------------------------------------------------------------------

@cronometro("ingresos + transferencias procesadas (RN-10/RN-11)")
def fase_stock(cur, vinos_bd, sala_ids, tr_codes, bodega_cuits):
    # El deposito central tiene fila de stock para cada vino (arranca en 0).
    cur.executemany('INSERT INTO "Stock_Deposito" (vino, cantidad) VALUES (%s, 0)',
                    [(v,) for v in vinos_bd])

    cur.execute('SELECT codigo, bodega FROM "Vino" ORDER BY codigo')
    vinos_bodega = {c: b for c, b in cur.fetchall()}
    bodega_vinos = {}
    for v, b in vinos_bodega.items():
        bodega_vinos.setdefault(b, []).append(v)

    deposito = {v: 0 for v in vinos_bd}      # unidades acreditadas por sp_procesar_ingreso
    transferido = {v: 0 for v in vinos_bd}    # unidades salidas via sp_procesar_transferencia
    stock_sala = {}                           # (sala, vino) -> unidades disponibles
    renglones_ingreso = 0
    renglones_transferencia = 0

    for i in range(1, N_INGRESOS + 1):
        codigo = f"ING-{i:05d}"
        origen = random.choice(bodega_cuits)
        campania = random.choice(CAMPANIAS)
        fecha = date(campania, random.choice([2, 3, 4]), random.randint(1, 28)) \
            + timedelta(days=random.randint(60, 240))
        fecha = min(fecha, HOY)
        cur.execute(
            'INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen) '
            "VALUES (%s, %s, DEFAULT, %s, %s)",
            (codigo, fecha, random.choice(tr_codes), origen))
        disponibles = bodega_vinos[origen]
        max_renglones = min(6, len(disponibles))
        min_renglones = min(3, max_renglones)
        elegidos = random.sample(disponibles, random.randint(min_renglones, max_renglones))
        renglones = [(codigo, v, random.randint(600, 1_600)) for v in elegidos]
        cur.executemany(
            'INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES (%s, %s, %s)',
            renglones)
        renglones_ingreso += len(renglones)
        cur.execute('UPDATE "Ingreso" SET estado = %s WHERE codigo = %s',
                    ("terminado", codigo))
        if random.random() < 0.85:                    # 85% procesados, resto terminado/en confeccion
            cur.execute("CALL sp_procesar_ingreso(%s)", (codigo,))
            for _c, v, cant in renglones:
                deposito[v] += cant

    for i in range(1, N_TRANSFERENCIAS + 1):
        numero = i
        sala = sala_ids[(i - 1) % len(sala_ids)]       # todas las salas reciben stock
        fecha_conf = fecha_aleatoria(date(2024, 6, 1), HOY - timedelta(days=7))
        cur.execute(
            'INSERT INTO "Transferencia" (numero, fecha_confeccion, estado, sala) '
            "VALUES (%s, %s, DEFAULT, %s)", (numero, fecha_conf, sala))
        candidatos = [v for v in vinos_bd if deposito[v] - transferido[v] >= 600]
        if len(candidatos) >= 6:
            elegidos = random.sample(candidatos, random.randint(6, 10))
            renglones = []
            for v in elegidos:
                disponible = deposito[v] - transferido[v]
                cant = min(random.randint(300, 700), disponible)
                if cant > 0:
                    renglones.append((numero, v, cant))
                    transferido[v] += cant
                    stock_sala[(sala, v)] = stock_sala.get((sala, v), 0) + cant
            if renglones:
                cur.executemany(
                    'INSERT INTO "Renglon_Transferencia" (transferencia, vino, cantidad) '
                    "VALUES (%s, %s, %s)", renglones)
                renglones_transferencia += len(renglones)
                dado = random.random()
                if dado < 0.80:                       # 80% procesadas
                    cur.execute('UPDATE "Transferencia" SET estado = %s WHERE numero = %s',
                                ("terminado", numero))
                    cur.execute("CALL sp_procesar_transferencia(%s)", (numero,))
                elif dado < 0.90:                     # 10% terminadas sin procesar
                    cur.execute('UPDATE "Transferencia" SET estado = %s WHERE numero = %s',
                                ("terminado", numero))
                # el resto queda en confeccion con sus renglones (pendiente)
        # sin candidatos: la transferencia queda en confeccion (historial pendiente)

    return renglones_ingreso + renglones_transferencia, stock_sala


# ---------------------------------------------------------------------------
# Fase 6: clientes, subtipos y permisos de exportacion - issues B-05
# ---------------------------------------------------------------------------

@cronometro("clientes + subtipos + permisos (RN-06 activo)")
def fase_clientes(cur):
    cur.execute('SELECT id_localidad FROM "Localidad" ORDER BY id_localidad')
    loc_ids = [r[0] for r in cur.fetchall()]
    alta_desde, alta_hasta = date(2015, 1, 1), date(2023, 10, 31)

    clientes = []
    for i in range(N_CLIENTES):
        clientes.append((fake.name(), "DNI", str(10_000_000 + i),
                         f"{fake.street_name()} {random.randint(100, 9_999)}",
                         random.choice(loc_ids), fecha_aleatoria(alta_desde, alta_hasta)))
    cur.executemany(
        'INSERT INTO "Cliente" (nombre, tipo_doc, n_doc, direccion, localidad, fecha_alta) '
        "VALUES (%s, %s, %s, %s, %s, %s)", clientes)

    cur.execute('SELECT id_cliente, localidad FROM "Cliente" ORDER BY id_cliente')
    filas = cur.fetchall()
    n_socios, n_distribuidores = int(N_CLIENTES * 0.60), int(N_CLIENTES * 0.25)

    socios = [(c, None) for c, _l in filas[:n_socios]]
    cur.executemany('INSERT INTO "Socio" (id_cliente) VALUES (%s)', [(s[0],) for s in socios])

    # dict.fromkeys preserva el orden de aparicion (un set no es reproducible).
    departamentos = list(dict.fromkeys(l for _c, l in filas))
    distribuidores = [(c, f"Zona {random.choice(departamentos)}", f"HAB-{random.randint(1000, 9999)}")
                      for c, _l in filas[n_socios:n_socios + n_distribuidores]]
    cur.executemany(
        'INSERT INTO "Distribuidor" (id_cliente, zona, n_habilitacion) VALUES (%s, %s, %s)',
        distribuidores)

    exportadores = [(c, random.choice(PAISES)) for c, _l in filas[n_socios + n_distribuidores:]]
    cur.executemany('INSERT INTO "Exportador" (id_cliente, pais) VALUES (%s, %s)', exportadores)

    # Permisos de exportacion validos (RN-07: vencimiento posterior a emision).
    permisos = []
    n = 1
    for c, _pais in exportadores:
        for _ in range(random.randint(1, 3)):
            emision = fecha_aleatoria(date(2023, 1, 1), date(2025, 12, 31))
            permisos.append((f"PE-{n:05d}", c, emision, emision + timedelta(days=365 * random.randint(1, 3))))
            n += 1
    cur.executemany(
        'INSERT INTO "Permiso_Exportacion" (codigo, exportador, fecha_emision, fecha_vencimiento) '
        "VALUES (%s, %s, %s, %s)", permisos)
    return N_CLIENTES + len(permisos)


# ---------------------------------------------------------------------------
# Fase 7: ventas masivas (comprobantes y renglones) - issue B-05
# ---------------------------------------------------------------------------

def benchmark_fila_a_fila(conn, cur, vinos_bd, tr_codes, bodega_cuits):
    """Compara insert fila-a-fila vs executemany sobre renglones de ingreso
    en confeccion (no toca stock). Todo dentro de transacciones con ROLLBACK."""
    codigo = "ING-BENCH"
    origen = bodega_cuits[0]
    n_muestra = min(300, len(vinos_bd))
    muestra = random.sample(list(vinos_bd.keys()), n_muestra)

    cur.execute("SAVEPOINT s1")
    cur.execute(
        'INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen) '
        "VALUES (%s, CURRENT_DATE, DEFAULT, %s, %s)", (codigo, tr_codes[0], origen))
    t0 = time.perf_counter()
    for v in muestra:
        cur.execute('INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES (%s, %s, 1)',
                    (codigo, v))
    t_fila = time.perf_counter() - t0
    cur.execute("ROLLBACK TO SAVEPOINT s1")

    cur.execute("SAVEPOINT s2")
    cur.execute(
        'INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen) '
        "VALUES (%s, CURRENT_DATE, DEFAULT, %s, %s)", (codigo, tr_codes[0], origen))
    t0 = time.perf_counter()
    cur.executemany('INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES (%s, %s, 1)',
                    [(codigo, v) for v in muestra])
    t_lote = time.perf_counter() - t0
    cur.execute("ROLLBACK TO SAVEPOINT s2")
    log(f"[benchmark] 300 renglones fila-a-fila: {t_fila:.2f}s | executemany: {t_lote:.2f}s "
        f"| aceleracion ~{t_fila / max(t_lote, 0.001):.0f}x")
    TIMES.append(("benchmark fila-a-fila vs lote (300 renglones)", t_fila, 300))
    TIMES.append(("benchmark lote (300 renglones)", t_lote, 300))


@cronometro("ventas masivas (comprobantes/renglones via COPY)")
def fase_ventas(cur):
    # Los triggers de importes y stock de Comprobante se desactivan SOLO para
    # el historial masivo; el resultado se controla al final (ver README).
    cur.execute('ALTER TABLE "Comprobante" DISABLE TRIGGER USER')
    cur.execute('ALTER TABLE "Renglon_Comprobante" DISABLE TRIGGER USER')

    cur.execute('SELECT id_cliente, descuento FROM "Cliente" ORDER BY id_cliente')
    descuentos = dict(cur.fetchall())
    cliente_ids = list(descuentos.keys())
    cur.execute('SELECT sala FROM "Stock_Sala" GROUP BY sala ORDER BY sala')
    salas_con_stock = [r[0] for r in cur.fetchall()]
    cur.execute('SELECT sala, vino, cantidad FROM "Stock_Sala" ORDER BY sala, vino')
    disponible = {(s, v): c for s, v, c in cur.fetchall()}
    vinos_por_sala = {}
    for s, v in disponible:
        vinos_por_sala.setdefault(s, []).append(v)
    cur.execute('SELECT codigo, precio FROM "Vino" ORDER BY codigo')
    precios = dict(cur.fetchall())

    venta_desde = date(2023, 11, 1)
    dias_venta = max((HOY - timedelta(days=1) - venta_desde).days, 1)
    objetivo = N_RENGLONES_MIN + min(25_000, N_COMPROBANTES)

    # 1) Cabeceras por COPY (importes en NULL: se calculan al final en bloque).
    total_renglones = 0
    comprobantes = []
    with cur.copy('COPY "Comprobante" (numero, fecha, cliente, sala) FROM STDIN') as cp:
        for numero in range(1, N_COMPROBANTES + 1):
            sala = salas_con_stock[numero % len(salas_con_stock)]
            cliente = random.choice(cliente_ids)
            comprobantes.append((numero, sala, cliente))
            cp.write_row((numero, venta_desde + timedelta(days=random.randint(0, dias_venta)),
                         cliente, sala))

    # 2) Renglones por COPY: se vende solo con stock (RN-09) dejando margen.
    #    El descuento se copia del cliente (historico, RN-08) y el subtotal
    #    usa la misma formula del trigger: bruto - 10%... segun corresponda.
    with cur.copy('COPY "Renglon_Comprobante" (comprobante, vino, cantidad, precio_unitario, '
                  "descuento, subtotal) FROM STDIN") as cp:
        for numero, sala, cliente in comprobantes:
            if total_renglones >= objetivo:
                break
            dcto_cliente = descuentos[cliente]
            k = min(random.randint(2, 8), objetivo - total_renglones)
            opciones = vinos_por_sala[sala]
            elegidos = random.sample(opciones, min(k, len(opciones)))
            for vino in elegidos:
                clave = (sala, vino)
                if disponible[clave] <= 1:
                    continue
                cant = random.randint(1, 6)
                if cant > disponible[clave] * 0.9:
                    cant = max(1, int(disponible[clave] * 0.9))
                disponible[clave] -= cant
                bruto = r2(cant * precios[vino])
                dcto = r2(bruto * dcto_cliente / 100)
                cp.write_row((numero, vino, cant, precios[vino], dcto_cliente, bruto - dcto))
                total_renglones += 1

    if total_renglones < N_RENGLONES_MIN:
        raise RuntimeError(f"solo se generaron {total_renglones} renglones "
                           f"(minimo exigido {N_RENGLONES_MIN})")
    log(f"[ventas] renglones generados: {total_renglones}")

    # 3) Importes de cabecera y stock de sala en operaciones de conjunto.
    cur.execute("""
        UPDATE "Comprobante" c
           SET subtotal = agg.sb, descuento = agg.dc, total = agg.tt
          FROM (SELECT r.comprobante,
                       SUM(ROUND(r.cantidad::numeric * r.precio_unitario, 2)) AS sb,
                       SUM(ROUND(ROUND(r.cantidad::numeric * r.precio_unitario, 2)
                                 * COALESCE(r.descuento, 0) / 100, 2)) AS dc,
                       SUM(r.subtotal) AS tt
                  FROM "Renglon_Comprobante" r
                 GROUP BY r.comprobante) agg
         WHERE c.numero = agg.comprobante
    """)
    cur.execute("""
        UPDATE "Stock_Sala" s
           SET cantidad = s.cantidad - vendidas.vendidas
          FROM (SELECT c.sala, r.vino, SUM(r.cantidad) AS vendidas
                  FROM "Renglon_Comprobante" r
                  JOIN "Comprobante" c ON c.numero = r.comprobante
                 GROUP BY c.sala, r.vino) vendidas
         WHERE s.sala = vendidas.sala AND s.vino = vendidas.vino
    """)

    cur.execute('ALTER TABLE "Comprobante" ENABLE TRIGGER USER')
    cur.execute('ALTER TABLE "Renglon_Comprobante" ENABLE TRIGGER USER')
    return total_renglones


# ---------------------------------------------------------------------------
# Fase 8: verificacion y reporte
# ---------------------------------------------------------------------------

@cronometro("verificaciones de control")
def fase_verificacion(conn):
    ok = True

    def check(nombre, sql, esperado=0):
        nonlocal ok
        with conn.cursor() as c:
            c.execute(sql)
            valor = c.fetchone()[0]
        pasa = (valor == esperado)
        ok = ok and pasa
        log(f"  {'OK ' if pasa else 'FALLA'} {nombre}: {valor} (esperado {esperado})")

    log("Consultas de control:")
    check("renglones de comprobante sin cabecera",
          'SELECT COUNT(*) FROM "Renglon_Comprobante" r '
          'WHERE NOT EXISTS (SELECT 1 FROM "Comprobante" c WHERE c.numero = r.comprobante)')
    check("stock de sala negativo", 'SELECT COUNT(*) FROM "Stock_Sala" WHERE cantidad < 0')
    check("stock de deposito negativo", 'SELECT COUNT(*) FROM "Stock_Deposito" WHERE cantidad < 0')
    check("cabeceras con total != suma de renglones",
          'SELECT COUNT(*) FROM "Comprobante" c '
          'WHERE c.total IS DISTINCT FROM (SELECT SUM(r.subtotal) '
          'FROM "Renglon_Comprobante" r WHERE r.comprobante = c.numero)')
    check("renglones con descuento != descuento del cliente",
          'SELECT COUNT(*) FROM "Renglon_Comprobante" r '
          'JOIN "Comprobante" c ON c.numero = r.comprobante '
          'JOIN "Cliente" cl ON cl.id_cliente = c.cliente '
          'WHERE r.descuento IS DISTINCT FROM cl.descuento')
    check("vinos con composicion != 100",
          'SELECT COUNT(*) FROM (SELECT vino FROM "Composicion" '
          'GROUP BY vino HAVING SUM(porcentaje) <> 100) x')
    check("tablas sin filas",
          'SELECT COUNT(*) FROM ('
          + " UNION ALL ".join(f'SELECT 1 FROM "{t}" HAVING COUNT(*) = 0' for t in TABLAS)
          + ') vacias')
    check("comprobantes con fecha < alta del cliente",
          'SELECT COUNT(*) FROM "Comprobante" c JOIN "Cliente" cl '
          'ON cl.id_cliente = c.cliente WHERE c.fecha < cl.fecha_alta')
    check("clientes sin exactamente un subtipo",
          'SELECT COUNT(*) FROM "Cliente" c WHERE '
          '(SELECT COUNT(*) FROM "Socio" s WHERE s.id_cliente = c.id_cliente) + '
          '(SELECT COUNT(*) FROM "Distribuidor" d WHERE d.id_cliente = c.id_cliente) + '
          '(SELECT COUNT(*) FROM "Exportador" e WHERE e.id_cliente = c.id_cliente) <> 1')

    with conn.cursor() as c:
        c.execute("SELECT " + ", ".join(f'(SELECT COUNT(*) FROM "{t}")' for t in TABLAS))
        counts = dict(zip(TABLAS, c.fetchone()))
    log("Conteos por tabla:")
    for t in TABLAS:
        log(f"  {t:24s} {counts[t]:>9,}")
    log(f"  {'TOTAL':24s} {sum(counts.values()):>9,}")

    grandes = [t for t in TABLAS if counts[t] > 10_000]
    log(f"Tablas con mas de 10.000 filas: {', '.join(sorted(grandes))}")
    log(f"Tablas con mas de 100.000 filas: "
        f"{', '.join(sorted(t for t in TABLAS if counts[t] > 100_000))}")
    if not ok:
        log("HAY VERIFICACIONES FALLIDAS")
    return 1 if ok else 0


def escribir_reporte():
    RESULTADOS.mkdir(exist_ok=True)
    archivo = RESULTADOS / "reporte_carga.txt"
    with open(archivo, "w", encoding="utf-8") as f:
        f.write("Reporte de carga masiva - Bodegas del Atuel (B-01/B-04/B-05)\n")
        f.write(f"Fecha: {date.today().isoformat()} | Semilla: {SEED} | "
                f"PostgreSQL local via variables de entorno\n")
        f.write("=" * 70 + "\n")
        f.write("\n".join(LOG_REPORT) + "\n")
        f.write("=" * 70 + "\n")
        f.write("Tiempos por fase:\n")
        for fase, dt, filas in TIMES:
            f.write(f"  {fase:60s} {dt:8.1f}s {filas:>9,} filas\n")
    print(f"Reporte escrito en {archivo}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    hacer_benchmark = "--sin-benchmark" not in sys.argv
    cargar_env()
    conn = conectar()
    try:
        with conn.cursor() as cur:
            _r, cepas_bd, maridajes_bd, _locs = fase_catalogos(cur)
            conn.commit()
            _r, bodega_cuits = fase_produccion(cur)
            conn.commit()
            _r, vinos_bd, auditados = fase_vinos(cur, cepas_bd, maridajes_bd, bodega_cuits)
            conn.commit()
            _r, sala_ids, tr_codes = fase_comercial(cur)
            conn.commit()
            _r, stock_sala = fase_stock(cur, vinos_bd, sala_ids, tr_codes, bodega_cuits)
            conn.commit()
            if hacer_benchmark:
                benchmark_fila_a_fila(conn, cur, vinos_bd, tr_codes, bodega_cuits)
                conn.commit()
            fase_clientes(cur)
            conn.commit()
            fase_ventas(cur)
            conn.commit()
        ok = fase_verificacion(conn)
        conn.commit()
    finally:
        conn.close()
    escribir_reporte()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
