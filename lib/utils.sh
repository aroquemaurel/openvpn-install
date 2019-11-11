#!/bin/bash

echo_empty_line() {
	echo ""
}

ask_any_key() {
	echo "Okay, that was all I needed. We are ready to set up your OpenVPN server now."
	read -n1 -r -p "Press any key to continue..."
}
