#!/bin/bash

# Cargar las variables de entorno
source .env

# Actualizar el sistema e instalar NFS y Git.
sudo apt update && sudo apt install nfs-kernel-server git -y

# Crear el directorio compartido.
sudo mkdir -p /var/www/html/web
echo "Directorio /var/www/html/web creado."

# Cambiar propietario y grupo a nobody:nogroup
sudo chown nobody:nogroup /var/www/html/web
echo "Propietario y grupo de /var/www/html/web cambiado."

# Editar /etc/exports.
sudo truncate -s 0 /etc/exports

sudo echo "/var/www/html/web 192.168.10.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
# sudo tee -a /etc/exports <<EOF
# $WEB_ROUTE $SERVER1_IP_WWW(rw,sync,no_subtree_check)
# $WEB_ROUTE $SERVER2_IP_WWW(rw,sync,no_subtree_check)
# EOF
echo "Archivo de configuración /etc/exports editado."

# Leer y activar inmediatamente /etc/exports
sudo exportfs -a 
echo "Exportaciones NFS activadas."

# Clonar la aplicación dentro del directorio compartido
cd /var/www/html/web
sudo git clone $REPOSITORIO_URL .
echo "Aplicación clonada en /var/www/html/web"


echo "Configuración del NFS completada con éxito."

