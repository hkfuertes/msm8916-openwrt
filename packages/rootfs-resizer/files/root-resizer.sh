#!/bin/sh
# Rootfs resize utility

log() { logger -t rootfs-resizer "$*"; }

get_rootdev() {
    local dev="$(awk '$2=="/"{print $1; exit}' /proc/mounts)"
    [ "$dev" = "/dev/root" ] && dev="$(sed -n 's/.*\broot=\([^ ]*\).*/\1/p' /proc/cmdline)"
    echo "$dev"
}

# Get root device
dev="$(get_rootdev)"

if [ -z "$dev" ] || [ ! -b "$dev" ]; then
    log "ERROR: invalid root device '$dev'"
    exit 1
fi

log "resizing $dev"

# Prepare filesystem
mount -o ro,remount / 2>/dev/null
tune2fs -O^resize_inode "$dev" >/dev/null 2>&1
e2fsck -yDf "$dev" >/dev/null 2>&1
mount -o rw,remount / 2>/dev/null

# Resize
if resize2fs "$dev" 2>&1 | logger -t rootfs-resizer; then
    log "resize successful"
    exit 0
else
    log "ERROR: resize failed"
    exit 1
fi
