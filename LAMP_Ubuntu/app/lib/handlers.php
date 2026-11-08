<?php
declare(strict_types=1);

/**
 * Port a PHP de productos/views.py (Django). Mismas rutas, mismas reglas de negocio,
 * mismos mensajes y mismo JSON. No cambia la estructura de la base de datos.
 */

const ROLE_SUPER = 'Superadministrador';
const ROLE_ADMIN = 'Administrador';
const ROLE_SUPERVISOR = 'Supervisor';
const ROLE_ADVISOR = 'Asesor de ventas';
const ROLE_CLIENT = 'Cliente';
const ROLES = [ROLE_CLIENT, ROLE_ADVISOR, ROLE_SUPERVISOR, ROLE_ADMIN, ROLE_SUPER];
const RANK = [ROLE_CLIENT => 0, ROLE_ADVISOR => 1, ROLE_SUPERVISOR => 2, ROLE_ADMIN => 3, ROLE_SUPER => 4];
const PAYMENTS = ['Efectivo', 'Tarjeta débito / crédito', 'Transferencia bancaria', 'Nequi / Daviplata'];
const DELIVERY_METHODS = ['pickup', 'ship', 'service'];
const EMAIL_RE = '/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/u';
const ADVISOR_SELF_SERVICE = 'Autoservicio';

const CATALOG_ROLES = [ROLE_ADMIN, ROLE_SUPERVISOR];
const SALE_ROLES = [ROLE_CLIENT, ROLE_ADVISOR, ROLE_SUPERVISOR, ROLE_ADMIN];
const ORDER_ROLES = [ROLE_ADVISOR, ROLE_SUPERVISOR, ROLE_ADMIN];
const STAFF_SALES = [ROLE_ADVISOR, ROLE_SUPERVISOR, ROLE_ADMIN];

/* ===================== Roles y usuarios ===================== */

function full_name(array $u): string
{
    return strip($u['first_name'] . ' ' . $u['last_name']);
}

function display_name(array $u): string
{
    $n = full_name($u);
    return $n !== '' ? $n : (string) $u['username'];
}

function get_profile(array $user): array
{
    $p = row('SELECT * FROM productos_companyprofile WHERE user_id=?', [(int) $user['id']]);
    if ($p) return $p;
    $role = !empty($user['is_superuser']) ? ROLE_ADMIN : ROLE_ADVISOR;
    insert('productos_companyprofile', ['user_id' => (int) $user['id'], 'company' => 'Magnus SIG S.A.S', 'role' => $role, 'dual' => 0, 'granted_by_id' => null]);
    return row('SELECT * FROM productos_companyprofile WHERE user_id=?', [(int) $user['id']]);
}

function role_of(array $user): string
{
    return (string) get_profile($user)['role'];
}

function assignable_roles(string $role): array
{
    return array_values(array_filter(ROLES, fn($r) => RANK[$r] <= RANK[$role]));
}

function can_modify(array $actor, array $target): bool
{
    $a = get_profile($actor);
    $t = get_profile($target);
    if (RANK[$a['role']] < RANK[ROLE_ADMIN] || (int) $actor['id'] === (int) $target['id']) return false;
    if (RANK[$a['role']] > RANK[$t['role']]) return true;
    return RANK[$a['role']] === RANK[$t['role']] && $a['role'] !== ROLE_SUPER && (int) ($t['granted_by_id'] ?? 0) === (int) $actor['id'];
}

function client_dict(array $c): array
{
    return ['id' => (int) $c['id'], 'name' => $c['name'], 'doc' => $c['document'], 'phone' => $c['phone']];
}

function client_of_user(array $user): ?array
{
    return row('SELECT * FROM productos_client WHERE user_id=? ORDER BY id LIMIT 1', [(int) $user['id']]);
}

function granted_by_email(array $profile): ?string
{
    if (empty($profile['granted_by_id'])) return null;
    $e = val('SELECT email FROM auth_user WHERE id=?', [(int) $profile['granted_by_id']]);
    return $e === null ? null : (string) $e;
}

function user_data(array $user): array
{
    $profile = get_profile($user);
    $client = client_of_user($user);
    return [
        'id' => (int) $user['id'],
        'name' => display_name($user),
        'email' => $user['email'],
        'role' => $profile['role'],
        'dual' => (bool) ($profile['dual'] && $profile['role'] === ROLE_ADMIN),
        'clientId' => $client ? (int) $client['id'] : null,
        'client' => $client ? client_dict($client) : null,
        'grantedBy' => granted_by_email($profile),
    ];
}

function user_row(array $user): array
{
    $profile = get_profile($user);
    return [
        'id' => (int) $user['id'],
        'name' => display_name($user),
        'email' => $user['email'],
        'role' => $profile['role'],
        'dual' => (bool) ($profile['dual'] && $profile['role'] === ROLE_ADMIN),
        'grantedBy' => granted_by_email($profile),
        'last' => iso($user['last_login'] ?? null),
        'status' => $user['is_active'] ? 'Activo' : 'Inactivo',
    ];
}

/* ===================== Validaciones compartidas ===================== */

function clean_email($value): string
{
    $email = lower(strip(pstr($value ?? '')));
    if (!preg_match(EMAIL_RE, $email) || mb_strlen($email) > 150) {
        fail('Escribe un correo electrónico válido.');
    }
    return $email;
}

function check_password_rules(string $password): void
{
    if (mb_strlen($password) < 8 || !preg_match('/\p{L}/u', $password) || !preg_match('/\p{Nd}/u', $password)) {
        fail('La contraseña debe tener mínimo 8 caracteres, una letra y un número.');
    }
}

function email_in_use(string $email, ?int $excludeId = null): bool
{
    $sql = 'SELECT 1 FROM auth_user WHERE (LOWER(email)=LOWER(?) OR LOWER(username)=LOWER(?))';
    $params = [$email, $email];
    if ($excludeId !== null) {
        $sql .= ' AND id<>?';
        $params[] = $excludeId;
    }
    return row($sql . ' LIMIT 1', $params) !== null;
}

function clean_client_fields(array $data): array
{
    $doc = strip(pstr(g($data, 'doc', '')));
    $phone = strip(pstr(g($data, 'phone', '')));
    if (!preg_match('/\A[A-Za-z0-9.\-]{5,20}\z/', $doc)) {
        fail('La cédula o NIT debe tener entre 5 y 20 números.');
    }
    if ($phone !== '' && !preg_match('/\A[0-9+\s\-]{7,20}\z/', $phone)) {
        fail('El teléfono no es válido.');
    }
    return [$doc, $phone];
}

function document_in_use(string $doc, ?int $excludeUser = null): bool
{
    $sql = 'SELECT 1 FROM productos_client WHERE LOWER(document)=LOWER(?)';
    $params = [$doc];
    if ($excludeUser !== null) {
        $sql .= ' AND (user_id IS NULL OR user_id<>?)';
        $params[] = $excludeUser;
    }
    return row($sql . ' LIMIT 1', $params) !== null;
}

/* ===================== Autenticación ===================== */

function h_csrf(): void
{
    respond(['csrfToken' => csrf_token()]);
}

function h_session(?array $u): void
{
    if (!$u) fail('Debes iniciar sesión.', 401);
    respond(['user' => user_data($u)]);
}

function h_login(): void
{
    $data = body();
    $email = lower(strip(pstr(g($data, 'email', ''))));
    $password = g($data, 'password', '');
    $user = row('SELECT * FROM auth_user WHERE LOWER(email)=LOWER(?) ORDER BY id LIMIT 1', [$email]);
    $ok = $user && $user['is_active'] && is_string($password) && password_check($password, (string) $user['password']);
    if (!$ok) fail('Correo o contraseña incorrectos.', 401);
    login_user($user, (bool) g($data, 'remember', true));
    $user = row('SELECT * FROM auth_user WHERE id=?', [(int) $user['id']]);
    respond(['user' => user_data($user)]);
}

function h_register(): void
{
    $data = body();
    $role = ROLE_CLIENT; // el registro público solo crea clientes; los demás roles los crea el Superadministrador
    $name = strip(pstr(g($data, 'name', '')));
    $email = lower(strip(pstr(g($data, 'email', ''))));
    $password = pstr(g($data, 'password', ''));
    if ($name === '' || $email === '' || $password === '') fail('Todos los campos obligatorios deben completarse.');
    $email = clean_email($email);
    check_password_rules($password);
    if (mb_strlen($name) > 150) fail('El nombre es demasiado largo.');
    $doc = $phone = '';
    if ($role === ROLE_CLIENT) {
        [$doc, $phone] = clean_client_fields($data);
        if (document_in_use($doc)) fail('Ya existe un cliente con esa cédula o NIT.', 409);
    }
    if (email_in_use($email)) fail('Ya existe una cuenta con ese correo.', 409);
    try {
        db()->beginTransaction();
        $uid = insert('auth_user', [
            'password' => password_make($password), 'last_login' => null, 'is_superuser' => 0,
            'username' => $email, 'first_name' => $name, 'last_name' => '', 'email' => $email,
            'is_staff' => 0, 'is_active' => 1, 'date_joined' => now_sql(),
        ]);
        insert('productos_companyprofile', ['user_id' => $uid, 'company' => 'Magnus SIG S.A.S', 'role' => $role, 'dual' => 0, 'granted_by_id' => null]);
        if ($role === ROLE_CLIENT) {
            insert('productos_client', ['name' => $name, 'document' => $doc, 'phone' => $phone, 'user_id' => $uid]);
        }
        db()->commit();
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        if (is_integrity($e) || is_data_error($e)) fail('No fue posible crear la cuenta.', 409);
        throw $e;
    }
    $user = row('SELECT * FROM auth_user WHERE id=?', [$uid]);
    login_user($user, true);
    $user = row('SELECT * FROM auth_user WHERE id=?', [$uid]);
    respond(['user' => user_data($user)], 201);
}

function h_logout(): void
{
    logout_user();
    respond(['message' => 'Sesión cerrada.']);
}

/* ===================== Categorías ===================== */

function h_categories(): void
{
    respond(['categories' => array_map('strval', array_column(rows('SELECT name FROM productos_category ORDER BY name'), 'name'))]);
}

function h_category_create(): void
{
    $name = squash(pstr(g(body(), 'name', '')));
    if ($name === '' || mb_strlen($name) > 80) fail('Escribe un nombre de categoría de hasta 80 caracteres.');
    if (row('SELECT 1 FROM productos_category WHERE LOWER(name)=LOWER(?) LIMIT 1', [$name])) fail('Esa categoría ya existe.', 409);
    insert('productos_category', ['name' => $name]);
    respond(['category' => $name], 201);
}

/* ===================== Productos y servicios ===================== */

function product_dict(array $p, bool $showCost = true): array
{
    return [
        'id' => (int) $p['id'],
        'kind' => $p['kind'],
        'name' => $p['name'],
        'sku' => $p['sku'],
        'cat' => $p['category'],
        'desc' => $p['description'],
        'cost' => ($showCost && $p['cost'] !== null) ? (float) $p['cost'] : null,
        'price' => (float) $p['price'],
        'stock' => (int) $p['stock'],
        'min' => $showCost ? (int) $p['minimum_stock'] : 0,
        'active' => (bool) $p['active'],
        'image' => $p['image'],
        'icon' => $p['icon'],
    ];
}

function h_products(array $u): void
{
    $isClient = role_of($u) === ROLE_CLIENT;
    $list = $isClient ? rows('SELECT * FROM productos_product WHERE active=1 ORDER BY name') : rows('SELECT * FROM productos_product ORDER BY name');
    respond(['products' => array_map(fn($p) => product_dict($p, !$isClient), $list)]);
}

/** Valida y normaliza los datos de un producto (igual que product_values en Django). */
function product_values(array $data): array
{
    $invalid = 'Los datos del producto no son válidos.';
    $kind = pstr(g($data, 'kind', 'product'));
    if (!in_array($kind, ['product', 'service'], true)) fail('El tipo debe ser producto o servicio.');
    $service = $kind === 'service';
    $name = strip(pstr(g($data, 'name', '')));
    $sku = upper(strip(pstr(g($data, 'sku', ''))));
    $category = strip(pstr(g($data, 'cat', '')));
    $desc = strip(pstr(g($data, 'desc', '')));
    if ($name === '' || $sku === '' || $category === '') fail('Nombre, código y categoría son obligatorios.');
    if ($desc === '') fail('La descripción es obligatoria.');
    try {
        $price = to_cents(g($data, 'price', ''));
        $rawCost = g($data, 'cost');
        $cost = ($service && ($rawCost === null || $rawCost === '')) ? null : to_cents($rawCost);
        $stock = $service ? 0 : pint(g($data, 'stock'));
        $minimum = $service ? 0 : pint(g($data, 'min'));
    } catch (InvalidArgumentException $e) {
        fail($invalid);
    }
    if ($price < 0 || ($cost !== null && $cost < 0) || $stock < 0 || $minimum < 0) {
        fail('Los precios y el stock no pueden ser negativos.');
    }
    $image = g($data, 'image');
    return [
        'kind' => $kind, 'name' => $name, 'sku' => $sku, 'category' => $category, 'description' => $desc,
        'active' => g($data, 'active', true) ? 1 : 0,
        'image' => (is_string($image) && $image !== '') ? $image : null,
        'icon' => pstr(g($data, 'icon', 'box')),
        'cost' => $cost === null ? null : cents_str($cost),
        'price' => cents_str($price), 'stock' => $stock, 'minimum_stock' => $minimum,
    ];
}

function h_product_create(array $u): void
{
    $values = product_values(body());
    if (row('SELECT 1 FROM productos_product WHERE sku=? LIMIT 1', [$values['sku']])) fail('Ya existe un producto con ese código.', 409);
    try {
        db()->beginTransaction();
        if (!row('SELECT 1 FROM productos_category WHERE name=? LIMIT 1', [$values['category']])) {
            insert('productos_category', ['name' => $values['category']]);
        }
        $now = now_sql();
        $id = insert('productos_product', $values + ['owner_id' => (int) $u['id'], 'created_at' => $now, 'updated_at' => $now]);
        db()->commit();
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        if (is_integrity($e)) fail('Ya existe un producto con ese código.', 409);
        if (is_data_error($e)) fail('Los datos del producto no son válidos.');
        throw $e;
    }
    respond(['product' => product_dict(row('SELECT * FROM productos_product WHERE id=?', [$id]))], 201);
}

function h_product_update(array $u, array $a): void
{
    $id = (int) $a['id'];
    if (!row('SELECT id FROM productos_product WHERE id=?', [$id])) fail('Producto no encontrado.', 404);
    $data = product_values(body());
    if (row('SELECT 1 FROM productos_product WHERE sku=? AND id<>? LIMIT 1', [$data['sku'], $id])) fail('Ya existe un producto con ese código.', 409);
    try {
        db()->beginTransaction();
        if (!row('SELECT 1 FROM productos_category WHERE name=? LIMIT 1', [$data['category']])) {
            insert('productos_category', ['name' => $data['category']]);
        }
        update('productos_product', $id, $data + ['updated_at' => now_sql()]);
        db()->commit();
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        if (is_integrity($e)) fail('Ya existe un producto con ese código.', 409);
        if (is_data_error($e)) fail('Los datos del producto no son válidos.');
        throw $e;
    }
    respond(['product' => product_dict(row('SELECT * FROM productos_product WHERE id=?', [$id]))]);
}

function h_product_delete(array $u, array $a): void
{
    $id = (int) $a['id'];
    if (!row('SELECT id FROM productos_product WHERE id=?', [$id])) fail('Producto no encontrado.', 404);
    try {
        q('DELETE FROM productos_product WHERE id=?', [$id]);
    } catch (PDOException $e) {
        if (is_integrity($e)) fail('No se puede eliminar: tiene ventas registradas. Márcalo como Inactivo.', 409);
        throw $e;
    }
    respond(['message' => 'Producto eliminado.']);
}

/* ===================== Clientes ===================== */

function h_clients(): void
{
    respond(['clients' => array_map('client_dict', rows('SELECT * FROM productos_client ORDER BY id'))]);
}

function h_client_create(): void
{
    $data = body();
    $name = strip(pstr(g($data, 'name', '')));
    if ($name === '' || mb_strlen($name) > 150) fail('Escribe el nombre del cliente.');
    [$doc, $phone] = clean_client_fields($data);
    if (document_in_use($doc)) fail('Ya existe un cliente con esa cédula o NIT.', 409);
    $id = insert('productos_client', ['name' => $name, 'document' => $doc, 'phone' => $phone, 'user_id' => null]);
    respond(['client' => client_dict(row('SELECT * FROM productos_client WHERE id=?', [$id]))], 201);
}

/* ===================== Ventas ===================== */

function sale_dicts(array $sales): array
{
    if (!$sales) return [];
    $ids = array_map(fn($s) => (int) $s['id'], $sales);
    $items = rows('SELECT * FROM productos_saleitem WHERE sale_id IN (' . implode(',', array_fill(0, count($ids), '?')) . ') ORDER BY id', $ids);
    $by = [];
    foreach ($items as $i) {
        $by[(int) $i['sale_id']][] = ['id' => (int) $i['product_id'], 'name' => $i['name'], 'sku' => $i['sku'], 'qty' => (int) $i['quantity'], 'price' => (float) $i['unit_price']];
    }
    $out = [];
    foreach ($sales as $s) {
        $out[] = [
            'folio' => $s['folio'],
            'date' => iso($s['created_at']),
            'client' => ['id' => $s['client_id'] === null ? null : (int) $s['client_id'], 'name' => $s['customer'], 'doc' => $s['customer_doc'], 'phone' => $s['customer_phone']],
            'advisor' => ['name' => $s['advisor_name'], 'email' => $s['advisor_email'], 'role' => $s['advisor_role']],
            'status' => $s['status'],
            'items' => $by[(int) $s['id']] ?? [],
            'subtotal' => (float) $s['subtotal'],
            'iva' => (float) $s['tax'],
            'total' => (float) $s['total'],
            'pay' => $s['payment'],
            'attendedBy' => $s['attended_by'],
            'delivery' => $s['delivery_method'] !== '' ? ['method' => $s['delivery_method'], 'city' => $s['delivery_city'], 'address' => $s['delivery_address']] : null,
            'notes' => $s['notes'],
        ];
    }
    return $out;
}

function visible_sales(array $user): array
{
    $role = role_of($user);
    $order = ' ORDER BY s.created_at DESC, s.id DESC LIMIT 1000';
    if (RANK[$role] >= RANK[ROLE_SUPERVISOR]) return rows('SELECT s.* FROM productos_sale s' . $order);
    if ($role === ROLE_CLIENT) {
        return rows('SELECT s.* FROM productos_sale s JOIN productos_client c ON c.id=s.client_id WHERE c.user_id=?' . $order, [(int) $user['id']]);
    }
    return rows('SELECT s.* FROM productos_sale s WHERE (s.owner_id=? OR s.advisor_role=?)' . $order, [(int) $user['id'], ADVISOR_SELF_SERVICE]);
}

function h_sales(array $u): void
{
    respond(['sales' => sale_dicts(visible_sales($u))]);
}

function h_sale_create(array $user): void
{
    $generic = 'La venta no es válida o hay productos que ya no están disponibles.';
    $data = body();
    $role = role_of($user);
    $rawItems = g($data, 'items', []);
    if (!$rawItems) fail('La venta debe incluir al menos un producto.');
    if (!is_array($rawItems)) fail($generic);
    $wanted = [];
    foreach ($rawItems as $item) {
        if (!is_dict($item) || !array_key_exists('id', $item) || !array_key_exists('quantity', $item)) fail($generic);
        try {
            $pid = pint($item['id']);
            $qty = pint($item['quantity']);
        } catch (InvalidArgumentException $e) {
            fail($generic);
        }
        if ($qty < 1) fail('La cantidad debe ser mayor a cero.');
        $wanted[$pid] = ($wanted[$pid] ?? 0) + $qty;
    }
    $payment = pstr(g($data, 'payment', 'Efectivo'));
    if (!in_array($payment, PAYMENTS, true)) $payment = 'Efectivo';

    $newValues = null;
    $deliveryMethod = $deliveryCity = $deliveryAddress = $notes = '';
    if ($role === ROLE_CLIENT) {
        $client = client_of_user($user);
        if (!$client) fail('Tu cuenta no tiene datos de cliente.');
        $info = g($data, 'customer');
        if (is_dict($info)) {
            $newName = squash(pstr(g($info, 'name', '')));
            if ($newName === '' || mb_strlen($newName) > 150) fail('Escribe tu nombre completo o la razón social de tu empresa.');
            [$newDoc, $newPhone] = clean_client_fields($info);
            if (document_in_use($newDoc, (int) $user['id'])) fail('Ese documento ya está registrado con otro cliente. Revisa el número.');
            $newValues = [$newName, $newDoc, $newPhone];
        }
        $delivery = is_dict(g($data, 'delivery')) ? $data['delivery'] : [];
        $deliveryMethod = strip(pstr(g($delivery, 'method', '')));
        if (!in_array($deliveryMethod, DELIVERY_METHODS, true)) $deliveryMethod = '';
        $deliveryCity = mb_substr(strip(pstr(g($delivery, 'city', ''))), 0, 80);
        $deliveryAddress = mb_substr(strip(pstr(g($delivery, 'address', ''))), 0, 200);
        $notes = mb_substr(strip(pstr(g($data, 'notes', ''))), 0, 300);
        $advisor = ['name' => 'Tienda en línea', 'email' => '', 'role' => ADVISOR_SELF_SERVICE];
        $status = 'Pendiente';
    } else {
        $cid = g($data, 'client_id');
        $client = null;
        if ($cid !== null && (is_int($cid) || (is_string($cid) && preg_match('/^\s*\d+\s*$/', $cid)))) {
            $client = row('SELECT * FROM productos_client WHERE id=?', [(int) $cid]);
        }
        $client = $client ?: row('SELECT * FROM productos_client WHERE name=? ORDER BY id LIMIT 1', ['Público general']);
        if (!$client) fail('Selecciona un cliente.');
        $advisor = ['name' => display_name($user), 'email' => $user['email'], 'role' => $role];
        $status = 'Entregado';
    }

    $pdo = db();
    $pdo->beginTransaction();
    try {
        if ($role === ROLE_CLIENT && $newValues) {
            update('productos_client', (int) $client['id'], ['name' => $newValues[0], 'document' => $newValues[1], 'phone' => $newValues[2]]);
            $client['name'] = $newValues[0];
            $client['document'] = $newValues[1];
            $client['phone'] = $newValues[2];
        }
        $lines = [];
        $subtotal = 0;
        ksort($wanted);
        foreach ($wanted as $pid => $qty) {
            $p = row('SELECT * FROM productos_product WHERE id=? AND active=1 FOR UPDATE', [$pid]);
            if (!$p) fail($generic);
            if ($p['kind'] !== 'service' && $qty > (int) $p['stock']) fail('Stock insuficiente para ' . $p['name'] . '.');
            $lines[] = [$p, $qty];
            $subtotal += to_cents($p['price']) * $qty;
        }
        // IVA 19 % redondeado a centavos (mitad al par, como Decimal.quantize de Python)
        $n = $subtotal * 19;
        $tax = intdiv($n, 100);
        $rem = $n % 100;
        if ($rem > 50 || ($rem === 50 && $tax % 2 === 1)) $tax++;
        $now = now_sql();
        $saleId = insert('productos_sale', [
            'owner_id' => (int) $user['id'], 'folio' => bin2hex(random_bytes(10)), 'client_id' => (int) $client['id'],
            'customer' => $client['name'], 'customer_doc' => $client['document'], 'customer_phone' => $client['phone'],
            'advisor_name' => $advisor['name'], 'advisor_email' => $advisor['email'], 'advisor_role' => $advisor['role'],
            'status' => $status, 'payment' => $payment,
            'attended_by' => $status === 'Pendiente' ? '' : $advisor['name'],
            'delivery_method' => $deliveryMethod, 'delivery_city' => $deliveryCity, 'delivery_address' => $deliveryAddress,
            'notes' => $notes, 'subtotal' => cents_str($subtotal), 'tax' => cents_str($tax), 'total' => cents_str($subtotal + $tax),
            'created_at' => $now,
        ]);
        q('UPDATE productos_sale SET folio=? WHERE id=?', ['V-' . (1000 + $saleId), $saleId]);
        foreach ($lines as [$p, $qty]) {
            insert('productos_saleitem', ['sale_id' => $saleId, 'product_id' => (int) $p['id'], 'name' => $p['name'], 'sku' => $p['sku'], 'quantity' => $qty, 'unit_price' => $p['price']]);
            if ($p['kind'] !== 'service') {
                q('UPDATE productos_product SET stock = stock - ?, updated_at=? WHERE id=?', [$qty, now_sql(), (int) $p['id']]);
            }
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        if ($e instanceof PDOException && (is_integrity($e) || is_data_error($e))) fail($generic);
        throw $e;
    }
    $sale = row('SELECT * FROM productos_sale WHERE id=?', [$saleId]);
    respond(['sale' => sale_dicts([$sale])[0]], 201);
}

function h_sale_status(array $user, array $a): void
{
    $role = role_of($user);
    $isClient = $role === ROLE_CLIENT;
    if (!$isClient && !in_array($role, ORDER_ROLES, true)) fail('Tu rol no tiene permiso para realizar esta acción.', 403);
    $action = pstr(g(body(), 'action', ''));
    if (!in_array($action, ['deliver', 'cancel'], true)) fail('La acción no es válida.');
    if ($isClient && $action !== 'cancel') fail('Tu rol no tiene permiso para realizar esta acción.', 403);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $sale = row('SELECT * FROM productos_sale WHERE folio=? ORDER BY created_at DESC, id DESC LIMIT 1 FOR UPDATE', [$a['folio']]);
        if ($sale && $isClient) {
            $owner = $sale['client_id'] === null ? null : val('SELECT user_id FROM productos_client WHERE id=?', [(int) $sale['client_id']]);
            if ($owner === null || (int) $owner !== (int) $user['id']) $sale = null;
        }
        if (!$sale) fail('Venta no encontrada.', 404);
        if ($sale['status'] !== 'Pendiente') fail('Este pedido ya fue atendido.', 409);
        $newStatus = 'Entregado';
        if ($action === 'cancel') {
            $newStatus = 'Anulada';
            foreach (rows('SELECT i.quantity, i.product_id, p.kind FROM productos_saleitem i JOIN productos_product p ON p.id=i.product_id WHERE i.sale_id=?', [(int) $sale['id']]) as $it) {
                if ($it['kind'] !== 'service') {
                    q('UPDATE productos_product SET stock = stock + ?, updated_at=? WHERE id=?', [(int) $it['quantity'], now_sql(), (int) $it['product_id']]);
                }
            }
        }
        $attended = $isClient ? $sale['attended_by'] : display_name($user);
        q('UPDATE productos_sale SET status=?, attended_by=? WHERE id=?', [$newStatus, $attended, (int) $sale['id']]);
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    respond(['sale' => sale_dicts([row('SELECT * FROM productos_sale WHERE id=?', [(int) $sale['id']])])[0]]);
}

/* ===================== Usuarios (Administrador y Superadministrador) ===================== */

function h_users(): void
{
    respond(['users' => array_map('user_row', rows('SELECT * FROM auth_user ORDER BY first_name, email'))]);
}

function h_user_create(array $actor): void
{
    $data = body();
    $name = strip(pstr(g($data, 'name', '')));
    $email = clean_email(g($data, 'email'));
    $role = strip(pstr(g($data, 'role', ROLE_ADVISOR)));
    $password = pstr(g($data, 'password', '') ?: '');
    if ($name === '' || mb_strlen($name) > 150) fail('Escribe el nombre del usuario.');
    if (!in_array($role, assignable_roles(role_of($actor)), true)) fail('No puedes asignar ese rol.');
    check_password_rules($password);
    $doc = $phone = '';
    if ($role === ROLE_CLIENT) {
        [$doc, $phone] = clean_client_fields($data);
        if (document_in_use($doc)) fail('Ya existe un cliente con esa cédula o NIT.', 409);
    }
    if (email_in_use($email)) fail('Ya existe una cuenta con ese correo.', 409);
    try {
        db()->beginTransaction();
        $uid = insert('auth_user', [
            'password' => password_make($password), 'last_login' => null, 'is_superuser' => 0,
            'username' => $email, 'first_name' => $name, 'last_name' => '', 'email' => $email,
            'is_staff' => 0, 'is_active' => 1, 'date_joined' => now_sql(),
        ]);
        insert('productos_companyprofile', [
            'user_id' => $uid, 'company' => 'Magnus SIG S.A.S', 'role' => $role,
            'dual' => (g($data, 'dual') && $role === ROLE_ADMIN) ? 1 : 0, 'granted_by_id' => (int) $actor['id'],
        ]);
        if ($role === ROLE_CLIENT) {
            insert('productos_client', ['name' => $name, 'document' => $doc, 'phone' => $phone, 'user_id' => $uid]);
        }
        db()->commit();
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        if (is_integrity($e) || is_data_error($e)) fail('No fue posible crear el usuario.', 409);
        throw $e;
    }
    respond(['user' => user_row(row('SELECT * FROM auth_user WHERE id=?', [$uid]))], 201);
}

function h_user_update(array $actor, array $a): void
{
    $id = (int) $a['id'];
    $target = row('SELECT * FROM auth_user WHERE id=?', [$id]);
    if (!$target) fail('Usuario no encontrado.', 404);
    if (!can_modify($actor, $target)) fail('No tienes permiso para modificar a este usuario.', 403);
    $data = body();
    $profile = get_profile($target);
    $name = array_key_exists('name', $data) ? strip(pstr($data['name'])) : full_name($target);
    $email = array_key_exists('email', $data) ? clean_email($data['email']) : (string) $target['email'];
    $password = pstr(g($data, 'password', '') ?: '');
    $role = array_key_exists('role', $data) ? strip(pstr($data['role'])) : (string) $profile['role'];
    if ($name === '' || mb_strlen($name) > 150) fail('Escribe el nombre del usuario.');
    if (!in_array($role, assignable_roles(role_of($actor)), true)) fail('No puedes asignar ese rol.');
    if ($password !== '') check_password_rules($password);
    if (email_in_use($email, $id)) fail('Ya existe una cuenta con ese correo.', 409);
    try {
        db()->beginTransaction();
        $fields = ['first_name' => $name, 'email' => $email, 'username' => $email];
        if ($password !== '') $fields['password'] = password_make($password);
        update('auth_user', $id, $fields);
        $newRole = (string) $profile['role'];
        $granted = $profile['granted_by_id'];
        if ($role !== $profile['role']) {
            $newRole = $role;
            $granted = (int) $actor['id'];
        }
        $dual = (int) $profile['dual'];
        if (array_key_exists('dual', $data)) $dual = $data['dual'] ? 1 : 0;
        if ($newRole !== ROLE_ADMIN) $dual = 0;
        update('productos_companyprofile', (int) $profile['id'], ['role' => $newRole, 'granted_by_id' => $granted, 'dual' => $dual]);
        if ($newRole === ROLE_CLIENT && !client_of_user($target)) {
            insert('productos_client', ['name' => $name, 'document' => '—', 'phone' => '', 'user_id' => $id]);
        }
        db()->commit();
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        if (is_integrity($e) || is_data_error($e)) fail('No fue posible actualizar el usuario.', 409);
        throw $e;
    }
    respond(['user' => user_row(row('SELECT * FROM auth_user WHERE id=?', [$id]))]);
}

function h_user_delete(array $actor, array $a): void
{
    $id = (int) $a['id'];
    $target = row('SELECT * FROM auth_user WHERE id=?', [$id]);
    if (!$target) fail('Usuario no encontrado.', 404);
    if ($id === (int) $actor['id']) fail('No puedes eliminar tu propia cuenta.');
    if (!can_modify($actor, $target)) fail('No tienes permiso para eliminar a este usuario.', 403);
    if (row('SELECT 1 FROM productos_product WHERE owner_id=? LIMIT 1', [$id])) {
        fail('Este usuario registró productos en el inventario, por eso no se puede eliminar.', 409);
    }
    try {
        q('DELETE FROM auth_user WHERE id=?', [$id]);
    } catch (PDOException $e) {
        if (is_integrity($e)) fail('No se puede eliminar este usuario porque tiene información asociada.', 409);
        throw $e;
    }
    respond(['message' => 'Usuario eliminado.']);
}

/* ===================== Raíz de la API ===================== */

function h_root(): void
{
    respond([
        'message' => 'API de Nexo activa.',
        'endpoints' => ['csrf' => '/api/auth/csrf/', 'login' => '/api/auth/login/', 'products' => '/api/products/', 'sales' => '/api/sales/'],
    ]);
}
