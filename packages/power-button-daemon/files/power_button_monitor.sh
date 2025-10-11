#!/bin/sh

DEVICE="/dev/input/event0"
LONG_PRESS_TIME=3  # seconds to trigger poweroff

echo "Power button monitor started"
echo "Hold button for ${LONG_PRESS_TIME}s to shutdown"
logger -t pwrkey "Daemon started"

PRESS_START=0

# Background checker
check_long_press() {
    while true; do
        if [ "$PRESS_START" -ne 0 ]; then
            CURRENT_TIME=$(date +%s)
            PRESS_DURATION=$((CURRENT_TIME - PRESS_START))
            
            if [ "$PRESS_DURATION" -ge "$LONG_PRESS_TIME" ]; then
                echo "Long press detected (${PRESS_DURATION}s) - Shutting down NOW!"
                logger -t pwrkey "Long press ${PRESS_DURATION}s: poweroff triggered"
                poweroff
                exit 0
            fi
        fi
        sleep 0.2
    done
}

# Start background checker
check_long_press &
CHECKER_PID=$!

# Monitor button events
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    # Button pressed
    if echo "$line" | grep -q "code 116.*value 1"; then
        PRESS_START=$(date +%s)
        export PRESS_START
        logger -t pwrkey "Button pressed at $PRESS_START"
    fi
    
    # Button released
    if echo "$line" | grep -q "code 116.*value 0"; then
        if [ "$PRESS_START" -ne 0 ]; then
            CURRENT_TIME=$(date +%s)
            PRESS_DURATION=$((CURRENT_TIME - PRESS_START))
            echo "Button released after ${PRESS_DURATION}s"
            logger -t pwrkey "Button released: ${PRESS_DURATION}s"
        fi
        PRESS_START=0
        export PRESS_START
    fi
done

# Cleanup
kill $CHECKER_PID 2>/dev/null