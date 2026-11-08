# Proyecto de Aula Final Magnus · Magnus SIG S.A.S · Sistema de inventario y ventas (Nexo)

Proyecto de aula. Aplicación web con **frontend**, **API REST** y base de datos **MySQL**.

| Capa | Tecnología |
|---|---|
| Frontend | HTML, CSS y JavaScript (sin frameworks) |
| Backend / API | Python + Django 5.2 (respuestas en JSON) |
| Base de datos | MySQL 8 (base `nexo_db`), conectada con PyMySQL |

## Estructura

```
Proyecto_Aula_Final_Magnus/
├── README.md
├── SQL/
│   ├── 01_crear_base_de_datos.sql      ← crea la base nexo_db
│   └── 02_consultas_y_pruebas.sql      ← consultas para verificar datos en Workbench
├── Aula_Project BACKEND/
│   ├── requirements.txt
│   └── aula/                            ← aquí está manage.py
│       ├── aula/settings.py             ← configuración (incluye la conexión a MySQL)
│       └── productos/                   ← modelos, vistas (API), rutas, migraciones y pruebas
└── nexo FRONTEND/nexo/                  ← index.html, app.js, styles.css, img/
```

## Requisitos

- Python 3.10 o superior
- MySQL Server 8 y MySQL Workbench, con el servidor encendido
- Un navegador

## Instalación y ejecución

### 1. Crear la base de datos
En MySQL Workbench abre `SQL/01_crear_base_de_datos.sql` y ejecútalo (rayo). Crea la base `nexo_db`.

### 2. Configurar la contraseña de MySQL
Abre `Aula_Project BACKEND/aula/aula/settings.py` y busca `DB_PASSWORD` (sección `DATABASES`) y cambia `'xxxx'` por la contraseña de tu usuario de MySQL (por defecto el usuario es `root`, host `127.0.0.1`, puerto `3306`).

### 3. Backend (Terminal 1)
```bash
cd "Aula_Project BACKEND"
python -m venv venv
source venv/Scripts/activate          # Git Bash en Windows
# venv\Scripts\activate               # CMD o PowerShell en Windows
# source venv/bin/activate            # Mac o Linux
pip install -r requirements.txt
cd aula
python manage.py migrate
python manage.py runserver 8000
```
`migrate` crea las tablas en `nexo_db`, los usuarios de demostración, 9 categorías, 37 productos y servicios de Magnus SIG y 5 clientes de ejemplo.

> Si ya habías ejecutado `migrate` con la versión anterior, vuelve a ejecutarlo: aplica las migraciones `0005`, `0006` y `0007`, convierte el rol viejo "Usuario" en "Asesor de ventas" y retira los productos de electrónica de ejemplo.

### 4. Frontend (Terminal 2)
```bash
cd "nexo FRONTEND/nexo"
python -m http.server 5173
```

### 5. Abrir la aplicación
Entra a **http://localhost:5173**

> Usa exactamente `localhost` y el puerto **5173**. El servidor solo acepta ese origen para CORS y CSRF.

Para comprobar que la API responde, abre http://localhost:8000/api/ (debe mostrar `API de Nexo activa.`). Desde la versión con ngrok, http://localhost:8000/ ya muestra la página completa (ver sección «Acceso público con ngrok»).

## Usuarios y roles

Usuarios de demostración que crea `python manage.py migrate` (**cambia estas claves antes de entregar**):

| Usuario | Clave | Rol |
|---|---|---|
| `ana@novacomercial.mx` | `Nexo2026Demo` | Administrador (con acceso también como usuario) |
| `superadmin@magnussig.com` | `Magnus2026Super` | Superadministrador |

Desde **Registrarse** cualquiera puede crear una cuenta de **Cliente** o **Asesor de ventas**. Los roles **Supervisor**, **Administrador** y **Superadministrador** piden un código de autorización que valida el servidor (`AUTH_CODES` al final de `settings.py`; por defecto `SUP-2026`, `ADM-2026` y `SUPER-2026`).

| Acción | Cliente | Asesor | Supervisor | Administrador | Superadmin |
|---|---|---|---|---|---|
| Ver catálogo y detalle de productos | Sí (sin costo) | Sí | Sí | Sí | Sí |
| Comprar en la tienda | Sí | | | | |
| Registrar ventas | | Sí | Sí | Sí (modo usuario) | No |
| Ver ventas | Las suyas | Las suyas + pedidos en línea | Todas | Todas | Todas |
| Entregar o anular pedidos | Solo cancelar el suyo | Sí | Sí | Sí | No |
| Agregar y eliminar productos, crear categorías | | | Sí | Sí | No |
| Crear usuarios | | | | Sí | No |
| Cambiar rol, dar acceso dual, eliminar usuarios | | | | Sí | Sí |

Reglas de seguridad (las aplica el servidor, no solo la pantalla):

- **Nadie puede quitarle el rol al Superadministrador**, ni siquiera un administrador.
- Un administrador puede dar rol a otra persona, pero esa persona **no puede quitarle el rol** a quien se lo dio (columna `granted_by`).
- Nadie puede modificarse o eliminarse a sí mismo.
- Solo el Administrador puede tener acceso **también como usuario** (columna `dual`).
- Al crear un usuario **ya no se pide el nombre de la empresa**.
- La descripción de un producto o servicio es obligatoria: sin ella el servidor no lo guarda.
- La moneda es COP y el IVA es 19 %.

Las contraseñas se guardan en `auth_user.password` (MySQL). Django guarda un **hash** (PBKDF2), no el texto original: es la forma segura estándar.

## Tablas de la base de datos (`nexo_db`)

| Tabla | Contenido |
|---|---|
| `auth_user` | Usuarios (correo, nombre, contraseña) |
| `productos_companyprofile` | **Rol** de cada usuario, acceso dual (`dual`) y quién le dio el rol (`granted_by_id`) |
| `productos_client` | Clientes (nombre, cédula/NIT, teléfono); se enlaza a un usuario si el cliente tiene cuenta |
| `productos_category` | Categorías del catálogo |
| `productos_product` | Productos **y servicios** (`kind`): nombre, código, categoría, descripción, costo, precio, stock, activo, imagen |
| `productos_sale` | Ventas: folio, cliente, asesor, estado (Pendiente / Entregado / Anulada), forma de pago, quién atendió, entrega (`delivery_method`, `delivery_city`, `delivery_address`), notas, subtotal, IVA y total |
| `productos_saleitem` | Detalle de cada venta: producto, cantidad y precio unitario |

El archivo `SQL/02_consultas_y_pruebas.sql` trae las consultas para ver los datos. Ejecuta **una instrucción a la vez**, porque incluye `UPDATE`, `INSERT` y `DELETE` de prueba. Si Workbench responde "Error 1175" en un `UPDATE` o `DELETE`, ejecuta antes `SET SQL_SAFE_UPDATES = 0;`.

## Rutas de la API

| Ruta | Método | Para qué |
|---|---|---|
| `/api/auth/csrf/` | GET | Token CSRF |
| `/api/auth/register/` | POST | Registro público (valida el código para roles con privilegios) |
| `/api/auth/login/`, `/session/`, `/logout/` | POST, GET, POST | Sesión |
| `/api/products/` | GET | Listar productos y servicios (al cliente no se le envía el costo) |
| `/api/products/create/` | POST | Crear (Administrador, Supervisor) |
| `/api/products/<id>/` | PUT | Editar (Administrador, Supervisor) |
| `/api/products/<id>/delete/` | DELETE | Eliminar (Administrador, Supervisor) |
| `/api/categories/`, `/api/categories/create/` | GET, POST | Categorías |
| `/api/clients/`, `/api/clients/create/` | GET, POST | Clientes (personal de ventas) |
| `/api/sales/` | GET | Ventas visibles según el rol |
| `/api/sales/create/` | POST | Registrar venta o compra en línea (descuenta stock). El cliente envía también entrega, notas y sus datos (nombre, documento, teléfono) |
| `/api/sales/<folio>/status/` | POST | Entregar o anular un pedido pendiente (al anular devuelve el stock). El cliente solo puede cancelar su propio pedido |
| `/api/users/` | GET | Listar usuarios (Administrador, Superadmin) |
| `/api/users/create/` | POST | Crear usuario (solo Administrador) |
| `/api/users/<id>/` | PUT | Cambiar rol, acceso dual, nombre, correo o clave |
| `/api/users/<id>/delete/` | DELETE | Eliminar usuario |
| `/api/team/`, `/api/team/create/` | GET, POST | Rutas originales de equipo (conservadas) |

El frontend consulta la API cada 8 segundos, así que cuando un cliente compra desde otro equipo el asesor ve el pedido sin recargar.

## Pruebas automáticas

Con el entorno virtual activo, dentro de `Aula_Project BACKEND/aula`:
```bash
python manage.py test
```
Son 43 pruebas: productos y servicios, descripción obligatoria, permisos de los 5 roles, ventas con IVA 19 %, pedidos en línea (entregar y anular), registro con códigos, reglas del superadministrador y de quien da el rol, clientes y categorías. Django usa una base temporal `test_nexo_db`, así que no toca los datos reales (el usuario de MySQL necesita permiso para crear bases).

## Cómo comprobar que los datos llegan a MySQL

1. Haz una acción en la página (registrar usuario, crear producto, registrar venta).
2. En Workbench ejecuta `USE nexo_db;` y la consulta correspondiente de `SQL/02_consultas_y_pruebas.sql`.
3. Para ver el JSON que devuelve la API, inicia sesión en la página y abre en otra pestaña `http://localhost:8000/api/products/`.

Al detener y volver a iniciar el backend los datos siguen ahí, porque están guardados en MySQL.

## Limitaciones conocidas

- Al **eliminar un usuario** sus ventas se conservan (con el nombre del cliente y del asesor copiados en la venta). No se puede eliminar un usuario que haya creado productos.
- No se puede eliminar un producto que ya tiene ventas (el servidor pide marcarlo como Inactivo).
- El historial de ventas empieza vacío: no hay ventas de ejemplo.
- Los ajustes son para desarrollo local (`DEBUG = True`, clave secreta de ejemplo, códigos de autorización de ejemplo).


---

## Nuevo frontend y versión para Ubuntu (LAMP con PHP)

- **Frontend nuevo:** `nexo FRONTEND/nexo/` ahora trae el nuevo diseño, conectado a la API. Se ejecuta con los **mismos comandos de siempre** (`python -m http.server 5173`) y habla con Django en el puerto 8000. El backend Django y la base de datos **no cambiaron**.
- **Ubuntu / Apache / PHP:** la carpeta `LAMP_Ubuntu/` agrega un backend PHP con las mismas rutas de API. Para la actividad de la Semana 13:
```bash
cd Proyecto_Aula_Final_Magnus/LAMP_Ubuntu
sudo bash deploy/install_lamp.sh      # instala Apache + MySQL + PHP y publica el sitio
```
  Guía completa y pruebas en `LAMP_Ubuntu/README_LAMP.md`. Datos de demostración: `ana@novacomercial.mx` / `Nexo2026Demo` y `superadmin@magnussig.com` / `Magnus2026Super`.


## Cambios de esta versión

- **Registro público**: solo crea cuentas de *Cliente*. Los demás roles (asesor, supervisor, administrador, superadministrador) los crea el **superadministrador** desde *Usuarios → Crear usuario* (ventana flotante con lista desplegable de roles).
- **Login fijo** (no se desplaza) y **logo** junto a «Magnus SIG S.A.S»: usa el logo oficial de Magnus SIG (`img/logo.png`; el logo completo con nombre está en `img/logo_completo.png`).
- **Imágenes** de cada producto y servicio en `img/productos/<CÓDIGO>.svg` (fijas en el proyecto). Puedes cambiar cualquiera subiendo la foto desde el catálogo o reemplazando el archivo.
- **Retirados**: anillo y televisor 4K (migración `0008_limpieza.py`, script `SQL/04_limpieza_tablas_y_usuarios.sql` y filtro en el frontend).
- **Base de datos limpia**: sin `productos_teammember`, `django_admin_log` ni `django_session`. Quedan `auth_user` + `productos_companyprofile` (usuarios y roles), `productos_client`, `productos_category`, `productos_product`, `productos_sale`, `productos_saleitem` y las tablas internas mínimas de Django (`auth_*`, `django_content_type`, `django_migrations`).
- Los usuarios nuevos **sí se guardan** en `auth_user` (nombre, correo) y su rol en `productos_companyprofile.role`. Para verlos: `SQL/04_limpieza_tablas_y_usuarios.sql`, consulta 3.


---

## Acceso público con ngrok (Windows: Django + MySQL locales)

**Cómo funciona.** Django sirve la página (`/`) **y** la API (`/api/...`) desde el mismo puerto 8000. Un solo túnel ngrok publica ese puerto; el navegador de cada visitante habla con Django por HTTPS y **solo Django** habla con MySQL (`127.0.0.1:3306`). No se publica el puerto de MySQL. El frontend no cambió: `app.js` ya usaba `/api` cuando el puerto no es 5173/5500.

### Variables de entorno (PowerShell, en la misma ventana donde arrancas Django)

| Variable | Para qué | Obligatoria |
|---|---|---|
| `DB_PASSWORD` | Contraseña del usuario de MySQL | Sí (el valor por defecto `xxxx` no sirve) |
| `NEXO_HTTPS` | `1` → cookies seguras y confianza en el HTTPS de ngrok | Sí con ngrok |
| `NGROK_DOMAIN` | Tu dominio fijo de ngrok, sin `https://`. Si no lo defines se aceptan los dominios temporales de ngrok | No |
| `DB_USER` | Usuario de MySQL (por defecto `root`) | No |
| `DJANGO_DEBUG` | `1` solo para depurar en local. **Nunca** con la página pública | No |
| `DJANGO_SECRET_KEY` | Clave secreta propia. Si no la defines, Django genera y guarda `aula/.secret_key` la primera vez | No |

### Arranque

& "C:\Users\PC\Downloads\Proyecto_Magnus_COMPLETO\venv\Scripts\Activate.ps1"
cd "C:\Users\PC\Downloads\Proyecto_Magnus_COMPLETO\Proyecto_Magnus_COMPLETO\Aula_Project BACKEND\aula"
$env:DB_PASSWORD = "TU_CLAVE_MYSQL"
$env:NEXO_HTTPS = "1"
$env:NGROK_DOMAIN = "wistful-roundish-cornbread.ngrok-free.dev"
python manage.py runserver 127.0.0.1:8000
```

**Terminal 2 · ngrok** (la primera vez: `ngrok config add-authtoken TU_TOKEN`)
```powershell
ngrok http 127.0.0.1:8000
```
Comparte la URL `https://...ngrok-free...` que muestra ngrok. Con dominio fijo: `ngrok http --url=tu-dominio.ngrok-free.dev 127.0.0.1:8000` (en versiones antiguas de ngrok el parámetro es `--domain`).

### Qué cambió para ngrok y para exponer la página
- `ALLOWED_HOSTS` y `CSRF_TRUSTED_ORIGINS` aceptan los dominios de ngrok (o solo `NGROK_DOMAIN` si lo defines).
- `DEBUG` ahora está **apagado por defecto**; la `SECRET_KEY` ya no es la clave pública de ejemplo.
- Cookies de sesión y CSRF `Secure` con `NEXO_HTTPS=1`; la sesión dura 7 días.
- Límite de intentos de inicio de sesión (8 fallos por correo → bloqueo de 15 minutos).
- La compra valida cantidades (1 a 1000 por producto, máximo 50 productos) y estructura; la foto del producto solo admite imagen en base64 o ruta `img/...`.
- `python manage.py test` ahora incluye pruebas de compras por usuario, seguridad y simulación de peticiones por ngrok.

### Antes de compartir el enlace
1. Cambia las claves de demostración: `python manage.py changepassword ana@novacomercial.mx` y `python manage.py changepassword superadmin@magnussig.com`.
2. Revisa en Workbench las consultas 7 y 8 de `SQL/05_verificar_compras_ngrok.sql` (MySQL en Windows suele escuchar en toda la red local; conviene `bind-address=127.0.0.1` en `my.ini` y un usuario de MySQL propio en vez de `root`).
3. Comprueba una compra desde otro dispositivo con `SQL/05_verificar_compras_ngrok.sql`.
4. Con ngrok gratuito, la primera visita puede mostrar una pantalla de aviso de ngrok: es normal; el visitante pulsa «Visit Site».

### Limitaciones conocidas de esta configuración
- `runserver` es el servidor de desarrollo de Django: sirve para demostraciones, no para mucho tráfico.
- La sesión va firmada en la cookie (`signed_cookies`, decisión original del proyecto): «Cerrar sesión» borra la cookie del navegador, pero una cookie copiada seguiría siendo válida hasta que expire o se cambie la contraseña de ese usuario.
- Si apagas el computador, Django, MySQL o ngrok, la página deja de estar disponible.


---

## Cambios recientes

- **Reporte de ventas en Excel:** en *Historial de ventas* aparece el botón **Descargar Excel** para Administrador, Superadministrador y Asesor de ventas. Descarga un `.xlsx` con dos hojas: *Ventas* (una fila por venta, con total sin anuladas) y *Detalle* (una fila por producto). Incluye las mismas ventas que cada rol ve en su historial; el Administrador en modo «Usuario» descarga solo las suyas. Ruta: `GET /api/sales/export/` (la valida el servidor; Cliente y Supervisor reciben 403).
- **Un solo Superadministrador:** el rol «Superadministrador» ya no se puede asignar ni crear (ni desde la pantalla ni por la API). Solo existe el predeterminado.
- **Usuarios:** la tabla muestra primero al que ingresó (o se creó) más recientemente.
- **Administrador en modo «Usuario»:** el inicio y el historial muestran solo las ventas que él registró, no las de toda la empresa ni los pedidos en línea de otros.


## Administrador con acceso dual: entra como cliente
El Administrador con acceso dual (Ana) puede elegir «Cliente» en «Entrar como»: ve la tienda, su perfil y sus compras, como un cliente más (no registra ventas como asesor).

Para eliminar las ventas que ese usuario registró antes como asesor (y devolver el stock al inventario), primero haz una copia de la base y revisa la lista:
```bash
python manage.py limpiar_ventas_modo_usuario            # solo muestra lo que se eliminaría
python manage.py limpiar_ventas_modo_usuario --confirmar # elimina
```
