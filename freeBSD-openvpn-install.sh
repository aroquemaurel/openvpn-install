#!/bin/bash
path_openvpn="/usr/local/etc/openvpn"

source lib/utils.sh
source lib/openvpn.sh
source lib/ask_infos.sh

source lib/freebsd_configuration.sh


if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi



echo

ask_protocol
ask_port

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

echo_empty_line
ask_client_name

echo_empty_line
ask_any_key

pkg update & pkg upgrade -y && pkg install -y nano openvpn mpack

if [[ ! -e $path_openvpn/keys ]]; then
	mkdir -p $path_openvpn/keys
fi

cp -r /usr/local/share/easy-rsa $path_openvpn/easy-rsa

echo 'set_var EASYRSA_REQ_COUNTRY	"FR"
set_var EASYRSA_REQ_PROVINCE	"France"
set_var EASYRSA_REQ_CITY	"Rueil-Malmaison"
set_var EASYRSA_REQ_ORG		"Copyleft Certificate Co"
set_var EASYRSA_REQ_EMAIL	"satenske@roquemaurel.pro"
set_var EASYRSA_KEY_SIZE	2048' > $path_openvpn/easy-rsa/vars

cd $path_openvpn/easy-rsa
./easyrsa.real init-pki
./easyrsa.real build-ca nopass
./easyrsa.real build-server-full openvpn-server nopass
./easyrsa.real build-client-full $client nopass
./easyrsa.real gen-dh

openvpn --genkey --secret ta.key
cp pki/dh.pem pki/ca.crt pki/issued/openvpn-server.crt pki/private/openvpn-server.key $path_openvpn/keys
cp ta.key $path_openvpn/keys
cp pki/issued/$client.crt pki/private/$client.key $path_openvpn/keys
cd - >> /dev/null # TODO : go to script path

if [[ ! -e $path_openvpn/server ]]; then
	mkdir -p $path_openvpn/server
fi

write_server_conf

write_client_conf
write_client_ovpn $client

write_ipfw

write_rc_conf

write_logs
