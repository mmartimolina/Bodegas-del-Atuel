# -*- coding: utf-8 -*-
"""Generador A-08: DER multipágina para Bodegas del Atuel.

Salidas (en D:\\Bodegas-del-Atuel\\docs\\modelo):
  - 08_diagrama_entidad_relacion.drawio  (7 páginas: mapa + 6 módulos; editable en diagrams.net)
  - 08_der_00_mapa.svg + 08_der_01..06_*.svg (renderizados por este script a partir del
    MISMO layout; no son exportaciones automáticas de draw.io)

Fuentes de contenido: A-01..A-07 (+ docs/requisitos.md). No se inventa nada:
  * Si un extremo es inferido/condicionado según A-04, lleva '*' en el rango.
  * Las PK se muestran como CANDIDATAS con estado (respaldada/inferida/pendiente),
    nunca como decisión cerrada.
"""
import html
import os

OUT = r"D:\Bodegas-del-Atuel\docs\modelo"

CLS = {
    'strong': ('#dae8fc', '#6c8ebf', ''),
    'weak':   ('#d5e8d4', '#666666', 'débil'),
    'assoc':  ('#ffe6cc', '#d79b00', 'asociativa'),
    'stock':  ('#fff2cc', '#d6b656', 'inventario'),
    'super':  ('#e1d5e7', '#9673a6', 'supertipo'),
    'sub':    ('#f7f0fa', '#9673a6', 'subtipo'),
}
HEAD_H = 36
LINE_H = 15
PAD_B = 8
W = 200


class Node:
    def __init__(self, nid, label, kind, attrs, keynote, x, y, w=W, ref=False, dashed=False):
        self.id, self.label, self.kind = nid, label, kind
        self.attrs, self.key = attrs, keynote
        self.x, self.y, self.w = x, y, w
        self.h = HEAD_H + len(attrs) * LINE_H + PAD_B + len(keynote.split('\n')) * 13
        self.ref = ref

EX_OPT = {'r': (1.0, 0.5), 'l': (0.0, 0.5), 't': (0.5, 0.0), 'b': (0.5, 1.0)}
EN_OPT = EX_OPT


def esc(s):
    return html.escape(s, quote=True)


def node_lines(n):
    body = [(n.label, 'head')]
    kn = CLS[n.kind][2]
    body.append(('[' + kn + ']') if kn else ('[fuerte]'),)
    return body


def node_value(n):
    kn = CLS[n.kind][2] or 'fuerte'
    head = f'<b>{esc(n.label)}</b> <font size="9" color="#444444">[{kn}]</font>'
    if n.ref:
        head += ' <font size="8" color="#777777">(referencia)</font>'
    body = '<br/>'.join(esc(a) for a in n.attrs)
    keys = '<br/>'.join('<font size="9" color="#7a0000">' + esc(k) + '</font>' for k in n.key.split('\n'))
    return head + '<br/>' + body + '<br/>' + keys

# =====================================================================
# DATOS POR PÁGINA
# =====================================================================
PAGES = []

# -------------------- 01 Producción --------------------
PAGES.append(dict(
    key='01_produccion', title='A-08 · DER (1/6) — Producción de uva', note_y=520,
    nodes=[
        Node('Finca', 'Finca', 'strong',
             ['id_finca  [K]', 'nombre', 'superficie', 'departamento', 'provincia'],
             'Candidata PK: id_finca [R · "ID" sec. 5]\n(natural vs. subrogada: decisión de diseño pendiente)', 40, 90),
        Node('Parcela', 'Parcela', 'weak',
             ['finca  [K/FK propietaria]', 'n_parcela  [K parcial]', 'superficie', 'anio_plantacion', 'cepa  [FK]'],
             'DÉBIL de Finca (3.2, 5§, etapa 1-2)\nCandidata PK: (finca, n_parcela) = ParK-1 [R · triple cita]', 320, 70),
        Node('Cepa', 'Cepa', 'strong',
             ['id  [K]', 'nombre', 'tipo'],
             'Candidata PK: id [R]\nnombre: AK [P] (unicidad no declarada; CeK-2)', 600, 90),
        Node('Lote', 'Lote de uva', 'strong',
             ['n_lote  [K·pend]', 'parcela (finca+n_parcela)  [FK]', 'campania', 'fecha_cosecha', 'kg', 'bodega_destino  [FK]'],
             'Candidatas PK pendientes (Q-02/LoteK-a):\nn_lote [P]  |  (parcela, campania) [P: unicidad textual UNIQUE etapa 2; minimalidad no demostrada]', 300, 330),
        Node('Analisis', 'Análisis de calidad', 'strong',
             ['id_analisis  [K]', 'lote  [FK]', 'fecha', 'brix', 'ph', 'acidez'],
             'Candidata PK: id_analisis [R] (identidad de fila dudosa: D-6/Q-06)\nAK (lote, fecha) [P] (AK-2 sin garantía)', 600, 330),
    ],
    edges=[
        ('e1', 'Finca', 'r', 'Parcela', 'l', 'REL-04  Finca 1*..N — Parcela 1..1  (identificadora; participación total de Parcela) [P]'),
        ('e2', 'Parcela', 'r', 'Cepa', 'l', 'REL-05  Parcela 1..1 — Cepa 0*..N*  (cepa plantada; sin historia: D-7/AMB-12) [P]'),
        ('e3', 'Parcela', 'b', 'Lote', 't', 'REL-06  Parcela 0*..N — Lote 1*..1  (máx. 1 por campaña: RN-04) [P]'),
        ('e4', 'Lote', 'r', 'Analisis', 'l', 'REL-08  Lote 1..N* — Análisis 1*..1*  (ambos inferidos) [P]'),
    ],
    notes=[('Lote → Bodega (REL-07, Lote 1..1 — Bodega 0*..N): relación ENTRE MÓDULOS (módulo 2, pág. 02). Rol "bodega destino" '
            '≠ bodega elaboradora del Vino ≠ bodega origen del Ingreso (AMB-06). [P]', 40, 520, 460),
           ],
))

# -------------------- 02 Elaboración --------------------
PAGES.append(dict(
    key='02_elaboracion', title='A-08 · DER (2/6) — Elaboración de vinos',
    nodes=[
        Node('Bodega', 'Bodega', 'strong',
             ['cuit  [K — UNIQUE etapa 2]', 'razon_social', 'domicilio'],
             'Candidata PK: cuit [R por UNIQUE textual; PK no decidida; alternativa ID subrogado abierta]', 40, 90),
        Node('Vino', 'Vino', 'strong',
             ['codigo  [K·inf: API /vinos/{cod}; sin UNIQUE textual]', 'nombre', 'tipo', 'anada', 'volumen_ml', 'graduacion', 'precio  (RN-01: único en red, > 0)', 'bodega  [FK]'],
             'Candidatas PK pendientes (VK): codigo [I]  |  (nombre, anada, volumen_ml) [P: unicidad textual; minimalidad no demostrada]', 300, 90, 220),
        Node('Maridaje', 'Maridaje', 'strong',
             ['id  [K]', 'nombre', 'temperatura'],
             'Candidata PK: id [R]\nnombre: AK [P] (sin UNIQUE textual; MK-2)', 600, 90),
        Node('Cepa_ref', 'Cepa', 'strong',
             ['id  [K]', 'nombre', 'tipo'],
             'Definida en pág. 01', 40, 420, ref=True),
        Node('Composicion', 'Composición (vino–cepa)', 'assoc',
             ['vino  [K/FK]', 'cepa  [K/FK]', 'porcentaje  (RN-05: suma 100 por vino)'],
             'N:M con atributo (REL-10)\nCandidata PK: (vino, cepa) = ComK-1 [I] — ComK-a abierto', 300, 450),
        Node('VinoMaridaje', 'Vino–Maridaje', 'assoc',
             ['vino  [K/FK]', 'maridaje  [K/FK]'],
             'N:M sin atributos (REL-11)\nCandidata PK: (vino, maridaje) = VMK-1 [I] — D-9 abierto', 600, 450),
    ],
    edges=[
        ('g1', 'Bodega', 'r', 'Vino', 'l', 'REL-09  Bodega 2*..N — Vino 1..1  ("varios"; mín. 2 no definitivo: AMB-05) [P]'),
        ('g2', 'Vino', 'b', 'Composicion', 't', 'REL-10  Vino 1..N cepas  (mín. 1 expreso: "una o más") [P]'),
        ('g3', 'Composicion', 'l', 'Cepa_ref', 'r', 'REL-10  Cepa 0*..N vinos  (mín. 0 indirecto: D2) [P]'),
        ('g4', 'Vino', 'r', 'VinoMaridaje', 'l', 'REL-11  Vino 1..N maridajes  (mín. 1 expreso) [P]'),
        ('g5', 'VinoMaridaje', 'r', 'Maridaje', 'l', 'REL-11  Maridaje 0*..N vinos  (mín. 0 inferido: AMB-16) [P]'),
    ],
    notes=[('Lote → Bodega (REL-07): llega desde el módulo 1 (pág. 01). Roles de bodega separados (AMB-06).', 40, 560, 380)],
))

# -------------------- 03 Comercial + jerarquía --------------------
PAGES.append(dict(
    key='03_comercial', title='A-08 · DER (3/6) — Red comercial + jerarquía de clientes (A-06)',
    nodes=[
        Node('Localidad', 'Localidad', 'strong',
             ['codigo_postal  [K·pend]', 'nombre', 'provincia', 'encargado_regional'],
             'Candidatas PK pendientes (LK): codigo_postal [P]  |  (nombre, provincia) [P] (LK-1/LK-2)',
             40, 90),
        Node('Sala', 'Sala de venta', 'strong',
             ['id_sala  [K]', 'calle', 'numero', 'dia_cierre', 'localidad  [FK]'],
             'Candidata PK: id_sala [R · "ID" sec. 5]', 320, 90),
        Node('Empleado', 'Empleado', 'strong',
             ['cuit  [K·inf condicionada]', 'nombre', 'fecha_ingreso', 'salario', 'sala  [FK]'],
             'Candidata PK: cuit [I condicionada a persona física con CUIT propio; sin UNIQUE textual; EK-a]', 320, 330),
        Node('Cliente', 'Cliente', 'super',
             ['id_cliente  [K]', 'nombre  (Q-04: 1 o 2 campos)', 'tipo_doc + n_doc  [AK·pend]', 'direccion', 'localidad  [FK]', 'fecha_alta', 'descuento  (Q-01/P-9)'],
             'SUPERTIPO (A-06). Candidata PK: id_cliente [R]; (tipo_doc, n_doc) [P]\nAMB-07 ABIERTA: total/partial ¿? disjunta/solapada ¿? — sujeta a Persona B', 40, 520, 230),
        Node('Socio', 'Socio', 'sub',
             ['id_cliente  [K/FK heredada · I]'],
             'SUBTIPO sin atributos propios. Clave heredada cond. a D-1/AMB-07', 40, 760),
        Node('Distribuidor', 'Distribuidor', 'sub',
             ['id_cliente  [K/FK heredada · I]', 'zona', 'n_habilitacion  [AK·pend]'],
             'Clave heredada cond. · n_habilitacion sin unicidad garantizada (DK-2)', 220, 730),
        Node('Exportador', 'Exportador', 'sub',
             ['id_cliente  [K/FK heredada · I]', 'pais'],
             'Clave heredada cond. a D-1/AMB-07', 400, 745),
        Node('Permiso', 'Permiso de exportación', 'strong',
             ['codigo  [K·pend]', 'exportador  [FK·inf]', 'fecha_emision  [K·pend]', 'fecha_vencimiento'],
             'Candidatas PK pendientes (PerK): codigo [P]  |  (exportador, fecha_emision) [P]\nRN-07: vencimiento > emisión (CHECK)', 400, 900),
    ],
    edges=[
        ('c1', 'Localidad', 'r', 'Sala', 'l', 'REL-01  Localidad 0*..N — Sala 1..1  (mín. 0 inferido: AMB-01) [P]'),
        ('c2', 'Sala', 'b', 'Empleado', 't', 'REL-02  Sala 2*..N — Empleado 1..1  (mín. 2 de "varios"; no definitivo: AMB-02) [P]'),
        ('c3', 'Localidad', 'b', 'Cliente', 't', 'REL-03  Localidad 0*..N — Cliente 1*..1 [P]'),
        ('c4', 'Cliente', 'b', 'Socio', 't', 'REL-15  especialización (supuesto de trabajo 1*..1*; AMB-07 ABIERTA)'),
        ('c5', 'Cliente', 'b', 'Distribuidor', 't', 'REL-15  ídem (AMB-07 ABIERTA)'),
        ('c6', 'Cliente', 'b', 'Exportador', 't', 'REL-15  ídem (AMB-07 ABIERTA)'),
        ('c7', 'Exportador', 'b', 'Permiso', 't', 'REL-16  Exportador 0..N — Permiso 1*..1 [P]'),
    ],
    notes=[('La estrategia A-06 (supertipo + 3 subtipos) NO decide totalidad ni exclusividad (AMB-07/D-1/Q-04). '
            'Decisión sujeta a revisión de Persona B. La cardinalidad Cliente→subtipo queda NO DETERMINADA (A-04 REL-15).',
            680, 700, 380)],
))

# -------------------- 04 Ventas --------------------
PAGES.append(dict(
    key='04_ventas', title='A-08 · DER (4/6) — Ventas (comprobante y renglones)',
    nodes=[
        Node('Cliente_v', 'Cliente', 'super',
             ['id_cliente  [K]', 'nombre', 'tipo_doc + n_doc', 'direccion', 'localidad', 'fecha_alta', 'descuento'],
             'Definida en pág. 03 (jerarquía A-06; AMB-07 abierta)', 40, 90, ref=True),
        Node('Sala_v', 'Sala de venta', 'strong',
             ['id_sala  [K]', 'calle', 'numero', 'dia_cierre', 'localidad'],
             'Definida en pág. 03', 40, 280, ref=True),
        Node('Comprobante', 'Comprobante', 'strong',
             ['numero  [K·pend]', 'fecha', 'subtotal *  (derivado RN-08)', 'descuento *  (derivado RN-08)', 'total *  (derivado RN-08)', 'cliente  [FK]', 'sala  [FK]'],
             'Candidatas PK pendientes (CompK-a): numero [P]  |  (sala, numero) [P] (global vs por sala)',
             320, 130),
        Node('RenglonCompr', 'Renglón de comprobante', 'assoc',
             ['comprobante  [K/FK]', 'vino  [K/FK]', 'cantidad', 'precio_unitario  (histórico RN-01)', 'descuento  (Q-05)', 'subtotal  (derivado RN-08)'],
             'Candidata PK: (comprobante, vino) = RK-1 [R · textual sec. 5]\nLa clave implica: un vino no se repite en un comprobante (A-05 §12)',
             600, 130, 230),
        Node('Vino_v', 'Vino', 'strong',
             ['codigo  [K·inf]', 'nombre', 'anada', 'volumen_ml', 'precio'],
             'Definida en pág. 02', 600, 420, ref=True),
    ],
    edges=[
        ('v1', 'Cliente_v', 'r', 'Comprobante', 'l', 'REL-12  Cliente 0*..N* — Comprobante 1..1  (D4/D6 respaldan "socios sin compras"; resto inferido) [P]'),
        ('v2', 'Sala_v', 'b', 'Comprobante', 'b', 'REL-13  Sala 0*..N — Comprobante 1..1  [P]'),
        ('v3', 'Comprobante', 'r', 'RenglonCompr', 'l', 'REL-14  Comprobante 1*..N* vinos  (mín./máx. inferidos: AMB-10a) [P]'),
        ('v4', 'RenglonCompr', 'b', 'Vino_v', 't', 'REL-14  Vino 0*..N comprobantes  [P]'),
    ],
    notes=[],
))

# -------------------- 05 Logística --------------------
PAGES.append(dict(
    key='05_logistica', title='A-08 · DER (5/6) — Logística (transportista y aprovisionamiento)',
    nodes=[
        Node('Transportista', 'Transportista', 'strong',
             ['codigo  [K·pend]', 'razon_social', 'cuit  [K·inf]', 'email', 'telefono', 'domicilio'],
             'Candidatas PK pendientes (TK): codigo [P]  |  cuit [I dominial]  |  ID: no hay "ID" en sec. 5', 40, 90),
        Node('Bodega_l', 'Bodega', 'strong',
             ['cuit  [K]', 'razon_social', 'domicilio'],
             'Definida en pág. 02', 40, 300, ref=True),
        Node('Ingreso', 'Ingreso', 'strong',
             ['codigo  [K·pend]', 'fecha  (semántica Q-03)', 'estado  (ENUM RN-10)', 'transportista  [FK]', 'bodega_origen  [FK]'],
             'Candidatas PK pendientes (IK): codigo [P]  |  (bodega_origen, codigo) [P]', 320, 170),
        Node('TCL', 'Transportista–Localidad', 'assoc',
             ['transportista  [K/FK]', 'localidad  [K/FK]'],
             'N:M sin atributos (cobertura REL-17)\nCandidata PK: (transportista, localidad) [I] — D-9\n≠ zona del Distribuidor (AMB-15 resuelta)', 320, 420),
        Node('Localidad_l', 'Localidad', 'strong',
             ['codigo_postal', 'nombre', 'provincia', 'encargado_regional'],
             'Definida en pág. 03', 320, 590, ref=True),
        Node('RenglonIngreso', 'Renglón de ingreso', 'assoc',
             ['ingreso  [K/FK]', 'vino  [K/FK]', 'cantidad'],
             'Candidata PK: (ingreso, vino) [I analogía; sin clave textual] — RI-a, AMB-10b/14', 600, 470),
        Node('Vino_l', 'Vino', 'strong',
             ['codigo  [K·inf]', 'nombre', 'anada', 'volumen_ml'],
             'Definida en pág. 02', 600, 190, ref=True),
    ],
    edges=[
        ('l1', 'Transportista', 'r', 'Ingreso', 'l', 'REL-19  Transportista 0*..N — Ingreso 1..1  [P]'),
        ('l2', 'Bodega_l', 'b', 'Ingreso', 't', 'REL-18  Bodega 0*..N — Ingreso 1..1  (rol "origen": AMB-06) [P]'),
        ('l3', 'Transportista', 'b', 'TCL', 't', 'REL-17  Transportista 0*..N localidades  (cobertura) [P · AMB-09]'),
        ('l4', 'TCL', 'b', 'Localidad_l', 't', 'REL-17  Localidad 0*..N transportistas  [P · AMB-09]'),
        ('l5', 'Ingreso', 'b', 'RenglonIngreso', 't', 'REL-20  Ingreso 1*..N* vinos  [P]'),
        ('l6', 'RenglonIngreso', 'r', 'Vino_l', 't', 'REL-20  Vino 0*..N ingresos  [P]'),
    ],
    notes=[],
))

# -------------------- 06 Depósito / stock / auditoría --------------------
PAGES.append(dict(
    key='06_stock_auditoria', title='A-08 · DER (6/6) — Depósito, stock y auditoría de precios',
    nodes=[
        Node('Vino_s', 'Vino', 'strong',
             ['codigo  [K·inf]', 'nombre', 'anada', 'volumen_ml', 'precio'],
             'Definida en pág. 02', 40, 90, ref=True),
        Node('StockDep', 'Stock de depósito', 'stock',
             ['vino  [K/FK]', 'cantidad  (RN-09: ≥0; P-6 pend.)'],
             'Inventario único depósito. Candidata PK: vino [I cond. a 1 fila por vino] — D-3/AMB-11', 320, 90),
        Node('Auditoria', 'Auditoría de precio', 'stock',
             ['id_auditoria  [K]', 'vino  [FK]', 'precio_anterior', 'precio_nuevo', 'fecha_hora', 'usuario  (Q-07)'],
             'Candidata PK: id_auditoria [R · sec. 5]\nAK (vino, fecha_hora) [P: hipótesis técnica AU-2] · RN-13', 320, 250),
        Node('Sala_s', 'Sala de venta', 'strong',
             ['id_sala  [K]', 'calle', 'numero', 'dia_cierre', 'localidad'],
             'Definida en pág. 03', 40, 420, ref=True),
        Node('StockSala', 'Stock de sala', 'stock',
             ['sala  [K/FK]', 'vino  [K/FK]', 'cantidad  (RN-09: ≥0; P-6 pend.)'],
             'Inventario por par. Candidata PK: (sala, vino) = SS-1 [R · textual sec. 5]\nFila ausente ≠ cantidad 0 (AMB-11)', 40, 600),
        Node('Transferencia', 'Transferencia', 'strong',
             ['numero  [K·pend]', 'fecha_confeccion  (RN-11: actual, inmodificable)', 'estado  (ENUM RN-11)', 'sala  [FK]'],
             'Candidatas PK pendientes (TF-a): numero [P]  |  (sala, numero) [P]', 600, 300),
        Node('RenglonTransf', 'Renglón de transferencia', 'assoc',
             ['transferencia  [K/FK]', 'vino  [K/FK]', 'cantidad'],
             'Candidata PK: (transferencia, vino) [I analogía] — RT-a, AMB-10b/14', 600, 480),
    ],
    edges=[
        ('s1', 'Vino_s', 'r', 'StockDep', 'l', 'REL-24  Vino 0*..1 — Stock deposits 1..1  (fila ausente ≠ cantidad 0) [P]'),
        ('s2', 'Vino_s', 'b', 'Auditoria', 'l', 'REL-25  Vino 0*..N — Auditoría 1..1  [P]'),
        ('s3', 'Sala_s', 'r', 'StockSala', 'l', 'REL-23  Sala 0*..N vinos  [P]'),
        ('s4', 'StockSala', 'r', 'Vino_s', 't', 'REL-23  Vino 0*..N salas  [P · AMB-11]'),
        ('s5', 'Sala_s', 'b', 'Transferencia', 't', 'REL-21  Sala 0*..N — Transferencia 1..1  [P]'),
        ('s6', 'Transferencia', 'b', 'RenglonTransf', 't', 'REL-22  Transferencia 1*..N* vinos  [P]'),
        ('s7', 'RenglonTransf', 'l', 'StockSala', 'r', 'REL-22  Vino 0*..N transferencias  [P]'),
    ],
    notes=[],
))


# =====================================================================
# DRAWIO
# =====================================================================
def vertex_xml(pkey, n):
    fill, stroke, _ = CLS[n.kind]
    st = (f'rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=8;spacingTop=4;'
          f'fillColor={fill};strokeColor={stroke};fontSize=10;'
          + ('dashed=1;strokeWidth=2;' if n.kind == 'weak' else '')
          + ('strokeWidth=1.5;' if n.kind == 'assoc' else '')
          + ('opacity=65;' if n.ref else ''))
    return (f'<mxCell id="{pkey}-{n.id}" value="{esc(node_value(n))}" style="{st}" vertex="1" parent="1">'
            f'<mxGeometry x="{n.x}" y="{n.y}" width="{n.w}" height="{n.h}" as="geometry"/></mxCell>')


def edge_xml(pkey, e):
    eid, src, ex, tgt, en, note = e
    exx, exy = EX_OPT[ex]
    enx, eny = EN_OPT[en]
    st = (f'edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;strokeColor=#444444;strokeWidth=1.4;'
          f'exitX={exx};exitY={exy};exitDx=0;exitDy=0;entryX={enx};entryY={eny};entryDx=0;entryDy=0;')
    lab = (f'<mxCell id="{pkey}-{eid}-lbl" value="{esc(note)}" style="edgeLabel;html=1;align=center;'
           f'verticalAlign=middle;resizable=0;points=[];fontSize=9;labelBackgroundColor=#ffffff;" '
           f'vertex="1" connectable="0" parent="{pkey}-{eid}">'
           f'<mxGeometry relative="1" as="geometry"><mxPoint as="offset"/></mxGeometry></mxCell>')
    return (f'<mxCell id="{pkey}-{eid}" style="{st}" edge="1" parent="1" '
            f'source="{pkey}-{src}" target="{pkey}-{tgt}">'
            f'<mxGeometry relative="1" as="geometry"/></mxCell>') + lab


def page_diagram_xml(p, idx):
    cells = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
    # título
    cells.append(f'<mxCell id="{p["key"]}-title" value="{esc("<b>" + esc(p["title"]) + "</b>")}" '
                 f'style="text;html=1;fontSize=17;align=left" vertex="1" parent="1">'
                 f'<mxGeometry x="30" y="20" width="760" height="30" as="geometry"/></mxCell>')
    cells.append(f'<mxCell id="{p["key"]}-leg" value="{esc(LEGEND)}" '
                 f'style="text;html=1;fontSize=9;align=left;fillColor=#fafafa;strokeColor=#cccccc;rounded=1" '
                 f'vertex="1" parent="1"><mxGeometry x="30" y="52" width="820" height="30" as="geometry"/></mxCell>')
    for n in p['nodes']:
        cells.append(vertex_xml(p['key'], n))
    for e in p['edges']:
        cells.append(edge_xml(p['key'], e))
    for i, (txt, nx, ny, nw) in enumerate(p.get('notes', [])):
        nh = 14 * (1 + len(txt) // 90) + 10
        cells.append(f'<mxCell id="{p["key"]}-note{i}" value="{esc(txt)}" '
                     f'style="text;html=1;fontSize=9;align=left;fillColor=#fff2cc;strokeColor=#d6b656;rounded=1;verticalAlign=top"'
                     f' vertex="1" parent="1"><mxGeometry x="{nx}" y="{ny}" width="{nw}" height="{nh}" as="geometry"/></mxCell>')
    w = max(n.x + n.w for n in p['nodes']) + 120
    h = max(n.y + n.h for n in p['nodes']) + 90
    NAME = {'01_produccion': '01_produccion', '02_elaboracion': '02_elaboracion',
            '03_comercial': '03_comercial_jerarquia', '04_ventas': '04_ventas',
            '05_logistica': '05_logistica', '06_stock_auditoria': '06_stock_auditoria'}[p['key']]
    return (f'<diagram id="der-{p["key"]}" name="{NAME}"><mxGraphModel dx="1200" dy="700" grid="1" '
            f'gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
            f'pageWidth="{max(w, 900)}" pageHeight="{max(h, 700)}" math="0" shadow="0">'
            f'<root>{"".join(cells)}</root></mxGraphModel></diagram>')


MAPA_TITLE = 'A-08 · DER — Mapa de módulos'
MAPA_MODULES = [
    ('Módulo 1 — Producción de uva (pág. 01)', 'Finca · Parcela (débil, identificada por Finca) · Cepa · Lote de uva · Análisis de calidad',
     'REL-04, REL-05, REL-06, REL-08  +  REL-07 (Lote→Bodega, cruz a módulo 2)'),
    ('Módulo 2 — Elaboración de vinos (pág. 02)', 'Bodega · Vino · Maridaje · Composición (asoc. con atributo) · Vino–Maridaje (asoc. sin atributos)',
     'REL-09, REL-10, REL-11'),
    ('Módulo 3 — Red comercial y jerarquía (pág. 03)', 'Localidad · Sala de venta · Empleado · Cliente (supertipo) · Socio / Distribuidor / Exportador (subtipos) · Permiso de exportación',
     'REL-01, REL-02, REL-03, REL-15 (jerarquía, AMB-07 abierta), REL-16'),
    ('Módulo 4 — Ventas (pág. 04)', 'Comprobante · Renglón de comprobante (asoc. con atributos; precio histórico)  [Cliente / Sala / Vino repetidas como referencia]',
     'REL-12, REL-13, REL-14'),
    ('Módulo 5 — Logística (pág. 05)', 'Transportista · Transportista–Localidad (cobertura, asoc.) · Ingreso · Renglón de ingreso (asoc.)',
     'REL-17, REL-18, REL-19, REL-20'),
    ('Módulo 6 — Depósito, stock y auditoría (pág. 06)', 'Stock de depósito · Auditoría de precio · Stock de sala · Transferencia · Renglón de transferencia (asoc.)',
     'REL-21, REL-22, REL-23, REL-24, REL-25'),
]
MAPA_NOTA = ('Modelo completo: 29 conceptos (A-01 §2; 27 si los subtipos se cuentan como jerarquía). '
             'Jerarquía Cliente: estrategia A-06 (supertipo + 3 subtipos), sujeta a revisión de Persona B; '
             'AMB-07 (totalidad/exclusividad) sigue ABIERTA. No se eligió ninguna PK definitiva: las cajas muestran '
             'claves CANDIDATAS con su estado (R respaldada / I inferida / P pendiente). Cardinalidades: notación '
             'independiente por extremo de A-04 ("A x..y — z..w B"); * = extremo inferido o condicionado; '
             'mínimo 0 = participación parcial.')

LEGEND = ('Notación: K = clave candidata respaldada [R] · I = inferida · P = pendiente de validación · AK = alterna · '
          'K/FK = componente de clave y foránea · FK → subrogada de cabecera/roja (débil: clave propietaria + parcial). '
          'Colores: azul = fuerte · verde (borde discontinuo) = débil · naranja = asociativa · amarillo = inventario · '
          'violeta = supertipo · violeta claro = subtipo. Cardinalidad "A x..y — z..w B" por extremo (A-04); '
          '* = extremo inferido. Cajas grises = referencia repetida de otra página.')


def mapa_diagram_xml():
    cells = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
    cells.append(f'<mxCell id="mapa-title" value="{esc("<b>" + esc(MAPA_TITLE) + "</b>")}" style="text;html=1;fontSize=17;align=left" '
                 f'vertex="1" parent="1"><mxGeometry x="30" y="20" width="500" height="30" as="geometry"/></mxCell>')
    y = 60
    for i, (name, ents, rels) in enumerate(MAPA_MODULES):
        cells.append(f'<mxCell id="mapa-m{i}" value="{esc("<b>" + esc(name) + "</b><br/><font size=\"10\">" + esc(ents) + "</font><br/><br/><font size=\"9\" color=\"#555555\">" + esc(rels) + "</font>")}" '
                     f'style="rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;fillColor=#f5f5f5;'
                     f'strokeColor=#888888" vertex="1" parent="1">'
                     f'<mxGeometry x="30" y="{y}" width="620" height="88" as="geometry"/></mxCell>')
        y += 100
    cells.append(f'<mxCell id="mapa-nota" value="{esc(MAPA_NOTA)}" style="rounded=1;whiteSpace=wrap;html=1;align=left;'
                 f'verticalAlign=top;fillColor=#fff2cc;strokeColor=#d6b656;fontSize=10" vertex="1" parent="1">'
                 f'<mxGeometry x="30" y="{y+10}" width="620" height="120" as="geometry"/></mxCell>')
    return (f'<diagram id="der-00_mapa" name="00_mapa"><mxGraphModel dx="1200" dy="700" grid="1" gridSize="10" '
            f'page="1" pageScale="1" pageWidth="700" pageHeight="{y+180}"><root>{"".join(cells)}</root>'
            f'</mxGraphModel></diagram>')


def drawio_file():
    body = mapa_diagram_xml() + ''.join(page_diagram_xml(p, i) for i, p in enumerate(PAGES))
    return (f'<mxfile host="app.diagrams.net" agent="gen_der.py (layout del equipo); contenido: A-01..A-07" '
            f'version="24.7.7" type="device" pages="7">{body}</mxfile>')

# =====================================================================
# SVG
# =====================================================================
def border_pt(shape, side):
    x, y, w, h = shape.x, shape.y, shape.w, shape.h
    if side == 'r': return (x + w, y + h / 2)
    if side == 'l': return (x, y + h / 2)
    if side == 'b': return (x + w / 2, y + h)
    return (x + w / 2, y)


def dogleg(p1, s1, p2, s2):
    if s1 in ('l', 'r') and s2 in ('l', 'r'):
        mx = (p1[0] + p2[0]) / 2
        return [p1, (mx, p1[1]), (mx, p2[1]), p2]
    if s1 in ('t', 'b') and s2 in ('t', 'b'):
        my = (p1[1] + p2[1]) / 2
        return [p1, (p1[0], my), (p2[0], my), p2]
    if s1 in ('l', 'r') and s2 in ('t', 'b'):
        return [p1, (p2[0], p1[1]), p2]
    return [p1, (p1[0], p2[1]), p2]


def wrap(s, n=46):
    words, lines, cur = s.split(), [], ''
    for w_ in words:
        t = (cur + ' ' + w_).strip()
        if len(t) > n:
            if cur: lines.append(cur)
            cur = w_
        else:
            cur = t
    if cur: lines.append(cur)
    return lines


def svg_page(p, footer=True):
    nodes = {n.id: n for n in p['nodes']}
    W_ = max(n.x + n.w for n in p['nodes']) + 130
    H_ = max(n.y + n.h for n in p['nodes']) + 110
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W_}" height="{H_}" viewBox="0 0 {W_} {H_}" '
             f'font-family="Helvetica,Arial,sans-serif">',
             f'<rect width="{W_}" height="{H_}" fill="#ffffff"/>',
             f'<text x="30" y="34" font-size="17" font-weight="bold">{esc(p["title"])}</text>',
             f'<text x="30" y="56" font-size="9.5" fill="#333333">{esc(LEGEND)}</text>',
             f'<text x="30" y="70" font-size="9.5" fill="#333333">{esc("Cardinalidades: rangos independientes por extremo (A-04: A x..y — z..w B); * junto al extremo inferido/condicionado; mínimo 0 = participación parcial.")}</text>']
    # edges under nodes
    for e in p['edges']:
        eid, src, ex, tgt, en, note = e
        p1, p2 = border_pt(nodes[src], ex), border_pt(nodes[tgt], en)
        pts = dogleg(p1, ex, p2, en)
        d = 'M ' + ' L '.join(f'{a:.1f},{b:.1f}' for a, b in pts)
        parts.append(f'<path d="{d}" fill="none" stroke="#444444" stroke-width="1.3"/>')
        mid = pts[len(pts) // 2] if len(pts) > 2 else ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
        lines = wrap(note, 44)
        bw = max(len(l) for l in lines) * 5.3 + 12
        bh = 13 * len(lines) + 6
        bx, by = mid[0] - bw / 2, mid[1] - bh / 2
        parts.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="#ffffff" stroke="#bbbbbb" stroke-width="0.7"/>')
        for i, l in enumerate(lines):
            parts.append(f'<text x="{bx+6:.1f}" y="{by+12+13*i:.1f}" font-size="9.5" fill="#1a1a1a">{esc(l)}</text>')
    # notes
    for i, (txt, nx, ny, nw) in enumerate(p.get('notes', [])):
        lines = wrap(txt, int(nw / 5.2))
        nh = 13 * len(lines) + 12
        parts.append(f'<rect x="{nx}" y="{ny}" width="{nw}" height="{nh}" rx="5" fill="#fff2cc" stroke="#d6b656"/>')
        for j, l in enumerate(lines):
            parts.append(f'<text x="{nx+8}" y="{ny+16+13*j}" font-size="9.5" fill="#333333">{esc(l)}</text>')
    # nodes
    for n in p['nodes']:
        fill, stroke, _ = CLS[n.kind]
        op = ' fill-opacity="0.62"' if n.ref else ''
        parts.append(f'<rect x="{n.x}" y="{n.y}" width="{n.w}" height="{n.h}" rx="5" fill="{fill}" stroke="{stroke}" stroke-width="1.6"{op}/>')
        if n.kind == 'weak':
            parts.append(f'<rect x="{n.x+3}" y="{n.y+3}" width="{n.w-6}" height="{n.h-6}" rx="4" fill="none" stroke="{stroke}" stroke-dasharray="5,3"/>')
        yy = n.y + 15
        kn = CLS[n.kind][2] or 'fuerte'
        t = n.label + '  [' + kn + ']'
        if n.ref: t += '  (referencia)'
        parts.append(f'<text x="{n.x+9}" y="{yy}" font-size="11" font-weight="bold">{esc(t)}</text>')
        yy += LINE_H + 2
        for a in n.attrs:
            parts.append(f'<text x="{n.x+9}" y="{yy}" font-size="9.6">{esc(a)}</text>')
            yy += LINE_H
        yy += 1
        for k in n.key.split('\n'):
            parts.append(f'<text x="{n.x+9}" y="{yy}" font-size="8.8" fill="#7a0000">{esc(k)}</text>')
            yy += 12.5
    parts.append(f'<text x="30" y="{H_-18}" font-size="8.6" fill="#777777">{esc("Elaborado a partir de A-01..A-07 y docs/requisitos.md · fuente editable: 08_diagrama_entidad_relacion.drawio (diagrams.net) · este SVG se genera por script a partir del mismo layout (no es una exportación de draw.io).")}</text>')
    parts.append('</svg>')
    return '\n'.join(parts)


def mapa_svg():
    W_, rowH, nR = 700, 96, len(MAPA_MODULES)
    H_ = 110 + rowH * nR + 170
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W_+50}" height="{H_}" viewBox="0 0 {W_+50} {H_}" font-family="Helvetica,Arial,sans-serif">',
             f'<rect width="{W_+50}" height="{H_}" fill="#ffffff"/>',
             f'<text x="30" y="34" font-size="17" font-weight="bold">{esc(MAPA_TITLE)}</text>']
    y = 60
    for i, (name, ents, rels) in enumerate(MAPA_MODULES):
        parts.append(f'<rect x="30" y="{y}" width="650" height="88" rx="5" fill="#f5f5f5" stroke="#888888"/>')
        for j, l in enumerate(wrap(ents, 96)):
            pass
        parts.append(f'<text x="42" y="{y+20}" font-size="12" font-weight="bold">{esc(name)}</text>')
        for j, l in enumerate(wrap(ents, 95)):
            parts.append(f'<text x="44" y="{y+38+13*j}" font-size="10">{esc(l)}</text>')
        parts.append(f'<text x="42" y="{y+80}" font-size="9" fill="#555555">{esc(rels)}</text>')
        y += rowH
    parts.append(f'<rect x="30" y="{y+12}" width="650" height="120" rx="5" fill="#fff2cc" stroke="#d6b656"/>')
    for j, l in enumerate(wrap(MAPA_NOTA, 108)):
        parts.append(f'<text x="42" y="{y+30+13*j}" font-size="9.8" fill="#333333">{esc(l)}</text>')
    parts.append(f'<text x="30" y="{H_-16}" font-size="8.6" fill="#777777">{esc("Fuente editable: 08_diagrama_entidad_relacion.drawio (7 páginas, diagrams.net). Este SVG se genera por script a partir del mismo layout (no es una exportación de draw.io).")}</text>')
    parts.append('</svg>')
    return '\n'.join(parts)

# =====================================================================
# MAIN
# =====================================================================
if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, '08_diagrama_entidad_relacion.drawio'), 'w', encoding='utf-8') as f:
        f.write(drawio_file())
    with open(os.path.join(OUT, '08_der_00_mapa.svg'), 'w', encoding='utf-8') as f:
        f.write(mapa_svg())
    for p in PAGES:
        fn = os.path.join(OUT, f'08_der_{p["key"]}.svg')
        with open(fn, 'w', encoding='utf-8') as f:
            f.write(svg_page(p))
    print('OK')
