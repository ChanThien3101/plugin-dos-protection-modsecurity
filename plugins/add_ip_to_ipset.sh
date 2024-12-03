#!/bin/bash
IP="$1"
BAN_TIME="$2"
ipset add blocklistip "$IP" timeout "$BAN_TIME"

#which /usr/local/bin/add_ip_to_ipset.sh
