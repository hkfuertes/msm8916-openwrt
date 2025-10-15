#!/bin/sh

BACKLIGHT="/sys/class/backlight/backlight"
MAX_BRIGHTNESS=$(cat $BACKLIGHT/max_brightness 2>/dev/null || echo 1785)

TIMEOUT_FULL=5
TIMEOUT_DIM=3
BRIGHTNESS_FULL=$MAX_BRIGHTNESS
BRIGHTNESS_DIM=$((MAX_BRIGHTNESS / 8))

DIM_TIMER_PID=""
OFF_TIMER_PID=""

logger -t display "Display monitor started (max: $MAX_BRIGHTNESS, dimmed: $BRIGHTNESS_DIM)"

set_brightness() {
	local level=$1
	echo $level > $BACKLIGHT/brightness
}

cancel_timers() {
	if [ -n "$DIM_TIMER_PID" ]; then
		kill $DIM_TIMER_PID
		DIM_TIMER_PID=""
	fi
	if [ -n "$OFF_TIMER_PID" ]; then
		kill $OFF_TIMER_PID
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
		set_brightness 1
	) &
	OFF_TIMER_PID=$!
}

button_monitor() {
	DEVICE="/dev/input/event0"
	logger -t display "Monitoring power button on /dev/input/event0"
	
	evtest "$DEVICE" 2>/dev/null | while read -r line; do
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
