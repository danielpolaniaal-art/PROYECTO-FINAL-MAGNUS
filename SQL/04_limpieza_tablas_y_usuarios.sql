-- =====================================================================
-- 04 · Limpieza de la base nexo_db  (ejecutar en MySQL Workbench)
-- Deja solo las tablas que el sistema usa de verdad.
-- Úsalo si ya habías corrido "python manage.py migrate" antes.
-- (Si haces "migrate" con este proyecto nuevo, la migración 0008 hace lo mismo.)
-- =====================================================================
USE nexo_db;

-- 1) Tablas que no usa el proyecto (siempre estaban vacías)
DROP TABLE IF EXISTS django_admin_log;     -- panel /admin de Django (ya no se usa)
DROP TABLE IF EXISTS django_session;       -- ahora la sesión va firmada en la cookie
DROP TABLE IF EXISTS productos_teammember; -- equipo antiguo, sin uso

-- 2) Productos que ya no se venden
DELETE FROM productos_product
 WHERE (LOWER(name) LIKE '%anillo%' OR (LOWER(name) LIKE '%televisor%' AND LOWER(name) LIKE '%4k%'))
   AND id NOT IN (SELECT product_id FROM productos_saleitem);
UPDATE productos_product SET active = 0, stock = 0
 WHERE LOWER(name) LIKE '%anillo%' OR (LOWER(name) LIKE '%televisor%' AND LOWER(name) LIKE '%4k%');

-- 3) Ver los usuarios que se han creado (AQUÍ aparecen los que inician sesión nuevos):
--    el usuario vive en auth_user y su rol en productos_companyprofile.
SELECT u.id, u.first_name AS nombre, u.email, p.role AS rol, p.dual AS entra_como_usuario, u.last_login, u.date_joined
  FROM auth_user u
  LEFT JOIN productos_companyprofile p ON p.user_id = u.id
 ORDER BY u.id;

-- 4) Los clientes registrados (solo los usuarios con rol Cliente)
SELECT c.id, c.name, c.document, c.phone, c.user_id FROM productos_client c ORDER BY c.id;

-- 5) Tablas que quedan
SHOW TABLES;
