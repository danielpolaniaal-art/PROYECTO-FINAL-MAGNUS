# Magnus SIG · Nexo — versión LAMP (Ubuntu Server + Apache + MySQL + PHP)

El proyecto original **no se tocó**: el backend Django sigue en `Aula_Project BACKEND/` y funciona igual que antes.
Esta carpeta (`LAMP_Ubuntu/`) **agrega** un backend en PHP con las mismas rutas para la Actividad de la Semana 13 (servidor LAMP). El nuevo frontend sirve para los dos.

| Capa | Antes | Ahora |
|---|---|---|
| Sistema operativo | Windows (desarrollo) | **Ubuntu Server** |
| Servidor web | `runserver` / `http.server` | **Apache 2** (todo por el puerto 80) |
| Backend / API | Python + Django | **PHP 8** (mismas rutas `/api/...`, mismo JSON, mismas reglas) |
| Base de datos | MySQL `nexo_db` | **MySQL `nexo_db`** (mismas tablas y columnas) |
| Frontend | HTML/CSS/JS | **Nuevo diseño** (HTML/CSS/JS), conectado a la API |

## Estructura
```
Proyecto_Aula_Final_Magnus/
├── Aula_Project BACKEND/   (Django original, sin cambios)
├── nexo FRONTEND/nexo/     (nuevo frontend: funciona con Django y con PHP)
├── SQL/                    (01 y 02 originales + 03_ubuntu_php_esquema_y_datos.sql)
└── LAMP_Ubuntu/            (backend PHP para Ubuntu)
    ├── public/api/index.php · prueba.php · .htaccess
    ├── app/  (config, lib/core.php, lib/handlers.php, storage/)
    └── deploy/ install_lamp.sh · nexo.conf · smoke_test.sh · dev-router.php
```

## Instalación rápida (un comando)
Copia la carpeta completa del proyecto al servidor (por ejemplo con `scp -r Proyecto_Aula_Final_Magnus usuario@IP:~`) y:
```bash
cd ~/Proyecto_Aula_Final_Magnus/LAMP_Ubuntu
sudo bash deploy/install_lamp.sh
```
El script instala Apache, MySQL y PHP, crea la base `nexo_db` con sus datos, crea el usuario
`nexo_user` con clave aleatoria, deja `app/config.local.php`, ajusta permisos y activa el sitio.
Al final imprime la dirección: `http://IP_DEL_SERVIDOR/`.

## Instalación manual (paso a paso, para documentar la práctica)
Sigue la guía de DigitalOcean (https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu) y luego:
```bash
# 1. Pila LAMP
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql php-mbstring rsync
sudo a2enmod rewrite headers
sudo ufw allow "Apache"                 # si usas firewall

# 2. Proyecto en /var/www/nexo
P=~/Proyecto_Aula_Final_Magnus
sudo mkdir -p /var/www/nexo && sudo rsync -a $P/LAMP_Ubuntu/ /var/www/nexo/
sudo rsync -a "$P/nexo FRONTEND/nexo/" /var/www/nexo/public/      # frontend
sudo mkdir -p /var/www/nexo/SQL && sudo cp $P/SQL/03_ubuntu_php_esquema_y_datos.sql /var/www/nexo/SQL/01_crear_base_de_datos.sql

# 3. Base de datos y usuario
sudo mysql < /var/www/nexo/SQL/01_crear_base_de_datos.sql
sudo mysql -e "CREATE USER 'nexo_user'@'localhost' IDENTIFIED BY 'TuClaveSegura123';
               GRANT ALL PRIVILEGES ON nexo_db.* TO 'nexo_user'@'localhost'; FLUSH PRIVILEGES;"

# 4. Configuración (pon la misma clave de MySQL)
sudo cp /var/www/nexo/app/config.local.php.example /var/www/nexo/app/config.local.php
sudo nano /var/www/nexo/app/config.local.php        # DB_PASSWORD y APP_SECRET

# 5. Permisos
sudo chown -R root:www-data /var/www/nexo
sudo chown -R www-data:www-data /var/www/nexo/app/storage && sudo chmod -R 770 /var/www/nexo/app/storage

# 6. Sitio de Apache
sudo cp /var/www/nexo/deploy/nexo.conf /etc/apache2/sites-available/nexo.conf
sudo a2dissite 000-default && sudo a2ensite nexo
sudo apache2ctl configtest && sudo systemctl restart apache2
```

## Comprobar que funciona (evidencias para la entrega en Q10)
```bash
apache2 -v ; php -v ; mysql --version
systemctl status apache2 --no-pager
bash /var/www/nexo/deploy/smoke_test.sh          # prueba la API: debe terminar con 0 errores
```
En el navegador (desde tu PC, con la IP del servidor):
1. `http://IP/prueba.php` → página dinámica con versión de PHP, Apache y conexión a MySQL (**captura**). Bórrala después: `sudo rm /var/www/nexo/public/prueba.php`.
2. `http://IP/` → inicia sesión con `ana@novacomercial.mx` / `Nexo2026Demo` (Administrador) o `superadmin@magnussig.com` / `Magnus2026Super`.
3. Registra una venta y revisa en MySQL: `sudo mysql nexo_db -e "SELECT folio,total FROM productos_sale;"`.

## Qué se conservó y qué se adaptó
- **Backend:** mismas rutas, métodos, roles, validaciones, mensajes y formato JSON que la API de Django; el frontend no necesita cambios de contrato. Contraseñas con el mismo formato (`pbkdf2_sha256`), así que las cuentas existentes siguen entrando. CSRF con cookie `csrftoken` + cabecera `X-CSRFToken`, igual que antes.
- **Base de datos:** mismas tablas y columnas (`auth_user`, `productos_*`). Solo se añadieron reglas `ON DELETE` a las llaves foráneas (lo que Django hacía por código).
- **Frontend:** se tomó el nuevo diseño completo (login, tienda, pagos con Nequi/transferencia/tarjeta, cambio de foto de producto) y se reconectó a la API en lugar de `localStorage`. La API ahora se llama en `/api` (mismo origen, sin puerto 8000).
- **Ajuste de ruta:** el botón de eliminar usuario llama `DELETE /api/users/<id>/`, ruta que en Django no existía (solo `/delete/`); el backend PHP acepta ambas.
- **Tarjetas:** el nuevo frontend valida los datos de la tarjeta, pero la base no tiene columnas para guardarlos; solo se muestran en la confirmación y no se almacenan (sin cambiar la estructura de la BD).

## Probar sin Apache (opcional, solo desarrollo)
```bash
cd Proyecto_Aula_Final_Magnus
php -S 0.0.0.0:8080 -t "nexo FRONTEND/nexo" LAMP_Ubuntu/deploy/dev-router.php
```

## Problemas frecuentes
- **404 en /api/...** → falta `sudo a2enmod rewrite` o `AllowOverride All` (viene en `deploy/nexo.conf`).
- **"No se pudo conectar con la base de datos"** → revisa `DB_PASSWORD` en `app/config.local.php` y `sudo systemctl status mysql`.
- **No guarda la sesión / 500** → `sudo chown -R www-data:www-data /var/www/nexo/app/storage`.
- **Ver errores:** `sudo tail -f /var/log/apache2/nexo_error.log`.
- **Cambiar claves de demo y códigos de registro** (SUP-2026, ADM-2026, SUPER-2026) antes de entregar: en Administración o en `config.local.php` (`AUTH_CODES`).
