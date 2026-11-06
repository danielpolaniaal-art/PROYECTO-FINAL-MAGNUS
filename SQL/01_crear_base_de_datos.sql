-- =====================================================================
--  NEXO · PASO 1: crear la base de datos en MySQL Workbench
-- =====================================================================
--  Ejecútalo UNA sola vez, ANTES de arrancar el proyecto:
--    File > Open SQL Script... > este archivo > rayo (Ctrl+Shift+Enter)
--
--  Después, en la terminal (carpeta donde está manage.py):
--      python manage.py migrate
--  Django crea las tablas dentro de nexo_db (productos, usuarios, roles,
--  ventas...) y deja creado el administrador inicial.
--
--  Siguiente archivo: 02_consultas_y_pruebas.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS nexo_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- (Opcional) Usuario propio para el proyecto, en lugar de usar "root".
-- Quita los "--" del inicio de las 3 líneas, ejecútalas y pon ese mismo
-- usuario y contraseña en settings.py.
-- CREATE USER IF NOT EXISTS 'nexo_user'@'localhost' IDENTIFIED BY 'CambiaEstaClave123';
-- GRANT ALL PRIVILEGES ON nexo_db.* TO 'nexo_user'@'localhost';
-- FLUSH PRIVILEGES;

SHOW DATABASES;
