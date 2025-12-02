#!/bin/bash

# variables de entorno
SERVER1_IP_WWW="192.168.10.10"
SERVER2_IP_WWW="192.168.10.20"

# Actualizar el sistema e instalar Apache.
sudo apt update 
sudo apt install -y apache2

# Proxy; módulos.
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests

sudo systemctl restart apache2

# Crear archivo de configuración del proxy inverso.
cd /etc/apache2/sites-available
sudo cp 000-default.conf balanceador.conf
sudo tee balanceador.conf <<EOF
<VirtualHost *:80>
    ServerName iawcris.ddns.net

    <Proxy balancer://wpbalanceadorweb>
        # Server 1
        BalancerMember http://$SERVER1_IP_WWW:80 route=1

        # Server 2
        BalancerMember http://$SERVER2_IP_WWW:80 route=2

        # Sticky Sessions para WordPress.
        ProxySet stickysession=ROUTEID
    </Proxy>

    ProxyPass / balancer://wpbalanceadorweb/
    ProxyPassReverse / balancer://wpbalanceadorweb/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Habilitar el site configurado y deshabilitar el que viene por defecto.
sudo a2ensite balanceador.conf
sudo a2dissite 000-default.conf

# Reiniciar Apache.
sudo systemctl restart apache2

echo "Configuración del balanceador completada con éxito."