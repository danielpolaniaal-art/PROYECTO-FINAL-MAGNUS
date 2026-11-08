<?php
declare(strict_types=1);

/**
 * Punto de entrada de la API de Nexo (PHP).
 * Apache redirige todo /api/... a este archivo (ver .htaccess y deploy/nexo.conf).
 * Rutas idénticas a las de Django (productos/urls.py).
 */

ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);

$APP = dirname(__DIR__, 2) . '/app';
$CONFIG = require $APP . '/config.php';
require $APP . '/lib/core.php';
require $APP . '/lib/handlers.php';

send_cors_headers();

try {
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }

    /* ---- ruta solicitada, relativa a /api/ ---- */
    $uri = (string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    $pos = strpos($uri, '/api');
    $path = $pos === false ? $uri : substr($uri, $pos + 4);
    $path = trim(rawurldecode($path), '/');
    if (strncmp($path, 'index.php', 9) === 0) {
        $path = trim(substr($path, 9), '/');
    }

    $AUTH = 'auth';
    $ADMINS = [ROLE_ADMIN, ROLE_SUPER];

    /* [métodos, patrón, quién puede entrar, función] */
    $routes = [
        [['GET'],           '#^$#',                               null,         fn($u, $a) => h_root()],
        [['GET'],           '#^auth/csrf$#',                      null,         fn($u, $a) => h_csrf()],
        [['GET'],           '#^auth/session$#',                   null,         fn($u, $a) => h_session($u)],
        [['POST'],          '#^auth/login$#',                     null,         fn($u, $a) => h_login()],
        [['POST'],          '#^auth/register$#',                  null,         fn($u, $a) => h_register()],
        [['POST'],          '#^auth/logout$#',                    null,         fn($u, $a) => h_logout()],

        [['GET'],           '#^products$#',                       $AUTH,        fn($u, $a) => h_products($u)],
        [['POST'],          '#^products/create$#',                CATALOG_ROLES, fn($u, $a) => h_product_create($u)],
        [['PUT', 'PATCH'],  '#^products/(?<id>\d+)$#',            CATALOG_ROLES, fn($u, $a) => h_product_update($u, $a)],
        [['DELETE'],        '#^products/(?<id>\d+)/delete$#',     CATALOG_ROLES, fn($u, $a) => h_product_delete($u, $a)],

        [['GET'],           '#^sales$#',                          $AUTH,        fn($u, $a) => h_sales($u)],
        [['POST'],          '#^sales/create$#',                   SALE_ROLES,   fn($u, $a) => h_sale_create($u)],
        [['POST'],          '#^sales/(?<folio>[^/]+)/status$#',   $AUTH,        fn($u, $a) => h_sale_status($u, $a)],

        [['GET'],           '#^categories$#',                     $AUTH,        fn($u, $a) => h_categories()],
        [['POST'],          '#^categories/create$#',              CATALOG_ROLES, fn($u, $a) => h_category_create()],

        [['GET'],           '#^clients$#',                        STAFF_SALES,  fn($u, $a) => h_clients()],
        [['POST'],          '#^clients/create$#',                 STAFF_SALES,  fn($u, $a) => h_client_create()],


        [['GET'],           '#^users$#',                          $ADMINS,      fn($u, $a) => h_users()],
        [['POST'],          '#^users/create$#',                   [ROLE_ADMIN, ROLE_SUPER], fn($u, $a) => h_user_create($u)],
        [['PUT', 'PATCH'],  '#^users/(?<id>\d+)$#',              $ADMINS,      fn($u, $a) => h_user_update($u, $a)],
        [['DELETE'],        '#^users/(?<id>\d+)/delete$#',        $ADMINS,      fn($u, $a) => h_user_delete($u, $a)],
        // La pantalla de Administración llama DELETE /api/users/<id>/ : se acepta también aquí.
        [['DELETE'],        '#^users/(?<id>\d+)$#',               $ADMINS,      fn($u, $a) => h_user_delete($u, $a)],
    ];

    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $pathMatched = false;
    $chosen = null;
    $args = [];
    foreach ($routes as [$methods, $pattern, $who, $fn]) {
        if (preg_match($pattern, $path, $m)) {
            $pathMatched = true;
            if (in_array($method, $methods, true)) {
                $chosen = [$who, $fn];
                $args = array_filter($m, 'is_string', ARRAY_FILTER_USE_KEY);
                break;
            }
        }
    }
    if (!$pathMatched) fail('Ruta no encontrada.', 404);

    check_csrf();

    if ($chosen === null) fail('Método no permitido.', 405);
    [$who, $fn] = $chosen;

    $user = null;
    if ($who !== null) {
        $user = current_user();
        if (!$user) fail('Debes iniciar sesión.', 401);
        if (is_array($who) && !in_array(role_of($user), $who, true)) {
            fail('Tu rol no tiene permiso para realizar esta acción.', 403);
        }
    } else {
        $user = current_user();
    }

    $fn($user, $args);
    fail('La ruta no devolvió respuesta.', 500);
} catch (ApiError $e) {
    respond(['error' => $e->getMessage()], $e->status);
} catch (Throwable $e) {
    error_log('[nexo-api] ' . get_class($e) . ': ' . $e->getMessage() . ' en ' . $e->getFile() . ':' . $e->getLine());
    $msg = 'Error interno del servidor.';
    if ($e instanceof PDOException && stripos($e->getMessage(), 'SQLSTATE[HY000] [') === 0) {
        $msg = 'No se pudo conectar con la base de datos. Revisa app/config.local.php.';
    }
    if (cfg('DEBUG')) $msg .= ' ' . $e->getMessage();
    respond(['error' => $msg], 500);
}
