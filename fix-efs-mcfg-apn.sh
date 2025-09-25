#!/bin/sh
# fix-efs-mcfg-apn-busybox.sh - MSM8916: poblar /var/lib/rmtfs y diagnosticar QMI con busybox/ash

set -eu

SECTION(){ printf "\n==== %s ====\n" "$*"; }
RUN(){ printf "\n$ %s\n" "$*"; set +e; sh -c "$*"; rc=$?; set -e; printf "[exit %s]\n" "$rc"; }
HAVE(){ command -v "$1" >/dev/null 2>&1; }

HASH_CMD=""
if HAVE sha256sum; then HASH_CMD="sha256sum";
elif HAVE sha1sum; then HASH_CMD="sha1sum";
elif HAVE md5sum; then HASH_CMD="md5sum";
elif HAVE cksum; then HASH_CMD="cksum";
else HASH_CMD=""; fi

# Layout según tu salida PARTNAME=
P_FSC=/dev/mmcblk0p1
P_FSG=/dev/mmcblk0p2
P_MODEMST1=/dev/mmcblk0p4
P_MODEMST2=/dev/mmcblk0p5

TS="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo now)"
BACKUP_DIR="/var/backups/rmtfs.$TS"
QMI_DEV="${QMI_DEV:-}"
NET_HINT="${NET_HINT:-wwan0}"

SECTION "Sistema"
RUN "uname -a"
[ -f /etc/openwrt_release ] && RUN "cat /etc/openwrt_release" || true

SECTION "Preparar /var/lib/rmtfs y backup (busybox)"
mkdir -p /var/lib/rmtfs
chmod 700 /var/lib/rmtfs
mkdir -p "$BACKUP_DIR"
for f in modem_fsg modem_fsc modem_fs1 modem_fs2; do
  [ -f "/var/lib/rmtfs/$f" ] && cp -a "/var/lib/rmtfs/$f" "$BACKUP_DIR/$f.old" || true
done
RUN "ls -la /var/lib/rmtfs | sed -n '1,200p'"

SECTION "Copiar ficheros EFS/FSG desde eMMC"
dd if="$P_FSG"      of=/var/lib/rmtfs/modem_fsg bs=4096 conv=fsync 2>/dev/null
dd if="$P_FSC"      of=/var/lib/rmtfs/modem_fsc bs=4096 conv=fsync 2>/dev/null
dd if="$P_MODEMST1" of=/var/lib/rmtfs/modem_fs1 bs=4096 conv=fsync 2>/dev/null
dd if="$P_MODEMST2" of=/var/lib/rmtfs/modem_fs2 bs=4096 conv=fsync 2>/dev/null
chmod 600 /var/lib/rmtfs/modem_fs* /var/lib/rmtfs/modem_fsg /var/lib/rmtfs/modem_fsc
RUN "ls -l /var/lib/rmtfs/modem_*"
[ -n "$HASH_CMD" ] && RUN "$HASH_CMD /var/lib/rmtfs/modem_*" || echo "hash: ninguna de sha256sum/sha1sum/md5sum/cksum disponible"
# Hexdump con od (busybox)
HAVE od && RUN "od -Ax -tx1 -N 256 /var/lib/rmtfs/modem_fsg | sed -n '1,16p'" || true
HAVE od && RUN "od -Ax -tx1 -N 256 /var/lib/rmtfs/modem_fs1 | sed -n '1,16p'" || true

SECTION "Reiniciar rmtfs y revisar logs"
[ -x /etc/init.d/rmtfs ] && RUN "/etc/init.d/rmtfs restart" || echo "no init rmtfs"
sleep 2
HAVE logread && RUN "logread -e rmtfs | tail -n 200" || true
RUN "ps w | grep -E 'rmtfs|qrtr-ns' | grep -v grep || true"

SECTION "QRTR: enumeración de servicios"
if command -v qrtr-lookup >/dev/null 2>&1; then
  RUN "qrtr-lookup -v"
  RUN "qrtr-lookup 14 1 || true"
else
  echo "qrtr-lookup no está instalado"
fi

detect_qmi_dev() {
  # 1) Forzado por entorno
  [ -n "$QMI_DEV" ] && { echo "$QMI_DEV"; return 0; }
  # 2) Probar nodos WWAN QMI nativos
  for dev in /dev/wwan*qmi*; do
    [ -e "$dev" ] || continue
    if qmicli -d "$dev" --timeout=4 --get-service-version-info >/dev/null 2>&1; then
      echo "$dev"; return 0
    fi
  done
  # 3) Probar qrtr:// nodos 0..7
  i=0
  while [ $i -le 7 ]; do
    if qmicli -d "qrtr://$i" --timeout=4 --get-service-version-info >/dev/null 2>&1; then
      echo "qrtr://$i"; return 0
    fi
    i=$((i+1))
  done
  # 4) Mapear desde interfaz NET_HINT si expone control
  if [ -d "/sys/class/net/$NET_HINT" ]; then
    for d in /dev/wwan*qmi*; do
      [ -e "$d" ] && echo "$d" && return 0
    done
  fi
  return 1
}

SECTION "Detección QMI"
if DEV="$(detect_qmi_dev)"; then
  QMI_DEV="$DEV"
  echo "QMI_DEV=$QMI_DEV"
else
  echo "No se pudo detectar dispositivo/URI QMI"
fi

if [ -n "${QMI_DEV:-}" ]; then
  SECTION "QMI: versiones de servicio"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=10 --get-service-version-info"
  SECTION "QMI: identidad/registro"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --dms-get-ids"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --nas-get-home-network || true"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --nas-get-serving-system || true"
  SECTION "QMI: perfiles 3GPP (APN)"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=12 --wds-get-profile-list=3gpp || true"
  SECTION "QMI: PDC/MCFG (si soportado)"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=15 --pdc-list-configs || true"
fi

SECTION "Interfaces WWAN/rmnet"
RUN "ip -d link show | grep -E 'rmnet|wwan|ipa' -n || true"
RUN "ip a | sed -n '1,200p'"

SECTION "Hecho"
echo "Listo. Comparte la salida completa."
