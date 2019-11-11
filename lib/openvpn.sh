#!/bin/bash

new_client () {
	# Generates the custom client.ovpn
	{
	cat $path_openvpn/server/client-common.txt
	echo "<ca>"
	cat path_openvpn/server/easy-rsa/pki/ca.crt
	echo "</ca>"
	echo "<cert>"
	sed -ne '/BEGIN CERTIFICATE/,$ p' $path_openvpn/server/easy-rsa/pki/issued/"$1".crt
	echo "</cert>"
	echo "<key>"
	cat $path_openvpn/server/easy-rsa/pki/private/"$1".key
	echo "</key>"
	echo "<tls-crypt>"
	sed -ne '/BEGIN OpenVPN Static key/,$ p' $path_openvpn/server/tc.key
	echo "</tls-crypt>"
	} > ~/"$1".ovpn
}


