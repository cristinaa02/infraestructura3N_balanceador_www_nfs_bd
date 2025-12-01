#!/bin/bash

# variables de entorno
NFS_IP_WWW="192.168.10.30"
WP_DIR_NFS="/var/www/wordpress"
DIR="/var/www/html"

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

# # Añadir la entrada al fstab para que el montaje persista tras reinicios
# FSTAB_ENTRY="$NFS_IP_WWW:$WP_DIR_NFS $DIR nfs defaults 0 0"
# if ! grep -q "$FSTAB_ENTRY" /etc/fstab; then
#     echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
# fi

# Permisos para acceder a los archivos.
sudo chown -R www-data:www-data $DIR

sudo systemctl start apache2