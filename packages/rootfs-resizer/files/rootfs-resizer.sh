#!/bin/sh
# Rootfs resize utility - fast version

log() { logger -t rootfs-resizer "$*"; }

# Get root partition
rootpart=$(findmnt -n -o SOURCE /)

if [ -z "$rootpart" ] || [ ! -b "$rootpart" ]; then
    log "ERROR: cannot find root partition"
    exit 1
fi

log "resizing $rootpart (fast mode)"

# Fast resize - modern ext4 can resize online without full fsck
if resize2fs "$rootpart" 2>&1 | logger -t rootfs-resizer; then
    log "resize completed successfully"
    sync
    exit 0
else
    # If online resize fails, try the slow safe method
    log "online resize failed, trying safe method"
    mount -o ro,remount /
    e2fsck -fy "$rootpart" 2>&1 | logger -t rootfs-resizer
    mount -o rw,remount /
    resize2fs "$rootpart" 2>&1 | logger -t rootfs-resizer
    
    if [ $? -eq 0 ]; then
        log "resize completed (safe method)"
        exit 0
    else
        log "ERROR: resize failed"
        exit 1
    fi
fi
