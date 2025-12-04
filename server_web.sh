#!/bin/bash

# variables de entorno
NFS_IP_WWW="192.168.10.30"
WP_DIR_NFS="/var/www/wordpress"
DIR="/var/www/html"

set -e
sudo hostnamectl set-hostname WebCrisAlm

# Instalar Apache, PHP (con módulos), MySQL Client y NFS Client
sudo apt update 
sudo apt install -y apache2 php libapache2-mod-php php-mysql nfs-common

sudo systemctl stop apache2
sudo rm -rf $DIR/*

# Crear el directorio local a de montar.
sudo mkdir -p $DIR

# Montar la carpeta compartida.
sudo mount $NFS_IP_WWW:$WP_DIR_NFS $DIR

if mountpoint -q $DIR; then
    echo "Montaje de NFS en $DIR."
else
    echo "ERROR: Fallo al montar la carpeta NFS"
    exit 1 # Detiene el script si el montaje falla.
fi

# SSL
sudo apt install -y ssl-cert
sudo a2enmod ssl headers

# Generar un certificado autofirmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/iawcris.key \
    -out /etc/ssl/certs/iawcris.crt \
    -subj "/CN=iawcris.ddns.net"

# Configurando HTTP
sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName iawcris.ddns.net
    DocumentRoot $DIR
    
    <Directory $DIR>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/balancer_http_error.log
    CustomLog ${APACHE_LOG_DIR}/balancer_http_access.log combined
</VirtualHost>
EOF

# Configuración HTTPS
sudo tee /etc/apache2/sites-available/default-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName iawcris.ddns.net
    DocumentRoot $DIR

    # Rutas del certificado generado
    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/iawcris.crt
    SSLCertificateKeyFile /etc/ssl/private/iawcris.key

    <Directory $DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF

# Habilitar SSL
sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo a2ensite default-ssl.conf

# # Permisos para acceder a los archivos.
# sudo chown -R www-data:www-data $DIR

sudo systemctl restart apache2