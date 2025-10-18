#!/bin/sh
# /usr/sbin/display-manager

PID_FILE=/var/run/display.pid

if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "Another display-manager is running (PID: $old_pid). Exiting."
        exit 1
    else
        # Stale PID file, remove it
        logger -t display "Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

echo $$ > "$PID_FILE"

# Enabling backlight power on startup
echo 0 > /sys/class/backlight/backlight/bl_power 2>/dev/null

. /lib/functions.sh
config_load system

# Defaults
DEFAULT_TIMEOUT_DIM=5
DEFAULT_TIMEOUT_OFF=3
DEFAULT_BRIGHTNESS_DIM_DIVISOR=8
DEFAULT_FIFO="/var/run/display.fifo"
DEFAULT_ENABLE_LOCKSCREEN=1

# Load from UCI
config_get TIMEOUT_DIM display timeout_dim "$DEFAULT_TIMEOUT_DIM"
config_get TIMEOUT_OFF display timeout_off "$DEFAULT_TIMEOUT_OFF"
config_get BRIGHTNESS_DIM_DIVISOR display brightness_dim_divisor "$DEFAULT_BRIGHTNESS_DIM_DIVISOR"
config_get FIFO display fifo "$DEFAULT_FIFO"
config_get ENABLE_LOCKSCREEN display enable_lockscreen "$DEFAULT_ENABLE_LOCKSCREEN"

# Derived or fixed values
BRIGHTNESS_OFF=1
BACKLIGHT_PATH="/sys/class/backlight/backlight"
MAX_BRIGHTNESS=$(cat "$BACKLIGHT_PATH/max_brightness" 2>/dev/null || echo 1785)
BRIGHTNESS_FULL=$MAX_BRIGHTNESS
BRIGHTNESS_DIM=$((MAX_BRIGHTNESS / BRIGHTNESS_DIM_DIVISOR))
LOCKSCREEN_FILE="/etc/logos/boot_logo.fb"
POWEROFF_FILE="/etc/logos/poweroff_logo.fb"
UPDATE_DISPLAY_BIN="/usr/bin/update-display"

# Timer PIDs
TIMER_DIM_PID=""
TIMER_OFF_PID=""

# Create FIFO if it doesn't exist
[ -e "$FIFO" ] || mkfifo "$FIFO"

# Cleanup function: kills timers, closes FD, removes FIFO
cleanup() {
    logger -t display "Cleaning up..."
    [ -n "$TIMER_DIM_PID" ] && kill "$TIMER_DIM_PID" 2>/dev/null
    [ -n "$TIMER_OFF_PID" ] && kill "$TIMER_OFF_PID" 2>/dev/null
    exec 3<&-  # Close file descriptor
    rm -f "$FIFO"
    rm -f "$PID_FILE"
    exit 0
}

# Register cleanup on exit/termination/interrupt
trap cleanup EXIT TERM INT

# Display image file to framebuffer
fb_show_file() {
    [ -c /dev/fb0 ] && [ -f "$1" ] && cat "$1" > /dev/fb0 2>/dev/null
}

# Set backlight brightness
set_brightness() {
    echo "$1" > "$BACKLIGHT_PATH/brightness" 2>/dev/null
}

# Cancel running timers
cancel_timers() {
    [ -n "$TIMER_DIM_PID" ] && kill "$TIMER_DIM_PID" 2>/dev/null
    [ -n "$TIMER_OFF_PID" ] && kill "$TIMER_OFF_PID" 2>/dev/null
    TIMER_DIM_PID=""
    TIMER_OFF_PID=""
}

# Send command to FIFO queue
enqueue() {
    [ -p "$FIFO" ] && echo "$1" > "$FIFO" 2>/dev/null
}

# Start dim and off timers
start_timers() {
    cancel_timers

    # Timer for DIM state
    (
        sleep $TIMEOUT_DIM
        logger -t display "Timer: DIM"
        enqueue "dim"
    ) &
    TIMER_DIM_PID=$!

    # Timer for OFF state
    TOTAL_TIMEOUT=$((TIMEOUT_DIM + TIMEOUT_OFF))
    (
        sleep $TOTAL_TIMEOUT
        logger -t display "Timer: OFF"
        enqueue "off"
    ) & 
    TIMER_OFF_PID=$!
}

logger -t display "Display manager started (dim:${TIMEOUT_DIM}s off:${TIMEOUT_OFF}s)"
start_timers

# Open FIFO once with persistent file descriptor
exec 3<> "$FIFO"

# Main FIFO command loop
while read -r cmd <&3; do
    [ -z "$cmd" ] && continue  # Skip empty lines
    
    case "$cmd" in
        full)
            logger -t display "Backlight: FULL"
            set_brightness $BRIGHTNESS_FULL
            start_timers
            enqueue "update"
            ;;
        dim)
            logger -t display "Backlight: DIM"
            set_brightness $BRIGHTNESS_DIM
            [ "$ENABLE_LOCKSCREEN" = "1" ] && enqueue "lockscreen"
            ;;
        off)
            logger -t display "Backlight: OFF"
            cancel_timers
            set_brightness $BRIGHTNESS_OFF
            ;;
        lockscreen)
            logger -t display "Show lockscreen"
            fb_show_file "$LOCKSCREEN_FILE"
            ;;
        update)
            logger -t display "Update display"
            [ -x $UPDATE_DISPLAY_BIN ] && $UPDATE_DISPLAY_BIN
            ;;
        shutdown)
            logger -t display "Shutdown sequence"
            cancel_timers
            fb_show_file "$POWEROFF_FILE"
            echo 0 > "$BACKLIGHT_PATH/brightness" 2>/dev/null
            # echo 4 > /sys/class/graphics/fb0/blank 2>/dev/null
            break  # Exit while loop
            ;;
        *)
            logger -t display "Unknown command: '$cmd'"
            ;;
    esac
done

# Cleanup runs automatically via trap EXIT
