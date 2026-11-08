-- =====================================================================
--  NEXO / MAGNUS SIG · Base de datos MySQL (esquema + datos iniciales)
-- =====================================================================
--  Ejecutar UNA sola vez en el servidor Ubuntu:
--      sudo mysql < SQL/01_crear_base_de_datos.sql
--  (o en MySQL Workbench: abrir este archivo y ejecutarlo con el rayo)
--
--  Las tablas y columnas son las mismas que creaba Django (auth_user y
--  productos_*): la estructura de la base de datos NO cambia, el backend
--  PHP lee y escribe exactamente las mismas tablas.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS nexo_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nexo_db;

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS auth_user (
  id           INT NOT NULL AUTO_INCREMENT,
  password     VARCHAR(128) NOT NULL,
  last_login   DATETIME(6) NULL,
  is_superuser TINYINT(1) NOT NULL DEFAULT 0,
  username     VARCHAR(150) NOT NULL,
  first_name   VARCHAR(150) NOT NULL DEFAULT '',
  last_name    VARCHAR(150) NOT NULL DEFAULT '',
  email        VARCHAR(254) NOT NULL DEFAULT '',
  is_staff     TINYINT(1) NOT NULL DEFAULT 0,
  is_active    TINYINT(1) NOT NULL DEFAULT 1,
  date_joined  DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_companyprofile (
  id            BIGINT NOT NULL AUTO_INCREMENT,
  company       VARCHAR(120) NOT NULL DEFAULT 'Magnus SIG S.A.S',
  role          VARCHAR(30) NOT NULL DEFAULT 'Asesor de ventas',
  dual          TINYINT(1) NOT NULL DEFAULT 0,
  granted_by_id INT NULL,
  user_id       INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY user_id (user_id),
  KEY granted_by_id (granted_by_id),
  CONSTRAINT fk_profile_user    FOREIGN KEY (user_id)       REFERENCES auth_user (id) ON DELETE CASCADE,
  CONSTRAINT fk_profile_granted FOREIGN KEY (granted_by_id) REFERENCES auth_user (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_client (
  id       BIGINT NOT NULL AUTO_INCREMENT,
  name     VARCHAR(150) NOT NULL,
  document VARCHAR(40) NOT NULL DEFAULT '—',
  phone    VARCHAR(40) NOT NULL DEFAULT '',
  user_id  INT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY user_id (user_id),
  CONSTRAINT fk_client_user FOREIGN KEY (user_id) REFERENCES auth_user (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_category (
  id   BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_product (
  id            BIGINT NOT NULL AUTO_INCREMENT,
  kind          VARCHAR(10) NOT NULL DEFAULT 'product',
  name          VARCHAR(120) NOT NULL,
  sku           VARCHAR(40) NOT NULL,
  category      VARCHAR(80) NOT NULL,
  description   LONGTEXT NOT NULL,
  cost          DECIMAL(12,2) NULL,
  price         DECIMAL(12,2) NOT NULL,
  stock         INT UNSIGNED NOT NULL DEFAULT 0,
  minimum_stock INT UNSIGNED NOT NULL DEFAULT 0,
  active        TINYINT(1) NOT NULL DEFAULT 1,
  image         LONGTEXT NULL,
  icon          VARCHAR(40) NOT NULL DEFAULT 'box',
  created_at    DATETIME(6) NOT NULL,
  updated_at    DATETIME(6) NOT NULL,
  owner_id      INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unique_product_sku_per_owner (owner_id, sku),
  CONSTRAINT fk_product_owner FOREIGN KEY (owner_id) REFERENCES auth_user (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_sale (
  id               BIGINT NOT NULL AUTO_INCREMENT,
  folio            VARCHAR(30) NOT NULL,
  customer         VARCHAR(150) NOT NULL DEFAULT 'Público general',
  customer_doc     VARCHAR(40) NOT NULL DEFAULT '',
  customer_phone   VARCHAR(40) NOT NULL DEFAULT '',
  advisor_name     VARCHAR(150) NOT NULL DEFAULT '',
  advisor_email    VARCHAR(150) NOT NULL DEFAULT '',
  advisor_role     VARCHAR(30) NOT NULL DEFAULT '',
  status           VARCHAR(15) NOT NULL DEFAULT 'Entregado',
  payment          VARCHAR(40) NOT NULL DEFAULT 'Efectivo',
  attended_by      VARCHAR(150) NOT NULL DEFAULT '',
  delivery_method  VARCHAR(20) NOT NULL DEFAULT '',
  delivery_city    VARCHAR(80) NOT NULL DEFAULT '',
  delivery_address VARCHAR(200) NOT NULL DEFAULT '',
  notes            VARCHAR(300) NOT NULL DEFAULT '',
  subtotal         DECIMAL(14,2) NOT NULL,
  tax              DECIMAL(14,2) NOT NULL,
  total            DECIMAL(14,2) NOT NULL,
  created_at       DATETIME(6) NOT NULL,
  client_id        BIGINT NULL,
  owner_id         INT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unique_sale_folio_per_owner (owner_id, folio),
  KEY client_id (client_id),
  CONSTRAINT fk_sale_client FOREIGN KEY (client_id) REFERENCES productos_client (id) ON DELETE SET NULL,
  CONSTRAINT fk_sale_owner  FOREIGN KEY (owner_id)  REFERENCES auth_user (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos_saleitem (
  id         BIGINT NOT NULL AUTO_INCREMENT,
  name       VARCHAR(120) NOT NULL DEFAULT '',
  sku        VARCHAR(40) NOT NULL DEFAULT '',
  quantity   INT UNSIGNED NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  product_id BIGINT NOT NULL,
  sale_id    BIGINT NOT NULL,
  PRIMARY KEY (id),
  KEY product_id (product_id),
  KEY sale_id (sale_id),
  CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES productos_product (id) ON DELETE RESTRICT,
  CONSTRAINT fk_item_sale    FOREIGN KEY (sale_id)    REFERENCES productos_sale (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
--  DATOS INICIALES (los mismos que cargaban las migraciones de Django)
--  Administrador:      ana@novacomercial.mx        clave: Nexo2026Demo
--  Superadministrador: superadmin@magnussig.com    clave: Magnus2026Super
--  (cambia las claves desde Administración > Usuarios al entregar el sistema)
-- =====================================================================

INSERT INTO auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES
 (1, 'pbkdf2_sha256$600000$Xk3mQ9vLpR2tWz7bN4cY8a$DqCovVKrBUbMo9J4wLGruc3h7ednZOvw2yzUohtUHyc=', NULL, 0, 'ana@novacomercial.mx', 'Ana Martínez', '', 'ana@novacomercial.mx', 0, 1, UTC_TIMESTAMP(6)),
 (2, 'pbkdf2_sha256$600000$Jd6hUe1sGf5oAq0iMn3xKb$RA1ohpPAIKOVIgTIKs9AeaYwwofzwtKviw/g0M1AwDg=', NULL, 0, 'superadmin@magnussig.com', 'Superadministrador', '', 'superadmin@magnussig.com', 0, 1, UTC_TIMESTAMP(6))
ON DUPLICATE KEY UPDATE username = username;

INSERT INTO productos_companyprofile (company, role, dual, granted_by_id, user_id) VALUES
 ('Magnus SIG S.A.S', 'Administrador', 1, NULL, 1),
 ('Magnus SIG S.A.S', 'Superadministrador', 0, NULL, 2)
ON DUPLICATE KEY UPDATE user_id = user_id;

INSERT IGNORE INTO productos_category (name) VALUES
 ('Camillas'),
 ('Botiquines'),
 ('Extintores'),
 ('Dotaciones'),
 ('Elementos de protección personal'),
 ('Gestión del SG-SST'),
 ('Capacitaciones'),
 ('Auditorías'),
 ('Evaluaciones y análisis');

INSERT IGNORE INTO productos_product (kind, name, sku, category, description, cost, price, stock, minimum_stock, active, image, icon, created_at, updated_at, owner_id) VALUES
 ('product', 'Camilla rígida de rescate con inmovilizador', 'CAM-001', 'Camillas', 'Camilla rígida en polietileno con correas de sujeción e inmovilizador de cabeza, para rescate y traslado de lesionados.', 390000.00, 549900.00, 8, 3, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Camilla plegable de emergencia', 'CAM-002', 'Camillas', 'Camilla plegable en aluminio, liviana y fácil de almacenar, con capacidad de hasta 150 kg.', 260000.00, 389900.00, 6, 2, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Botiquín portátil de primeros auxilios', 'BOT-001', 'Botiquines', 'Botiquín portátil con gasas, vendas, antisépticos, guantes y demás elementos básicos de primeros auxilios.', 85000.00, 129900.00, 25, 8, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Botiquín de pared con tapa metálica', 'BOT-002', 'Botiquines', 'Botiquín fijo en lámina metálica para áreas de trabajo, dotado con insumos de primeros auxilios.', 150000.00, 229900.00, 15, 5, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Extintor multipropósito ABC 10 lb', 'EXT-001', 'Extintores', 'Extintor de polvo químico seco ABC de 10 libras, para fuegos de sólidos, líquidos y equipos eléctricos.', 55000.00, 89900.00, 30, 10, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Extintor de CO2 10 lb', 'EXT-002', 'Extintores', 'Extintor de dióxido de carbono, ideal para equipos eléctricos y electrónicos sin dejar residuos.', 210000.00, 319900.00, 12, 4, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Extintor multipropósito ABC 20 lb', 'EXT-003', 'Extintores', 'Extintor de polvo químico seco ABC de 20 libras, para bodegas, talleres y áreas industriales.', 85000.00, 129900.00, 14, 5, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Overol industrial de dotación', 'DOT-001', 'Dotaciones', 'Overol en tela drill, resistente, con bolsillos y cierre frontal. Disponible en varias tallas.', 65000.00, 99900.00, 40, 10, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Botas de seguridad con punta de acero', 'DOT-002', 'Dotaciones', 'Botas de cuero con puntera de acero y suela antideslizante, para trabajo industrial y construcción.', 90000.00, 139900.00, 35, 10, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Casco de seguridad con barbuquejo', 'EPP-001', 'Elementos de protección personal', 'Casco industrial de polietileno con suspensión de 4 puntos y barbuquejo ajustable.', 18000.00, 29900.00, 60, 15, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Gafas de seguridad antiempañantes', 'EPP-002', 'Elementos de protección personal', 'Gafas de policarbonato con protección UV y tratamiento antiempañante.', 6000.00, 12900.00, 80, 20, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Guantes de nitrilo (caja x 100)', 'EPP-003', 'Elementos de protección personal', 'Guantes desechables de nitrilo sin polvo, caja de 100 unidades.', 28000.00, 44900.00, 20, 6, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Mascarilla N95 (caja x 20)', 'EPP-004', 'Elementos de protección personal', 'Respirador desechable N95 con filtración de partículas, caja de 20 unidades.', 45000.00, 69900.00, 0, 10, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('product', 'Protector auditivo tipo copa', 'EPP-005', 'Elementos de protección personal', 'Protector auditivo de copa con diadema ajustable, para ambientes con alto nivel de ruido.', 22000.00, 36900.00, 9, 10, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Diagnóstico inicial del SG-SST', 'SER-001', 'Gestión del SG-SST', 'Evaluación del estado actual del Sistema de Gestión de Seguridad y Salud en el Trabajo frente a los estándares mínimos.', NULL, 1200000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Diseño del SG-SST', 'SER-002', 'Gestión del SG-SST', 'Diseño del sistema: políticas, objetivos, matrices, procedimientos y formatos adaptados a la empresa.', NULL, 2800000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Implementación del SG-SST', 'SER-003', 'Gestión del SG-SST', 'Puesta en marcha del SG-SST con acompañamiento en sitio y capacitación al equipo responsable.', NULL, 4500000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Mantenimiento del SG-SST (mensual)', 'SER-004', 'Gestión del SG-SST', 'Seguimiento mensual al sistema: actualización de documentos, indicadores y planes de acción.', NULL, 900000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Administración del SG-SST (mensual)', 'SER-005', 'Gestión del SG-SST', 'Administración completa del SG-SST por parte de Magnus SIG, con informes periódicos a la gerencia.', NULL, 1500000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Asesoría en la implementación del SG-SST', 'SER-006', 'Gestión del SG-SST', 'Sesión de asesoría especializada para resolver dudas y orientar la implementación (por sesión).', NULL, 350000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Capacitación en primeros auxilios', 'CAP-001', 'Capacitaciones', 'Formación teórico-práctica en atención básica de emergencias y primeros auxilios (por grupo).', NULL, 650000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Capacitación en control de incendios', 'CAP-002', 'Capacitaciones', 'Uso de extintores, evacuación y respuesta ante conatos de incendio, con práctica (por grupo).', NULL, 650000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Capacitación en diagnóstico psicosocial', 'CAP-003', 'Capacitaciones', 'Formación para identificar y valorar los factores de riesgo psicosocial en la empresa (por grupo).', NULL, 780000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Intervención del riesgo psicosocial', 'CAP-004', 'Capacitaciones', 'Diseño y ejecución de acciones de intervención a partir de los resultados de la batería psicosocial.', NULL, 1350000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Capacitación en PESV', 'CAP-005', 'Capacitaciones', 'Formación en el Plan Estratégico de Seguridad Vial para conductores y responsables (por grupo).', NULL, 700000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Aplicación de batería de riesgo psicosocial', 'CAP-006', 'Capacitaciones', 'Aplicación y análisis de la batería de instrumentos de riesgo psicosocial (precio por trabajador).', NULL, 45000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Capacitaciones y entrenamientos en SST', 'CAP-007', 'Capacitaciones', 'Programa de capacitación y entrenamiento en seguridad y salud en el trabajo según las necesidades de la empresa.', NULL, 800000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría ISO 9001:2026', 'AUD-001', 'Auditorías', 'Auditoría del sistema de gestión de la calidad frente a la norma ISO 9001:2026.', NULL, 3200000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría ISO 14001:2026', 'AUD-002', 'Auditorías', 'Auditoría del sistema de gestión ambiental frente a la norma ISO 14001:2026.', NULL, 3200000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría ISO 45001:2026', 'AUD-003', 'Auditorías', 'Auditoría del sistema de gestión de seguridad y salud en el trabajo frente a la norma ISO 45001:2026.', NULL, 3500000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría a proveedores', 'AUD-004', 'Auditorías', 'Verificación del cumplimiento de requisitos de SST y calidad en proveedores y contratistas.', NULL, 1600000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría del PESV', 'AUD-005', 'Auditorías', 'Revisión del cumplimiento y la eficacia del Plan Estratégico de Seguridad Vial.', NULL, 1800000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Auditoría interna del SG-SST', 'AUD-006', 'Auditorías', 'Auditoría interna anual del SG-SST con informe de hallazgos y plan de mejora.', NULL, 2100000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Evaluación de riesgos laborales', 'EVA-001', 'Evaluaciones y análisis', 'Identificación de peligros, valoración de riesgos y definición de controles por área y cargo.', NULL, 1900000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Análisis de puesto de trabajo', 'EVA-002', 'Evaluaciones y análisis', 'Estudio del puesto para identificar exigencias, riesgos y recomendaciones ergonómicas (por puesto).', NULL, 450000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Profesiograma', 'EVA-003', 'Evaluaciones y análisis', 'Documento que define requisitos, exigencias y exámenes médicos por cargo (por cargo).', NULL, 380000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1),
 ('service', 'Gestión de exámenes médicos ocupacionales', 'EVA-004', 'Evaluaciones y análisis', 'Coordinación y seguimiento de exámenes de ingreso, periódicos y de egreso (precio por trabajador).', NULL, 85000.00, 0, 0, 1, NULL, 'box', UTC_TIMESTAMP(6), UTC_TIMESTAMP(6), 1);

INSERT INTO productos_client (name, document, phone, user_id)
SELECT name, document, phone, user_id FROM (
 SELECT 'Público general' AS name, '—' AS document, '' AS phone, NULL AS user_id
 UNION ALL
 SELECT 'Constructora Andina S.A.S' AS name, '900123456-1' AS document, '608 871 2345' AS phone, NULL AS user_id
 UNION ALL
 SELECT 'Transportes del Huila Ltda' AS name, '891234567-4' AS document, '608 875 4410' AS phone, NULL AS user_id
 UNION ALL
 SELECT 'Clínica Los Rosales S.A.S' AS name, '901234567-8' AS document, '310 456 7821' AS phone, NULL AS user_id
 UNION ALL
 SELECT 'Agroindustrias del Sur S.A.S' AS name, '900765432-2' AS document, '320 118 4490' AS phone, NULL AS user_id
) AS seed WHERE NOT EXISTS (SELECT 1 FROM productos_client);

SELECT 'Base nexo_db lista' AS estado, (SELECT COUNT(*) FROM productos_product) AS productos, (SELECT COUNT(*) FROM productos_client) AS clientes, (SELECT COUNT(*) FROM auth_user) AS usuarios;

-- Productos que ya no se venden (no deben volver a aparecer)
DELETE FROM productos_product
 WHERE (LOWER(name) LIKE '%anillo%' OR (LOWER(name) LIKE '%televisor%' AND LOWER(name) LIKE '%4k%'))
   AND id NOT IN (SELECT product_id FROM productos_saleitem);
UPDATE productos_product SET active = 0, stock = 0
 WHERE LOWER(name) LIKE '%anillo%' OR (LOWER(name) LIKE '%televisor%' AND LOWER(name) LIKE '%4k%');
DROP TABLE IF EXISTS productos_teammember;
