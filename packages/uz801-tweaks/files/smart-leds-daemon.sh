#!/bin/sh
# /usr/bin/smart-leds-daemon

while true; do
    # WiFi LED 
    if ip link show phy0-ap0 2>/dev/null | grep -q "UP"; then
        echo 1 > /sys/class/leds/blue:wan/brightness
    else
        echo 0 > /sys/class/leds/blue:wan/brightness
    fi
    
    # 4G LED
    if ip addr show wwan0 2>/dev/null | grep -q "inet "; then
        echo 1 > /sys/class/leds/green:wlan/brightness
    else
        echo 0 > /sys/class/leds/green:wlan/brightness
    fi
    
    sleep 10
done
