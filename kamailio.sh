echo -e "\o/ Instalación de kamailio"
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xfb40d3e6508ea4c8
echo "deb http://deb.kamailio.org/kamailio wheezy main" >> /etc/apt/sources.list
echo "deb-src http://deb.kamailio.org/kamailio wheezy main" >> /etc/apt/sources.list
apt-get update
apt-get install kamailio kamailio-mysql-modules kamailio-tls-modules rtpproxy

usermod -a -G rtpproxy kamailio

#### Alternativa
#crear usuario de sistema rtpproxy
#instalar rtproxy desde fuentes
#crear init.d de rtpproxy
#git clone https://github.com/sippy/rtpproxy.git
#cd rtpproxy
#./configure
#make
#make install
#rtpproxy -u rtpproxy -l xx.xx.xx.xx -s udp:127.0.0.1:7722

sed -i "s|#RUN_KAMAILIO=yes|RUN_KAMAILIO=yes|g" /etc/default/kamailio 

echo -n "Escriba dominio: "
read dominio
echo -e "\n"

read -s -p "Invente una clave para el usuario rw: " kamailiorw
echo -e "\n"

read -s -p "Invente una clave para el usuario ro: " kamailioro
echo -e "\n"

sed -i "s|# SIP_DOMAIN=kamailio.org|SIP_DOMAIN=${dominio}|g ; s|# DBENGINE=MYSQL|DBENGINE=MYSQL|g ; s|# DBRWPW=\"kamailiorw\"|DBRWPW=\"${kamailiorw}\"|g ; s|# DBROPW=\"kamailioro\"|DBROPW=\"${kamailioro}\"|g ; s|# STORE_PLAINTEXT_PW=0|STORE_PLAINTEXT_PW=0|g" /etc/kamailio/kamctlrc

sed -i "s|#!KAMAILIO||g" /etc/kamailio/kamailio.cfg
sed -i "1i #!KAMAILIO\n#!define WITH_MYSQL\n#!define WITH_AUTH\n#!define WITH_USRLOCDB\n#!define WITH_NAT\n#!define WITH_TLS\n" /etc/kamailio/kamailio.cfg

sed -i 's|modparam("rtpproxy", "rtpproxy_sock", "udp:127.0.0.1:7722")|modparam("rtpproxy", "rtpproxy_sock", "unix:/var/run/rtpproxy/rtpproxy.sock")|g' /etc/kamailio/kamailio.cfg

sed -i "s|#alias=\"sip.mydomain.com\"|alias=\"${dominio}\"|g" /etc/kamailio/kamailio.cfg
sed -i 's|modparam("auth_db", "calculate_ha1", yes)|modparam("auth_db", "calculate_ha1", 0)|g ; s|modparam("auth_db", "password_column", "password")|modparam("auth_db", "password_column", "ha1")|g' /etc/kamailio/kamailio.cfg

#pedir y cambiar contraseñas para kamailiorw y kamailioro

rm /etc/kamailio/tls.cfg
cat > /etc/kamailio/tls.cfg << EOF
#
# TLS Configuration File
#

# This is the default server domain, settings
# in this domain will be used for all incoming
# connections that do not match any other server
# domain in this configuration file.
#
[server:default]
method = TLSv1
verify_certificate = no
require_certificate = no
private_key = /etc/kamailio/kamailio-selfsigned.key
certificate = /etc/kamailio/kamailio-selfsigned.pem
EOF

echo -e "Creacion de base de datos"

kamdbctl create

echo -e "(-_-) Creación de usuarios"
while :
do
	echo -n "\o Extensión: "
	read extension
	read -s -p "o/ Contraseña: " contrasena
	echo -e "\n"
	kamctl add $extension $contrasena
	echo -n "¿Crear otro? [s/n]: "
	read sino
	if [ $sino == "n" ]; then
		break
	fi 
done


/etc/init.d/kamailio start
