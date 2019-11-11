#!/bin/bash
source lib/openvpn.sh

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

path_openvpn="/usr/local/etc/openvpn"


echo
protocol=ask_protocol()
echo
port=ask_port()
echo

#echo "Which DNS do you want to use with the VPN?"
#echo "   1) Current system resolvers"
#echo "   2) 1.1.1.1"
#echo "   3) Google"
#echo "   4) OpenDNS"
#echo "   5) Verisign"
#read -p "DNS [1]: " dns
#until [[ -z "$dns" || "$dns" =~ ^[1-5]$ ]]; do
	#echo "$dns: invalid selection."
#	read -p "DNS [1]: " dns
#done

echo
echo "Finally, tell me a name for the client certificate."
read -p "Client name [client]: " unsanitized_client
# Allow a limited set of characters to avoid conflicts
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
[[ -z "$client" ]] && client="client"
echo
echo "Okay, that was all I needed. We are ready to set up your OpenVPN server now."
read -n1 -r -p "Press any key to continue..."

pkg update & pkg upgrade -y && pkg install -y nano openvpn mpack

if [[ ! -e $path_openvpn/keys ]]; then
	mkdir -p $path_openvpn/keys
fi

cp -r /usr/local/share/easy-rsa $path_openvpn/easy-rsa
cp rsa_keys $path_openvpn/easy-rsa/vars
cd $path_openvpn/easy-rsa
#./easyrsa.real init-pki
#./easyrsa.real build-ca nopass
#./easyrsa.real build-server-full openvpn-server nopass
#./easyrsa.real build-client-full TODO nopass
#./easyrsa.real gen-dh
openvpn --genkey --secret ta.key
cp pki/dh.pem pki/ca.crt pki/issued/openvpn-server.crt pki/private/openvpn-server.key $path_openvpn/keys
cp ta.key $path_openvpn/keys
cp pki/issued/TODO.crt pki/private/TODO.key $path_openvpn/keys
cd - # TODO : go to script path

if [[ ! -e $path_openvpn/server ]]; then
	mkdir -p $path_openvpn/server
fi
# Generate openvpn.conf
echo "local $ip
port $port
proto $protocol
dev tun
ca ca.crt
cert server.crt
key keys/openvpn-server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > $path_openvpn/server/openvpn.conf

echo 'push "redirect-gateway def1 bypass-dhcp"
cipher AES-256-CBC
user nobody
group nobody 
persist-key
persist-tun
status openvpn-status.log
verb 3' >> $path_openvpn/server/openvpn.conf

echo '#!/bin/sh
EPAIR=$(/sbin/ifconfig -l | tr " " "\n" | /usr/bin/grep epair)
ipfw -q -f flush
ipfw -q nat 1 config if ${EPAIR}
ipfw -q add nat 1 all from 10.8.0.0/24 to any out via ${EPAIR}
ipfw -q add nat 1 all from any to any in via ${EPAIR}

TUN=$(/sbin/ifconfig -l | tr " " "\n" | /usr/bin/grep tun)
ifconfig ${TUN} name tun0 
' >> /usr/local/etc/ipfw.rules

echo 'openvpn_enable="YES"
openvpn_if="tun"
openvpn_configfile="/usr/local/etc/openvpn/openvpn.conf"
openvpn_dir="/usr/local/etc/openvpn/"
cloned_interfaces="tun"
gateway_enable="YES"
firewall_enable="YES"
firewall_script="/usr/local/etc/ipfw.rules"' >> /etc/rc.conf

if ! grep -q openvpn /etc/newsyslog.conf; then
	echo " /var/log/openvpn.log 600 30 * @T00 ZC" >> /etc/newsyslog.conf
fi

if ! grep -q openvpn /etc/syslog.conf; then
	echo " !openvpn
	*.* /var/log/openvpn.log" >> /etc/syslog.conf
fi

