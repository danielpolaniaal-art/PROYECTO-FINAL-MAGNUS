<?php
// Solo para probar SIN Apache (desde la carpeta Proyecto_Aula_Final_Magnus):
//   php -S 0.0.0.0:8080 -t "nexo FRONTEND/nexo" LAMP_Ubuntu/deploy/dev-router.php
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (strncmp($path, '/api', 4) === 0) { require __DIR__ . '/../public/api/index.php'; return true; }
if ($path === '/prueba.php') { require __DIR__ . '/../public/prueba.php'; return true; }
return false;
