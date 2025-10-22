#!/bin/sh
# LED Control Utility for OpenWrt
# Usage: ledcontrol <color:function> <on|off|blink|blink_fast>
# Examples:
#   ledcontrol green:wan on
#   ledcontrol blue:wlan blink
#   ledcontrol red:charging off

set -e

# Parse arguments
if [ $# -ne 2 ]; then
    echo "Usage: ledcontrol <color:function> <on|off|blink|blink_fast>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  ledcontrol green:wan on" >&2
    echo "  ledcontrol blue:wlan blink" >&2
    echo "  ledcontrol red:charging off" >&2
    echo "" >&2
    echo "Available LEDs:" >&2
    ls -1 /sys/class/leds 2>/dev/null | grep -v "^mmc" | sed 's/^/  /' >&2
    exit 1
fi

LED_NAME="$1"
ACTION="$2"
LED_PATH="/sys/class/leds/$LED_NAME"

# Check if LED exists
if [ ! -d "$LED_PATH" ]; then
    echo "[!] LED '$LED_NAME' not found" >&2
    echo "[*] Available LEDs:" >&2
    ls -1 /sys/class/leds 2>/dev/null | grep -v "^mmc" | sed 's/^/    /' >&2
    exit 1
fi

# Set LED state
case "$ACTION" in
    on)
        echo none > "$LED_PATH/trigger" 2>/dev/null || true
        echo 1 > "$LED_PATH/brightness"
        ;;
    off)
        echo none > "$LED_PATH/trigger" 2>/dev/null || true
        echo 0 > "$LED_PATH/brightness"
        ;;
    blink)
        echo timer > "$LED_PATH/trigger" 2>/dev/null || {
            echo "[!] Blink not supported, setting ON" >&2
            echo 1 > "$LED_PATH/brightness"
            exit 0
        }
        echo 500 > "$LED_PATH/delay_on" 2>/dev/null || true
        echo 500 > "$LED_PATH/delay_off" 2>/dev/null || true
        ;;
    blink_fast)
        echo timer > "$LED_PATH/trigger" 2>/dev/null || {
            echo "[!] Blink not supported, setting ON" >&2
            echo 1 > "$LED_PATH/brightness"
            exit 0
        }
        echo 100 > "$LED_PATH/delay_on" 2>/dev/null || true
        echo 100 > "$LED_PATH/delay_off" 2>/dev/null || true
        ;;
    *)
        echo "[!] Invalid action: $ACTION" >&2
        echo "[*] Valid actions: on, off, blink, blink_fast" >&2
        exit 1
        ;;
esac

logger -t ledcontrol "LED '$LED_NAME' set to '$ACTION'"

# Only print to stdout if running interactively (not from a script/service)
[ -t 1 ] && echo "[+] LED '$LED_NAME' set to '$ACTION'"
