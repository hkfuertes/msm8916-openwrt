#!/bin/sh

BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo 100)
OPERATOR=$(uci get network.modem.operator 2>/dev/null || echo "Unknown")
NETWORK="4G"
SSID=$(uci get wireless.@wifi-iface[0].ssid 2>/dev/null || echo "WiFi")
PASSWORD=$(uci get wireless.@wifi-iface[0].key 2>/dev/null || echo "")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "Router")

/usr/bin/router-display \
    -b "$BATTERY" \
    -n "$OPERATOR" \
    -t "$NETWORK" \
    -s "$SSID" \
    -p "$PASSWORD" \
    -h "$HOSTNAME" \
    -q > /dev/fb0
