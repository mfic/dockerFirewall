#!/bin/bash

# Add iptables variable
IPT=iptables

function setPolicy(){
	# Set deafult policies
	$IPT -P INPUT DROP
	$IPT -P OUTPUT DROP
	$IPT -P FORWARD DROP
}

function setGeneral(){
	# Allow loopback
	$IPT -A OUTPUT -o lo -j ACCEPT
	$IPT -A INPUT -i lo -j ACCEPT

	# Allow running traffic
	$IPT -A OUTPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
	$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

	# Allow SSH traffic
	$IPT -A INPUT -p tcp -m conntrack --ctstate NEW --dport 22 -j ACCEPT

	# Allow icmp traffic
	$IPT -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
	$IPT -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
	$IPT -A INPUT -p icmp -m conntrack --ctstate NEW -m icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT}

function setWebserver() {
	# Allow HTTP traffic
	$IPT -A INPUT -p tcp -m conntrack --cstate NEW --dport 80 -j ACCEPT
	# Allow HTTPS traffic
	$IPT -A INPUT -p tcp -m conntrack --cstate NEW --dport 443 -j ACCEPT
}

function setMailserver() {
	# Allow IMAP traffic
	$IPT -A INPUT -p tcp -m conntrack --cstate NEW -m multiport --dport 993,143 -j ACCEPT
	# Allow SMTP traffic
	$IPT -A INPUT -p tcp -m conntrack --cstate NEW -m multiport --dport 25,587 -j ACCEPT
}

function setTeamspeak() {
	$IPT -A INPUT -p tcp -m conntrack --cstate NEW -m multiport --dport 2008,10011,30033,4144 -j ACCEPT
	$IPT -A INPUT -p udp -m conntrack --cstate NEW -m multiport --dport 9987 -j ACCEPT
}

function doFlush(){
	$IPT -F INPUT
	$IPT -F OUTPUT
}

case "$1" in
	general)
		setPolicy
		setGeneral
		;;
	webserver)
		setWebserver
		;;
	mailserver)
		setMailserver
		;;
	flush)
		doFlush
		;;
	*)
	echo $"Usage: $0 {general|webserver|mailserver}"
	exit 1
esac

exit 0
