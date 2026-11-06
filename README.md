# Proyecto de Aula Final Magnus · Magnus SIG S.A.S · Sistema de inventario y ventas (Nexo)

Proyecto de aula. Aplicación web con **frontend**, **API REST** y base de datos **MySQL**. Se puede ejecutar de dos formas:

- **Versión Django (local + ngrok):** el backend en Python/Django se ejecuta en tu equipo y se publica en internet con un enlace de **ngrok**.
- **Versión LAMP (Ubuntu Server):** el mismo backend reescrito en PHP para desplegarlo en Apache + MySQL (ver `LAMP_Ubuntu/README_LAMP.md`).

| Capa          | Tecnología                                              |
|---------------|---------------------------------------------------------|
| Frontend      | HTML, CSS y JavaScript (sin frameworks)                 |
| Backend / API | Python + Django 5.2 (JSON) · alternativa en PHP (LAMP)  |
| Base de datos | MySQL 8 (base `nexo_db`)                                |
| Acceso remoto | ngrok (enlace HTTPS hacia el servidor local)            |

## Estructura

```
Proyecto_Aula_Final_Magnus/
├── README.md
├── .gitignore
├── SQL/
│   ├── 01_crear_base_de_datos.sql          ← crea la base nexo_db
│   ├── 02_consultas_y_pruebas.sql          ← consultas para verificar datos en Workbench
│   ├── 03_ubuntu_php_esquema_y_datos.sql   ← esquema y datos para la versión Ubuntu + PHP
│   ├── 04_limpieza_tablas_y_usuarios.sql   ← limpieza de tablas y usuarios
│   └── 05_verificar_compras_ngrok.sql      ← verifica las compras hechas desde el enlace de ngrok
├── Aula_Project BACKEND/
│   ├── requirements.txt
│   └── aula/                               ← aquí está manage.py
│       ├── aula/                           ← settings.py, urls.py, middleware.py, wsgi/asgi
│       └── productos/                      ← modelos, vistas (API), rutas y migraciones (0001 a 0008)
├── LAMP_Ubuntu/                            ← versión PHP para Apache + MySQL en Ubuntu Server
│   ├── README_LAMP.md                      ← guía de instalación en Ubuntu
│   ├── app/                                ← config.php, lib/ (core y handlers), storage/sessions
│   ├── deploy/                             ← install_lamp.sh, nexo.conf, smoke_test.sh, dev-router.php
│   └── public/                             ← punto de entrada web (api/index.php, prueba.php)
└── nexo FRONTEND/nexo/                     ← index.html, app.js, styles.css, img/
```

## Requisitos

- Python 3.10 o superior
- MySQL Server 8 y MySQL Workbench, con el servidor encendido
- Un navegador
- Una cuenta gratuita en [ngrok](https://ngrok.com) con su programa instalado (solo si quieres compartir el enlace)
- Windows PowerShell (los comandos de este README son para PowerShell)

## Instalación y ejecución (versión Django)

### 1. Crear la base de datos

En MySQL Workbench abre `SQL/01_crear_base_de_datos.sql` y ejecútalo (rayo). Crea la base `nexo_db`.

### 2. Configurar la contraseña de MySQL

Abre `Aula_Project BACKEND/aula/aula/settings.py`, busca `DB_PASSWORD` (sección `DATABASES`) y cambia `'xxxx'` por la contraseña de tu usuario de MySQL (por defecto el usuario es `root`, host `127.0.0.1`, puerto `3306`).

> La contraseña es tuya: no la subas a GitHub.

### 3. Backend (Terminal 1) powershell

```powershell
cd "C:\Users\PC\Downloads\Proyecto_Aula_Final_Magnus_NGROK\Proyecto_Aula_Final_Magnus\Aula_Project BACKEND"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\venv\Scripts\Activate.ps1
cd aula
$env:NEXO_HTTPS = "1"
python manage.py runserver 127.0.0.1:8000
```

> Cambia la ruta del primer comando por la ruta donde tengas la carpeta `Aula_Project BACKEND` en tu equipo.

- `Set-ExecutionPolicy ... Bypass` solo afecta a esa ventana de PowerShell y permite activar el entorno virtual.
- `$env:NEXO_HTTPS = "1"` activa el modo HTTPS, necesario para entrar por el enlace seguro de ngrok.

**Solo la primera vez**, antes de encender el servidor, crea el entorno virtual, instala las dependencias y crea las tablas:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd aula
python manage.py migrate
```

`migrate` crea las tablas en `nexo_db`, los usuarios de demostración, 9 categorías, 37 productos y servicios de Magnus SIG y 5 clientes de ejemplo.

> Si ya habías ejecutado `migrate` con una versión anterior, vuelve a ejecutarlo: aplica las migraciones nuevas (hasta `0008_limpieza`), convierte el rol viejo "Usuario" en "Asesor de ventas" y retira los productos de electrónica de ejemplo.

### 4. ngrok (Terminal 2)

Abre otra terminal con el **+** junto a powershell y ejecuta:

```powershell
ngrok http 127.0.0.1:8000
```

La primera vez, registra tu token de ngrok (lo ves en tu panel de ngrok):

```powershell
ngrok config add-authtoken TU_TOKEN
```

En la pantalla de ngrok mira la línea **Forwarding**, por ejemplo:

```
https://xxxx-xxxx-xxxx.ngrok-free.dev -> http://127.0.0.1:8000
```

Ese enlace `https://...ngrok-free.dev` es el que abres y compartes para usar la aplicación desde cualquier equipo. Notas:

- Deja **las dos terminales abiertas**: si cierras alguna, el enlace deja de funcionar.
- En el plan gratuito el enlace **cambia cada vez** que reinicias ngrok.
- ngrok muestra el tráfico en vivo en `http://127.0.0.1:4040`.
- Para detener ngrok o el servidor, presiona `Ctrl + C` en su terminal.

### 5. Abrir la aplicación

- Desde el enlace de ngrok (cualquier equipo), o
- Desde tu equipo: [http://127.0.0.1:8000](http://127.0.0.1:8000)

Para comprobar que la API responde, entra a la dirección raíz del servidor: debe mostrar el mensaje de API activa.

## Versión LAMP (Ubuntu Server)

La carpeta `LAMP_Ubuntu/` contiene el backend en PHP para correr sobre Apache + MySQL:

- `deploy/install_lamp.sh`: instala y configura Apache, PHP y MySQL.
- `deploy/nexo.conf`: configuración del sitio en Apache.
- `deploy/smoke_test.sh`: prueba rápida para verificar que todo quedó funcionando.
- `deploy/dev-router.php`: servidor de desarrollo de PHP para probar sin Apache.
- `app/config.php`: configuración; los valores se pueden sobrescribir con variables de entorno o con `app/config.local.php` (copia de `config.local.php.example`, recomendado en el servidor).
- `public/prueba.php`: página de prueba para confirmar que Apache ejecuta PHP.
- `SQL/03_ubuntu_php_esquema_y_datos.sql`: esquema y datos de la base para esta versión.

La guía completa paso a paso está en [`LAMP_Ubuntu/README_LAMP.md`](LAMP_Ubuntu/README_LAMP.md).

## Usuarios y roles

Usuarios de demostración que crea `python manage.py migrate` (**cambia estas claves antes de entregar**):

| Usuario                    | Clave             | Rol                                             |
|----------------------------|-------------------|-------------------------------------------------|
| `ana@novacomercial.mx`     | `Nexo2026Demo`    | Administrador (con acceso también como usuario) |
| `superadmin@magnussig.com` | `Magnus2026Super` | Superadministrador                              |

No existe registro libre: **solo el Superadministrador crea los usuarios y le asigna el rol a cada uno** desde la sección Usuarios, dentro de la página. Nadie puede elegir su propio rol.

| Acción                                          | Cliente               | Asesor                       | Supervisor | Administrador     | Superadmin |
|-------------------------------------------------|-----------------------|------------------------------|------------|-------------------|------------|
| Ver catálogo y detalle de productos             | Sí (sin costo)        | Sí                           | Sí         | Sí                | Sí         |
| Comprar en la tienda                            | Sí                    |                              |            |                   |            |
| Registrar ventas                                |                       | Sí                           | Sí         | Sí (modo usuario) | No         |
| Ver ventas                                      | Las suyas             | Las suyas + pedidos en línea | Todas      | Todas             | Todas      |
| Entregar o anular pedidos                       | Solo cancelar el suyo | Sí                           | Sí         | Sí                | No         |
| Agregar y eliminar productos, crear categorías  |                       |                              | Sí         | Sí                | No         |
| Crear usuarios y asignarles el rol              |                       |                              |            |                   | Sí         |
| Cambiar rol, dar acceso dual, eliminar usuarios |                       |                              |            |                   | Sí         |

Reglas de seguridad (las aplica el servidor, no solo la pantalla):

- **Nadie puede quitarle el rol al Superadministrador.**
- Nadie puede modificarse o eliminarse a sí mismo.
- Solo el Superadministrador puede crear usuarios, cambiar roles y dar el acceso **también como usuario** (columna `dual`) al Administrador.
- La descripción de un producto o servicio es obligatoria: sin ella el servidor no lo guarda.
- La moneda es COP y el IVA es 19 %.

Las contraseñas se guardan en `auth_user.password` (MySQL). Django guarda un **hash** (PBKDF2), no el texto original: es la forma segura estándar.

## Tablas de la base de datos (`nexo_db`)

| Tabla                      | Contenido                                                                                                                                                                                              |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `auth_user`                | Usuarios (correo, nombre, contraseña)                                                                                                                                                                  |
| `productos_companyprofile` | **Rol** de cada usuario, acceso dual (`dual`) y quién le dio el rol (`granted_by_id`)                                                                                                                  |
| `productos_client`         | Clientes (nombre, cédula/NIT, teléfono); se enlaza a un usuario si el cliente tiene cuenta                                                                                                             |
| `productos_category`       | Categorías del catálogo                                                                                                                                                                                |
| `productos_product`        | Productos **y servicios** (`kind`): nombre, código, categoría, descripción, costo, precio, stock, activo, imagen                                                                                       |
| `productos_sale`           | Ventas: folio, cliente, asesor, estado (Pendiente / Entregado / Anulada), forma de pago, quién atendió, entrega (`delivery_method`, `delivery_city`, `delivery_address`), notas, subtotal, IVA y total |
| `productos_saleitem`       | Detalle de cada venta: producto, cantidad y precio unitario                                                                                                                                            |
| `productos_teammember`     | Tabla original de equipo (ya no se muestra en pantalla)                                                                                                                                                |

Los scripts de la carpeta `SQL/` sirven para:

- `02_consultas_y_pruebas.sql`: ver los datos. Ejecuta **una instrucción a la vez**, porque incluye `UPDATE`, `INSERT` y `DELETE` de prueba. Si Workbench responde "Error 1175", ejecuta antes `SET SQL_SAFE_UPDATES = 0;`.
- `05_verificar_compras_ngrok.sql`: comprobar que las compras hechas desde el enlace de ngrok quedaron guardadas en MySQL.
- `04_limpieza_tablas_y_usuarios.sql`: limpiar datos de prueba. Ejecútalo solo si quieres reiniciar los datos, porque borra información.

## Rutas de la API

| Ruta                                          | Método          | Para qué                                                                                                                               |
|-----------------------------------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `/api/auth/csrf/`                             | GET             | Token CSRF                                                                                                                             |
| `/api/auth/register/`                         | POST            | Registro público (valida el código para roles con privilegios)                                                                         |
| `/api/auth/login/`, `/session/`, `/logout/`   | POST, GET, POST | Sesión                                                                                                                                 |
| `/api/products/`                              | GET             | Listar productos y servicios (al cliente no se le envía el costo)                                                                      |
| `/api/products/create/`                       | POST            | Crear (Administrador, Supervisor)                                                                                                      |
| `/api/products/<id>/`                         | PUT             | Editar (Administrador, Supervisor)                                                                                                     |
| `/api/products/<id>/delete/`                  | DELETE          | Eliminar (Administrador, Supervisor)                                                                                                   |
| `/api/categories/`, `/api/categories/create/` | GET, POST       | Categorías                                                                                                                             |
| `/api/clients/`, `/api/clients/create/`       | GET, POST       | Clientes (personal de ventas)                                                                                                          |
| `/api/sales/`                                 | GET             | Ventas visibles según el rol                                                                                                           |
| `/api/sales/create/`                          | POST            | Registrar venta o compra en línea (descuenta stock). El cliente envía también entrega, notas y sus datos (nombre, documento, teléfono) |
| `/api/sales/<folio>/status/`                  | POST            | Entregar o anular un pedido pendiente (al anular devuelve el stock). El cliente solo puede cancelar su propio pedido                   |
| `/api/users/`                                 | GET             | Listar usuarios (Administrador, Superadmin)                                                                                            |
| `/api/users/create/`                          | POST            | Crear usuario (solo Administrador)                                                                                                     |
| `/api/users/<id>/`                            | PUT             | Cambiar rol, acceso dual, nombre, correo o clave                                                                                       |
| `/api/users/<id>/delete/`                     | DELETE          | Eliminar usuario                                                                                                                       |
| `/api/team/`, `/api/team/create/`             | GET, POST       | Rutas originales de equipo (conservadas)                                                                                               |

El frontend consulta la API cada 8 segundos, así que cuando un cliente compra desde otro equipo (por ejemplo, desde el enlace de ngrok) el asesor ve el pedido sin recargar.

## Pruebas automáticas

Con el entorno virtual activo, dentro de `Aula_Project BACKEND/aula`:

```powershell
python manage.py test
```

Cubren productos y servicios, descripción obligatoria, permisos de los roles, ventas con IVA 19 %, pedidos en línea (entregar y anular), registro con códigos, reglas del superadministrador y de quien da el rol, clientes y categorías. Django usa una base temporal `test_nexo_db`, así que no toca los datos reales (el usuario de MySQL necesita permiso para crear bases).

## Cómo comprobar que los datos llegan a MySQL

1. Haz una acción en la página (registrar usuario, crear producto, registrar venta).
2. En Workbench ejecuta `USE nexo_db;` y la consulta correspondiente de `SQL/02_consultas_y_pruebas.sql` (o `SQL/05_verificar_compras_ngrok.sql` para compras hechas por ngrok).
3. Para ver el JSON que devuelve la API, inicia sesión en la página y abre en otra pestaña `/api/products/` sobre el mismo enlace.

Al detener y volver a iniciar el backend los datos siguen ahí, porque están guardados en MySQL.

## Limitaciones conocidas

- Al **eliminar un usuario** sus ventas se conservan (con el nombre del cliente y del asesor copiados en la venta). No se puede eliminar un usuario que haya creado productos.
- No se puede eliminar un producto que ya tiene ventas (el servidor pide marcarlo como Inactivo).
- El historial de ventas empieza vacío: no hay ventas de ejemplo.
- Los ajustes son para desarrollo y demostración (`DEBUG = True`, clave secreta local, códigos de autorización y claves de ejemplo). No son aptos para producción.
- El enlace gratuito de ngrok cambia en cada ejecución y solo funciona mientras tu equipo, el servidor y ngrok estén encendidos.
