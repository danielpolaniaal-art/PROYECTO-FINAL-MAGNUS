<?php
declare(strict_types=1);

/* ===================== Errores y respuestas JSON ===================== */

class ApiError extends Exception
{
    public int $status;
    public function __construct(string $message, int $status = 400)
    {
        parent::__construct($message);
        $this->status = $status;
    }
}

function cfg(string $key)
{
    global $CONFIG;
    return $CONFIG[$key] ?? null;
}

function fail(string $message, int $status = 400): void
{
    throw new ApiError($message, $status);
}

function respond($data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION);
    exit;
}

/* ===================== Base de datos (PDO + MySQL) ===================== */

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', cfg('DB_HOST'), cfg('DB_PORT'), cfg('DB_NAME'));
        $pdo = new PDO($dsn, (string) cfg('DB_USER'), (string) cfg('DB_PASSWORD'), [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
        $pdo->exec("SET time_zone = '+00:00'");
    }
    return $pdo;
}

function q(string $sql, array $params = []): PDOStatement
{
    $st = db()->prepare($sql);
    $st->execute($params);
    return $st;
}

function row(string $sql, array $params = []): ?array
{
    $r = q($sql, $params)->fetch();
    return $r === false ? null : $r;
}

function rows(string $sql, array $params = []): array
{
    return q($sql, $params)->fetchAll();
}

function val(string $sql, array $params = [])
{
    $r = q($sql, $params)->fetch(PDO::FETCH_NUM);
    return $r === false ? null : $r[0];
}

function insert(string $table, array $data): int
{
    $cols = array_keys($data);
    $sql = 'INSERT INTO ' . $table . ' (' . implode(',', $cols) . ') VALUES (' . implode(',', array_fill(0, count($cols), '?')) . ')';
    q($sql, array_values($data));
    return (int) db()->lastInsertId();
}

function update(string $table, int $id, array $data): void
{
    $set = implode(',', array_map(fn($c) => $c . '=?', array_keys($data)));
    q('UPDATE ' . $table . ' SET ' . $set . ' WHERE id=?', array_merge(array_values($data), [$id]));
}

/** Equivale a IntegrityError de Django (clave duplicada, llave foránea...). */
function is_integrity(PDOException $e): bool
{
    return (string) $e->getCode() === '23000';
}

/** Equivale a DataError de Django (texto demasiado largo, número fuera de rango...). */
function is_data_error(PDOException $e): bool
{
    return strncmp((string) $e->getCode(), '22', 2) === 0;
}

function now_sql(): string
{
    return (new DateTime('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s.u');
}

/** Fecha de MySQL (UTC) -> ISO 8601 como la entrega Django: 2026-10-22T02:53:00.000000+00:00 */
function iso(?string $s): ?string
{
    if ($s === null || $s === '') {
        return null;
    }
    $utc = new DateTimeZone('UTC');
    $d = DateTime::createFromFormat('Y-m-d H:i:s.u', $s, $utc) ?: DateTime::createFromFormat('Y-m-d H:i:s', $s, $utc);
    return $d ? $d->format('Y-m-d\TH:i:s.uP') : null;
}

/* ===================== Utilidades de texto y números (equivalentes a Python) ===================== */

/** str(valor) de Python. */
function pstr($v): string
{
    if ($v === null) return 'None';
    if ($v === true) return 'True';
    if ($v === false) return 'False';
    if (is_array($v)) return json_encode($v, JSON_UNESCAPED_UNICODE);
    return (string) $v;
}

/** .strip() de Python (quita espacios Unicode). */
function strip(string $s): string
{
    return (string) preg_replace('/^[\s\x{00A0}]+|[\s\x{00A0}]+$/u', '', $s);
}

function lower(string $s): string
{
    return mb_strtolower($s, 'UTF-8');
}

function upper(string $s): string
{
    return mb_strtoupper($s, 'UTF-8');
}

/** " ".join(s.split()) */
function squash(string $s): string
{
    return strip((string) preg_replace('/\s+/u', ' ', $s));
}

function g(array $d, string $key, $default = null)
{
    return array_key_exists($key, $d) ? $d[$key] : $default;
}

function is_dict($v): bool
{
    return is_array($v) && ($v === [] || array_keys($v) !== range(0, count($v) - 1));
}

/** int(valor) de Python; lanza ValueError si no es un entero. */
function pint($v): int
{
    if (is_int($v)) return $v;
    if (is_bool($v)) return $v ? 1 : 0;
    if (is_float($v)) return (int) $v;
    if (is_string($v) && preg_match('/^\s*[+-]?\d+\s*$/', $v)) return (int) trim($v);
    throw new InvalidArgumentException('valor entero no válido');
}

/** Decimal(str(valor)) -> centavos enteros (evita errores de coma flotante). */
function to_cents($v): int
{
    $s = trim(pstr($v));
    if (!preg_match('/^[+-]?(\d+(\.\d*)?|\.\d+)$/', $s)) {
        throw new InvalidArgumentException('decimal no válido');
    }
    $neg = $s[0] === '-';
    $s = ltrim($s, '+-');
    [$int, $frac] = array_pad(explode('.', $s, 2), 2, '');
    $frac = str_pad($frac, 3, '0');
    $cents = (int) $int * 100 + (int) substr($frac, 0, 2);
    if ((int) $frac[2] >= 5) $cents++;
    return $neg ? -$cents : $cents;
}

function cents_str(int $c): string
{
    return ($c < 0 ? '-' : '') . intdiv(abs($c), 100) . '.' . str_pad((string) (abs($c) % 100), 2, '0', STR_PAD_LEFT);
}

function cents_float($dbValue): float
{
    return (float) $dbValue;
}

/* ===================== Petición (JSON) ===================== */

function body(): array
{
    $raw = file_get_contents('php://input') ?: '';
    if (trim($raw) === '') return [];
    $v = json_decode($raw, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        fail('El cuerpo de la solicitud debe ser JSON válido.');
    }
    if (!is_dict($v)) {
        fail('El cuerpo de la solicitud debe ser un objeto JSON.');
    }
    return $v;
}

/* ===================== Contraseñas (formato de Django: pbkdf2_sha256) ===================== */

function password_check(string $password, string $encoded): bool
{
    $p = explode('$', $encoded, 4);
    if (count($p) !== 4 || $p[0] !== 'pbkdf2_sha256') return false;
    $calc = base64_encode(hash_pbkdf2('sha256', $password, $p[2], (int) $p[1], 0, true));
    return hash_equals($p[3], $calc);
}

function password_make(string $password): string
{
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    $salt = '';
    for ($i = 0; $i < 22; $i++) $salt .= $chars[random_int(0, 61)];
    $iter = 600000;
    return 'pbkdf2_sha256$' . $iter . '$' . $salt . '$' . base64_encode(hash_pbkdf2('sha256', $password, $salt, $iter, 0, true));
}

/* ===================== Sesión (cookie propia, igual idea que sessionid de Django) ===================== */

function is_https(): bool
{
    return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
}

function send_session_cookie(bool $remember): void
{
    setcookie((string) cfg('SESSION_NAME'), session_id(), [
        'expires'  => $remember ? time() + (int) cfg('SESSION_DAYS') * 86400 : 0,
        'path'     => '/',
        'httponly' => true,
        'samesite' => 'Lax',
        'secure'   => is_https(),
    ]);
}

function start_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) return;
    $path = (string) cfg('SESSION_PATH');
    if (!is_dir($path)) @mkdir($path, 0770, true);
    ini_set('session.use_cookies', '0');
    ini_set('session.use_only_cookies', '1');
    ini_set('session.use_strict_mode', '1');
    ini_set('session.gc_maxlifetime', (string) ((int) cfg('SESSION_DAYS') * 86400));
    ini_set('session.gc_probability', '1');
    ini_set('session.gc_divisor', '100');
    session_save_path($path);
    session_name((string) cfg('SESSION_NAME'));
    $sid = $_COOKIE[(string) cfg('SESSION_NAME')] ?? '';
    if ($sid !== '' && preg_match('/^[A-Za-z0-9,-]{22,128}$/', $sid)) session_id($sid);
    session_start();
    if (!empty($_SESSION['uid'])) send_session_cookie(!empty($_SESSION['remember']));
}

function session_hash(string $passwordHash): string
{
    return substr(hash_hmac('sha256', $passwordHash, (string) cfg('APP_SECRET')), 0, 32);
}

function login_user(array $user, bool $remember): void
{
    start_session();
    session_regenerate_id(true);
    $_SESSION['uid'] = (int) $user['id'];
    $_SESSION['hash'] = session_hash((string) $user['password']);
    $_SESSION['remember'] = $remember;
    send_session_cookie($remember);
    update('auth_user', (int) $user['id'], ['last_login' => now_sql()]);
}

function logout_user(): void
{
    start_session();
    $_SESSION = [];
    session_destroy();
    setcookie((string) cfg('SESSION_NAME'), '', ['expires' => 1, 'path' => '/', 'httponly' => true, 'samesite' => 'Lax']);
}

/** Usuario con sesión iniciada o null. */
function current_user(): ?array
{
    static $cache = false;
    if ($cache !== false) return $cache;
    start_session();
    $cache = null;
    if (!empty($_SESSION['uid'])) {
        $u = row('SELECT * FROM auth_user WHERE id=? AND is_active=1', [(int) $_SESSION['uid']]);
        if ($u && hash_equals(session_hash((string) $u['password']), (string) ($_SESSION['hash'] ?? ''))) {
            $cache = $u;
        }
    }
    return $cache;
}

/* ===================== CSRF (mismo esquema que Django: cookie csrftoken + cabecera X-CSRFToken) ===================== */

function csrf_token(): string
{
    $t = $_COOKIE['csrftoken'] ?? '';
    if (!preg_match('/^[A-Za-z0-9]{32,64}$/', $t)) {
        $t = bin2hex(random_bytes(32));
    }
    setcookie('csrftoken', $t, [
        'expires'  => time() + 365 * 86400,
        'path'     => '/',
        'httponly' => false,
        'samesite' => 'Lax',
        'secure'   => is_https(),
    ]);
    return $t;
}

function check_csrf(): void
{
    if (in_array($_SERVER['REQUEST_METHOD'], ['GET', 'HEAD', 'OPTIONS'], true)) return;
    $cookie = (string) ($_COOKIE['csrftoken'] ?? '');
    $header = (string) ($_SERVER['HTTP_X_CSRFTOKEN'] ?? '');
    if ($cookie === '' || !hash_equals($cookie, $header)) {
        fail('Falló la verificación CSRF. Recarga la página e inténtalo de nuevo.', 403);
    }
}

/* ===================== CORS (solo para desarrollo con otro puerto) ===================== */

function send_cors_headers(): void
{
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if ($origin !== '' && in_array($origin, (array) cfg('ALLOWED_ORIGINS'), true)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Allow-Headers: Content-Type, X-CSRFToken');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Vary: Origin');
    }
}
