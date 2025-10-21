#!/bin/sh
# LED Control Utility for OpenWrt
# Usage: ledcontrol <function> [color] <on|off|blink|blink_fast>
# Examples:
#   ledcontrol wan on          (MiFi with green:wan)
#   ledcontrol wlan on         (MiFi with green:wlan)
#   ledcontrol blue on         (Dongle with blue LED)
#   ledcontrol wan green on    (Explicit color override)

set -e

# Parse arguments (support both 2 and 3 arg syntax)
if [ $# -eq 2 ]; then
    # 2 args: <function_or_color> <action>
    SEARCH_KEY="$1"
    COLOR=""
    ACTION="$2"
elif [ $# -eq 3 ]; then
    # 3 args: <function> <color> <action>
    SEARCH_KEY="$1"
    COLOR="$2"
    ACTION="$3"
else
    echo "Usage: ledcontrol <function|color> <on|off|blink|blink_fast>" >&2
    echo "   or: ledcontrol <function> <color> <on|off|blink|blink_fast>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  ledcontrol wan on          # Auto-detect color (green:wan or blue)" >&2
    echo "  ledcontrol wlan off        # Auto-detect color (green:wlan or blue)" >&2
    echo "  ledcontrol blue blink      # Specific color LED" >&2
    echo "  ledcontrol wan green on    # Explicit function+color" >&2
    echo "" >&2
    echo "Available LEDs:" >&2
    ls -1 /sys/class/leds 2>/dev/null | grep -v "^mmc" | sed 's/^/  /' >&2
    exit 1
fi

LED_BASE="/sys/class/leds"

# Find LED with smart matching
find_led() {
    local search="$1"
    local color="$2"
    local led_path
    
    # Priority 1: Exact match with color prefix (green:wan, red:wlan)
    if [ -n "$color" ]; then
        led_path=$(find "$LED_BASE" -maxdepth 1 -type l -name "${color}:${search}" 2>/dev/null | head -n 1)
        if [ -n "$led_path" ]; then
            echo "$led_path"
            return 0
        fi
    fi
    
    # Priority 2: Function-based match (wan, wlan, charging)
    # Prefer green for status, fallback to any color
    for clr in green blue red amber; do
        led_path=$(find "$LED_BASE" -maxdepth 1 -type l -name "${clr}:${search}" 2>/dev/null | head -n 1)
        if [ -n "$led_path" ]; then
            echo "$led_path"
            return 0
        fi
    done
    
    # Priority 3: Color-only match (blue, green, red)
    led_path=$(find "$LED_BASE" -maxdepth 1 -type l -name "${search}" 2>/dev/null | head -n 1)
    if [ -n "$led_path" ]; then
        echo "$led_path"
        return 0
    fi
    
    # Priority 4: Case-insensitive partial match
    led_path=$(find "$LED_BASE" -maxdepth 1 -type l | grep -i "${search}" | grep -v "mmc" | head -n 1)
    if [ -n "$led_path" ]; then
        echo "$led_path"
        return 0
    fi
    
    logger -t ledcontrol "LED '$search' not found"
    echo "[!] LED '$search' not found" >&2
    echo "[*] Available LEDs:" >&2
    ls -1 "$LED_BASE" 2>/dev/null | grep -v "^mmc" | sed 's/^/    /' >&2
    return 1
}

# Set LED state
set_led() {
    local led_path="$1"
    local action="$2"
    
    case "$action" in
        on)
            echo none > "$led_path/trigger" 2>/dev/null || true
            echo 1 > "$led_path/brightness"
            ;;
        off)
            echo none > "$led_path/trigger" 2>/dev/null || true
            echo 0 > "$led_path/brightness"
            ;;
        blink)
            echo timer > "$led_path/trigger" 2>/dev/null || {
                echo "[!] Blink not supported, setting ON" >&2
                echo 1 > "$led_path/brightness"
                return 0
            }
            echo 500 > "$led_path/delay_on" 2>/dev/null || true
            echo 500 > "$led_path/delay_off" 2>/dev/null || true
            ;;
        blink_fast)
            echo timer > "$led_path/trigger" 2>/dev/null || {
                echo "[!] Blink not supported, setting ON" >&2
                echo 1 > "$led_path/brightness"
                return 0
            }
            echo 100 > "$led_path/delay_on" 2>/dev/null || true
            echo 100 > "$led_path/delay_off" 2>/dev/null || true
            ;;
        *)
            logger -t ledcontrol "Invalid action: $action"
            echo "[!] Invalid action: $action" >&2
            echo "[*] Valid actions: on, off, blink, blink_fast" >&2
            return 1
            ;;
    esac
}

# Main
LED_PATH=$(find_led "$SEARCH_KEY" "$COLOR") || exit 1
LED_NAME=$(basename "$LED_PATH")

if set_led "$LED_PATH" "$ACTION"; then
    logger -t ledcontrol "LED '$LED_NAME' set to '$ACTION'"
    echo "[+] LED '$LED_NAME' set to '$ACTION'"
else
    exit 1
fi
