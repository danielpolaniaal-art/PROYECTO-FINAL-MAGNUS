<?php
/**
 * Configuración del backend PHP de Nexo (Magnus SIG).
 * Equivale al settings.py de la versión Django: mismos nombres de base, mismos códigos.
 *
 * Los valores se pueden sobrescribir con variables de entorno (SetEnv en Apache)
 * o con el archivo app/config.local.php (recomendado en el servidor: ahí va la clave real).
 */
$config = [
    'DB_HOST'     => getenv('DB_HOST') ?: '127.0.0.1',
    'DB_PORT'     => getenv('DB_PORT') ?: '3306',
    'DB_NAME'     => getenv('DB_NAME') ?: 'nexo_db',
    'DB_USER'     => getenv('DB_USER') ?: 'nexo_user',
    'DB_PASSWORD' => getenv('DB_PASSWORD') ?: 'CambiaEstaClave123',

    // Códigos para registrarse desde la pantalla pública con estos roles (igual que en Django).
    'AUTH_CODES' => [
        'Supervisor'         => getenv('CODE_SUPERVISOR') ?: 'SUP-2026',
        'Administrador'      => getenv('CODE_ADMIN') ?: 'ADM-2026',
        'Superadministrador' => getenv('CODE_SUPER') ?: 'SUPER-2026',
    ],

    // Clave para firmar la sesión. Cámbiala (install_lamp.sh la genera sola).
    'APP_SECRET' => getenv('APP_SECRET') ?: 'cambia-esta-clave-larga-y-aleatoria',

    'SESSION_DAYS' => 14,                                  // "Recordarme" (2 semanas, como Django)
    'SESSION_NAME' => 'nexo_sid',
    'SESSION_PATH' => __DIR__ . '/storage/sessions',        // carpeta propia: Ubuntu limpia /var/lib/php/sessions cada 24 min

    // Orígenes que pueden llamar a la API desde otro puerto (solo desarrollo). En producción todo es mismo origen.
    'ALLOWED_ORIGINS' => [
        'http://localhost:5173', 'http://127.0.0.1:5173',
        'http://localhost:5500', 'http://127.0.0.1:5500',
    ],

    'DEBUG' => false,
];

if (is_file(__DIR__ . '/config.local.php')) {
    $local = require __DIR__ . '/config.local.php';
    if (is_array($local)) {
        $config = array_replace_recursive($config, $local);
    }
}

return $config;
