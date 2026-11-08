<?php
// Página de prueba LAMP (Actividad Semana 13). Bórrala cuando termines la práctica.
$cfg = require dirname(__DIR__) . '/app/config.php';
$db = 'sin probar';
try {
    $pdo = new PDO(sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $cfg['DB_HOST'], $cfg['DB_PORT'], $cfg['DB_NAME']), $cfg['DB_USER'], $cfg['DB_PASSWORD'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $n = $pdo->query('SELECT COUNT(*) FROM productos_product')->fetchColumn();
    $db = "✅ Conectado a MySQL ({$pdo->getAttribute(PDO::ATTR_SERVER_VERSION)}) · productos en el catálogo: $n";
} catch (Throwable $e) {
    $db = '❌ No se pudo conectar a la base de datos: ' . htmlspecialchars($e->getMessage());
}
$ok = fn($b) => $b ? '✅' : '❌';
?><!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Prueba LAMP · Magnus SIG</title>
<style>body{font:16px/1.5 system-ui,sans-serif;max-width:720px;margin:40px auto;padding:0 16px;color:#16302b}
h1{color:#0f7a4d}table{border-collapse:collapse;width:100%}td{border:1px solid #cfe3da;padding:8px 10px}td:first-child{background:#eef7f2;font-weight:600;width:42%}</style></head>
<body>
<h1>🌐 Servidor LAMP funcionando</h1>
<p>Si ves esta página, Apache está entregando páginas dinámicas con PHP.</p>
<table>
<tr><td>Sistema operativo (Linux)</td><td><?= htmlspecialchars(php_uname('s') . ' ' . php_uname('r')) ?></td></tr>
<tr><td>Servidor web (Apache)</td><td><?= htmlspecialchars($_SERVER['SERVER_SOFTWARE'] ?? 'desconocido') ?></td></tr>
<tr><td>PHP</td><td><?= PHP_VERSION ?> · interfaz: <?= php_sapi_name() ?></td></tr>
<tr><td>Extensión pdo_mysql</td><td><?= $ok(extension_loaded('pdo_mysql')) ?></td></tr>
<tr><td>Extensión mbstring</td><td><?= $ok(extension_loaded('mbstring')) ?></td></tr>
<tr><td>Base de datos (MySQL)</td><td><?= $db ?></td></tr>
<tr><td>Fecha y hora del servidor</td><td><?= date('d/m/Y H:i:s') ?> (<?= date_default_timezone_get() ?>)</td></tr>
<tr><td>Dirección del cliente</td><td><?= htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? '') ?></td></tr>
</table>
<p><a href="/">Ir a la aplicación Nexo →</a></p>
</body></html>
