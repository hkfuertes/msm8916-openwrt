#!/bin/sh

BACKLIGHT="/sys/class/backlight/backlight"
MAX_BRIGHTNESS=$(cat $BACKLIGHT/max_brightness 2>/dev/null || echo 1785)

# Configuración (en segundos)
TIMEOUT_FULL=3      # 3s al 100%
TIMEOUT_DIM=2       # 2s al 50% antes de apagar
BRIGHTNESS_FULL=$MAX_BRIGHTNESS
BRIGHTNESS_DIM=$((MAX_BRIGHTNESS / 2))

# PIDs de timers activos
DIM_TIMER_PID=""
OFF_TIMER_PID=""

logger -t display "Display monitor started (max: $MAX_BRIGHTNESS)"

# Control del backlight
set_brightness() {
	local level=$1
	
	if [ "$level" -eq 0 ]; then
		# Apagar
		echo 4 > $BACKLIGHT/bl_power 2>/dev/null
	else
		# Encender y establecer brillo
		echo "$level" > $BACKLIGHT/brightness 2>/dev/null
		echo 0 > $BACKLIGHT/bl_power 2>/dev/null
	fi
}

# Cancelar timers activos
cancel_timers() {
	[ -n "$DIM_TIMER_PID" ] && kill $DIM_TIMER_PID 2>/dev/null
	[ -n "$OFF_TIMER_PID" ] && kill $OFF_TIMER_PID 2>/dev/null
	DIM_TIMER_PID=""
	OFF_TIMER_PID=""
}

# Iniciar secuencia de backlight
start_backlight_sequence() {
	# Cancelar timers previos
	cancel_timers
	
	# Encender al 100%
	logger -t display "Backlight: FULL (100%)"
	set_brightness $BRIGHTNESS_FULL
	
	# Timer 1: DIM después de TIMEOUT_FULL segundos
	(
		sleep $TIMEOUT_FULL
		logger -t display "Backlight: DIM (50%)"
		set_brightness $BRIGHTNESS_DIM
	) &
	DIM_TIMER_PID=$!
	
	# Timer 2: OFF después de TIMEOUT_FULL + TIMEOUT_DIM segundos
	(
		sleep $((TIMEOUT_FULL + TIMEOUT_DIM))
		logger -t display "Backlight: OFF"
		set_brightness 0
	) &
	OFF_TIMER_PID=$!
}

# Monitor de eventos del botón
button_monitor() {
	PIPE="/tmp/backlight_button_events"
	[ ! -p "$PIPE" ] && mkfifo "$PIPE"
	
	while true; do
		read event < "$PIPE" 2>/dev/null
		if [ "$event" = "press" ]; then
			logger -t display "Button pressed - wake display"
			start_backlight_sequence
		fi
	done
}

# Inicializar: encender backlight al arrancar
start_backlight_sequence

# Ejecutar monitor de botón
button_monitor
