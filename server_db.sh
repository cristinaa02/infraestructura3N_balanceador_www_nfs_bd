#!/bin/bash

# Cargar las variables de entorno
source .env

# Actualizar el sistema e instalar MariaDB y Git.
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install mariadb-server git -y

# Configurando MySQL para escuchar en 0.0.0.0.
sudo sed -i "s/^bind-address.*127.0.0.1/bind-address = 0.0.0.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb

# Creando la BD y usuario.
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARSET utf8mb4;
CREATE USER '$DB_USER1'@'$SERVER1_IP_DB' IDENTIFIED BY '$DB_PASS';
CREATE USER '$DB_USER2'@'$SERVER2_IP_DB' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER1'@'$SERVER1_IP_DB';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER2'@'$SERVER2_IP_DB';
FLUSH PRIVILEGES;
EOF
echo "Usuario server1: $DB_USER1"
echo "Usuario server2: $DB_USER2"
echo "Contraseña: $DB_PASS"
echo "Creada la BD con acceso a $SERVER1_IP_DB."
echo "Creada la BD con acceso a $SERVER2_IP_DB."

# Clonar temporalmente el repositorio para obtener el archivo SQL
git clone $REPOSITORIO_URL /tmp/iaw-practica-lamp
echo "Repositorio clonado."

# Importando el archivo sql del repositorio.
if [ -f "/tmp/iaw-practica-lamp/db/database.sql" ]; then
    sudo mysql -u root $DB_NAME < "/tmp/iaw-practica-lamp/db/database.sql"
    echo "Archivo database.sql copiado."
else
    echo "ERROR: Archivo database.sql no encontrado."
fi

# Eliminar la carpeta temporal
sudo rm -rf /tmp/iaw-practica-lamp
echo "Repositorio temporal eliminado."

# Eliminar la puerta de enlace de la NAT
sudo ip route del default

echo "Configuración de la base de datos completada con éxito."