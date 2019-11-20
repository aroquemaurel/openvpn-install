#!/bin/bash

write_ipfw() {
	echo '#!/bin/sh
	EPAIR=$(/sbin/ifconfig -l | tr " " "\n" | /usr/bin/grep epair)
	ipfw -q -f flush
	ipfw -q nat 1 config if ${EPAIR}
	ipfw -q add nat 1 all from 10.8.0.0/24 to any out via ${EPAIR}
	ipfw -q add nat 1 all from any to any in via ${EPAIR}

	TUN=$(/sbin/ifconfig -l | tr " " "\n" | /usr/bin/grep tun)
	ifconfig ${TUN} name tun0 
	' >> /usr/local/etc/ipfw.rules
}

write_rc_conf() {
	echo 'openvpn_enable="YES"
	openvpn_if="tun"
	openvpn_configfile="'$path_openvpn'/server/openvpn.conf"
	openvpn_dir="/usr/local/etc/openvpn/"
	cloned_interfaces="tun"
	gateway_enable="YES"
	firewall_enable="YES"
	firewall_script="/usr/local/etc/ipfw.rules"' >> /etc/rc.conf
}

write_logs() {
	if ! grep -q openvpn /etc/newsyslog.conf; then
		echo " /var/log/openvpn.log 600 30 * @T00 ZC" >> /etc/newsyslog.conf
	fi

	if ! grep -q openvpn /etc/syslog.conf; then
		echo " !openvpn"
		echo "*.* /var/log/openvpn.log" >> /etc/syslog.conf
	fi
}
