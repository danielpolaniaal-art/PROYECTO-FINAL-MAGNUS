/* ===== Magnus SIG S.A.S · Inventario y ventas ===== */
(function () {
  'use strict';

  /* ---------- Utilidades ---------- */
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const esc = (t) => String(t == null ? '' : t).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const copFmt = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', minimumFractionDigits: 0, maximumFractionDigits: 0 });
  const money = (n) => copFmt.format(Math.round(Number(n) || 0));
  const initials = (name) => name.trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase();
  const norm = (t) => String(t).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
  const IVA = 0.19;

  const Store = {
    get(k, d) { try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch (e) { return d; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* sin espacio */ } }
  };

  const fmtDate = (iso) => new Date(iso).toLocaleDateString('es-CO', { day: 'numeric', month: 'short', year: 'numeric' }).replace(/\./g, '');
  const fmtTime = (iso) => new Date(iso).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: true });
  const fmtDateTime = (iso) => fmtDate(iso) + ', ' + fmtTime(iso);
  const dayKey = (d) => d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();

  /* ---------- Iconos ---------- */
  const ICONS = {
    logo: '<path d="M12 3 8.5 5v4L12 11l3.5-2V5zM7 11.5l-3.5 2v4L7 19.5l3.5-2v-4zM17 11.5l-3.5 2v4l3.5 2 3.5-2v-4z"/>',
    mail: '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-10 6L2 7"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    eyeOff: '<path d="M9.9 4.2A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-2.2 3.2M6.6 6.6A17 17 0 0 0 2 12s3.5 7 10 7a10 10 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/><path d="m2 2 20 20"/>',
    checkCircle: '<circle cx="12" cy="12" r="10"/><path d="m8 12 3 3 5-6"/>',
    shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>',
    refresh: '<path d="M21 12a9 9 0 0 0-15-6.7L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 15 6.7L21 16"/><path d="M16 16h5v5"/>',
    logOut: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    grid: '<rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/>',
    box: '<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="m3 8 9 5 9-5M12 13v8"/>',
    boxPlus: '<path d="M20 11V8l-8-5-9 5v8l9 5 2-1"/><path d="m3 8 9 5 8-5M12 13v8M19 15v6M16 18h6"/>',
    users: '<circle cx="9" cy="8" r="4"/><path d="M2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1"/><path d="M16 4a4 4 0 0 1 0 8M22 21v-1a6 6 0 0 0-4-5.6"/>',
    cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.7 12.4a2 2 0 0 0 2 1.6h8.1a2 2 0 0 0 2-1.5L21 8H6"/>',
    receipt: '<path d="M5 2h14v20l-3-2-2 2-2-2-2 2-2-2-3 2z"/><path d="M9 7h6M9 11h6M9 15h4"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>',
    trash: '<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>',
    wallet: '<path d="M20 7H5a2 2 0 0 1 0-4h13v4"/><path d="M3 5v14a2 2 0 0 0 2 2h15V7"/><path d="M16 14h2"/>',
    alert: '<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
    userPlus: '<circle cx="9" cy="8" r="4"/><path d="M2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1M19 8v6M16 11h6"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    upload: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/>',
    download: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>',
    clipboard: '<rect x="5" y="4" width="14" height="18" rx="2"/><path d="M9 2h6v4H9zM9 14l2 2 4-4"/>',
    bag: '<path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4zM3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
    mouse: '<rect x="6" y="3" width="12" height="18" rx="6"/><path d="M12 7v4"/>',
    keyboard: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M6 9h.01M10 9h.01M14 9h.01M18 9h.01M7 15h10"/>',
    monitor: '<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>',
    headphones: '<path d="M3 14v-2a9 9 0 0 1 18 0v2"/><path d="M21 15a2 2 0 0 1-2 2h-1v-6h1a2 2 0 0 1 2 2zM3 15a2 2 0 0 0 2 2h1v-6H5a2 2 0 0 0-2 2z"/>',
    cable: '<path d="M9 2v4M15 2v4M7 6h10v4a5 5 0 0 1-10 0zM12 15v7"/>',
    laptop: '<rect x="4" y="5" width="16" height="11" rx="2"/><path d="M2 19h20"/>',
    printer: '<path d="M6 9V3h12v6"/><rect x="3" y="9" width="18" height="8" rx="2"/><path d="M7 14h10v7H7z"/>',
    wifi: '<path d="M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 20h.01"/>',
    drive: '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 14h.01M11 14h6"/>',
    phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
    plug: '<path d="M9 2v6M15 2v6M6 8h12v3a6 6 0 0 1-12 0zM12 17v5"/>',
    camera: '<path d="M3 8h4l2-3h6l2 3h4v11H3z"/><circle cx="12" cy="13" r="4"/>',
    key: '<circle cx="8" cy="15" r="4"/><path d="m11 12 9-9M16 7l3 3M14 9l2 2"/>',
    gamepad: '<rect x="2" y="7" width="20" height="11" rx="5"/><path d="M7 10v5M4.5 12.5h5M16 11h.01M18 14h.01"/>',
    cross: '<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6z"/>',
    bed: '<path d="M2 18V6M2 14h20v4M22 14v-3a3 3 0 0 0-3-3h-9v6"/><circle cx="6" cy="10" r="2"/>',
    flame: '<path d="M12 2s5 4 5 9a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3 1-5 1-8z"/>',
    shirt: '<path d="M8 3 3 6l2 4 3-1v12h8V9l3 1 2-4-5-3a4 4 0 0 1-8 0z"/>',
    hardhat: '<path d="M3 18h18M5 18a7 7 0 0 1 14 0M12 5v6"/>',
    calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    ban: '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>'
  };
  const icon = (name) => `<svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[name] || ''}</svg>`;
  function paintIcons(root = document) {
    $$('[data-icon]', root).forEach((el) => { if (!el.firstElementChild) el.innerHTML = icon(el.dataset.icon); });
  }

  /* ---------- Roles y permisos ---------- */
  const ROLES = ['Superadministrador', 'Administrador', 'Supervisor', 'Asesor de ventas', 'Cliente'];
  /* Roles que piden código de autorización al registrarse (el servidor valida el código) */
  const CODE_ROLES = ['Supervisor', 'Administrador', 'Superadministrador'];
  const RANK = { 'Superadministrador': 4, 'Administrador': 3, 'Supervisor': 2, 'Asesor de ventas': 1, 'Cliente': 0 };
  const PAGES = {
    'Superadministrador': ['dashboard', 'inventory', 'history', 'admin'], // solo vigila (lectura) y gestiona usuarios
    'Administrador': ['dashboard', 'inventory', 'add', 'history', 'admin'],
    'Supervisor': ['dashboard', 'inventory', 'add', 'history', 'sales'],
    'Asesor de ventas': ['dashboard', 'inventory', 'sales', 'history'], // atiende clientes y vende; no edita el catálogo
    'Cliente': ['shop', 'checkout', 'history', 'profile'] // Tienda, pasos de compra, sus compras y su perfil
  };
  const isAdminRole = (r) => RANK[r] >= 3;
  /* El superadministrador es solo de vigilancia: puede ver todo, pero lo único que
     puede modificar son los usuarios ya existentes. No vende, no toca el catálogo,
     crea los usuarios y no tiene "modo usuario". */
  const isSuperRole = (r) => r === 'Superadministrador';
  const hasDual = (r) => r === 'Administrador'; // solo el administrador puede entrar también como usuario

  /* ¿Puede `actor` cambiar el rol de `target`?
     - Nunca el suyo propio.
     - Solo a quien tiene un rango menor.
     - Un administrador también puede cambiar a otro administrador que él mismo creó,
       pero ese administrador nunca puede tocar a quien le dio el rol.
     - Nadie (ni otro superadministrador) puede cambiar a un superadministrador. */
  function canModify(actor, target) {
    if (!isAdminRole(actor.role) || actor.email === target.email) return false;
    if (RANK[actor.role] > RANK[target.role]) return true;
    return RANK[actor.role] === RANK[target.role] && actor.role !== 'Superadministrador' && target.grantedBy === actor.email;
  }
  /* El Superadministrador es único (el predeterminado): ya no aparece como opción al crear ni al cambiar roles. */
  const assignableRoles = (actor) => ROLES.filter((r) => RANK[r] <= RANK[actor.role] && r !== 'Superadministrador');

  /* Productos que ya no se venden: no deben aparecer nunca */
  const RETIRED = /anillo|televisor.*4\s*k|tv.*4\s*k/i;

  /* ---------- Iconos por categoría ---------- */
  const CATEGORY_ICON = { 'Camillas': 'bed', 'Botiquines': 'cross', 'Extintores': 'flame', 'Dotaciones': 'shirt', 'Elementos de protección personal': 'hardhat', 'Gestión del SG-SST': 'shield', 'Capacitaciones': 'users', 'Auditorías': 'checkCircle', 'Evaluaciones y análisis': 'search' };
  const catIcon = (c) => CATEGORY_ICON[c] || 'box';

  /* ---------- Conexión con el backend (Django + MySQL) ---------- */
  /* Dos modos, sin cambiar nada: si abres el frontend con `python -m http.server 5173` (o Live Server 5500) usa el backend Django en el puerto 8000;
     en cualquier otro caso (Apache en Ubuntu / servidor PHP) usa la API del mismo servidor en /api. */
  const API_URL = window.NEXO_API_URL || (['5173', '5500'].includes(window.location.port) ? `http://${window.location.hostname}:8000/api` : '/api');
  const csrfToken = () => document.cookie.split('; ').find((row) => row.startsWith('csrftoken='))?.split('=')[1] || '';
  async function api(path, options = {}) {
    let response;
    try {
      if (!document.cookie.includes('csrftoken=')) await fetch(API_URL + '/auth/csrf/', { credentials: 'include' });
      response = await fetch(API_URL + path, {
        credentials: 'include',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': decodeURIComponent(csrfToken()), ...(options.headers || {}) },
        ...options
      });
    } catch (e) { throw new Error('No se pudo conectar con el servidor. Verifica que Apache y PHP estén activos en el servidor.'); }
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || 'No fue posible completar la operación.');
    return data;
  }

  /* ---------- Estado (los datos vienen del servidor / MySQL) ---------- */
  const state = {
    me: null,          // usuario con sesión iniciada (lo entrega el servidor)
    users: [], products: [], categories: [], clients: [], sales: [],
    session: null,
    page: 'dashboard',
    tab: 'all',
    histTab: 'all',
    cart: {},
    newImage: null
  };

  /* Descarga los datos que el rol actual puede ver. */
  async function loadData() {
    const role = state.me.role, jobs = [
      api('/products/').then((d) => { state.products = d.products.filter((p) => !RETIRED.test(p.name)); }),
      api('/categories/').then((d) => { state.categories = d.categories; }),
      api('/sales/').then((d) => { state.sales = d.sales; })
    ];
    if (role !== 'Cliente' && role !== 'Superadministrador') jobs.push(api('/clients/').then((d) => { state.clients = d.clients; }));
    if (RANK[role] >= 3) jobs.push(api('/users/').then((d) => { state.users = d.users; }));
    await Promise.all(jobs);
  }

  const sortedCats = () => state.categories.slice().sort((a, b) => a.localeCompare(b, 'es'));

  const isSvc = (p) => p.kind === 'service';
  function status(p) {
    if (isSvc(p)) return { key: 'service', label: 'Servicio', cls: 'ok' };
    if (p.stock <= 0) return { key: 'out', label: 'Agotado', cls: 'out' };
    if (p.stock <= p.min) return { key: 'low', label: 'Pocas unidades', cls: 'low' };
    return { key: 'ok', label: 'Disponible', cls: 'ok' };
  }

  /* ---------- Permisos de la sesión ---------- */
  /* El administrador con acceso dual puede entrar «como cliente»: ve la tienda, su perfil y sus compras, como un cliente más. */
  const effRole = () => (hasDual(state.session.role) && state.session.mode === 'user') ? 'Cliente' : state.session.role;
  const isSuper = () => !!state.session && isSuperRole(state.session.role);
  const can = (page) => PAGES[effRole()].includes(page);
  const seesAllSales = () => RANK[effRole()] >= 2;
  const isClient = () => effRole() === 'Cliente';
  const canDelete = () => RANK[effRole()] >= 2 && !isSuper();
  const home = () => PAGES[effRole()][0];
  const visibleSales = () => {
    if (seesAllSales()) return state.sales;
    if (isClient()) { const u = currentUser(), cid = u ? (u.clientId != null ? u.clientId : (u.client && u.client.id)) : null; return state.sales.filter((v) => cid != null && v.client.id === cid); }
    return state.sales.filter((v) => v.advisor.email === state.session.email || v.advisor.role === 'Autoservicio');
  };
  const currentUser = () => state.me;

  /* ---------- Avisos ---------- */
  let toastTimer;
  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg; t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { t.hidden = true; }, 3000);
  }

  /* ---------- Navegación ---------- */
  function showView(id) {
    $$('.view').forEach((v) => { v.hidden = v.id !== id; });
    document.body.classList.toggle('auth-open', id === 'view-login' || id === 'view-register');
    window.scrollTo(0, 0);
  }
  function showAuth(which) {
    $('#login-error').hidden = true; $('#register-error').hidden = true;
    showView('view-' + which);
  }

  const TITLES = { profile: 'Mi perfil', dashboard: 'Inicio', inventory: 'Productos y servicios', admin: 'Usuarios', sales: 'Registrar venta', history: 'Historial de ventas', add: 'Agregar al catálogo' };
  const titleOf = (page) => isClient() ? ({ shop: 'Tienda', checkout: 'Finalizar compra', history: 'Mis compras', profile: 'Mi perfil' }[page] || TITLES[page]) : TITLES[page];
  const statusOf = (v) => v.status || 'Entregado';
  /* Las ventas anuladas no suman en totales ni gráficas (igual que el reporte de Excel). */
  const counts = (v) => (v.status || 'Entregado') !== 'Anulada';
  const statusCls = (v) => ({ 'Pendiente': 'low', 'Entregado': 'ok', 'Anulada': 'out' }[statusOf(v)]);
  const canManageOrders = () => !isSuper() && !isClient();
  function applyShell() {
    const s = state.session, u = currentUser();
    $('#side-name').textContent = s.name;
    $('#side-avatar').textContent = initials(s.name);
    const dual = hasDual(s.role) && u && u.dual;
    $('#side-role').textContent = dual && s.mode === 'user' ? s.role + ' · modo cliente' : s.role;
    $('#mode-switch').hidden = !dual;
    $$('#mode-switch [data-mode]').forEach((b) => b.classList.toggle('active', b.dataset.mode === s.mode));
    $$('[data-page]').forEach((el) => { el.hidden = !can(el.dataset.page); });
    const nameNav = (pg, txt) => { const b = $('.nav-item[data-page="' + pg + '"]'); if (b) b.lastChild.textContent = ' ' + txt; };
    nameNav('history', isClient() ? 'Mis compras' : 'Historial de ventas');
    document.body.classList.toggle('is-client', isClient());
    document.body.classList.toggle('is-super', isSuper());
    $('#readonly-badge').hidden = !isSuper();
    $('#cart-btn').hidden = !isClient();
    syncCartViews();
    $('#top-date').textContent = new Date().toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  }

  function go(page) {
    if (!can(page)) page = home();
    state.page = page;
    $$('.page').forEach((p) => { p.hidden = p.id !== 'page-' + page; });
    $$('.nav-item').forEach((n) => n.classList.toggle('active', n.dataset.page === page));
    $('#crumb').textContent = titleOf(page);
    $('#sidebar').classList.remove('open');
    ({ dashboard: renderDashboard, inventory: renderInventory, admin: renderAdmin, profile: renderProfile, sales: renderSales, history: renderHistory, add: renderAdd, shop: renderShop, checkout: renderCheckout }[page])();
    window.scrollTo(0, 0);
  }

  /* ---------- Sesión ---------- */
  async function enterApp(user, mode) {
    state.me = user;
    const dual = hasDual(user.role) && user.dual;
    state.session = { name: user.name, email: user.email, role: user.role, mode: dual && mode === 'user' ? 'user' : 'admin' };
    persistMode();
    showView('app');
    applyShell();
    try { await loadData(); } catch (e) { toast(e.message); }
    go(home());
  }
  function persistMode() { Store.set('magnus_mode', { email: state.session.email, mode: state.session.mode }); }
  async function logout() {
    try { await api('/auth/logout/', { method: 'POST' }); } catch (e) { /* sin conexión: igual se sale */ }
    state.session = null; state.me = null; state.cart = {}; CO.step = 1; CO.filled = false; CO.data = {}; clearCardForm();
    state.users = []; state.products = []; state.sales = []; state.clients = []; state.categories = [];
    closeModals();
    $('#login-email').value = ''; $('#login-pass').value = '';
    showAuth('login');
    toast('Sesión cerrada');
  }

  /* ---------- Inicio de sesión ---------- */
  $('#login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = $('#login-email').value.trim().toLowerCase(), pass = $('#login-pass').value;
    const err = $('#login-error');
    if (!email || !pass) { err.textContent = 'Ingresa tu correo y tu contraseña.'; err.hidden = false; return; }
    try {
      const d = await api('/auth/login/', { method: 'POST', body: JSON.stringify({ email, password: pass, remember: $('#login-remember').checked }) });
      err.hidden = true;
      await enterApp(d.user, 'admin');
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
  $('#forgot-link').addEventListener('click', (e) => { e.preventDefault(); toast('Pídele a un administrador que te ayude a restablecer tu contraseña.'); });

  /* ---------- Validación de cédula / NIT y teléfono (anti-números al azar) ---------- */
  const onlyDigits = (s) => String(s || '').replace(/\D/g, '');
  const LETTERS = 'A-Za-zÁÉÍÓÚÜÑáéíóúüñ';
  const sameDoc = (a, b) => { const x = onlyDigits(a), y = onlyDigits(b); return !!x && x === y; };

  /* Detecta números "inventados": 1111111, 1212121, 123456789, 987654321... */
  function isTrivialDigits(d) {
    if (d.length < 2) return false;
    for (let p = 1; p <= 3; p++) {
      if (d.length >= p * 2 && d.split('').every((c, i) => c === d[i % p])) return true;
    }
    const steps = d.split('').slice(1).map((c, i) => (+c - +d[i] + 10) % 10);
    return steps.every((s) => s === 1) || steps.every((s) => s === 9);
  }
  const fewDistinct = (d) => new Set(d.split('')).size < 3;

  /* Dígito de verificación del NIT (algoritmo de la DIAN) */
  function nitDV(base) {
    const w = [3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71];
    const sum = base.split('').reverse().reduce((a, c, i) => a + (+c) * w[i], 0);
    const r = sum % 11;
    return r > 1 ? 11 - r : r;
  }

  function validateDoc(raw) {
    const t = String(raw || '').trim();
    if (!t) return { ok: false, msg: 'Escribe tu cédula o NIT.' };
    if (/[^\d.\-\s]/.test(t)) return { ok: false, msg: 'Solo se permiten números (y el guion del NIT).' };
    if (t.includes('-')) {
      const parts = t.replace(/[.\s]/g, '').split('-');
      if (parts.length !== 2 || !/^\d{8,10}$/.test(parts[0]) || !/^\d$/.test(parts[1])) {
        return { ok: false, msg: 'El NIT debe tener de 8 a 10 dígitos, un guion y el dígito de verificación. Ej: 900123456-1' };
      }
      if (parts[0][0] === '0' || isTrivialDigits(parts[0]) || fewDistinct(parts[0])) return { ok: false, msg: 'Ese NIT no parece real. Revisa el número.' };
      if (nitDV(parts[0]) !== +parts[1]) return { ok: false, msg: 'El dígito de verificación del NIT no es correcto.' };
      return { ok: true, type: 'NIT', value: parts[0] + '-' + parts[1] };
    }
    const d = onlyDigits(t);
    if (d.length < 6 || d.length > 10) return { ok: false, msg: 'La cédula debe tener entre 6 y 10 dígitos.' };
    if (d[0] === '0') return { ok: false, msg: 'La cédula no puede empezar por 0.' };
    if (d.length === 10 && d[0] !== '1') return { ok: false, msg: 'Una cédula de 10 dígitos empieza por 1. Si es un NIT, escríbelo con guion y dígito de verificación.' };
    if (isTrivialDigits(d) || fewDistinct(d)) return { ok: false, msg: 'Ese número no parece una cédula real. Revisa que esté bien escrito.' };
    return { ok: true, type: 'Cédula', value: d };
  }

  function validatePhone(raw) {
    const t = String(raw || '').trim();
    if (!t) return { ok: false, msg: 'Escribe tu número de teléfono.' };
    if (/[^\d\s\-+().]/.test(t)) return { ok: false, msg: 'Solo se permiten números.' };
    let d = onlyDigits(t);
    if (d.length === 12 && d.startsWith('57')) d = d.slice(2);
    if (d.length !== 10) return { ok: false, msg: 'El teléfono debe tener 10 dígitos. Ej: 310 456 7821 o 608 871 2345.' };
    const mobile = /^3[0-5]\d{8}$/.test(d), land = /^60[1-8]\d{7}$/.test(d);
    if (!mobile && !land) return { ok: false, msg: 'Número no válido: un celular empieza por 3 (ej. 310…) y un fijo por 60 + indicativo (ej. 608…).' };
    const sub = d.slice(3);
    if (isTrivialDigits(d) || isTrivialDigits(sub) || fewDistinct(sub)) return { ok: false, msg: 'Ese número no parece real. Revisa que esté bien escrito.' };
    return { ok: true, value: d.slice(0, 3) + ' ' + d.slice(3, 6) + ' ' + d.slice(6) };
  }

  /* Muestra el aviso de error bajo el campo mientras se escribe y al salir de él */
  function bindValidation(id, fn, strip, maxLen) {
    const el = $('#' + id); if (!el) return;
    el.maxLength = maxLen;
    const msg = document.createElement('small');
    msg.className = 'field-msg'; msg.hidden = true;
    el.insertAdjacentElement('afterend', msg);
    const check = () => {
      if (!el.value.trim()) { msg.hidden = true; el.classList.remove('invalid'); return; }
      const r = fn(el.value);
      msg.textContent = r.ok ? '' : r.msg; msg.hidden = r.ok;
      el.classList.toggle('invalid', !r.ok);
    };
    el.addEventListener('input', () => {
      const clean = el.value.replace(strip, '');
      if (clean !== el.value) el.value = clean;
      if (el.classList.contains('invalid')) check();
    });
    el.addEventListener('blur', check);
    if (el.form) el.form.addEventListener('reset', () => { msg.hidden = true; el.classList.remove('invalid'); });
  }
  const DOC_STRIP = /[^\d.\-\s]/g, PHONE_STRIP = /[^\d\s\-+().]/g;
  ['reg', 'u', 'cl', 'co'].forEach((p) => {
    bindValidation(p + '-doc', validateDoc, DOC_STRIP, 16);
    bindValidation(p + '-phone', validatePhone, PHONE_STRIP, 18);
  });

  /* ---------- Registro ---------- */
  const passOk = (p) => p.length >= 8 && /[A-Za-z]/.test(p) && /\d/.test(p);
  const emailOk = (e) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);
  function updateStrength() {
    const p = $('#reg-pass').value, p2 = $('#reg-pass2').value;
    const box = $('#reg-strength'), txt = $('span', box);
    box.className = 'strength';
    if (!p) { box.classList.add('bad'); txt.textContent = 'Mínimo 8 caracteres, una letra y un número'; return; }
    if (!passOk(p)) { box.classList.add('err'); txt.textContent = 'Muy débil: usa 8 caracteres, una letra y un número'; return; }
    if (p2 && p !== p2) { box.classList.add('err'); txt.textContent = 'Las contraseñas no coinciden'; return; }
    txt.textContent = 'Contraseña válida';
  }
  $('#reg-pass').addEventListener('input', updateStrength);
  $('#reg-pass2').addEventListener('input', updateStrength);

  function syncRegFields() { $('#reg-client-fields').hidden = false; }

  $('#register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const role = 'Cliente';
    const name = $('#reg-name').value.trim(), email = $('#reg-email').value.trim().toLowerCase();
    const p = $('#reg-pass').value, p2 = $('#reg-pass2').value;
    const err = $('#register-error');
    const fail = (m) => { err.textContent = m; err.hidden = false; };
    if (!name || !email || !p || !p2) return fail('Completa todos los campos obligatorios (*).');
    if (!emailOk(email)) return fail('Escribe un correo electrónico válido.');
    if (!passOk(p)) return fail('La contraseña debe tener mínimo 8 caracteres, una letra y un número.');
    if (p !== p2) return fail('Las contraseñas no coinciden.');
    let doc = $('#reg-doc').value.trim(), phone = $('#reg-phone').value.trim();
    if (role === 'Cliente') {
      const vd = validateDoc(doc); if (!vd.ok) return fail(vd.msg);
      const vp = validatePhone(phone); if (!vp.ok) return fail(vp.msg);
      doc = vd.value; phone = vp.value;
    }
    try {
      const d = await api('/auth/register/', { method: 'POST', body: JSON.stringify({ role, name, email, password: p, doc, phone }) });
      err.hidden = true;
      $('#register-form').reset(); syncRegFields(); updateStrength();
      toast('Cuenta creada. ¡Bienvenido/a!');
      await enterApp(d.user, 'admin');
    } catch (ex) { fail(ex.message); }
  });

  $$('[data-eye]').forEach((btn) => btn.addEventListener('click', () => {
    const input = $('#' + btn.dataset.eye), show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    btn.innerHTML = icon(show ? 'eye' : 'eyeOff');
  }));
  $$('[data-auth]').forEach((a) => a.addEventListener('click', (e) => { e.preventDefault(); showAuth(a.dataset.auth); }));

  /* ---------- Inicio (panel) ---------- */
  function niceMax(v) {
    if (v <= 0) return 100000;
    const p = Math.pow(10, Math.floor(Math.log10(v))), m = v / p;
    return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p;
  }
  const shortMoney = (n) => n >= 1e6 ? '$ ' + (n / 1e6).toLocaleString('es-CO', { maximumFractionDigits: 1 }) + ' M' : n >= 1e3 ? '$ ' + Math.round(n / 1e3) + ' mil' : '$ ' + n;

  function renderDashboard() {
    const s = state.session, today = new Date();
    const mine = !seesAllSales();
    $('#dash-title').textContent = `Hola, ${s.name.split(' ')[0]}`;
    $('#dash-sub').textContent = `${isSuper() ? 'Vista de vigilancia (solo lectura) · ' : ''}Resumen de Magnus SIG S.A.S · ${today.toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long' })}`;
    $('#k-sales-label').textContent = mine ? 'Mis ventas de hoy' : 'Ventas de hoy';

    const sales = visibleSales().filter(counts);
    const todays = sales.filter((v) => dayKey(new Date(v.date)) === dayKey(today));
    const active = state.products.filter((p) => p.active);
    const stocked = state.products.filter((p) => !isSvc(p));
    const units = stocked.reduce((a, p) => a + p.stock, 0);
    const low = active.filter((p) => status(p).key === 'low').length, out = active.filter((p) => status(p).key === 'out').length;

    $('#k-sales').textContent = money(todays.reduce((a, v) => a + v.total, 0));
    $('#k-sales-sub').textContent = `${todays.length} venta${todays.length === 1 ? '' : 's'} registrada${todays.length === 1 ? '' : 's'} hoy`;
    $('#k-active').textContent = active.length;
    $('#k-active-sub').textContent = `${active.filter((p) => !isSvc(p)).length} productos · ${active.filter(isSvc).length} servicios`;
    $('#k-units').textContent = units;
    $('#k-units-sub').textContent = `Valor en inventario: ${money(stocked.reduce((a, p) => a + p.stock * p.price, 0))}`;
    $('#k-alerts').textContent = low + out;
    $('#k-alerts-sub').textContent = `${low} con pocas unidades · ${out} agotado${out === 1 ? '' : 's'}`;

    const days = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
    const series = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(); d.setDate(d.getDate() - i);
      const total = sales.filter((v) => dayKey(new Date(v.date)) === dayKey(d)).reduce((a, v) => a + v.total, 0);
      series.push({ label: days[d.getDay()], total, today: i === 0 });
    }
    const top = niceMax(Math.max.apply(null, series.map((x) => x.total)));
    $('#week-total').textContent = money(series.reduce((a, x) => a + x.total, 0));
    $('#y-axis').innerHTML = `<span>${shortMoney(top)}</span><span>${shortMoney(top / 2)}</span><span>$ 0</span>`;
    $('#bars').innerHTML = series.map((x) => `<div class="bar-col"><div class="bar ${x.today ? 'today' : ''}" style="height:${Math.round(x.total / top * 100)}%" title="${money(x.total)}"></div><span>${x.label}</span></div>`).join('');

    const att = active.filter((p) => ['low', 'out'].includes(status(p).key)).slice(0, 4);
    $('#attention').innerHTML = att.length ? att.map((p) => {
      const st = status(p);
      return `<li><div class="att-name">${icon(catIcon(p.cat))} ${esc(p.name)}</div>
        <div class="att-meta"><span>${p.stock} unidades · avisar en ${p.min}</span><span class="pill ${st.cls}">${st.label}</span></div></li>`;
    }).join('') : '<li class="muted" style="border:0">Todo en orden, no hay productos por reponer.</li>';

    $('#recent-sales').innerHTML = sales.slice(0, 5).map((v) =>
      `<tr class="click-row" data-sale="${esc(v.folio)}"><td><a>${esc(v.folio)}</a></td><td>${esc(v.client.name)}</td><td class="muted">${esc(v.advisor.name)}</td><td><b>${money(v.total)}</b></td></tr>`).join('')
      || '<tr class="empty-row"><td colspan="4">Aún no hay ventas.</td></tr>';
  }
  $('#recent-sales').addEventListener('click', (e) => { const r = e.target.closest('[data-sale]'); if (r) openSaleDetail(r.dataset.sale); });

  /* ---------- Inventario ---------- */
  const imgOf = (p) => p.image || (p.sku ? `img/productos/${encodeURIComponent(p.sku)}.svg` : '');
  const thumb = (p) => imgOf(p) ? `<img src="${imgOf(p)}" alt="${esc(p.name)}" onerror="this.replaceWith(Object.assign(document.createElement('span'),{innerHTML:window.__fallbackIcon||''}))">` : icon(catIcon(p.cat));

  function fillCategorySelect() {
    const sel = $('#inv-cat'), current = sel.value;
    const cats = sortedCats();
    sel.innerHTML = '<option value="">Todas las categorías</option>' + cats.map((c) => `<option>${esc(c)}</option>`).join('');
    sel.value = cats.includes(current) ? current : '';
  }

  function renderInventory() {
    fillCategorySelect();
    const all = state.products, goods = all.filter((p) => !isSvc(p)), svcs = all.filter(isSvc);
    const lowN = all.filter((p) => status(p).key === 'low').length, outN = all.filter((p) => status(p).key === 'out').length;
    const outNames = all.filter((p) => status(p).key === 'out').map((p) => p.name);
    $('#i-total').textContent = goods.length;
    $('#i-total-sub').textContent = `${svcs.length} servicios en el catálogo`;
    $('#i-units').textContent = goods.reduce((a, p) => a + p.stock, 0);
    $('#i-value').textContent = `Valor: ${money(goods.reduce((a, p) => a + p.stock * p.price, 0))}`;
    $('#i-low').textContent = lowN; $('#i-out').textContent = outN;
    $('#i-out-sub').textContent = outNames.length ? outNames[0] + (outNames.length > 1 ? ` y ${outNames.length - 1} más` : '') : 'Ningún producto agotado';
    $('#c-all').textContent = all.length; $('#c-product').textContent = goods.length; $('#c-service').textContent = svcs.length; $('#c-low').textContent = lowN; $('#c-out').textContent = outN;
    $$('#inv-tabs .tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === state.tab));

    const q = norm($('#inv-search').value.trim()), cat = $('#inv-cat').value, canEdit = canDelete();
    const rows = all.filter((p) => {
      if (state.tab === 'product' && isSvc(p)) return false;
      if (state.tab === 'service' && !isSvc(p)) return false;
      if (['low', 'out'].includes(state.tab) && status(p).key !== state.tab) return false;
      if (cat && p.cat !== cat) return false;
      return !q || norm(p.name).includes(q) || norm(p.sku).includes(q);
    });
    $('#inv-body').innerHTML = rows.length ? rows.map((p) => {
      const st = status(p);
      return `<tr class="click-row" data-product="${p.id}">
        <td><div class="prod-cell"><span class="thumb">${thumb(p)}</span><div><strong>${esc(p.name)}</strong><small>Código ${esc(p.sku)}</small></div></div></td>
        <td class="muted">${esc(p.cat)}</td>
        <td>${isSvc(p) ? '<span class="muted">Servicio</span>' : `<b>${p.stock}</b> uds.`}</td>
        <td>${money(p.price)}</td>
        <td>${isSvc(p) ? '' : `<span class="pill ${st.cls}">${st.label}</span>`}${p.active ? '' : ' <span class="pill gray">Inactivo</span>'}</td>
        <td>${canEdit ? `<button class="icon-btn" data-del="${p.id}" aria-label="Eliminar producto" title="Eliminar">${icon('trash')}</button>` : ''}</td>
      </tr>`;
    }).join('') : '<tr class="empty-row"><td colspan="6">No se encontraron productos.</td></tr>';
  }
  $('#inv-tabs').addEventListener('click', (e) => { const t = e.target.closest('.tab'); if (!t) return; state.tab = t.dataset.tab; renderInventory(); });
  $('#inv-search').addEventListener('input', renderInventory);
  $('#inv-cat').addEventListener('change', renderInventory);
  $('#inv-body').addEventListener('click', (e) => {
    const del = e.target.closest('[data-del]');
    if (del) {
      if (!canDelete()) return toast('El superadministrador solo puede consultar.');
      const p = state.products.find((x) => x.id === +del.dataset.del);
      if (p && confirm(`¿Eliminar "${p.name}" del catálogo?`)) {
        api('/products/' + p.id + '/delete/', { method: 'DELETE' }).then(() => {
          state.products = state.products.filter((x) => x.id !== p.id);
          delete state.cart[p.id];
          renderInventory(); toast('Eliminado del catálogo');
        }).catch((ex) => toast(ex.message));
      }
      return;
    }
    const row = e.target.closest('[data-product]');
    if (row) openProductDetail(+row.dataset.product);
  });

  /* Solo el administrador y el superadministrador pueden cambiar la foto de un producto o servicio */
  const canEditPhoto = () => RANK[effRole()] >= 3;
  const photoInput = document.createElement('input');
  photoInput.type = 'file'; photoInput.accept = 'image/png,image/jpeg'; photoInput.hidden = true; document.body.appendChild(photoInput);
  let photoTarget = null;
  $('#detail-body').addEventListener('click', (e) => {
    const b = e.target.closest('[data-photo]'); if (!b || !canEditPhoto()) return;
    const p = state.products.find((x) => x.id === +b.dataset.id); if (!p) return;
    if (b.dataset.photo === 'remove') {
      if (!confirm(`¿Quitar la foto de "${p.name}"?`)) return;
      saveProductImage(p, null).then(() => { afterPhotoChange(p.id); toast('Foto eliminada.'); }).catch((ex) => toast(ex.message)); return;
    }
    photoTarget = p.id; photoInput.click();
  });
  /* Guarda la foto con la API existente (PUT /api/products/<id>/), sin cambiar nada del backend */
  function saveProductImage(p, image) {
    return api('/products/' + p.id + '/', { method: 'PUT', body: JSON.stringify({
      kind: p.kind, name: p.name, sku: p.sku, cat: p.cat, desc: p.desc, cost: p.cost, price: p.price,
      stock: p.stock, min: p.min, active: p.active, icon: p.icon || 'box', image
    }) }).then((d) => { Object.assign(p, d.product); });
  }
  function afterPhotoChange(id) { if (state.page === 'inventory') renderInventory(); openProductDetail(id); }
  photoInput.addEventListener('change', (e) => {
    const f = e.target.files[0], id = photoTarget; e.target.value = '';
    if (!f || !canEditPhoto()) return;
    if (!/^image\/(png|jpeg)$/.test(f.type)) return toast('La imagen debe ser JPG o PNG.');
    if (f.size > 5 * 1024 * 1024) return toast('La imagen supera el máximo de 5 MB.');
    const reader = new FileReader();
    reader.onload = () => {
      const im = new Image();
      im.onload = () => {
        const max = 320, ratio = Math.min(1, max / Math.max(im.width, im.height));
        const c = document.createElement('canvas'); c.width = Math.round(im.width * ratio); c.height = Math.round(im.height * ratio);
        c.getContext('2d').drawImage(im, 0, 0, c.width, c.height);
        const p = state.products.find((x) => x.id === id); if (!p) return;
        saveProductImage(p, c.toDataURL('image/jpeg', 0.8)).then(() => { afterPhotoChange(id); toast('Foto actualizada.'); }).catch((ex) => toast(ex.message));
      };
      im.src = reader.result;
    };
    reader.readAsDataURL(f);
  });

  function openProductDetail(id) {
    const p = state.products.find((x) => x.id === id); if (!p) return;
    const st = status(p), margin = p.cost ? Math.round((p.price - p.cost) / p.price * 100) : null, staff = !isClient();
    $('#detail-body').innerHTML = `
      <div class="detail-head">
        <span class="thumb big">${thumb(p)}</span>
        <div><h2>${esc(p.name)}</h2><p class="sub">${esc(p.cat)} · Código ${esc(p.sku)}</p>
        <p><span class="pill ${st.cls}">${isSvc(p) ? 'Servicio' : st.label}</span>${p.active ? '' : ' <span class="pill gray">Inactivo</span>'}</p>
        ${canEditPhoto() ? `<div class="photo-actions"><button type="button" class="btn btn-outline" data-photo="change" data-id="${p.id}">${icon('upload')} ${p.image ? 'Cambiar foto' : 'Cargar foto'}</button>${p.image ? `<button type="button" class="btn btn-outline" data-photo="remove" data-id="${p.id}">Quitar foto</button>` : ''}</div>` : ''}</div>
      </div>
      <h4 class="detail-title">Descripción</h4>
      <p class="detail-text">${p.desc ? esc(p.desc) : '<span class="muted">Sin descripción.</span>'}</p>
      <div class="detail-grid">
        <div><small>Precio de venta</small><strong>${money(p.price)}</strong></div>
        <div><small>Precio con IVA (19%)</small><strong>${money(p.price * (1 + IVA))}</strong></div>
        ${staff ? `<div><small>Precio de costo</small><strong>${p.cost != null ? money(p.cost) : '—'}</strong></div>
        <div><small>Margen de ganancia</small><strong>${margin != null ? margin + '%' : '—'}</strong></div>` : ''}
        ${isSvc(p) ? '' : `<div><small>Unidades disponibles</small><strong>${p.stock}</strong></div>
        ${staff ? `<div><small>Avisar cuando queden</small><strong>${p.min}</strong></div>` : ''}`}
      </div>
      ${!staff ? `<div class="detail-buy"><button type="button" class="btn btn-primary" data-buy="${p.id}" ${!isSvc(p) && p.stock <= 0 ? 'disabled' : ''}>${icon('cart')} ${!isSvc(p) && p.stock <= 0 ? 'Producto agotado' : 'Agregar al carrito'}</button></div>` : ''}`;
    openModal('detail-modal');
  }

  /* ---------- Usuarios ---------- */
  function renderAdmin() {
    const me = currentUser() || state.session;
    const q = norm($('#team-search').value.trim());
    const stamp = (m) => Date.parse(m.last || m.joined || '') || 0;
    const rows = state.users.filter((m) => !q || norm(m.name).includes(q) || norm(m.email).includes(q)).sort((a, b) => stamp(b) - stamp(a));
    $('#team-sub').textContent = `${state.users.length} usuario${state.users.length === 1 ? '' : 's'} registrados · el que ingresó más recientemente aparece primero`;
    $('#team-body').innerHTML = rows.length ? rows.map((m) => {
      const editable = canModify(me, m), self = m.email === me.email;
      const roleCell = editable
        ? `<select class="role-select" data-role-for="${esc(m.email)}">${assignableRoles(me).map((r) => `<option ${r === m.role ? 'selected' : ''}>${r}</option>`).join('')}</select>`
        : `<span class="pill ${m.role === 'Superadministrador' ? 'ok' : 'gray'}">${esc(m.role)}</span>${m.role === 'Superadministrador' || !self ? '' : ''}`;
      let dualCell = '<span class="muted">—</span>';
      if (hasDual(m.role)) {
        dualCell = editable
          ? `<label class="check inline"><input type="checkbox" data-dual-for="${esc(m.email)}" ${m.dual ? 'checked' : ''}><span class="box"></span> ${m.dual ? 'Sí' : 'No'}</label>`
          : `<span class="pill ${m.dual ? 'ok' : 'gray'}">${m.dual ? 'Sí' : 'No'}</span>`;
      }
      return `<tr>
        <td><div class="user-cell"><span class="avatar">${esc(initials(m.name))}</span><div><strong>${esc(m.name)}${self ? ' (tú)' : ''}</strong><small>${esc(m.email)}</small></div></div></td>
        <td>${roleCell}</td>
        <td>${dualCell}</td>
        <td class="muted">${m.last ? esc(fmtDateTime(m.last)) : 'Aún no ha ingresado'}</td>
        <td>${editable ? `<button class="icon-btn" data-del-user="${esc(m.email)}" aria-label="Eliminar usuario" title="Eliminar usuario">${icon('trash')}</button>` : ''}</td>
      </tr>`;
    }).join('') : '<tr class="empty-row"><td colspan="5">No se encontraron usuarios.</td></tr>';
  }
  $('#team-body').addEventListener('click', (e) => {
    const b = e.target.closest('[data-del-user]'); if (!b) return;
    const me = currentUser(), target = state.users.find((u) => u.email === b.dataset.delUser);
    if (!target) return;
    if (!canModify(me, target)) return toast('No tienes permiso para eliminar a este usuario.');
    if (!confirm(`¿Eliminar a ${target.name} (${target.email})? Ya no podrá iniciar sesión.`)) return;
    api('/users/' + target.id + '/', { method: 'DELETE' }).then(() => {
      state.users = state.users.filter((u) => u.email !== target.email);
      renderAdmin(); toast(`Usuario ${target.name} eliminado.`);
    }).catch((ex) => toast(ex.message));
  });
  $('#team-search').addEventListener('input', renderAdmin);
  $('#team-body').addEventListener('change', (e) => {
    const me = currentUser();
    const sel = e.target.closest('[data-role-for]'), chk = e.target.closest('[data-dual-for]');
    const target = state.users.find((u) => u.email === (sel ? sel.dataset.roleFor : chk && chk.dataset.dualFor));
    if (!target) return;
    if (!canModify(me, target)) { toast('No tienes permiso para cambiar a este usuario.'); return renderAdmin(); }
    if (sel && !assignableRoles(me).includes(sel.value)) { toast('No puedes asignar ese rol.'); return renderAdmin(); }
    const payload = sel ? { role: sel.value } : { dual: chk.checked };
    api('/users/' + target.id + '/', { method: 'PUT', body: JSON.stringify(payload) }).then((d) => {
      Object.assign(target, d.user);
      toast(sel ? `Ahora ${target.name} es ${target.role}.` : (target.dual ? `${target.name} ahora también puede entrar como cliente.` : `${target.name} entra solo como ${target.role}.`));
      renderAdmin();
    }).catch((ex) => { toast(ex.message); renderAdmin(); });
  });

  $('#open-create-user').addEventListener('click', () => {
    const me = currentUser();
    $('#user-form').reset(); $('#user-error').hidden = true;
    $('#u-role').innerHTML = assignableRoles(me).map((r) => `<option ${r === 'Asesor de ventas' ? 'selected' : ''}>${r}</option>`).join('');
    syncDualRow(); openModal('user-modal'); $('#u-name').focus();
  });
  function syncDualRow() { $('#u-client-fields').hidden = $('#u-role').value !== 'Cliente'; $('#u-dual-row').hidden = !hasDual($('#u-role').value); if ($('#u-dual-row').hidden) $('#u-dual').checked = false; }
  $('#u-role').addEventListener('change', syncDualRow);
  $('#user-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const me = currentUser();
    const name = $('#u-name').value.trim(), email = $('#u-email').value.trim().toLowerCase(), pass = $('#u-pass').value, role = $('#u-role').value;
    const err = $('#user-error'), fail = (m) => { err.textContent = m; err.hidden = false; };
    if (!name || !email || !pass) return fail('Completa el nombre, el correo y la contraseña.');
    if (!emailOk(email)) return fail('Escribe un correo electrónico válido.');
    if (!passOk(pass)) return fail('La contraseña debe tener mínimo 8 caracteres, una letra y un número.');
    if (!assignableRoles(me).includes(role)) return fail('No puedes asignar ese rol.');
    let udoc = $('#u-doc').value.trim(), uphone = $('#u-phone').value.trim();
    if (role === 'Cliente') {
      const vd = validateDoc(udoc); if (!vd.ok) return fail(vd.msg);
      const vp = validatePhone(uphone); if (!vp.ok) return fail(vp.msg);
      udoc = vd.value; uphone = vp.value;
    }
    api('/users/create/', { method: 'POST', body: JSON.stringify({ name, email, password: pass, role, doc: udoc, phone: uphone, dual: hasDual(role) && $('#u-dual').checked }) })
      .then((d) => { state.users.unshift(d.user); closeModals(); renderAdmin(); toast(`Usuario ${name} creado.`); })
      .catch((ex) => fail(ex.message));
  });

  /* ---------- Registrar venta ---------- */
  function fillClients(selectedId) {
    const sel = $('#s-client');
    sel.innerHTML = state.clients.map((c) => `<option value="${c.id}">${esc(c.name)}</option>`).join('');
    if (selectedId) sel.value = selectedId;
    showClientInfo();
  }
  function showClientInfo() {
    const c = state.clients.find((x) => x.id === +$('#s-client').value);
    $('#s-client-info').textContent = c ? (c.doc && c.doc !== '—' ? `Documento: ${c.doc}` : 'Sin documento') + (c.phone ? ` · Tel. ${c.phone}` : '') : '';
  }
  $('#s-client').addEventListener('change', showClientInfo);

  function renderSales() {
    const keep = $('#s-client').value;
    fillClients(keep ? +keep : null);
    const cl = isClient();
    $('#sale-data-card').hidden = cl;
    $('#sales-title').textContent = cl ? 'Tienda' : 'Registrar venta';
    $('#sales-sub').textContent = cl ? 'Elige tus productos y servicios, agrégalos al carrito y confirma tu compra.' : 'Elige el cliente, agrega los productos y confirma la venta.';
    $('#confirm-sale').lastChild.textContent = cl ? ' Confirmar compra' : ' Registrar venta';
    $('#s-advisor').value = state.session.name;
    $('#s-date-info').textContent = new Date().toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
    $('#s-folio').textContent = 'Venta nueva · el número se asigna al registrar';
    renderProductGrid(); renderCart();
  }

  function renderProductGrid() {
    const q = norm($('#s-search').value.trim());
    const list = state.products.filter((p) => p.active && (!q || norm(p.name).includes(q) || norm(p.sku).includes(q) || norm(p.cat).includes(q)));
    $('#product-grid').innerHTML = list.length ? list.map((p) => {
      const out = !isSvc(p) && p.stock <= 0;
      return `<button type="button" class="p-tile" data-add="${p.id}" ${out ? 'disabled' : ''}>
        <div class="t-top"><span class="t-thumb">${thumb(p)}</span>${icon(out ? 'ban' : 'plus')}</div>
        <strong>${esc(p.name)}</strong>
        <small class="t-cat">${esc(p.cat)}</small>
        <div class="t-bot"><b>${money(p.price)}</b>${out ? '<span class="red">Agotado</span>' : `<span>${isSvc(p) ? 'Servicio' : p.stock + ' disp.'}</span>`}</div>
      </button>`;
    }).join('') : '<p class="muted" style="grid-column:1/-1">No hay productos que coincidan.</p>';
  }

  function cartTotals() {
    let units = 0, subtotal = 0;
    Object.keys(state.cart).forEach((id) => { const p = state.products.find((x) => x.id === +id); if (p) { units += state.cart[id]; subtotal += state.cart[id] * p.price; } });
    const iva = Math.round(subtotal * IVA);
    return { units, subtotal, iva, total: subtotal + iva };
  }
  const prodById = (id) => state.products.find((x) => x.id === id);
  const cartIds = () => Object.keys(state.cart).map(Number).filter((id) => prodById(id));
  function cleanCart() {
    const ids = cartIds();
    state.cart = ids.reduce((o, id) => { o[id] = state.cart[id]; return o; }, {});
    return ids;
  }
  const cartItemHtml = (id) => {
    const p = prodById(id), q = state.cart[id];
    return `<div class="cart-item">
        <div class="cart-info"><strong>${esc(p.name)}</strong><small>${money(p.price)} por unidad</small></div>
        <div class="qty"><button type="button" data-dec="${id}" aria-label="Menos">${icon('minus')}</button><input type="number" class="qty-input" min="1" data-qty="${id}" value="${q}" aria-label="Cantidad"><button type="button" data-inc="${id}" aria-label="Más">${icon('plus')}</button></div>
        <div class="cart-price">${money(q * p.price)}</div>
        <button type="button" class="icon-btn" data-rm="${id}" aria-label="Quitar">${icon('trash')}</button>
      </div>`;
  };
  function renderCart() {
    const ids = cleanCart();
    const t = cartTotals();
    $('#cart-list').innerHTML = ids.map(cartItemHtml).join('') || '<p class="cart-empty">Aún no agregas productos. Elígelos de la lista de arriba.</p>';
    $('#cart-sub').textContent = `${ids.length} producto${ids.length === 1 ? '' : 's'} · ${t.units} unidad${t.units === 1 ? '' : 'es'}`;
    $('#s-sub').textContent = money(t.subtotal); $('#s-iva').textContent = money(t.iva); $('#s-total').textContent = money(t.total);
    $('#sale-error').hidden = true;
    syncCartViews();
  }
  /* Mantiene al día el contador, el carrito lateral, los pasos de compra y la tienda */
  function syncCartViews() {
    const n = cartTotals().units, badge = $('#cart-count');
    badge.textContent = n; badge.hidden = !n;
    if (!$('#cart-drawer').hidden) renderDrawer();
    if (state.session && state.page === 'checkout' && CO.step < 5) { if (CO.step === 1) renderCoCart(); renderCoSummary(); }
    if (state.session && state.page === 'shop') renderShopGrid();
  }
  function bindCartControls(el) {
    el.addEventListener('click', (e) => {
      const inc = e.target.closest('[data-inc]'), dec = e.target.closest('[data-dec]'), rm = e.target.closest('[data-rm]');
      if (inc) {
        const id = +inc.dataset.inc, p = prodById(id);
        if (!isSvc(p) && state.cart[id] >= p.stock) return toast(`Solo hay ${p.stock} unidades disponibles`);
        state.cart[id]++;
      } else if (dec) { const id = +dec.dataset.dec; state.cart[id]--; if (state.cart[id] <= 0) delete state.cart[id]; }
      else if (rm) delete state.cart[+rm.dataset.rm]; else return;
      renderCart();
    });
    el.addEventListener('change', (e) => {
      const inp = e.target.closest('[data-qty]'); if (!inp) return;
      const id = +inp.dataset.qty, p = prodById(id);
      let q = Math.floor(Number(inp.value)) || 1;
      if (q < 1) q = 1;
      if (!isSvc(p) && q > p.stock) { q = p.stock; toast(`Solo hay ${p.stock} unidades disponibles`); }
      state.cart[id] = q; renderCart();
    });
  }
  ['#cart-list', '#drawer-list', '#co-cart'].forEach((s) => bindCartControls($(s)));
  $('#s-search').addEventListener('input', renderProductGrid);
  $('#product-grid').addEventListener('click', (e) => {
    const b = e.target.closest('[data-add]'); if (!b) return;
    const p = state.products.find((x) => x.id === +b.dataset.add), cur = state.cart[p.id] || 0;
    if (!isSvc(p) && cur >= p.stock) return toast(`Solo hay ${p.stock} unidades de ${p.name}`);
    state.cart[p.id] = cur + 1; renderCart();
  });
  $('#cancel-sale').addEventListener('click', () => { state.cart = {}; renderCart(); toast('Venta cancelada'); });
  $('#confirm-sale').addEventListener('click', async () => {
    if (isSuper()) return toast('El superadministrador solo puede consultar.');
    const ids = Object.keys(state.cart).map(Number);
    if (!ids.length) { const er = $('#sale-error'); er.textContent = 'Agrega al menos un producto para registrar la venta.'; er.hidden = false; return; }
    const btn = $('#confirm-sale'); btn.disabled = true;
    try {
      const d = await api('/sales/create/', { method: 'POST', body: JSON.stringify({
        items: ids.map((id) => ({ id, quantity: state.cart[id] })),
        client_id: isClient() ? null : +$('#s-client').value,
        payment: $('#s-pay').value
      }) });
      state.cart = {};
      await loadData();
      toast(isClient() ? `Compra ${d.sale.folio} realizada. Un asesor atenderá tu pedido.` : `Venta ${d.sale.folio} registrada. Las existencias se actualizaron.`);
      renderSales();
    } catch (ex) {
      const er = $('#sale-error'); er.textContent = ex.message; er.hidden = false;
      try { await loadData(); renderProductGrid(); renderCart(); } catch (e2) { /* se reintenta luego */ }
    } finally { btn.disabled = false; }
  });

  $('#open-new-client').addEventListener('click', () => { $('#client-form').reset(); $('#client-error').hidden = true; openModal('client-modal'); $('#cl-name').focus(); });
  $('#client-form').addEventListener('submit', (e) => {
    e.preventDefault();
    if (isSuper()) return toast('El superadministrador solo puede consultar.');
    const name = $('#cl-name').value.trim();
    const err = $('#client-error'), fail = (m) => { err.textContent = m; err.hidden = false; };
    if (!name) return fail('Escribe el nombre del cliente.');
    const vd = validateDoc($('#cl-doc').value); if (!vd.ok) return fail(vd.msg);
    const vp = validatePhone($('#cl-phone').value); if (!vp.ok) return fail(vp.msg);
    api('/clients/create/', { method: 'POST', body: JSON.stringify({ name, doc: vd.value, phone: vp.value }) })
      .then((d) => { state.clients.push(d.client); closeModals(); fillClients(d.client.id); toast(`Cliente ${name} guardado.`); })
      .catch((ex) => fail(ex.message));
  });

  /* ---------- TIENDA DEL CLIENTE ---------- */
  state.shopKind = 'all';
  const myClient = () => (state.me && state.me.client) || null;

  function addToCart(id, qty) {
    const p = prodById(id); if (!p) return false;
    const cur = state.cart[id] || 0;
    if (!isSvc(p) && cur + qty > p.stock) { toast(p.stock <= 0 ? `${p.name} está agotado.` : `Solo hay ${p.stock} unidades de ${p.name}.`); return false; }
    state.cart[id] = cur + qty; renderCart();
    return true;
  }
  const stockProblem = () => {
    for (const id of cartIds()) {
      const p = prodById(id);
      if (!isSvc(p) && state.cart[id] > p.stock) return p.stock > 0 ? `Solo quedan ${p.stock} unidades de "${p.name}". Ajusta la cantidad en tu carrito.` : `"${p.name}" se agotó. Quítalo del carrito para continuar.`;
    }
    return '';
  };

  function renderShop() {
    $('#shop-hello').textContent = `Hola, ${state.session.name.split(' ')[0]}`;
    const sel = $('#shop-cat'), cur = sel.value, cats = sortedCats();
    sel.innerHTML = '<option value="">Todas las categorías</option>' + cats.map((c) => `<option>${esc(c)}</option>`).join('');
    sel.value = cats.includes(cur) ? cur : '';
    $$('#shop-kinds button').forEach((b) => b.classList.toggle('active', b.dataset.kind === state.shopKind));
    renderShopGrid();
  }
  function renderShopGrid() {
    const q = norm($('#shop-search').value.trim()), cat = $('#shop-cat').value;
    const list = state.products.filter((p) => p.active
      && (state.shopKind === 'all' || (state.shopKind === 'service') === isSvc(p))
      && (!cat || p.cat === cat)
      && (!q || norm(p.name).includes(q) || norm(p.desc || '').includes(q) || norm(p.cat).includes(q) || norm(p.sku).includes(q)));
    $('#shop-count').textContent = `${list.length} resultado${list.length === 1 ? '' : 's'}`;
    $('#shop-grid').innerHTML = list.length ? list.map((p) => {
      const st = status(p), out = !isSvc(p) && p.stock <= 0, inCart = state.cart[p.id] || 0;
      const label = isSvc(p) ? 'Servicio' : out ? 'Agotado' : st.key === 'low' ? `Últimas ${p.stock}` : 'Disponible';
      return `<article class="shop-card" data-view="${p.id}">
        <div class="shop-img">${thumb(p)}${inCart ? `<span class="in-cart">${inCart} en tu carrito</span>` : ''}</div>
        <div class="shop-body">
          <small class="t-cat">${esc(p.cat)}</small>
          <h4>${esc(p.name)}</h4>
          <p class="shop-desc">${esc(p.desc || '')}</p>
          <div class="shop-meta"><div class="shop-price"><b>${money(p.price)}</b><small>+ IVA</small></div><span class="pill ${st.cls}">${label}</span></div>
        </div>
        <div class="shop-actions">
          <button type="button" class="btn btn-outline btn-sm" data-view="${p.id}">Ver detalles</button>
          <button type="button" class="btn btn-primary btn-sm" data-add="${p.id}" ${out ? 'disabled' : ''}>${icon('cart')} ${out ? 'Agotado' : 'Agregar'}</button>
        </div>
      </article>`;
    }).join('') : '<p class="muted" style="grid-column:1/-1">No hay productos que coincidan con tu búsqueda.</p>';
  }
  $('#shop-search').addEventListener('input', renderShopGrid);
  $('#shop-cat').addEventListener('change', renderShopGrid);
  $('#shop-kinds').addEventListener('click', (e) => {
    const b = e.target.closest('[data-kind]'); if (!b) return;
    state.shopKind = b.dataset.kind; renderShop();
  });
  $('#shop-grid').addEventListener('click', (e) => {
    const add = e.target.closest('[data-add]');
    if (add) { if (addToCart(+add.dataset.add, 1)) toast('Agregado al carrito'); return; }
    const v = e.target.closest('[data-view]');
    if (v) openProductDetail(+v.dataset.view);
  });

  /* Compra desde la ventana de detalle del producto */
  $('#detail-body').addEventListener('click', (e) => {
    const b = e.target.closest('[data-buy]'); if (!b) return;
    if (addToCart(+b.dataset.buy, 1)) { closeModals(); toast('Agregado al carrito'); }
  });

  /* ---------- Carrito lateral ---------- */
  function renderDrawer() {
    const ids = cleanCart(), t = cartTotals();
    $('#drawer-list').innerHTML = ids.length ? ids.map(cartItemHtml).join('') : '<p class="cart-empty">Tu carrito está vacío.<br>Agrega productos desde la tienda.</p>';
    $('#drawer-sub').textContent = `${ids.length} producto${ids.length === 1 ? '' : 's'} · ${t.units} unidad${t.units === 1 ? '' : 'es'}`;
    $('#d-sub').textContent = money(t.subtotal); $('#d-iva').textContent = money(t.iva); $('#d-total').textContent = money(t.total);
    $('#drawer-checkout').disabled = !ids.length;
  }
  $('#cart-btn').addEventListener('click', () => { renderDrawer(); openModal('cart-drawer'); });
  $('#drawer-checkout').addEventListener('click', () => {
    if (!cartIds().length) return toast('Tu carrito está vacío.');
    closeModals(); CO.step = 1; go('checkout');
  });

  /* ---------- Pasos para comprar ---------- */
  const CO = { step: 1, filled: false, data: {} };
  const hasGoods = () => cartIds().some((id) => !isSvc(prodById(id)));
  const hasSvcs = () => cartIds().some((id) => isSvc(prodById(id)));
  const coMethod = () => { if (!hasGoods()) return 'service'; const r = $('input[name="co-method"]:checked'); return r ? r.value : 'pickup'; };
  const needAddress = () => coMethod() === 'ship' || hasSvcs();
  const methodText = (m) => ({ pickup: 'Recoger en la bodega', ship: 'Envío a domicilio', service: 'Servicio en sitio' }[m] || m);

  function syncCoDelivery() {
    $('#co-method-wrap').hidden = !hasGoods();
    $('#co-address-fields').hidden = !needAddress();
    $('#co-addr-label').textContent = hasSvcs() ? 'Dirección de entrega o del servicio *' : 'Dirección de entrega *';
  }
  $$('input[name="co-method"]').forEach((r) => r.addEventListener('change', syncCoDelivery));

  function renderCoCart() {
    const ids = cleanCart();
    $('#co-cart').innerHTML = ids.length ? ids.map(cartItemHtml).join('') : '<p class="cart-empty">Tu carrito está vacío. <a href="#" data-page="shop">Ir a la tienda</a></p>';
  }
  function renderCoSummary() {
    const ids = cleanCart(), t = cartTotals();
    $('#co-sum-items').innerHTML = ids.map((id) => { const p = prodById(id); return `<div class="co-line"><span>${state.cart[id]} × ${esc(p.name)}</span><b>${money(state.cart[id] * p.price)}</b></div>`; }).join('');
    $('#co-sub').textContent = money(t.subtotal); $('#co-iva').textContent = money(t.iva); $('#co-total').textContent = money(t.total);
  }
  function renderCoReview() {
    const d = CO.data, ids = cleanCart();
    const where = needAddress() ? `${esc(d.address)}, ${esc(d.city)}` : 'Recoger en la bodega de Magnus SIG S.A.S';
    $('#co-review').innerHTML = `
      <div class="rev-block"><div class="rev-head"><h4>Tus datos</h4><button type="button" class="link-btn" data-goto="2">Editar</button></div>
        <p><b>${esc(d.name)}</b></p><p>${esc(d.docType)}: ${esc(d.doc)}</p><p>Teléfono: ${esc(d.phone)}</p><p>${esc(state.session.email)}</p></div>
      <div class="rev-block"><div class="rev-head"><h4>Entrega y pago</h4><button type="button" class="link-btn" data-goto="3">Editar</button></div>
        <p><b>${esc(methodText(d.method))}</b></p><p>${where}</p><p>Pago: ${esc(d.pay)}${d.card ? ` · ${esc(d.card.brand)} terminada en ${esc(d.card.last4)}` : ''}</p>${d.pay === 'Nequi / Daviplata' || d.pay === 'Transferencia bancaria' ? `<p>Consigna al número <b>${esc(fmtPayNumber())}</b></p>` : ''}${d.notes ? `<p>Notas: ${esc(d.notes)}</p>` : ''}</div>
      <div class="rev-block"><div class="rev-head"><h4>Productos</h4><button type="button" class="link-btn" data-goto="1">Editar</button></div>
        ${ids.map((id) => { const p = prodById(id); return `<p class="rev-line"><span>${state.cart[id]} × ${esc(p.name)}</span><b>${money(state.cart[id] * p.price)}</b></p>`; }).join('')}</div>`;
  }
  $('#co-review').addEventListener('click', (e) => { const b = e.target.closest('[data-goto]'); if (b) { CO.step = +b.dataset.goto; renderCheckoutStep(); } });

  function renderCheckout() {
    if (CO.step === 5) CO.step = 1;
    if (!cartIds().length) { go('shop'); toast('Tu carrito está vacío. Elige algo de la tienda primero.'); return; }
    if (!CO.filled) {
      const c = myClient();
      $('#co-name').value = (c && c.name) || state.session.name;
      $('#co-email').value = state.session.email;
      $('#co-doc').value = c && c.doc && c.doc !== '—' ? c.doc : '';
      $('#co-phone').value = (c && c.phone) || '';
      CO.filled = true;
    }
    syncCoDelivery();
    renderCheckoutStep();
  }
  const NEXT_LABEL = { 1: 'Continuar con mis datos', 2: 'Continuar a entrega y pago', 3: 'Revisar mi pedido', 4: 'Confirmar compra' };
  function renderCheckoutStep() {
    const s = CO.step;
    $$('.co-step').forEach((el) => { el.hidden = +el.dataset.step !== s; });
    $$('#co-stepper li').forEach((li) => { const n = +li.dataset.s; li.classList.toggle('done', n < s || s === 5); li.classList.toggle('active', n === s); });
    $('#co-back').hidden = s === 1 || s === 5;
    $('#co-actions').hidden = s === 5;
    $('#co-next').textContent = NEXT_LABEL[s] || '';
    $('#co-summary').hidden = s === 5;
    $('#checkout-grid').classList.toggle('done', s === 5);
    $('#co-error').hidden = true;
    if (s === 1) renderCoCart();
    if (s === 3) { syncCoDelivery(); syncPayPanels(); }
    if (s === 4) renderCoReview();
    renderCoSummary();
    window.scrollTo(0, 0);
  }

  function readStep2() {
    const name = $('#co-name').value.trim().replace(/\s+/g, ' ');
    if (name.length < 3 || !new RegExp('[' + LETTERS + ']').test(name)) return { error: 'Escribe tu nombre completo o la razón social de tu empresa.' };
    const doc = validateDoc($('#co-doc').value); if (!doc.ok) return { error: doc.msg };
    const ph = validatePhone($('#co-phone').value); if (!ph.ok) return { error: ph.msg };
    $('#co-name').value = name; $('#co-doc').value = doc.value; $('#co-phone').value = ph.value;
    return { name, doc: doc.value, docType: doc.type, phone: ph.value };
  }
  /* ---------- Datos de pago ---------- */
  const PAY_NUMBER = '3022959136'; // número al que se consigna (Nequi / Daviplata / transferencia)
  const fmtPayNumber = () => PAY_NUMBER.replace(/(\d{3})(\d{3})(\d{4})/, '$1 $2 $3');
  const selectedPay = () => ($('input[name="co-pay"]:checked') || {}).value;
  function syncPayPanels() {
    const pay = selectedPay();
    const toNumber = pay === 'Nequi / Daviplata' || pay === 'Transferencia bancaria';
    $('#pay-number').hidden = !toNumber;
    $('#pay-card').hidden = pay !== 'Tarjeta débito / crédito';
    $('#pay-number-title').textContent = pay === 'Nequi / Daviplata' ? 'Consigna por Nequi / Daviplata al número' : 'Haz la transferencia al número';
    $('#pay-number-val').textContent = fmtPayNumber();
    $('#pay-number-total').textContent = money(cartTotals().total);
  }
  $$('input[name="co-pay"]').forEach((r) => r.addEventListener('change', syncPayPanels));
  $('#pay-copy').addEventListener('click', () => {
    const done = () => toast('Número copiado: ' + fmtPayNumber());
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(PAY_NUMBER).then(done, done); else done();
  });
  $('#cc-number').addEventListener('input', (e) => { e.target.value = e.target.value.replace(/\D/g, '').slice(0, 19).replace(/(\d{4})(?=\d)/g, '$1 '); });
  $('#cc-exp').addEventListener('input', (e) => { let v = e.target.value.replace(/\D/g, '').slice(0, 4); if (v.length > 2) v = v.slice(0, 2) + '/' + v.slice(2); e.target.value = v; });
  $('#cc-cvv').addEventListener('input', (e) => { e.target.value = e.target.value.replace(/\D/g, '').slice(0, 4); });
  function clearCardForm() { ['#cc-number', '#cc-name', '#cc-exp', '#cc-cvv'].forEach((i) => { $(i).value = ''; }); }
  const luhn = (n) => { let sum = 0, alt = false; for (let i = n.length - 1; i >= 0; i--) { let d = +n[i]; if (alt) { d *= 2; if (d > 9) d -= 9; } sum += d; alt = !alt; } return sum % 10 === 0; };
  const cardBrand = (n) => /^4/.test(n) ? 'Visa' : /^(5[1-5]|2[2-7])/.test(n) ? 'Mastercard' : /^3[47]/.test(n) ? 'American Express' : /^(36|38|30[0-5])/.test(n) ? 'Diners' : 'Tarjeta';
  function readCard() {
    const num = $('#cc-number').value.replace(/\D/g, ''), holder = $('#cc-name').value.trim().replace(/\s+/g, ' ');
    const exp = $('#cc-exp').value.trim(), cvv = $('#cc-cvv').value.trim();
    if (num.length < 13 || num.length > 19 || !luhn(num)) return { error: 'El número de la tarjeta no es válido. Revísalo.' };
    if (holder.length < 3 || !new RegExp('^[' + LETTERS + "][" + LETTERS + " .'-]+$").test(holder)) return { error: 'Escribe el nombre del titular como aparece en la tarjeta.' };
    const m = /^(0[1-9]|1[0-2])\/(\d{2})$/.exec(exp);
    if (!m) return { error: 'La fecha de vencimiento debe tener el formato MM/AA.' };
    const now = new Date();
    if (2000 + +m[2] < now.getFullYear() || (2000 + +m[2] === now.getFullYear() && +m[1] < now.getMonth() + 1)) return { error: 'La tarjeta está vencida.' };
    const brand = cardBrand(num);
    if (!new RegExp(brand === 'American Express' ? '^\\d{4}$' : '^\\d{3}$').test(cvv)) return { error: brand === 'American Express' ? 'El CVV de American Express tiene 4 dígitos.' : 'El CVV debe tener 3 dígitos.' };
    return { card: { brand, last4: num.slice(-4), holder } }; // nunca se guarda el número completo ni el CVV
  }

  function readStep3() {
    const pay = ($('input[name="co-pay"]:checked') || {}).value;
    if (!pay) return { error: 'Elige una forma de pago.' };
    let card = null;
    if (pay === 'Tarjeta débito / crédito') { const r = readCard(); if (r.error) return r; card = r.card; }
    let city = '', address = '';
    if (needAddress()) {
      city = $('#co-city').value.trim().replace(/\s+/g, ' ');
      address = $('#co-address').value.trim().replace(/\s+/g, ' ');
      if (!new RegExp('^[' + LETTERS + '][' + LETTERS + " .'-]{2,39}$").test(city)) return { error: 'Escribe el nombre de tu ciudad o municipio (solo letras).' };
      if (address.length < 6 || !/\d/.test(address) || !new RegExp('[' + LETTERS + ']').test(address)) return { error: 'Escribe una dirección completa, con calle o carrera y número. Ej: Cra 7 # 12-34, barrio Centro.' };
      $('#co-city').value = city; $('#co-address').value = address;
    }
    return { method: coMethod(), pay, card, city, address, notes: $('#co-notes').value.trim().slice(0, 300) };
  }

  async function placeOrder() {
    const d = CO.data;
    const r = await api('/sales/create/', { method: 'POST', body: JSON.stringify({
      items: cartIds().map((id) => ({ id, quantity: state.cart[id] })),
      payment: d.pay,
      delivery: { method: d.method, city: d.city, address: d.address },
      notes: d.notes,
      customer: { name: d.name, doc: d.doc, phone: d.phone },
      as_client: hasDual(state.session.role) && state.session.mode === 'user'
    }) });
    const sale = r.sale;
    if (d.card) sale.card = { brand: d.card.brand, last4: d.card.last4, holder: d.card.holder }; // solo se muestra en pantalla; el servidor no guarda tarjetas
    if (state.me) { state.me.client = { id: sale.client.id, name: sale.client.name, doc: sale.client.doc, phone: sale.client.phone }; state.me.clientId = sale.client.id; }
    state.cart = {}; CO.filled = false; CO.data = {};
    try { await loadData(); } catch (e) { /* se actualiza en el próximo ciclo */ }
    return sale;
  }
  function renderCoDone(v) {
    const dl = v.delivery || {};
    const where = dl.address ? `${esc(dl.address)}, ${esc(dl.city)}` : methodText(dl.method);
    $('#co-done').innerHTML = `
      <div class="done-icon">${icon('check')}</div>
      <h2>¡Pedido recibido!</h2>
      <p class="sub">Tu compra <b>${esc(v.folio)}</b> quedó registrada por <b>${money(v.total)}</b>.</p>
      <ol class="next-steps">
        ${v.pay === 'Nequi / Daviplata' || v.pay === 'Transferencia bancaria' ? `<li><b>Consigna ${money(v.total)} al número ${esc(fmtPayNumber())}</b><small>Guarda el comprobante: el asesor te lo pedirá para confirmar tu pedido.</small></li>` : ''}
        <li><b>Un asesor te contactará</b><small>Te llamará o escribirá al ${esc(v.client.phone)} para confirmar tu pedido.</small></li>
        <li><b>Coordinan el pago y la entrega</b><small>Pago: ${esc(v.pay)}${v.card ? ' (' + esc(v.card.brand) + ' terminada en ' + esc(v.card.last4) + ')' : ''} · ${where}</small></li>
        <li><b>Sigue el estado de tu pedido</b><small>Lo verás actualizado en «Mis compras».</small></li>
      </ol>
      <div class="co-done-actions"><button type="button" class="btn btn-primary" data-page="history">Ver mis compras</button><button type="button" class="btn btn-outline" data-page="shop">Seguir comprando</button></div>`;
  }

  $('#co-back').addEventListener('click', () => { if (CO.step > 1) { CO.step--; renderCheckoutStep(); } });
  $('#co-next').addEventListener('click', async () => {
    const fail = (m) => { const er = $('#co-error'); er.textContent = m; er.hidden = false; };
    if (!isClient()) return;
    if (CO.step === 1) {
      if (!cartIds().length) return fail('Tu carrito está vacío.');
      const bad = stockProblem(); if (bad) return fail(bad);
      CO.step = 2;
    } else if (CO.step === 2) {
      const r = readStep2(); if (r.error) return fail(r.error);
      Object.assign(CO.data, r); CO.step = 3;
    } else if (CO.step === 3) {
      const r = readStep3(); if (r.error) return fail(r.error);
      Object.assign(CO.data, r); CO.step = 4;
    } else if (CO.step === 4) {
      if (!cartIds().length) return fail('Tu carrito está vacío.');
      const bad = stockProblem(); if (bad) return fail(bad);
      if (!$('#co-accept').checked) return fail('Marca la casilla de confirmación para finalizar tu compra.');
      const btn = $('#co-next'); btn.disabled = true;
      try {
        const sale = await placeOrder(); clearCardForm();
        $('#co-accept').checked = false;
        CO.step = 5; renderCoDone(sale); renderCheckoutStep(); syncCartViews();
        toast(`Compra ${sale.folio} realizada.`);
      } catch (ex) {
        fail(ex.message);
        try { await loadData(); syncCartViews(); } catch (e2) { /* se reintenta luego */ }
      } finally { btn.disabled = false; }
      return;
    }
    renderCheckoutStep();
  });

  /* ---------- Historial de ventas ---------- */
  const unitsOf = (v) => v.items.reduce((a, i) => a + i.qty, 0);

  /* Reporte de ventas en Excel: el servidor genera el .xlsx (y decide qué ventas puede incluir cada rol). */
  $('#export-sales').addEventListener('click', async () => {
    const btn = $('#export-sales'); btn.disabled = true;
    try {
      const userMode = hasDual(state.session.role) && state.session.mode === 'user';
      const res = await fetch(API_URL + '/sales/export/' + (userMode ? '?scope=mine' : ''), { credentials: 'include' });
      if (!res.ok) { const d = await res.json().catch(() => ({})); throw new Error(d.error || 'No fue posible generar el reporte.'); }
      const blob = await res.blob(), url = URL.createObjectURL(blob), now = new Date();
      const stamp = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
      const a = document.createElement('a');
      a.href = url; a.download = `reporte_ventas_${stamp}.xlsx`;
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 2000);
      toast('Reporte de ventas descargado.');
    } catch (ex) { toast(ex instanceof TypeError ? 'No se pudo conectar con el servidor.' : ex.message); }
    finally { btn.disabled = false; }
  });

  /* Tabla de compras de un cliente (Mis compras y Mi perfil). */
  function clientTableHtml(list) {
    return `<thead><tr><th>Compra</th><th>Fecha</th><th>Productos</th><th>Pago</th><th>Estado</th><th>Total</th><th></th></tr></thead><tbody>` +
        (list.length ? list.map((v) => `<tr class="click-row" data-sale="${esc(v.folio)}">
      <td><a>${esc(v.folio)}</a></td><td>${esc(fmtDate(v.date))}<small class="cell-sub">${esc(fmtTime(v.date))}</small></td>
      <td>${unitsOf(v)} uds.</td><td class="muted">${esc(v.pay)}</td>
      <td><span class="pill ${statusCls(v)}">${statusOf(v)}</span></td><td><b>${money(v.total)}</b></td>
      <td><span class="link-strong">Ver detalle</span></td></tr>`).join('') : '<tr class="empty-row"><td colspan="7">Aún no has hecho compras. ¡Visita la tienda!</td></tr>') + '</tbody>';
  }

  /* ---------- Perfil del cliente: solo sus datos y sus compras ---------- */
  async function renderProfile() {
    try { const d = await api('/auth/session/'); if (d.user) state.me = d.user; } catch (e) { /* se muestran los datos que ya había */ }
    const u = currentUser() || {}, c = u.client || {};
    const row = (label, val) => `<div class="person"><small>${label}</small><strong>${esc(val || 'No registrado')}</strong></div>`;
    $('#profile-data').innerHTML = row('Nombre o razón social', c.name || u.name) + row('Correo electrónico', u.email) +
      row('Cédula o NIT', c.doc && c.doc !== '—' ? c.doc : '') + row('Teléfono', c.phone);
    $('#profile-orders').innerHTML = clientTableHtml(visibleSales());
  }
  $('#profile-orders').addEventListener('click', (e) => { const r = e.target.closest('[data-sale]'); if (r) openSaleDetail(r.dataset.sale); });

  function renderHistory() {
    const all = seesAllSales();
    $('#hist-sub').textContent = all ? 'Todas las ventas de Magnus SIG S.A.S, con los datos del cliente y del asesor. Los totales no incluyen ventas anuladas.' : 'Aquí aparecen las ventas que has registrado, con los datos de cada cliente.';
    $('#tab-advisor').hidden = !all;
    $('#export-sales').hidden = !['Administrador', 'Superadministrador', 'Asesor de ventas'].includes(effRole());
    $('#hist-tabs [data-tab=client]').hidden = !all;
    if (!all) state.histTab = 'all';
    $('#hist-tabs').hidden = isClient();
    if (isClient()) $('#hist-sub').textContent = 'Aquí aparecen tus compras, con el detalle de cada una y el asesor que te atendió.';
    $$('#hist-tabs .tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === state.histTab));

    const base = visibleSales(), valid = base.filter(counts);
    $('#hist-kpis').hidden = isClient();   // el cliente no ve estadísticas, solo sus compras
    $('#h-count').textContent = valid.length;
    $('#h-total').textContent = money(valid.reduce((a, v) => a + v.total, 0));
    $('#h-avg').textContent = money(valid.length ? valid.reduce((a, v) => a + v.total, 0) / valid.length : 0);
    $('#h-units').textContent = valid.reduce((a, v) => a + unitsOf(v), 0);

    const q = norm($('#hist-search').value.trim());
    const list = base.filter((v) => !q || norm(v.folio).includes(q) || norm(v.client.name).includes(q) || norm(v.advisor.name).includes(q) || norm(v.client.doc).includes(q));
    const table = $('#hist-table');

    if (isClient()) {
      table.innerHTML = clientTableHtml(list);
    } else if (state.histTab === 'all') {
      table.innerHTML = `<thead><tr><th>Venta</th><th>Fecha</th><th>Cliente</th><th>Asesor de ventas</th><th>Productos</th><th>Pago</th><th>Estado</th><th>Total</th><th></th></tr></thead><tbody>` +
        (list.length ? list.map((v) => `<tr class="click-row" data-sale="${esc(v.folio)}">
          <td><a>${esc(v.folio)}</a></td>
          <td>${esc(fmtDate(v.date))}<small class="cell-sub">${esc(fmtTime(v.date))}</small></td>
          <td><strong>${esc(v.client.name)}</strong><small class="cell-sub">${v.client.doc && v.client.doc !== '—' ? 'Doc. ' + esc(v.client.doc) : ''}</small></td>
          <td>${esc(v.advisor.name)}<small class="cell-sub">${esc(v.advisor.role)}</small></td>
          <td>${unitsOf(v)} uds.</td>
          <td class="muted">${esc(v.pay)}</td>
          <td><span class="pill ${statusCls(v)}">${statusOf(v)}</span></td>
          <td><b>${money(v.total)}</b></td>
          <td><span class="link-strong">Ver detalle</span></td></tr>`).join('') : '<tr class="empty-row"><td colspan="9">No se encontraron ventas.</td></tr>') + '</tbody>';
    } else {
      const byClient = state.histTab === 'client';
      const groups = {};
      list.filter(counts).forEach((v) => {
        const key = byClient ? v.client.name : (v.advisor.email || v.advisor.name);
        const g = groups[key] || (groups[key] = { name: byClient ? v.client.name : v.advisor.name, sub: byClient ? (v.client.doc && v.client.doc !== '—' ? 'Doc. ' + v.client.doc : '') : v.advisor.role, count: 0, units: 0, total: 0, last: v.date });
        g.count++; g.units += unitsOf(v); g.total += v.total; if (v.date > g.last) g.last = v.date;
      });
      const rows = Object.values(groups).sort((a, b) => b.total - a.total);
      table.innerHTML = `<thead><tr><th>${byClient ? 'Cliente' : 'Asesor de ventas'}</th><th>Ventas</th><th>Unidades</th><th>${byClient ? 'Total comprado' : 'Total vendido'}</th><th>Última venta</th><th></th></tr></thead><tbody>` +
        (rows.length ? rows.map((g) => `<tr class="click-row" data-filter="${esc(g.name)}">
          <td><strong>${esc(g.name)}</strong><small class="cell-sub">${esc(g.sub)}</small></td>
          <td>${g.count}</td><td>${g.units}</td><td><b>${money(g.total)}</b></td><td class="muted">${esc(fmtDate(g.last))}</td>
          <td><span class="link-strong">Ver ventas</span></td></tr>`).join('') : '<tr class="empty-row"><td colspan="6">No hay datos para mostrar.</td></tr>') + '</tbody>';
    }
  }
  $('#hist-tabs').addEventListener('click', (e) => { const t = e.target.closest('.tab'); if (!t) return; state.histTab = t.dataset.tab; renderHistory(); });
  $('#hist-search').addEventListener('input', renderHistory);
  $('#hist-table').addEventListener('click', (e) => {
    const s = e.target.closest('[data-sale]'), f = e.target.closest('[data-filter]');
    if (s) openSaleDetail(s.dataset.sale);
    else if (f) { state.histTab = 'all'; $('#hist-search').value = f.dataset.filter; renderHistory(); }
  });

  const deliveryText = (v) => {
    const d = v.delivery; if (!d) return 'Por coordinar con el asesor';
    const m = { pickup: 'Recoger en la bodega', ship: 'Envío a domicilio', service: 'Servicio en sitio' }[d.method] || '';
    return d.address ? `${m} · ${d.address}, ${d.city}` : m;
  };
  function trackHtml(v) {
    const s = statusOf(v);
    const step = (cls, t, sm) => `<li class="${cls}"><span></span><b>${t}</b><small>${sm}</small></li>`;
    return `<h4 class="detail-title">Estado de tu pedido</h4><ol class="track">` +
      step('done', 'Pedido recibido', esc(fmtDateTime(v.date))) +
      (s === 'Anulada' ? step('cancelled', 'Pedido anulado', 'Las unidades volvieron al inventario.')
        : step(s === 'Entregado' ? 'done' : 'active', 'En atención', s === 'Entregado' ? 'Un asesor atendió tu pedido.' : 'Un asesor te contactará para coordinar pago y entrega.') +
          step(s === 'Entregado' ? 'done' : '', 'Entregado', s === 'Entregado' ? 'Tu pedido fue entregado.' : 'Pendiente')) + '</ol>';
  }
  function openSaleDetail(folio) {
    const v = state.sales.find((x) => x.folio === folio); if (!v) return;
    $('#detail-body').innerHTML = `
      <div class="icon-tile"><i>${icon('receipt')}</i></div>
      <h2>Venta ${esc(v.folio)}</h2>
      <p class="sub">${esc(fmtDateTime(v.date))} · Pago: ${esc(v.pay)} · <span class="pill ${statusCls(v)}">${statusOf(v)}</span></p>
      <div class="people">
        <div class="person"><small>Cliente</small><strong>${esc(v.client.name)}</strong>
          <span>Documento: ${esc(v.client.doc || '—')}</span><span>Teléfono: ${esc(v.client.phone || 'No registrado')}</span></div>
        ${isClient() ? `<div class="person"><small>Entrega</small><strong>${esc(deliveryText(v))}</strong><span>${v.attendedBy ? 'Atendido por ' + esc(v.attendedBy) : 'Un asesor atenderá tu pedido'}</span></div>`
          : `<div class="person"><small>Asesor de ventas</small><strong>${esc(v.advisor.name)}</strong>
          <span>${esc(v.advisor.role)}</span>${v.advisor.email ? `<span>${esc(v.advisor.email)}</span>` : ''}</div>`}
      </div>
      ${v.delivery && !isClient() ? `<p class="muted small" style="margin-top:10px">Entrega: ${esc(deliveryText(v))}</p>` : ''}
      ${v.card ? `<p class="muted small" style="margin-top:6px">Pagó con ${esc(v.card.brand)} terminada en ${esc(v.card.last4)} (titular: ${esc(v.card.holder)})</p>` : ''}
      ${v.notes ? `<p class="muted small" style="margin-top:6px">Notas: ${esc(v.notes)}</p>` : ''}
      ${isClient() ? trackHtml(v) : ''}
      <h4 class="detail-title">Productos vendidos</h4>
      <div class="table-wrap"><table class="table simple">
        <thead><tr><th>Producto</th><th>Cant.</th><th>Precio</th><th>Subtotal</th></tr></thead>
        <tbody>${v.items.map((i) => `<tr><td><strong>${esc(i.name)}</strong><small class="cell-sub">Código ${esc(i.sku)}</small></td><td>${i.qty}</td><td>${money(i.price)}</td><td><b>${money(i.qty * i.price)}</b></td></tr>`).join('')}</tbody>
      </table></div>
      <div class="sum-rows"><div><span>Subtotal</span><b>${money(v.subtotal)}</b></div><div><span>IVA (19%)</span><b>${money(v.iva)}</b></div></div>
      <div class="total-row"><span>Total</span><strong>${money(v.total)}</strong></div>
      ${statusOf(v) === 'Pendiente' && isClient() ? `<div class="order-actions"><button class="btn btn-outline" data-order="client-cancel" data-folio="${esc(v.folio)}">Cancelar mi pedido</button></div>` : ''}
      ${statusOf(v) === 'Pendiente' && canManageOrders() ? `<div class="order-actions"><button class="btn btn-primary" data-order="deliver" data-folio="${esc(v.folio)}">Marcar como entregado</button><button class="btn btn-outline" data-order="cancel" data-folio="${esc(v.folio)}">Anular pedido</button></div>` : ''}`;
    openModal('detail-modal');
  }

  $('#detail-body').addEventListener('click', (e) => {
    const b = e.target.closest('[data-order]'); if (!b) return;
    const client = b.dataset.order === 'client-cancel';
    if (client ? !isClient() : !canManageOrders()) return;
    const v = (client ? visibleSales() : state.sales).find((x) => x.folio === b.dataset.folio);
    if (!v || statusOf(v) !== 'Pendiente') return;
    const cancel = client || b.dataset.order === 'cancel';
    if (client && !confirm(`¿Cancelar tu pedido ${v.folio}?`)) return;
    if (!client && cancel && !confirm(`¿Anular el pedido ${v.folio}? Las unidades volverán al inventario.`)) return;
    api('/sales/' + encodeURIComponent(v.folio) + '/status/', { method: 'POST', body: JSON.stringify({ action: cancel ? 'cancel' : 'deliver', as_client: client && hasDual(state.session.role) }) })
      .then(() => loadData())
      .then(() => { closeModals(); go(state.page); toast(client ? `Pedido ${v.folio} cancelado.` : `Pedido ${v.folio} ${cancel ? 'anulado' : 'entregado'}.`); })
      .catch((ex) => toast(ex.message));
  });

  /* ---------- Agregar producto ---------- */
  function fillAddCategories(selected) {
    const sel = $('#p-cat');
    sel.innerHTML = sortedCats().map((c) => `<option>${esc(c)}</option>`).join('');
    if (selected) sel.value = selected;
  }
  function renderImage() {
    const box = $('#img-box'), img = state.newImage;
    box.innerHTML = img ? `<img src="${img.src}" alt="Vista previa del producto">` : `${icon('upload')}<small>Sin imagen</small>`;
    $('#file-row').hidden = !img;
    if (img) { $('#file-name').textContent = img.name; $('#file-meta').textContent = img.meta; }
    $('#img-change').lastChild.textContent = img ? ' Cambiar imagen' : ' Subir imagen';
  }
  function syncKind() {
    const svc = $('#p-kind').value === 'Servicio';
    $('#stock-fields').hidden = svc;
    $('#lbl-cost').textContent = svc ? 'Costo estimado (opcional)' : 'Precio de costo *';
    $('#lbl-price').textContent = svc ? 'Precio del servicio *' : 'Precio de venta *';
    $('#price-card-title').textContent = svc ? 'Precio' : 'Precios y existencias';
  }
  $('#p-kind').addEventListener('change', syncKind);
  function resetAddForm() {
    $('#add-form').reset(); syncKind(); $('#add-error').hidden = true;
    state.newImage = null; fillAddCategories(); renderImage();
  }
  function renderAdd() { fillAddCategories($('#p-cat').value); renderImage(); }

  $('#img-change').addEventListener('click', () => $('#img-input').click());
  $('#img-remove').addEventListener('click', () => { state.newImage = null; renderImage(); });
  $('#img-input').addEventListener('change', (e) => {
    const f = e.target.files[0]; if (!f) return;
    const er = $('#add-error');
    if (!/^image\/(png|jpeg)$/.test(f.type)) { er.textContent = 'La imagen debe ser JPG o PNG.'; er.hidden = false; return; }
    if (f.size > 5 * 1024 * 1024) { er.textContent = 'La imagen supera el máximo de 5 MB.'; er.hidden = false; return; }
    er.hidden = true;
    const reader = new FileReader();
    reader.onload = () => {
      const im = new Image();
      im.onload = () => {
        const max = 320, ratio = Math.min(1, max / Math.max(im.width, im.height));
        const c = document.createElement('canvas'); c.width = Math.round(im.width * ratio); c.height = Math.round(im.height * ratio);
        c.getContext('2d').drawImage(im, 0, 0, c.width, c.height);
        state.newImage = { src: c.toDataURL('image/jpeg', 0.8), name: f.name, meta: Math.max(1, Math.round(f.size / 1024)) + ' KB' };
        renderImage();
      };
      im.src = reader.result;
    };
    reader.readAsDataURL(f);
    e.target.value = '';
  });

  $('#add-form').addEventListener('submit', (e) => {
    e.preventDefault();
    if (isSuper()) return toast('El superadministrador solo puede consultar.');
    const kind = $('#p-kind').value === 'Servicio' ? 'service' : 'product';
    const name = $('#p-name').value.trim(), sku = $('#p-sku').value.trim().toUpperCase(), desc = $('#p-desc').value.trim();
    const price = parseFloat($('#p-price').value), cost = parseFloat($('#p-cost').value);
    const stock = parseInt($('#p-stock').value, 10), min = parseInt($('#p-min').value, 10);
    const er = $('#add-error'), fail = (m) => { er.textContent = m; er.hidden = false; };
    const svc = kind === 'service';
    if (!name || !sku || isNaN(price) || (!svc && (isNaN(cost) || isNaN(stock) || isNaN(min)))) return fail('Completa todos los campos obligatorios (*).');
    if (!desc) { $('#p-desc').focus(); return fail('La descripción es obligatoria. Escríbela para poder guardar el producto.'); }
    if (price < 0 || (!svc && (cost < 0 || stock < 0 || min < 0))) return fail('Los precios y las unidades no pueden ser negativos.');
    api('/products/create/', { method: 'POST', body: JSON.stringify({
      kind, name, sku, cat: $('#p-cat').value, desc,
      stock: svc ? 0 : stock, min: svc ? 0 : min, price,
      cost: svc ? (isNaN(cost) ? null : cost) : cost,
      active: $('#p-state').value === 'Activo', image: state.newImage ? state.newImage.src : null
    }) }).then((d) => {
      state.products.push(d.product);
      resetAddForm();
      toast(`"${name}" guardado en el catálogo`);
      go('inventory');
    }).catch((ex) => fail(ex.message));
  });
  $('#add-cancel').addEventListener('click', () => { resetAddForm(); go('inventory'); });

  $('#open-new-cat').addEventListener('click', () => { $('#cat-form').reset(); $('#cat-error').hidden = true; openModal('cat-modal'); $('#c-name').focus(); });
  $('#cat-form').addEventListener('submit', (e) => {
    e.preventDefault();
    if (isSuper()) return toast('El superadministrador solo puede consultar.');
    const name = $('#c-name').value.trim(), err = $('#cat-error');
    if (!name) { err.textContent = 'Escribe el nombre de la categoría.'; err.hidden = false; return; }
    api('/categories/create/', { method: 'POST', body: JSON.stringify({ name }) })
      .then((d) => { state.categories.push(d.category); closeModals(); fillAddCategories(d.category); toast(`Categoría "${d.category}" agregada`); })
      .catch((ex) => { err.textContent = ex.message; err.hidden = false; });
  });

  /* ---------- Modales ---------- */
  function openModal(id) { $('#' + id).hidden = false; }
  function closeModals() { $$('.modal-backdrop').forEach((m) => { m.hidden = true; }); }
  $('#open-logout').addEventListener('click', () => {
    const s = state.session;
    $('#m-name').textContent = s.name; $('#m-email').textContent = s.email; $('#m-avatar').textContent = initials(s.name);
    openModal('logout-modal');
  });
  $('#confirm-logout').addEventListener('click', logout);
  $$('[data-close]').forEach((b) => b.addEventListener('click', closeModals));
  $$('.modal-backdrop').forEach((m) => m.addEventListener('mousedown', (e) => { if (e.target === m) closeModals(); }));
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeModals(); });

  /* ---------- Navegación general ---------- */
  document.addEventListener('click', (e) => {
    const t = e.target.closest('[data-page]');
    if (t && state.session) { e.preventDefault(); go(t.dataset.page); }
  });
  $('#menu-btn').addEventListener('click', () => $('#sidebar').classList.toggle('open'));
  $('#mode-switch').addEventListener('click', (e) => {
    const b = e.target.closest('[data-mode]'); if (!b || b.dataset.mode === state.session.mode) return;
    state.session.mode = b.dataset.mode; persistMode(); applyShell(); go(home());
    toast(b.dataset.mode === 'user' ? 'Ahora estás en modo cliente' : 'Ahora estás en modo administrador');
  });

  /* ---------- Actualización automática ---------- */
  /* Cada pocos segundos se consultan los datos al servidor: así, cuando un cliente
     compra desde su equipo, el asesor lo ve sin recargar la página. */
  let refreshing = false;
  const salesKey = () => state.sales.length + '|' + state.sales.map((v) => v.folio + v.status).join(',');
  async function refreshData() {
    if (!state.session || refreshing || document.hidden) return;
    if ($$('.modal-backdrop').some((m) => !m.hidden) || ['add', 'checkout'].includes(state.page)) return;
    refreshing = true;
    try {
      const before = salesKey();
      await loadData();
      if (state.page === 'sales') { renderProductGrid(); renderCart(); }
      else if (state.page === 'shop') renderShopGrid();
      else ({ dashboard: renderDashboard, inventory: renderInventory, admin: renderAdmin, history: renderHistory, profile: renderProfile }[state.page] || (() => {}))();
      if (before !== salesKey()) toast('Hay movimientos nuevos en las ventas');
    } catch (ex) {
      if (/iniciar sesión/i.test(ex.message)) { state.session = null; state.me = null; showAuth('login'); toast('Tu sesión terminó. Inicia sesión de nuevo.'); }
    } finally { refreshing = false; }
  }
  setInterval(refreshData, 8000);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) refreshData(); });

  /* ---------- Arranque ---------- */
  paintIcons();
  syncRegFields();
  (async () => {
    try {
      const d = await api('/auth/session/');            // ¿ya hay una sesión abierta en el servidor?
      const saved = Store.get('magnus_mode', null);
      await enterApp(d.user, saved && saved.email === d.user.email ? saved.mode : 'admin');
    } catch (e) { showAuth('login'); }
  })();
})();
