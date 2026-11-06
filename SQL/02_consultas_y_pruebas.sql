-- =====================================================================
--  NEXO · PASO 2: ver y administrar los datos desde MySQL Workbench
-- =====================================================================
--  Ejecútalo DESPUÉS de "python manage.py migrate".
--  IMPORTANTE: ejecuta UNA instrucción a la vez (cursor sobre ella y
--  Ctrl+Enter). No lo ejecutes completo: incluye INSERT/UPDATE/DELETE
--  de prueba.
--
--  Tablas que creó Django:
--    productos_product ........ PRODUCTOS (nombre, sku, categoría, costo,
--                               precio, stock, stock mínimo, activo...)
--    auth_user ................ USUARIOS (nombre, correo, contraseña cifrada)
--    productos_companyprofile . ROL de cada usuario (columna "role":
--                               'Administrador' o 'Usuario') y su empresa
--    productos_sale / productos_saleitem .. VENTAS y su detalle
--    productos_teammember ..... tabla original de "equipo" (ya no se
--                               muestra en pantalla; se conserva)
--    django_*, auth_* ......... tablas internas de Django
-- =====================================================================

USE nexo_db;

-- ---------------------------------------------------------------------
-- A. COMPROBAR que todo se creó
-- ---------------------------------------------------------------------
SHOW TABLES;
DESCRIBE productos_product;
DESCRIBE productos_companyprofile;

-- ---------------------------------------------------------------------
-- B. USUARIOS registrados con su rol
--    (el administrador inicial es ana@novacomercial.mx / Nexo2026Demo)
-- ---------------------------------------------------------------------
SELECT u.id, u.first_name AS nombre, u.email AS correo,
       p.role AS rol, p.company AS empresa, u.last_login AS ultimo_acceso
FROM auth_user u
LEFT JOIN productos_companyprofile p ON p.user_id = u.id
ORDER BY u.id;

-- ---------------------------------------------------------------------
-- C. PRODUCTOS
-- ---------------------------------------------------------------------
SELECT id, name AS nombre, sku, category AS categoria,
       cost AS costo, price AS precio, stock, minimum_stock AS stock_minimo,
       active AS activo
FROM productos_product
ORDER BY id;

-- ---------------------------------------------------------------------
-- D. VENTAS
-- ---------------------------------------------------------------------
SELECT s.id, s.folio, s.customer AS cliente, s.total, s.created_at,
       u.email AS vendedor
FROM productos_sale s
JOIN auth_user u ON u.id = s.owner_id
ORDER BY s.id DESC;

-- ---------------------------------------------------------------------
-- E. ROLES: crear un administrador o volver a alguien usuario normal
--    Primero el usuario debe existir (registrado en la página).
--    Cambia el correo antes de ejecutar.
-- ---------------------------------------------------------------------
-- Convertir en ADMINISTRADOR:
UPDATE productos_companyprofile
SET role = 'Administrador'
WHERE user_id = (SELECT id FROM auth_user WHERE email = 'correo_del_usuario@ejemplo.com');

-- Volver a USUARIO NORMAL:
UPDATE productos_companyprofile
SET role = 'Usuario'
WHERE user_id = (SELECT id FROM auth_user WHERE email = 'correo_del_usuario@ejemplo.com');

-- ---------------------------------------------------------------------
-- F. PRUEBA: cambiar datos aquí y verlos en la página
--    (recarga la página del frontend después de cada instrucción)
-- ---------------------------------------------------------------------
-- Cambiar el stock de un producto:
UPDATE productos_product SET stock = 99 WHERE sku = 'ELE-001';

-- Agregar un producto (el dueño será el administrador inicial):
INSERT INTO productos_product
    (name, sku, category, description, cost, price, stock, minimum_stock,
     active, image, icon, created_at, updated_at, owner_id)
VALUES
    ('Producto desde Workbench', 'WB-001', 'Accesorios', '', 10.00, 20.00, 5, 2,
     1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6),
     (SELECT id FROM auth_user WHERE email = 'ana@novacomercial.mx'));

-- Eliminar ese producto de prueba:
DELETE FROM productos_product WHERE sku = 'WB-001';


-- ---------------------------------------------------------------------
-- MAGNUS SIG: consultas de las tablas nuevas (solo lectura)
-- ---------------------------------------------------------------------

-- Usuarios con rol, acceso dual y quién les dio el rol
SELECT u.id, u.first_name AS nombre, u.email AS correo, p.role AS rol,
       p.dual AS acceso_dual, g.email AS rol_dado_por
FROM auth_user u
JOIN productos_companyprofile p ON p.user_id = u.id
LEFT JOIN auth_user g ON g.id = p.granted_by_id
ORDER BY u.id;

-- Categorías y cuántos productos/servicios tiene cada una
SELECT c.name AS categoria, COUNT(p.id) AS cantidad
FROM productos_category c
LEFT JOIN productos_product p ON p.category = c.name
GROUP BY c.name ORDER BY c.name;

-- Catálogo (productos y servicios)
SELECT id, kind AS tipo, sku AS codigo, name AS nombre, category AS categoria,
       price AS precio, stock, description AS descripcion
FROM productos_product ORDER BY category, name;

-- Clientes
SELECT id, name AS nombre, document AS documento, phone AS telefono, user_id
FROM productos_client;

-- Historial de ventas con cliente, asesor, estado y quién atendió
SELECT folio, created_at AS fecha, customer AS cliente, customer_doc AS documento,
       advisor_name AS asesor, advisor_role AS rol_asesor, status AS estado,
       attended_by AS atendido_por, payment AS pago, subtotal, tax AS iva, total
FROM productos_sale ORDER BY created_at DESC;

-- Detalle de cada venta
SELECT s.folio, i.sku AS codigo, i.name AS producto, i.quantity AS cantidad,
       i.unit_price AS precio_unitario, i.quantity * i.unit_price AS subtotal
FROM productos_saleitem i JOIN productos_sale s ON s.id = i.sale_id
ORDER BY s.id DESC;
