#!/bin/sh

# === BATERÍA ===
BMS_PATH="/sys/class/power_supply/pm8916-bms-vm"

VOLTAGE=$(cat "$BMS_PATH/voltage_now" 2>/dev/null)
VMAX=$(cat "$BMS_PATH/voltage_max_design" 2>/dev/null)
VMIN=$(cat "$BMS_PATH/voltage_min_design" 2>/dev/null)

if [ -n "$VOLTAGE" ] && [ -n "$VMAX" ] && [ -n "$VMIN" ]; then
    BATTERY=$(awk "BEGIN {pct = (($VOLTAGE - $VMIN) / ($VMAX - $VMIN)) * 100; if(pct < 0) pct=0; if(pct > 100) pct=100; printf \"%.0f\", pct}")
else
    BATTERY=100
fi

# === WiFi AP ===
SHOW_QR=0
if ip link show phy0-ap0 2>/dev/null | grep -q "state UP"; then
    SHOW_QR=1
fi

# === MODEM ===
MODEM_IDX=$(mmcli -L 2>/dev/null | grep -oE 'Modem/[0-9]+' | head -1 | cut -d'/' -f2)

if [ -n "$MODEM_IDX" ]; then
    # Operador siempre viene de la SIM (disponible aunque no haya señal)
    SIM_IDX=$(mmcli -m "$MODEM_IDX" -K 2>/dev/null | grep 'modem.generic.sim' | awk -F': ' '{print $2}' | grep -oE '[0-9]+$')
    
    if [ -n "$SIM_IDX" ]; then
        OPERATOR=$(mmcli -i "$SIM_IDX" -K 2>/dev/null | grep 'sim.properties.operator-name' | awk -F': ' '{print $2}')
    fi
    
    # Fallback al operador de red si la SIM no tiene nombre
    if [ -z "$OPERATOR" ]; then
        OPERATOR=$(mmcli -m "$MODEM_IDX" -K 2>/dev/null | grep 'modem.3gpp.operator-name' | awk -F': ' '{print $2}')
    fi
    
    # Tecnología de acceso (solo disponible si hay conexión activa)
    ACCESS_TECH=$(mmcli -m "$MODEM_IDX" -K 2>/dev/null | grep 'modem.generic.access-technologies' | awk -F': ' '{print $2}')
    
    # Si no hay access-technologies, no hay conexión -> red vacía
    if [ -n "$ACCESS_TECH" ] && [ "$ACCESS_TECH" != "unknown" ]; then
        case "$ACCESS_TECH" in
            *lte*) NETWORK="4G" ;;
            *umts*|*hspa*|*hsupa*|*hsdpa*) NETWORK="3G" ;;
            *edge*|*gprs*|*gsm*) NETWORK="2G" ;;
            *) NETWORK="$ACCESS_TECH" ;;
        esac
    else
        # Sin conexión: mostrar operador pero sin tipo de red
        NETWORK=""
    fi
else
    # Sin módem
    OPERATOR=""
    NETWORK=""
fi

# === WiFi Info ===
SSID=$(uci get wireless.@wifi-iface[0].ssid 2>/dev/null || echo "WiFi")
PASSWORD=$(uci get wireless.@wifi-iface[0].key 2>/dev/null || echo "")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "Router")

# === Actualizar Display ===
if [ "$SHOW_QR" -eq 1 ]; then
    /usr/bin/router-display -q -b "$BATTERY" -n "$OPERATOR" -t "$NETWORK" -s "$SSID" -p "$PASSWORD" -h "$HOSTNAME" > /dev/fb0
else
    /usr/bin/router-display -b "$BATTERY" -n "$OPERATOR" -t "$NETWORK" -s "$SSID" -p "$PASSWORD" -h "$HOSTNAME" > /dev/fb0
fi
