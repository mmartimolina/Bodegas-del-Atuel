const API_BASE_URL = (window.APP_CONFIG?.apiBaseUrl || "").replace(/\/+$/, "");
const PAGE_SIZE = 20;
const state = {
  offset: 0,
  totalWines: 0,
  editingWine: null,
  catalogs: { cepas: [], bodegas: [], maridajes: [], tipos_vino: [] },
  salas: [],
  customers: [],
  selectableWines: [],
  wines: [],
  transfer: null,
};

const byId = (id) => document.getElementById(id);
const make = (tag, className, value) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (value !== undefined) node.textContent = value;
  return node;
};

const apiDocsLink = byId("api-docs");
if (API_BASE_URL) {
  apiDocsLink.href = `${API_BASE_URL}/docs`;
} else {
  apiDocsLink.hidden = true;
}

function showStatus(message, isError = false) {
  const status = byId("status");
  status.textContent = message;
  status.classList.toggle("error", isError);
}

async function request(path, options = {}) {
  if (!API_BASE_URL) throw new Error("Falta configurar la URL de la API.");
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...options.headers,
    },
  });
  const body = response.status === 204 ? null : await response.json();
  if (!response.ok) {
    const detail = body?.detail || `La solicitud fallo (${response.status}).`;
    throw new Error(detail);
  }
  return body;
}

function fillSelect(select, items, valueOf, labelOf, placeholder) {
  select.replaceChildren();
  if (placeholder) {
    const option = make("option", "", placeholder);
    option.value = "";
    select.append(option);
  }
  for (const item of items) {
    const option = make("option", "", labelOf(item));
    option.value = String(valueOf(item));
    select.append(option);
  }
}

function populateReferences() {
  const types = state.catalogs.tipos_vino.map((item) => item.tipo);
  fillSelect(byId("filter-type"), types, (value) => value, (value) => value, "Todos");
  byId("wine-types").replaceChildren(
    ...types.map((type) => {
      const option = make("option");
      option.value = type;
      return option;
    }),
  );
  fillSelect(
    byId("filter-grape"),
    state.catalogs.cepas,
    (item) => item.id,
    (item) => item.nombre,
    "Todas",
  );
  fillSelect(
    byId("filter-winery"),
    state.catalogs.bodegas,
    (item) => item.cuit,
    (item) => item.razon_social || item.cuit,
    "Todas",
  );
  fillSelect(
    byId("wine-winery"),
    state.catalogs.bodegas,
    (item) => item.cuit,
    (item) => `${item.razon_social || "Bodega"} (${item.cuit})`,
    "Seleccione una bodega",
  );
  for (const id of ["sale-sala", "transfer-sala", "report-sala"]) {
    fillSelect(
      byId(id),
      state.salas,
      (item) => item.id_sala,
      (item) => `Sala ${item.id_sala} · ${item.localidad}`,
      "Seleccione una sala",
    );
  }
  const typeInput = byId("wine-form").elements.namedItem("tipo");
  typeInput.setAttribute("list", "wine-types");
  const pairings = byId("food-pairings");
  pairings.replaceChildren();
  for (const pairing of state.catalogs.maridajes) {
    const label = make("label");
    const checkbox = make("input");
    checkbox.type = "checkbox";
    checkbox.name = "maridajes";
    checkbox.value = pairing.id;
    label.append(checkbox, document.createTextNode(pairing.nombre));
    pairings.append(label);
  }
  populateCustomerSelect();
}

function populateCustomerSelect() {
  fillSelect(
    byId("sale-customer"),
    state.customers,
    (item) => item.id_cliente,
    (item) => `${item.nombre} · ${item.subtipo}`,
    "Seleccione un cliente",
  );
}

function currentFilters() {
  const params = new URLSearchParams({ limit: PAGE_SIZE, offset: state.offset });
  const values = {
    tipo: byId("filter-type").value,
    cepa: byId("filter-grape").value,
    bodega: byId("filter-winery").value,
    anada: byId("filter-vintage").value,
  };
  for (const [key, value] of Object.entries(values)) {
    if (value) params.set(key, value);
  }
  return params;
}

function addCell(row, value) {
  const cell = make("td", "", value ?? "—");
  row.append(cell);
  return cell;
}

async function loadWines() {
  showStatus("Cargando catálogo...");
  const result = await request(`/vinos?${currentFilters()}`);
  state.wines = result.items;
  state.totalWines = result.total;
  const body = byId("wine-rows");
  body.replaceChildren();
  if (result.items.length === 0) {
    const row = make("tr");
    const cell = make("td", "empty", "No hay vinos que coincidan con los filtros.");
    cell.colSpan = 7;
    row.append(cell);
    body.append(row);
  }
  for (const wine of result.items) {
    const row = make("tr");
    addCell(row, wine.nombre);
    addCell(row, wine.tipo);
    addCell(row, wine.anada);
    addCell(row, `${wine.volumen_ml} ml`);
    addCell(row, wine.precio);
    addCell(row, wine.bodega_nombre);
    const actions = make("td");
    const detail = make("button", "button secondary", "Detalle");
    detail.type = "button";
    detail.addEventListener("click", () => showWine(wine.codigo));
    const edit = make("button", "button secondary", "Editar");
    edit.type = "button";
    edit.addEventListener("click", () => editWine(wine.codigo));
    actions.append(detail, edit);
    row.append(actions);
    body.append(row);
  }
  const page = Math.floor(state.offset / PAGE_SIZE) + 1;
  byId("page-label").textContent = `Página ${page} · ${result.total} vinos`;
  byId("previous-page").disabled = state.offset === 0;
  byId("next-page").disabled = state.offset + PAGE_SIZE >= result.total;
  showStatus("");
}

function showView(name) {
  document.querySelectorAll(".screen").forEach((section) => {
    section.hidden = section.id !== `view-${name}`;
  });
  document.querySelectorAll(".nav-button").forEach((button) => {
    const active = button.dataset.view === name;
    button.classList.toggle("active", active);
    button.setAttribute("aria-current", active ? "page" : "false");
  });
  if (name === "dashboard") refreshDashboard().catch((error) => showStatus(error.message, true));
}

function addCompositionRow(selected = "", percentage = "") {
  const row = make("div", "composition-row");
  const cepa = make("select");
  cepa.setAttribute("aria-label", "Cepa");
  fillSelect(
    cepa,
    state.catalogs.cepas,
    (item) => item.id,
    (item) => `${item.nombre} (${item.tipo})`,
    "Seleccione cepa",
  );
  cepa.value = String(selected);
  const amount = make("input");
  amount.type = "number";
  amount.min = "0.01";
  amount.max = "100";
  amount.step = "0.01";
  amount.required = true;
  amount.value = percentage;
  amount.setAttribute("aria-label", "Porcentaje");
  const remove = make("button", "button secondary remove-row", "Quitar");
  remove.type = "button";
  remove.addEventListener("click", () => row.remove());
  row.append(wrapField("Cepa", cepa), wrapField("Porcentaje", amount), remove);
  byId("composition-rows").append(row);
}

function wrapField(labelText, control) {
  const label = make("label", "", labelText);
  label.append(control);
  return label;
}

function addWineLine(container, labelText = "Vino", selected = "", quantity = 1) {
  const row = make("div", "line-row");
  const wine = make("select");
  wine.setAttribute("aria-label", labelText);
  fillSelect(
    wine,
    state.selectableWines,
    (item) => item.codigo,
    (item) => `${item.nombre} (${item.codigo})`,
    "Seleccione vino",
  );
  wine.value = selected;
  const amount = make("input");
  amount.type = "number";
  amount.min = "1";
  amount.step = "1";
  amount.required = true;
  amount.value = String(quantity);
  amount.setAttribute("aria-label", "Cantidad");
  const remove = make("button", "button secondary remove-row", "Quitar");
  remove.type = "button";
  remove.addEventListener("click", () => row.remove());
  row.append(wrapField("Vino", wine), wrapField("Cantidad", amount), remove);
  container.append(row);
}

function refreshWineSelectors() {
  document.querySelectorAll(".line-row select").forEach((select) => {
    const selected = select.value;
    fillSelect(
      select,
      state.selectableWines,
      (item) => item.codigo,
      (item) => `${item.nombre} (${item.codigo})`,
      "Seleccione vino",
    );
    if (state.selectableWines.some((wine) => wine.codigo === selected)) {
      select.value = selected;
    }
  });
}

function getLines(container) {
  return [...container.querySelectorAll(".line-row")].map((row) => ({
    vino: row.querySelector("select").value,
    cantidad: Number(row.querySelector('input[type="number"]').value),
  }));
}

function readWineForm() {
  const form = byId("wine-form");
  const data = Object.fromEntries(new FormData(form).entries());
  const composition = [...byId("composition-rows").querySelectorAll(".composition-row")].map(
    (row) => ({
      cepa: Number(row.querySelector("select").value),
      porcentaje: row.querySelector('input[type="number"]').value,
    }),
  );
  return {
    codigo: data.codigo.trim(),
    nombre: data.nombre.trim(),
    tipo: data.tipo.trim(),
    anada: Number(data.anada),
    volumen_ml: Number(data.volumen_ml),
    graduacion: Number(data.graduacion),
    precio: Number(data.precio),
    bodega: data.bodega,
    composicion,
    maridajes: [...form.querySelectorAll('input[name="maridajes"]:checked')].map((input) =>
      Number(input.value),
    ),
  };
}

function resetWineForm() {
  state.editingWine = null;
  byId("wine-form").reset();
  byId("composition-rows").replaceChildren();
  addCompositionRow();
  byId("wine-form-title").textContent = "Alta de vino";
  byId("wine-form").elements.namedItem("codigo").readOnly = false;
  showView("catalog");
}

async function showWine(code) {
  try {
    const wine = await request(`/vinos/${encodeURIComponent(code)}`);
    const card = byId("wine-detail");
    card.replaceChildren();
    card.append(make("h3", "", `${wine.nombre} · ${wine.codigo}`));
    card.append(make("p", "", `Composición: ${wine.composicion.map((item) => `${item.nombre} ${item.porcentaje}%`).join(", ") || "Sin datos"}`));
    card.append(make("p", "", `Maridajes: ${wine.maridajes.map((item) => item.nombre).join(", ") || "Sin datos"}`));
    card.append(make("p", "", `Stock depósito: ${wine.stock_deposito} · stock en salas: ${wine.stock_salas}`));
    card.hidden = false;
  } catch (error) {
    showStatus(error.message, true);
  }
}

async function editWine(code) {
  try {
    const wine = await request(`/vinos/${encodeURIComponent(code)}`);
    const form = byId("wine-form");
    for (const key of ["codigo", "nombre", "tipo", "anada", "volumen_ml", "graduacion", "precio", "bodega"]) {
      form.elements.namedItem(key).value = wine[key] ?? "";
    }
    form.elements.namedItem("codigo").readOnly = true;
    byId("composition-rows").replaceChildren();
    wine.composicion.forEach((item) => addCompositionRow(item.cepa, item.porcentaje));
    const pairingIds = new Set(wine.maridajes.map((item) => String(item.id)));
    form.querySelectorAll('input[name="maridajes"]').forEach((checkbox) => {
      checkbox.checked = pairingIds.has(checkbox.value);
    });
    state.editingWine = code;
    byId("wine-form-title").textContent = "Editar vino";
    showView("wine-form");
  } catch (error) {
    showStatus(error.message, true);
  }
}

function renderSimpleTable(container, rows, columns, emptyMessage) {
  container.replaceChildren();
  if (!rows.length) {
    container.append(make("p", "empty", emptyMessage));
    return;
  }
  const table = make("table");
  const head = make("thead");
  const headRow = make("tr");
  columns.forEach(([, label]) => headRow.append(make("th", "", label)));
  head.append(headRow);
  const body = make("tbody");
  for (const item of rows) {
    const row = make("tr");
    columns.forEach(([key]) => addCell(row, item[key]));
    body.append(row);
  }
  table.append(head, body);
  container.append(table);
}

async function refreshDashboard() {
  const [top, sales] = await Promise.all([
    request("/reportes/top-vinos?limit=10"),
    request("/reportes/ventas-por-sala"),
  ]);
  renderSimpleTable(
    byId("top-wines"),
    top,
    [["nombre", "Vino"], ["botellas_vendidas", "Botellas"]],
    "Todavía no hay ventas.",
  );
  const chart = byId("sales-by-sala");
  chart.replaceChildren();
  const max = Math.max(0, ...sales.map((item) => Number(item.monto_total)));
  if (!sales.length) chart.append(make("p", "empty", "No hay salas para mostrar."));
  for (const item of sales) {
    const block = make("div", "bar-row");
    const label = make("div", "bar-label");
    label.append(make("span", "", `Sala ${item.id_sala} · ${item.localidad}`));
    label.append(make("strong", "", String(item.monto_total)));
    const bar = make("div", "bar");
    const fill = make("span");
    fill.style.width = `${max ? (Number(item.monto_total) / max) * 100 : 0}%`;
    bar.append(fill);
    block.append(label, bar);
    chart.append(block);
  }
  await refreshNoStock();
}

async function refreshNoStock() {
  const sala = byId("report-sala").value;
  if (!sala) return;
  const rows = await request(`/reportes/vinos-sin-stock?sala=${encodeURIComponent(sala)}`);
  renderSimpleTable(
    byId("no-stock-wines"),
    rows,
    [["codigo", "Código"], ["nombre", "Vino"], ["stock_deposito", "Depósito"]],
    "No hay vinos con stock pendiente para esta sala.",
  );
}

function renderReceipt(receipt) {
  const card = byId("sale-result");
  card.replaceChildren();
  card.hidden = false;
  card.append(make("h3", "", `Comprobante ${receipt.numero}`));
  card.append(make("p", "", `Total calculado por la base: ${receipt.total}`));
  renderSimpleTable(
    card,
    receipt.renglones,
    [["nombre", "Vino"], ["cantidad", "Cantidad"], ["subtotal", "Subtotal"]],
    "Sin renglones.",
  );
}

function renderTransfer(transfer) {
  state.transfer = transfer;
  byId("transfer-workflow").hidden = false;
  byId("transfer-number").textContent = `Transferencia ${transfer.numero}`;
  byId("transfer-state").textContent = `Estado: ${transfer.estado}`;
  const editable = transfer.estado === "en_confeccion";
  byId("transfer-lines-form").querySelector('button[type="submit"]').disabled = !editable;
  byId("add-transfer-line").disabled = !editable;
  byId("finish-transfer").disabled = !editable;
  byId("process-transfer").disabled = transfer.estado !== "terminado";
}

async function loadInitialData() {
  const [catalogs, salas, customersPage, winesPage] = await Promise.all([
    request("/catalogos"),
    request("/salas"),
    request("/clientes?limit=100"),
    request("/vinos?limit=500"),
  ]);
  state.catalogs = catalogs;
  state.salas = salas;
  state.customers = customersPage.items;
  state.selectableWines = winesPage.items;
  populateReferences();
  refreshWineSelectors();
  await loadWines();
}

let customerSearchTimer;
let customerSearchSequence = 0;
byId("customer-search").addEventListener("input", () => {
  const sequence = ++customerSearchSequence;
  clearTimeout(customerSearchTimer);
  customerSearchTimer = setTimeout(async () => {
    try {
      const query = byId("customer-search").value.trim();
      const params = new URLSearchParams({ limit: "100" });
      if (query) params.set("q", query);
      const page = await request(`/clientes?${params}`);
      if (sequence !== customerSearchSequence) return;
      state.customers = page.items;
      populateCustomerSelect();
    } catch (error) {
      if (sequence === customerSearchSequence) showStatus(error.message, true);
    }
  }, 250);
});

document.querySelectorAll(".nav-button").forEach((button) => {
  button.addEventListener("click", () => showView(button.dataset.view));
});

byId("catalog-filters").addEventListener("submit", (event) => {
  event.preventDefault();
  state.offset = 0;
  loadWines().catch((error) => showStatus(error.message, true));
});
byId("clear-filters").addEventListener("click", () => {
  byId("catalog-filters").reset();
  state.offset = 0;
  loadWines().catch((error) => showStatus(error.message, true));
});
byId("previous-page").addEventListener("click", () => {
  state.offset = Math.max(0, state.offset - PAGE_SIZE);
  loadWines().catch((error) => showStatus(error.message, true));
});
byId("next-page").addEventListener("click", () => {
  state.offset += PAGE_SIZE;
  loadWines().catch((error) => showStatus(error.message, true));
});
byId("new-wine").addEventListener("click", () => {
  resetWineForm();
  showView("wine-form");
});
byId("add-composition").addEventListener("click", () => addCompositionRow());
byId("cancel-wine-edit").addEventListener("click", resetWineForm);
byId("wine-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  try {
    const body = readWineForm();
    const url = state.editingWine
      ? `/vinos/${encodeURIComponent(state.editingWine)}`
      : "/vinos";
    const method = state.editingWine ? "PUT" : "POST";
    await request(url, { method, body: JSON.stringify(body) });
    showStatus("El vino se guardó correctamente.");
    resetWineForm();
    await loadInitialData();
  } catch (error) {
    showStatus(error.message, true);
  }
});

byId("add-sale-line").addEventListener("click", () =>
  addWineLine(byId("sale-lines"), "Vino"),
);
byId("sale-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  try {
    const receipt = await request("/comprobantes", {
      method: "POST",
      body: JSON.stringify({
        cliente: Number(byId("sale-customer").value),
        sala: Number(byId("sale-sala").value),
        renglones: getLines(byId("sale-lines")),
      }),
    });
    renderReceipt(receipt);
    byId("sale-lines").replaceChildren();
    addWineLine(byId("sale-lines"), "Vino");
    showStatus("La venta se registró sin operaciones locales de stock o importes.");
    await loadInitialData();
  } catch (error) {
    showStatus(error.message, true);
  }
});

byId("transfer-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  try {
    const transfer = await request("/transferencias", {
      method: "POST",
      body: JSON.stringify({ sala: Number(byId("transfer-sala").value) }),
    });
    byId("transfer-lines").replaceChildren();
    addWineLine(byId("transfer-lines"), "Vino");
    renderTransfer(transfer);
    showStatus("Transferencia creada en confección.");
  } catch (error) {
    showStatus(error.message, true);
  }
});
byId("add-transfer-line").addEventListener("click", () =>
  addWineLine(byId("transfer-lines"), "Vino"),
);
byId("transfer-lines-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  if (!state.transfer) return;
  try {
    const transfer = await request(`/transferencias/${state.transfer.numero}/renglones`, {
      method: "POST",
      body: JSON.stringify({ renglones: getLines(byId("transfer-lines")) }),
    });
    renderTransfer(transfer);
    byId("transfer-lines").replaceChildren();
    addWineLine(byId("transfer-lines"), "Vino");
    showStatus("Renglones agregados; el stock todavía no se modificó.");
  } catch (error) {
    showStatus(error.message, true);
  }
});
byId("finish-transfer").addEventListener("click", async () => {
  if (!state.transfer) return;
  try {
    renderTransfer(
      await request(`/transferencias/${state.transfer.numero}/terminar`, { method: "POST" }),
    );
    showStatus("Transferencia terminada.");
  } catch (error) {
    showStatus(error.message, true);
  }
});
byId("process-transfer").addEventListener("click", async () => {
  if (!state.transfer) return;
  try {
    renderTransfer(
      await request(`/transferencias/${state.transfer.numero}/procesar`, { method: "POST" }),
    );
    showStatus("Transferencia procesada por PostgreSQL.");
  } catch (error) {
    showStatus(error.message, true);
  }
});

byId("refresh-dashboard").addEventListener("click", () =>
  refreshDashboard().catch((error) => showStatus(error.message, true)),
);
byId("report-sala").addEventListener("change", () =>
  refreshNoStock().catch((error) => showStatus(error.message, true)),
);

byId("composition-rows").replaceChildren();
addCompositionRow();
byId("sale-lines").replaceChildren();
addWineLine(byId("sale-lines"), "Vino");
byId("transfer-lines").replaceChildren();
addWineLine(byId("transfer-lines"), "Vino");
loadInitialData().catch((error) => showStatus(error.message, true));
