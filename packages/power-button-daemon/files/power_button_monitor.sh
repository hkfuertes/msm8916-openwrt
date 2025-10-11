#!/bin/sh

DEVICE="/dev/input/event0"
LONG_PRESS_TIME=3

echo "Power button monitor started - Hold ${LONG_PRESS_TIME}s to shutdown"
logger -t pwrkey "Daemon started"

# Monitor button events and check duration in real-time
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    # Button pressed - start background timer
    if echo "$line" | grep -q "code 116.*value 1"; then
        PRESS_START=$(date +%s)
        logger -t pwrkey "Button pressed"
        
        # Background timer to trigger poweroff
        (
            sleep "$LONG_PRESS_TIME"
            # Check if button is still pressed (no release event yet)
            echo "Long press ${LONG_PRESS_TIME}s reached - Shutting down!"
            logger -t pwrkey "Long press ${LONG_PRESS_TIME}s: poweroff triggered"
            poweroff
        ) &
        TIMER_PID=$!
    fi
    
    # Button released - cancel timer
    if echo "$line" | grep -q "code 116.*value 0"; then
        if [ -n "$TIMER_PID" ]; then
            # Kill the background timer if button released early
            kill "$TIMER_PID" 2>/dev/null
            
            CURRENT_TIME=$(date +%s)
            PRESS_DURATION=$((CURRENT_TIME - PRESS_START))
            
            if [ "$PRESS_DURATION" -lt "$LONG_PRESS_TIME" ]; then
                echo "Button released after ${PRESS_DURATION}s - Ignored"
                logger -t pwrkey "Short press ${PRESS_DURATION}s - Ignored"
            fi
            
            TIMER_PID=""
        fi
    fi
done