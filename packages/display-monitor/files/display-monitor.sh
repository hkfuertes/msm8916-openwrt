#!/bin/sh

. /lib/functions.sh

# Cargar configuración UCI
config_load display

# Variables por defecto
TIMEOUT_FULL=5
TIMEOUT_DIM=3
BRIGHTNESS_DIM_DIVISOR=8
BACKLIGHT_PATH="/sys/class/backlight/backlight"
INPUT_DEVICE="/dev/input/event0"
BRIGHTNESS_OFF=1

# Función callback para leer la configuración
load_display_config() {
	local cfg="$1"
	
	config_get TIMEOUT_FULL "$cfg" timeout_full "$TIMEOUT_FULL"
	config_get TIMEOUT_DIM "$cfg" timeout_dim "$TIMEOUT_DIM"
	config_get BRIGHTNESS_DIM_DIVISOR "$cfg" brightness_dim_divisor "$BRIGHTNESS_DIM_DIVISOR"
	config_get BACKLIGHT_PATH "$cfg" backlight_path "$BACKLIGHT_PATH"
	config_get INPUT_DEVICE "$cfg" input_device "$INPUT_DEVICE"
	config_get BRIGHTNESS_OFF "$cfg" brightness_off "$BRIGHTNESS_OFF"
}

# Procesar configuración
config_foreach load_display_config display

# Variables calculadas
BACKLIGHT="$BACKLIGHT_PATH"
MAX_BRIGHTNESS=$(cat $BACKLIGHT/max_brightness 2>/dev/null || echo 1785)
BRIGHTNESS_FULL=$MAX_BRIGHTNESS
BRIGHTNESS_DIM=$((MAX_BRIGHTNESS / BRIGHTNESS_DIM_DIVISOR))

DIM_TIMER_PID=""
OFF_TIMER_PID=""

logger -t display "Display monitor started (max: $MAX_BRIGHTNESS, dimmed: $BRIGHTNESS_DIM)"

set_brightness() {
    local level=$1
    echo $level > $BACKLIGHT/brightness
}

cancel_timers() {
    if [ -n "$DIM_TIMER_PID" ]; then
        kill $DIM_TIMER_PID 2>/dev/null
        DIM_TIMER_PID=""
    fi
    if [ -n "$OFF_TIMER_PID" ]; then
        kill $OFF_TIMER_PID 2>/dev/null
        OFF_TIMER_PID=""
    fi
}

start_backlight_sequence() {
    cancel_timers
    
    logger -t display "Backlight: FULL"
    set_brightness $BRIGHTNESS_FULL

    TOTAL_TIMEOUT=$((TIMEOUT_FULL + TIMEOUT_DIM))
    
    (
        sleep $TIMEOUT_FULL
        logger -t display "Backlight: DIM"
        set_brightness $BRIGHTNESS_DIM
    ) &
    DIM_TIMER_PID=$!
    
    (
        sleep $TOTAL_TIMEOUT
        logger -t display "Backlight: OFF"
        set_brightness $BRIGHTNESS_OFF
    ) &
    OFF_TIMER_PID=$!
}

button_monitor() {
    logger -t display "Monitoring power button on $INPUT_DEVICE"
    
    evtest "$INPUT_DEVICE" 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "code 116.*value 1"; then
            logger -t display "Button event detected"
            start_backlight_sequence
            
            usleep 500000
        fi
    done
}

trap 'cancel_timers; logger -t display "Display monitor stopped"; exit 0' INT TERM

start_backlight_sequence
button_monitor
