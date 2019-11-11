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

ask_protocol() {
    echo "Which protocol do you want for OpenVPN connections?"
    echo "   1) UDP (recommended)"
    echo "   2) TCP"
    read -p "Protocol [1]: " protocol
    until [[ -z "$protocol" || "$protocol" =~ ^[12]$ ]]; do
	    echo "$protocol: invalid selection."
	    read -p "Protocol [1]: " protocol
    done
    case "$protocol" in
	    1|"") 
	    protocol=udp
	    ;;
	    2) 
	    protocol=tcp
	    ;;
    esac
    
    return $protocol
}

ask_port() {
    echo "What port do you want OpenVPN listening to?"
    read -p "Port [1194]: " port
    until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
	    echo "$port: invalid selection."
	    read -p "Port [1194]: " port
    done
    [[ -z "$port" ]] && port="1194"
    
    return $port
}
