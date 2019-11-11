#!/bin/bash

# return $protocol
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
}

# Return $port 
ask_port() {
    echo "What port do you want OpenVPN listening to?"
    read -p "Port [1194]: " port
    until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
	    echo "$port: invalid selection."
	    read -p "Port [1194]: " port
    done
    [[ -z "$port" ]] && port="1194"
}

# Return $client
ask_client_name() {
	echo "Finally, tell me a name for the client certificate."
	read -p "Client name [client]: " unsanitized_client
	# Allow a limited set of characters to avoid conflicts
	client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
	[[ -z "$client" ]] && client="client"
}

