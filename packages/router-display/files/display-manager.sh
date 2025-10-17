#!/bin/sh
# /usr/sbin/display-manager
# Central display timer daemon using FIFO with UCI configuration

# Load UCI config
. /lib/functions.sh

# UCI config section: system.display
config_load system

# Default values
DEFAULT_TIMEOUT_DIM=5
DEFAULT_TIMEOUT_OFF=3
DEFAULT_BRIGHTNESS_DIM_DIVISOR=8
DEFAULT_BRIGHTNESS_OFF=1
DEFAULT_BACKLIGHT_PATH="/sys/class/backlight/backlight"
DEFAULT_FIFO="/var/run/display.fifo"
DEFAULT_ENABLE_LOCKSCREEN=0

# Load config from UCI (with defaults)
config_get TIMEOUT_DIM display timeout_dim "$DEFAULT_TIMEOUT_DIM"
config_get TIMEOUT_OFF display timeout_off "$DEFAULT_TIMEOUT_OFF"
config_get BRIGHTNESS_DIM_DIVISOR display brightness_dim_divisor "$DEFAULT_BRIGHTNESS_DIM_DIVISOR"
config_get BRIGHTNESS_OFF display brightness_off "$DEFAULT_BRIGHTNESS_OFF"
config_get BACKLIGHT_PATH display backlight_path "$DEFAULT_BACKLIGHT_PATH"
config_get FIFO display fifo "$DEFAULT_FIFO"
config_get ENABLE_LOCKSCREEN display enable_lockscreen "$DEFAULT_ENABLE_LOCKSCREEN"

# Calculated variables
MAX_BRIGHTNESS=$(cat "$BACKLIGHT_PATH/max_brightness" 2>/dev/null || echo 1785)
BRIGHTNESS_FULL=$MAX_BRIGHTNESS
BRIGHTNESS_DIM=$((MAX_BRIGHTNESS / BRIGHTNESS_DIM_DIVISOR))

# Timer PIDs
TIMER_DIM_PID=""
TIMER_OFF_PID=""

# Create FIFO if not exists
[ -e "$FIFO" ] || mkfifo "$FIFO"

# Cleanup on exit
trap "rm -f $FIFO; exit 0" EXIT TERM INT

maybe_set_lockscreen() {
    # Only set lockscreen if enabled in config
    [ "$ENABLE_LOCKSCREEN" = "1" ] && \
    [ -n "$1" ] && [ "$1" = "$BRIGHTNESS_DIM" ] && [ -f /etc/boot_logo.fb ] && \
        cat /etc/boot_logo.fb > /dev/fb0 2>/dev/null
}

set_brightness() {
    echo "$1" > "$BACKLIGHT_PATH/brightness"
    maybe_set_lockscreen "$1"
}

cancel_timers() {
    [ -n "$TIMER_DIM_PID" ] && kill "$TIMER_DIM_PID" 2>/dev/null
    [ -n "$TIMER_OFF_PID" ] && kill "$TIMER_OFF_PID" 2>/dev/null
    TIMER_DIM_PID=""
    TIMER_OFF_PID=""
}

start_timers() {
    # Cancel previous timers
    cancel_timers
    
    # Timer 1: DIM after TIMEOUT_DIM seconds
    (
        sleep $TIMEOUT_DIM
        logger -t display "Backlight: DIM"
        set_brightness $BRIGHTNESS_DIM
    ) &
    TIMER_DIM_PID=$!
    
    # Timer 2: OFF after (TIMEOUT_DIM + TIMEOUT_OFF) seconds
    TOTAL_TIMEOUT=$((TIMEOUT_DIM + TIMEOUT_OFF))
    (
        sleep $TOTAL_TIMEOUT
        logger -t display "Backlight: OFF"
        set_brightness $BRIGHTNESS_OFF
    ) &
    TIMER_OFF_PID=$!
}

logger -t display "Display manager started (dim:${TIMEOUT_DIM}s off:${TIMEOUT_OFF}s)"

# Main loop reading from FIFO
while true; do
    if read -r cmd < "$FIFO"; then
        case "$cmd" in
            full)
                logger -t display "Backlight: FULL"
                set_brightness $BRIGHTNESS_FULL
                
                # Update display content
                if [ -x /usr/sbin/update-display ]; then
                    /usr/sbin/update-display &
                fi
                
                # Start auto-dim/off timers
                start_timers
                ;;
            dim)
                logger -t display "Backlight: DIM (manual)"
                cancel_timers
                set_brightness $BRIGHTNESS_DIM
                ;;
            off)
                logger -t display "Backlight: OFF (manual)"
                cancel_timers
                set_brightness $BRIGHTNESS_OFF
                ;;
            cancel)
                logger -t display "Timers cancelled"
                cancel_timers
                ;;
            shutdown)
                logger -t display "Shutdown signal received"
                cancel_timers
                echo 0 > "$BACKLIGHT_PATH/brightness" 2>/dev/null
                echo 4 > /sys/class/graphics/fb0/blank 2>/dev/null
                exit 0
                ;;
            *)
                logger -t display "Unknown command: $cmd"
                ;;
        esac
    fi
done
