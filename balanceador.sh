#!/bin/bash

# variables de entorno
SERVER1_IP_WWW="192.168.10.10"
SERVER2_IP_WWW="192.168.10.20"

set -e
sudo hostnamectl set-hostname BalanceadorCrisAlm

# Actualizar el sistema e instalar Apache y SSL.
sudo apt update 
sudo apt install -y apache2 ssl-cert

# Proxy; módulos.
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests
sudo a2enmod ssl
sudo a2enmod headers

sudo systemctl restart apache2

# Crear archivo de configuración del proxy inverso.
cd /etc/apache2/sites-available

# Configurando HTTP (redirigir a HTTPS)
sudo tee balanceadorhttp.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName iawcris.ddns.net
    
    Redirect permanent / https://iawcris.ddns.net/ 

    ErrorLog ${APACHE_LOG_DIR}/balancer_http_error.log
    CustomLog ${APACHE_LOG_DIR}/balancer_http_access.log combined
</VirtualHost>
EOF

sudo tee balanceadorhttps.conf <<EOF
<VirtualHost *:443>
    ServerName iawcris.ddns.net

    <Proxy balancer://wpbalanceadorweb>
        # Server 1
        BalancerMember https://$SERVER1_IP_WWW:443 route=1

        # Server 2
        BalancerMember https://$SERVER2_IP_WWW:443 route=2

        # Sticky Sessions para WordPress.
        ProxySet stickysession=ROUTEID
    </Proxy>

    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    ProxyPass / balancer://wpbalanceadorweb/
    ProxyPassReverse / balancer://wpbalanceadorweb/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Habilitar el site configurado y deshabilitar el que viene por defecto.
sudo a2ensite balanceadorhttps.conf
sudo a2ensite balanceadorhttp.conf
sudo a2dissite 000-default.conf

# Reiniciar Apache.
sudo systemctl restart apache2

echo "Configuración del balanceador completada con éxito."