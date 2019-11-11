#!/bin/bash
write_server_conf() {
echo "port $port
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
}

write_client_conf() {
echo "client
dev tun
proto $protocol
remote $ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
block-outside-dns
verb 3" > $path_openvpn/server/client-common.txt
}

write_client_ovpn () {
	client_file=~/"$1".ovpn

	# Generates the custom client.ovpn
	cat $path_openvpn/server/client-common.txt > $client_file
	echo "<ca>" >> $client_file
	cat $path_openvpn/keys/ca.crt >> $client_file
	echo "</ca>" >> $client_file
	echo "<cert>" >> $client_file
	sed -ne '/BEGIN CERTIFICATE/,$ p' $path_openvpn/keys/"$1".crt >> $client_file
	echo "</cert>" >> $client_file
	echo "<key>" >> $client_file
	cat $path_openvpn/keys/"$1".key >> $client_file
	echo "</key>" >> $client_file
	echo "<tls-crypt>" >> $client_file
	sed -ne '/BEGIN OpenVPN Static key/,$ p' $path_openvpn/server/ta.key >> $client_file
	echo "</tls-crypt>" >> $client_file
}


