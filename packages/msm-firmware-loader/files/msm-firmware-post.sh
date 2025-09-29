#!/bin/bash

logger -t msm-firmware-loader "Starting post-firmware tasks"

# Wait a bit for firmware path to be fully processed  
sleep 5

# Link MCFG from /lib/firmware to firmware search path (BEFORE restart)
FIRMWARE_PATH=$(cat /sys/module/firmware_class/parameters/path)
ln -sf /lib/firmware/MCFG_SW.MBN "$FIRMWARE_PATH/MCFG_SW.MBN" 2>/dev/null || true
logger -t msm-firmware-loader "Linked MCFG_SW.MBN to firmware search path"

# Check remoteproc states
MODEM_STATE=$(cat /sys/class/remoteproc/remoteproc0/state 2>/dev/null || echo "offline")
WIFI_STATE=$(cat /sys/class/remoteproc/remoteproc1/state 2>/dev/null || echo "offline")

logger -t msm-firmware-loader "Current states - Modem: $MODEM_STATE, WiFi: $WIFI_STATE"

# Only restart modem if it's not running
if [ "$MODEM_STATE" != "running" ]; then
    logger -t msm-firmware-loader "Restarting modem remoteproc"
    echo stop > /sys/class/remoteproc/remoteproc0/state 2>/dev/null || true
    sleep 2
    echo start > /sys/class/remoteproc/remoteproc0/state 2>/dev/null || true
else
    logger -t msm-firmware-loader "Modem already running, skipping restart"
fi

# Only restart WiFi if it's not running
if [ "$WIFI_STATE" != "running" ]; then
    logger -t msm-firmware-loader "Restarting WiFi remoteproc"
    echo stop > /sys/class/remoteproc/remoteproc1/state 2>/dev/null || true
    sleep 2
    echo start > /sys/class/remoteproc/remoteproc1/state 2>/dev/null || true
else
    logger -t msm-firmware-loader "WiFi already running, skipping restart"
fi

logger -t msm-firmware-loader "Remoteproc restart completed"

# Wait for stability
sleep 3

logger -t msm-firmware-loader "Restarting entire network stack"
/etc/init.d/network restart

logger -t msm-firmware-loader "All post-firmware tasks completed"
