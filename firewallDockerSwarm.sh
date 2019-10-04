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

	# Allow SSH IN GENRRAL
	$IPT -A INPUT -p tcp -m conntrack --ctstate NEW --dport 22 -j ACCEPT 

	# Allow icmp traffic
	$IPT -A INPUT -p icmp -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
}

function setManager(){
	# Docker Swarm Ports - Manager
	$IPT -A INPUT -p tcp -m conntrack --ctstate NEW -m multiport --dports 80,443 -j ACCEPT
	$IPT -A INPUT -p tcp -m conntrack --ctstate NEW -m multiport --dports 2376,2377,7946 -j ACCEPT
	$IPT -A INPUT -p udp -m conntrack --ctstate NEW -m multiport --dports 7946,4789 -j ACCEPT
}

function setWorker(){
	# Docker Swarm Ports - Worker
	$IPT -I INPUT -p udp -m conntrack --ctstate NEW -m multiport --dports 7946,4789 -j ACCEPT
	$IPT -I INPUT -p tcp -m conntrack --ctstate NEW -m multiport --dports 2376,7946 -j ACCEPT
	$IPT -I INPUT -p tcp -m conntrack --ctstate NEW -m multiport --dports 80,443 -j ACCEPT
}

funciton doFlush(){
	$IPT -F INPUT
	$IPT -F OUTPUT
}

case "$1" in 
	manager)
		setPolicy
		setGeneral
		setManager
		;;
	worker)
		setPolicy
		setGeneral
		setWorker
		;;
	flush)
		doFlush
		;;
	*)
	echo $"Usage: $0 {manager|worker|flush}"
	exit 1
esac

exit 0
