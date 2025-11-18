#!/bin/bash

# Cargar las variables de entorno
source .env

# Actualizar el sistema e instalar Apache.
sudo apt update && sudo apt install apache2 -y

# Proxy; módulos.
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests

echo "Apache y módulos de proxy inverso instalados."

# Reiniciar Apache.
sudo systemctl restart apache2

# Crear archivo de configuración del proxy inverso.
cd /etc/apache2/sites-available
sudo cp 000-default.conf balanceador.conf
sudo tee balanceador.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/web

    <Proxy balancer://serverbalanceador>
        # Server 1
        BalancerMember http://$SERVER1_IP_WWW

        # Server 2
        BalancerMember http://$SERVER2_IP_WWW
    </Proxy>

    ProxyPass / balancer://serverbalanceador/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
echo "Archivo de configuración del balanceador.conf creado."

# Habilitar el site configurado y deshabilitar el que viene por defecto.
sudo a2ensite balanceador.conf
sudo a2dissite 000-default.conf
echo "Habilitado el archivo /etc/apache2/sites-available/balanceador.conf."
# Reiniciar Apache.
sudo systemctl restart apache2

echo "Configuración del balanceador completada con éxito."