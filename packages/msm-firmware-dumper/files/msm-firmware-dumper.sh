#!/bin/sh
# One-shot Qualcomm firmware dumper: mount partitions read-only,
# copy relevant blobs into /lib/firmware, set a marker to avoid
# re-running, and trigger a reboot. Accepts optional 'MCFG_PATH'
# env var to override the MCFG relative path within modem/persist.

set -e

MARKER="/etc/msm-fw-dumped"
[ -f "$MARKER" ] && exit 0

log() { logger -t msm-fw-dumper "$*"; }

MNT="/tmp/mnt/msmfw"
FW="/lib/firmware"
MCFG_REL="${MCFG_PATH:-}"

log "start (marker not present)"

# Prepare mount points and target
mkdir -p "$MNT/modem" "$MNT/persist" "$FW/wlan/prima"

# Mount partitions read-only (adjust device nodes if needed)
# mount -t vfat -o ro,nosuid,nodev,noexec,iocharset=iso8859-1,codepage=437 /dev/mmcblk0p3 "$MNT/modem" 2>/dev/null || log "WARN: modem mount failed"
# mount -t ext4 -o ro,nosuid,nodev,noexec /dev/mmcblk0p6 "$MNT/persist" 2>/dev/null || log "WARN: persist mount failed"
mount -t vfat -o ro,nosuid,nodev,noexec,iocharset=iso8859-1,codepage=437 /dev/disk/by-label/modem "$MNT/modem" 2>/dev/null || log "WARN: modem mount failed"
mount -t ext4 -o ro,nosuid,nodev,noexec /dev/disk/by-label/persist "$MNT/persist" 2>/dev/null || log "WARN: persist mount failed"

copy_if() { [ -f "$1" ] && cp -af "$1" "$2" && log "copied $(basename "$1")"; }

# Modem/Wi-Fi core blobs (MDT + fragments + MBA if present)
for p in "$MNT/modem"/image/wcnss.mdt "$MNT/modem"/image/wcnss.b* \
         "$MNT/modem"/image/modem.mdt "$MNT/modem"/image/modem.b* \
         "$MNT/modem"/image/mba.mbn
do
  [ -f "$p" ] && cp -af "$p" "$FW/"
done

# Wi‑Fi NV/configs required by wcn36xx (place under wlan/prima)
copy_if "$MNT/persist/WCNSS_qcom_wlan_nv.bin" "$FW/wlan/prima/WCNSS_qcom_wlan_nv.bin"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_qcom_wlan_nv.bin" "$FW/wlan/prima/WCNSS_qcom_wlan_nv.bin"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_cfg.dat" "$FW/wlan/prima/WCNSS_cfg.dat"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_qcom_cfg.ini" "$FW/wlan/prima/WCNSS_qcom_cfg.ini"

# MCFG handling:
if [ -n "$MCFG_REL" ]; then
  if [ -f "$MNT/modem/$MCFG_REL" ]; then
    cp -af "$MNT/modem/$MCFG_REL" "$FW/MCFG_SW.MBN" && log "MCFG from modem:$MCFG_REL"
  else
    log "WARN: MCFG 'path=$MCFG_REL' not found in modem/persist"
  fi
fi
if [ ! -f "$FW/MCFG_SW.MBN" ] && [ -f "$MNT/modem/image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn" ]; then
  cp -af "$MNT/modem/image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn" "$FW/MCFG_SW.MBN" && log "MCFG default copied"
fi

[ -f "$FW/mcfg_sw.mbn" ] && ln -sf "$FW/mcfg_sw.mbn" "$FW/MCFG_SW.MBN" 2>/dev/null || true

sync


# Unmount and cleanup
umount "$MNT/modem" 2>/dev/null || true
umount "$MNT/persist" 2>/dev/null || true
rmdir "$MNT/persist" "$MNT/modem" 2>/dev/null || true

# Set marker and reboot once
touch "$MARKER"
log "done, rebooting"
( sleep 2; reboot ) &

exit 0
