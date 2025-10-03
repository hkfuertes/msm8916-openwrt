#!/bin/sh
# One-shot Qualcomm firmware dumper with LED feedback

set -e
DEFAULT_MARKER="/lib/firmware/DUMPED"
DEFAULT_MCFG_PATH="image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default"

MARKER="${MSM_DUMPER_FLAG_FILE:-$DEFAULT_MARKER}"
[ -f "$MARKER" ] && exit 0

log() { logger -t msm-fw-dumper "$*"; }
led() { command -v ledcontrol >/dev/null 2>&1 && ledcontrol "$@" || true; }

MNT="/tmp/mnt/msmfw"
FW="/lib/firmware"
MCFG_REL="${MCFG_PATH:-$DEFAULT_MCFG_PATH}"

log "starting firmware dump"
led blue blink

# Prepare mount points and target
mkdir -p "$MNT/modem" "$MNT/persist" "$FW/wlan/prima"

# Mount partitions read-only
mount -t vfat -o ro,nosuid,nodev,noexec,iocharset=iso8859-1,codepage=437 /dev/mmcblk0p3 "$MNT/modem" 2>/dev/null || log "WARN: modem mount failed"
mount -t ext4 -o ro,nosuid,nodev,noexec /dev/mmcblk0p6 "$MNT/persist" 2>/dev/null || log "WARN: persist mount failed"

# Copy helper
copy_if() {
  [ -f "$1" ] && cp -af "$1" "$2" && log "copied $(basename "$1")"
}

# Modem/Wi-Fi core blobs
for p in "$MNT/modem"/image/wcnss.{mdt,b*} \
         "$MNT/modem"/image/modem.{mdt,b*} \
         "$MNT/modem"/image/mba.mbn
do
  copy_if "$p" "$FW/"
done

# Wi‑Fi NV/configs
copy_if "$MNT/persist/WCNSS_qcom_wlan_nv.bin" "$FW/wlan/prima/WCNSS_qcom_wlan_nv.bin"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_qcom_wlan_nv.bin" "$FW/wlan/prima/WCNSS_qcom_wlan_nv.bin"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_cfg.dat" "$FW/wlan/prima/WCNSS_cfg.dat"
copy_if "$MNT/modem/image/wlan/prima/WCNSS_qcom_cfg.ini" "$FW/wlan/prima/WCNSS_qcom_cfg.ini"

# MCFG handling
if [ -f "$MNT/modem/$MCFG_REL/mcfg_sw.mbn" ]; then
  cp -af "$MNT/modem/$MCFG_REL/mcfg_sw.mbn" "$FW/MCFG_SW.MBN" && log "MCFG from modem:$MCFG_REL"
else
  log "WARN: MCFG '$MCFG_REL' not found"
fi

# User override support
[ -f "$FW/mcfg_sw.mbn" ] && ln -sf "$FW/mcfg_sw.mbn" "$FW/MCFG_SW.MBN" 2>/dev/null || true

sync

# Cleanup
umount "$MNT/modem" "$MNT/persist" 2>/dev/null || true
rmdir "$MNT/persist" "$MNT/modem" 2>/dev/null || true

# Mark done
touch "$MARKER"
log "firmware dump complete, rebooting"
led green on

( sleep 2; led green blink; sleep 1; reboot ) &
exit 0
