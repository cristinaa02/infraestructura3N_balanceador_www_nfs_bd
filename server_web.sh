#!/bin/bash

# Cargar las variables de entorno
source .env

# Instalar Apache, PHP (con módulos), MySQL Client y NFS Client
sudo apt update && sudo apt install -y \
    apache2 \
    php \
    libapache2-mod-php \
    php-mysql \
    nfs-common 
echo "Apache, PHP, NFS Client instalado."

# Crear el directorio local a de montar.
sudo mkdir -p "$WEB_ROUTE"

# Permisos para acceder a los archivos.
sudo chown -R www-data:www-data "$WEB_ROUTE"
sudo chmod -R 755 "$WEB_ROUTE"

# Montar la carpeta compartida.
sudo mount $NFS_IP_WWW:$WEB_ROUTE $WEB_ROUTE

if mountpoint -q "$WEB_ROUTE"; then
    echo "Montaje de NFS desde $NFS_IP_WWW:$WEB_ROUTE en $WEB_ROUTE."
else
    echo "ERROR: Fallo al montar la carpeta NFS"
fi

# Crear archivo de configuración de sitio.
cd /etc/apache2/sites-available
sudo cp 000-default.conf server_www.conf

sudo sed -i "s|DocumentRoot /var/www/html|DocumentRoot $WEB_ROUTE|" server_www.conf
echo "DocumentRoot modificado a $WEB_ROUTE."

# Habilitar el site configurado y deshabilitar el que viene por defecto.
sudo a2ensite server_www.conf
sudo a2dissite 000-default.conf
echo "Habilitado el archivo /etc/apache2/sites-available/server_www.conf."

# Reiniciar Apache.
sudo systemctl restart apache2

# Conexión a base de datos.

# Detectar el nombre de la máquina actual.
SERVER_NAME=$(hostname)

if [ "$SERVER_NAME" = "server1" ]; then
    # Si estamos en server1, usamos el usuario para server1.
    APP_DB_USER="$DB_USER1"
elif [ "$SERVER_NAME" = "server2" ]; then
    # Si estamos en server2, usamos el usuario para server2.
    APP_DB_USER="$DB_USER2"
else
    echo "ERROR: Máquina no identificada."
    exit 1
fi

# Configuración de la Aplicación.
CONFIG_FILE="$WEB_ROUTE/config.php"

if [ -f "$CONFIG_FILE" ]; then
    # 1. Reemplazamos 'localhost' por la IP privada de MySQL.
    sudo sed -i "s/localhost/$SERVERBD_IP_DB/g" "$CONFIG_FILE"
    # 2. Reemplazamos el nombre de la BD.
    sudo sed -i "s/database_name_here/$DB_NAME/g" "$CONFIG_FILE"
    # 3. Reemplazamos el usuario por el usuario de la aplicación (variable dinámica).
    sudo sed -i "s/username_here/$APP_DB_USER/g" "$CONFIG_FILE" 
    # 4. Reemplazar la contraseña.
    sudo sed -i "s/password_here/$DB_PASS/g" "$CONFIG_FILE"
    echo "Configuración de DB completada en $CONFIG_FILE. Usuario usado: $APP_DB_USER"
else
    echo "ERROR: Archivo $CONFIG_FILE no encontrado."
fi

echo "Configuración del servidor web completada con éxito."