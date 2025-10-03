#!/bin/sh
# Rootfs resize utility

log() { logger -t rootfs-resizer "$*"; }

# Get root partition
rootpart=$(findmnt -n -o SOURCE /)

if [ -z "$rootpart" ] || [ ! -b "$rootpart" ]; then
    log "ERROR: cannot find root partition"
    exit 1
fi

log "resizing $rootpart"

# Resize procedure (based on HandsomeMod script)
mount -o ro,remount /
tune2fs -O^resize_inode "$rootpart" 2>&1 | logger -t rootfs-resizer
fsck.ext4 -yDf "$rootpart" 2>&1 | logger -t rootfs-resizer
mount -o rw,remount /
resize2fs "$rootpart" 2>&1 | logger -t rootfs-resizer

if [ $? -eq 0 ]; then
    log "resize completed successfully"
    exit 0
else
    log "ERROR: resize failed"
    exit 1
fi
