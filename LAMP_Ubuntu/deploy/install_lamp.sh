#!/usr/bin/env bash
# Instala la pila LAMP en Ubuntu Server y despliega Nexo (Magnus SIG).
# Uso:  cd Proyecto_Aula_Final_Magnus/LAMP_Ubuntu && sudo bash deploy/install_lamp.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo:  sudo bash deploy/install_lamp.sh"; exit 1; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"           # carpeta LAMP_Ubuntu
FRONT="$(cd "$SRC/../nexo FRONTEND/nexo" && pwd)"  # frontend del proyecto (no se duplica)
DEST=/var/www/nexo
DB_NAME=nexo_db
DB_USER=nexo_user

echo "==> 1/7 Instalando Apache, MySQL y PHP"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql php-mbstring openssl rsync
a2enmod rewrite headers >/dev/null
systemctl enable --now apache2 mysql

echo "==> 2/7 Copiando el proyecto a $DEST"
mkdir -p "$DEST"
rsync -a --delete --exclude 'app/config.local.php' --exclude 'app/storage/sessions/*' "$SRC/" "$DEST/"
rsync -a "$FRONT/" "$DEST/public/"   # frontend + API PHP en el mismo DocumentRoot
mkdir -p "$DEST/app/storage/sessions"
mkdir -p "$DEST/SQL" && cp "$SRC/../SQL/03_ubuntu_php_esquema_y_datos.sql" "$DEST/SQL/01_crear_base_de_datos.sql"

echo "==> 3/7 Creando la base de datos y los datos iniciales"
mysql < "$DEST/SQL/01_crear_base_de_datos.sql"

echo "==> 4/7 Creando el usuario de MySQL para la aplicación"
if [ -f "$DEST/app/config.local.php" ]; then
  DB_PASS="$(grep -oP "'DB_PASSWORD'\s*=>\s*'\K[^']+" "$DEST/app/config.local.php")"
else
  DB_PASS="$(openssl rand -hex 16)"
fi
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
          ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
          GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

echo "==> 5/7 Escribiendo app/config.local.php"
if [ ! -f "$DEST/app/config.local.php" ]; then
  SECRET="$(openssl rand -hex 32)"
  cat > "$DEST/app/config.local.php" <<PHP
<?php
return [
    'DB_HOST'     => '127.0.0.1',
    'DB_NAME'     => '$DB_NAME',
    'DB_USER'     => '$DB_USER',
    'DB_PASSWORD' => '$DB_PASS',
    'APP_SECRET'  => '$SECRET',
];
PHP
fi

echo "==> 6/7 Permisos"
chown -R root:www-data "$DEST"
find "$DEST" -type d -exec chmod 750 {} \;
find "$DEST" -type f -exec chmod 640 {} \;
chmod 750 "$DEST"
chown -R www-data:www-data "$DEST/app/storage"
chmod -R 770 "$DEST/app/storage"

echo "==> 7/7 Activando el sitio en Apache"
cp "$DEST/deploy/nexo.conf" /etc/apache2/sites-available/nexo.conf
a2dissite 000-default >/dev/null 2>&1 || true
a2ensite nexo >/dev/null
apache2ctl configtest
systemctl restart apache2
command -v ufw >/dev/null && ufw status | grep -q active && ufw allow 'Apache' >/dev/null || true

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✔ Listo.  Aplicación:  http://$IP/      Página de prueba LAMP:  http://$IP/prueba.php"
echo "  Usuarios de demostración: ana@novacomercial.mx / Nexo2026Demo  y  superadmin@magnussig.com / Magnus2026Super"
