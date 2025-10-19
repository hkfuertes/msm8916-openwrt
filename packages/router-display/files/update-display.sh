#!/bin/sh
# /usr/sbin/update-display
# Optimized display update script - caches operator name (requires reboot to change SIM)

# === BATTERY ===
BMS_PATH="/sys/class/power_supply/pm8916-bms-vm"

VOLTAGE=$(cat "$BMS_PATH/voltage_now" 2>/dev/null)
VMAX=$(cat "$BMS_PATH/voltage_max_design" 2>/dev/null)
VMIN=$(cat "$BMS_PATH/voltage_min_design" 2>/dev/null)

# Check charging status
CHARGING_STATUS=$(cat "$BMS_PATH/status" 2>/dev/null)
CHARGING_FLAG=""

if [ "$CHARGING_STATUS" = "Charging" ] || [ "$CHARGING_STATUS" = "Full" ]; then
    CHARGING_FLAG="-c"
fi

if [ -n "$VOLTAGE" ] && [ -n "$VMAX" ] && [ -n "$VMIN" ]; then
    BATTERY=$(awk "BEGIN {pct = (($VOLTAGE - $VMIN) / ($VMAX - $VMIN)) * 100; if(pct < 0) pct=0; if(pct > 100) pct=100; printf \"%.0f\", pct}")
else
    BATTERY=100
fi

# === WiFi AP ===
QR_FLAG=""
if ip link show phy0-ap0 2>/dev/null | grep -q "state UP"; then
    QR_FLAG="-q"
fi

# === MODEM (OPTIMIZED - single mmcli call + operator cache) ===
OPERATOR_CACHE="/tmp/modem_operator.cache"
MODEM_IDX=$(mmcli -L 2>/dev/null | grep -oE 'Modem/[0-9]+' | head -1 | cut -d'/' -f2)

if [ -n "$MODEM_IDX" ]; then
    # Single mmcli call - cache all modem data
    MODEM_DATA=$(mmcli -m "$MODEM_IDX" -K 2>/dev/null)
    
    # Try to get operator from cache first (SIM doesn't change without reboot)
    if [ -f "$OPERATOR_CACHE" ]; then
        OPERATOR=$(cat "$OPERATOR_CACHE")
    else
        # Cache miss - fetch operator from SIM
        SIM_IDX=$(echo "$MODEM_DATA" | grep 'modem.generic.sim' | awk -F': ' '{print $2}' | grep -oE '[0-9]+$')
        
        if [ -n "$SIM_IDX" ]; then
            OPERATOR=$(mmcli -i "$SIM_IDX" -K 2>/dev/null | grep 'sim.properties.operator-name' | awk -F': ' '{print $2}')
        fi
        
        # Fallback: operator from network (use cached modem data)
        if [ -z "$OPERATOR" ]; then
            OPERATOR=$(echo "$MODEM_DATA" | grep 'modem.3gpp.operator-name' | awk -F': ' '{print $2}')
        fi
        
        # Cache operator for future calls
        if [ -n "$OPERATOR" ]; then
            echo "$OPERATOR" > "$OPERATOR_CACHE"
        fi
    fi
    
    # Access technology (use cached modem data)
    ACCESS_TECH=$(echo "$MODEM_DATA" | grep 'modem.generic.access-technologies' | awk -F': ' '{print $2}')
    
    # Determine network type only if connected
    if [ -n "$ACCESS_TECH" ] && [ "$ACCESS_TECH" != "unknown" ]; then
        case "$ACCESS_TECH" in
            *lte*) NETWORK="4G" ;;
            *umts*|*hspa*|*hsupa*|*hsdpa*) NETWORK="3G" ;;
            *edge*|*gprs*|*gsm*) NETWORK="2G" ;;
            *) NETWORK="$ACCESS_TECH" ;;
        esac
    else
        # No connection: show operator but no network type
        NETWORK=""
    fi
else
    # No modem
    OPERATOR=""
    NETWORK=""
fi

# === WiFi Info ===
SSID=$(uci get wireless.@wifi-iface[0].ssid 2>/dev/null || echo "WiFi")
PASSWORD=$(uci get wireless.@wifi-iface[0].key 2>/dev/null || echo "")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "Router")

# === Update Display ===
/usr/bin/router-display $QR_FLAG $CHARGING_FLAG -b "$BATTERY" -n "$OPERATOR" -t "$NETWORK" -s "$SSID" -p "$PASSWORD" -h "$HOSTNAME" > /dev/fb0
