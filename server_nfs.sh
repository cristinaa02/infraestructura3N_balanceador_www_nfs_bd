#!/bin/bash

# Cargar las variables de entorno
source .env

# Actualizar el sistema e instalar NFS y Git.
sudo apt update && sudo apt install nfs-kernel-server git -y

# Crear el directorio compartido.
sudo mkdir -p "$WEB_ROUTE"
echo "Directorio $WEB_ROUTE creado."

# Cambiar propietario y grupo a nobody:nogroup
sudo chown nobody:nogroup "$WEB_ROUTE"
echo "Propietario y grupo de $WEB_ROUTE cambiado."

# Editar /etc/exports.
sudo tee -a /etc/exports <<EOF
$WEB_ROUTE $SERVER1_IP_WWW"(rw,sync,no_subtree_check)
$WEB_ROUTE $SERVER2_IP_WWW(rw,sync,no_subtree_check)
EOF
echo "Archivo de configuración /etc/exports editado."

# Reiniciar el servicio NFS para aplicar los cambios.
sudo systemctl restart nfs-kernel-server

# Clonar la aplicación dentro del directorio compartido
cd "$WEB_ROUTE"
sudo git clone $REPOSITORIO_URL .
echo "Aplicación clonada en $WEB_ROUTE"

# Leer y activar inmediatamente /etc/exports
sudo exportfs -a 
echo "Exportaciones NFS activadas."

echo "Configuración del NFS completada con éxito."

