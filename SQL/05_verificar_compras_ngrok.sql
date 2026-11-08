-- =====================================================================
--  NEXO · PASO 5: verificar en MySQL Workbench las compras hechas por ngrok
-- =====================================================================
--  Solo lee datos (SELECT), salvo la sección OPCIONAL del final.
--  Ejecuta UNA instrucción a la vez (cursor sobre ella y Ctrl+Enter).
--  Nombres de tabla confirmados en models.py / migraciones del proyecto.
-- =====================================================================

USE nexo_db;

-- ---------------------------------------------------------------------
-- 0. ANTES de la compra de prueba: anota el stock del producto que vas a comprar
-- ---------------------------------------------------------------------
SELECT id, sku, name AS producto, stock, updated_at
FROM productos_product
WHERE kind = 'product'
ORDER BY name;

-- ---------------------------------------------------------------------
-- 1. Usuarios registrados desde la página (los más recientes primero)
--    El que se registró desde el otro dispositivo debe aparecer aquí.
-- ---------------------------------------------------------------------
SELECT u.id, u.first_name AS nombre, u.email AS correo, p.role AS rol,
       u.date_joined AS registrado, u.last_login AS ultimo_ingreso
FROM auth_user u
LEFT JOIN productos_companyprofile p ON p.user_id = u.id
ORDER BY u.id DESC
LIMIT 20;

-- ---------------------------------------------------------------------
-- 2. Ventas más recientes y A QUÉ USUARIO pertenece cada una
--    owner_id / usuario_que_compro = cuenta con la que se inició sesión.
--    origen 'Autoservicio' = compra hecha por un cliente en la tienda en línea.
-- ---------------------------------------------------------------------
SELECT s.id, s.folio, s.created_at AS fecha, s.status AS estado, s.total,
       s.owner_id, u.email AS usuario_que_compro,
       c.name AS cliente, c.document AS documento,
       s.advisor_role AS origen
FROM productos_sale s
LEFT JOIN auth_user u ON u.id = s.owner_id
LEFT JOIN productos_client c ON c.id = s.client_id
ORDER BY s.id DESC
LIMIT 20;

-- ---------------------------------------------------------------------
-- 3. Detalle (productos y cantidades) de las 5 ventas más recientes
-- ---------------------------------------------------------------------
SELECT s.folio, u.email AS usuario_que_compro, i.sku, i.name AS producto,
       i.quantity AS cantidad, i.unit_price AS precio_unitario
FROM productos_saleitem i
JOIN productos_sale s ON s.id = i.sale_id
LEFT JOIN auth_user u ON u.id = s.owner_id
WHERE s.id IN (SELECT id FROM (SELECT id FROM productos_sale ORDER BY id DESC LIMIT 5) t)
ORDER BY s.id DESC, i.id;

-- ---------------------------------------------------------------------
-- 4. DESPUÉS de la compra: el stock debe haber bajado la cantidad comprada
--    (compara con la consulta 0). Una venta Anulada devuelve el stock.
-- ---------------------------------------------------------------------
SELECT id, sku, name AS producto, stock, updated_at
FROM productos_product
WHERE kind = 'product'
ORDER BY updated_at DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 5. Control de consistencia: compras en línea cuyo "usuario dueño" NO coincide
--    con el usuario del cliente. DEBE devolver 0 filas.
-- ---------------------------------------------------------------------
SELECT s.id, s.folio, s.owner_id, c.user_id AS usuario_del_cliente
FROM productos_sale s
JOIN productos_client c ON c.id = s.client_id
WHERE s.advisor_role = 'Autoservicio'
  AND NOT (s.owner_id <=> c.user_id);

-- ---------------------------------------------------------------------
-- 6. Contraseñas: solo se guarda el hash, nunca el texto (debe empezar por pbkdf2_)
-- ---------------------------------------------------------------------
SELECT email, LEFT(password, 14) AS inicio_del_hash FROM auth_user ORDER BY id DESC LIMIT 5;

-- ---------------------------------------------------------------------
-- 7. SEGURIDAD DE LA BASE: ¿MySQL acepta conexiones desde otros equipos?
--    Si bind_address es '*' o '0.0.0.0', MySQL escucha en toda la red local.
--    ngrok NO lo expone a Internet (solo túnel al puerto 8000), pero conviene
--    dejarlo en 127.0.0.1 (ver README, sección ngrok).
-- ---------------------------------------------------------------------
SHOW VARIABLES LIKE 'bind_address';
SELECT user, host FROM mysql.user ORDER BY user, host;   -- ¿hay cuentas con host '%'?

-- ---------------------------------------------------------------------
-- 8. OPCIONAL (recomendado): usuario propio para Django en vez de root.
--    Cambia CLAVE_FUERTE y ejecútalo como root. Luego en PowerShell:
--       $env:DB_USER = "nexo_app" ; $env:DB_PASSWORD = "CLAVE_FUERTE"
--    (el permiso sobre test_nexo_db es solo para "python manage.py test")
-- ---------------------------------------------------------------------
-- CREATE USER 'nexo_app'@'localhost' IDENTIFIED BY 'CLAVE_FUERTE';
-- GRANT ALL PRIVILEGES ON nexo_db.* TO 'nexo_app'@'localhost';
-- GRANT ALL PRIVILEGES ON test_nexo_db.* TO 'nexo_app'@'localhost';
-- FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- 9. ¿Cuántos Superadministradores hay? Debe ser 1 (superadmin@magnussig.com).
--    Si aparece más de uno, avísame antes de cambiar nada.
-- ---------------------------------------------------------------------
SELECT u.id, u.email, p.role
FROM productos_companyprofile p
JOIN auth_user u ON u.id = p.user_id
WHERE p.role = 'Superadministrador';
