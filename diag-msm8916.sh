#!/bin/sh
# diag-msm8916.sh - Diagnóstico QRTR/rmtfs/QMI para MSM8916 (OpenWrt/Linux)
# Requiere: qmicli, qrtr-lookup (opcional), rmtfs instalado, ip, dmesg

set -eu

SECTION() { printf "\n==== %s ====\n" "$*"; }
RUN() {
  printf "\n$ %s\n" "$*"
  set +e
  sh -c "$*"
  rc=$?
  set -e
  printf "[exit %s]\n" "$rc"
}
HAVE() { command -v "$1" >/dev/null 2>&1; }

QMI_DEV="${QMI_DEV:-}"
QRTR_NODE="${QRTR_NODE:-}"
NET_HINT="${NET_HINT:-wwan0}"

SECTION "Sistema"
RUN "uname -a"
[ -f /etc/openwrt_release ] && RUN "cat /etc/openwrt_release" || true
RUN "ip -o link"

SECTION "Kernel/dmesg (qcom|rmtfs|remoteproc|ipa|rmnet|qrtr|qmi)"
RUN "dmesg | tail -n 200"
RUN "dmesg | grep -i -E 'qcom|rmtfs|remoteproc|ipa|rmnet|qrtr|qmi' | tail -n 400"

SECTION "/dev y procesos"
RUN "ls -l /dev/qcom_rmtfs_mem* 2>/dev/null || echo 'no /dev/qcom_rmtfs_mem*'"
RUN "ps w | grep -E 'rmtfs|qrtr-ns|modemmanager|ofonod' | grep -v grep || true"
[ -x /etc/init.d/rmtfs ] && RUN "/etc/init.d/rmtfs status || true" || true
[ -x /etc/init.d/qrtr-ns ] && RUN "/etc/init.d/qrtr-ns status || true" || true

SECTION "QRTR"
if HAVE qrtr-lookup; then
  RUN "qrtr-lookup -v || qrtr-lookup 0 || true"
else
  echo "qrtr-lookup no está instalado"
fi

SECTION "EFS/MCFG en /var/lib/rmtfs"
[ -d /var/lib/rmtfs ] && RUN "find /var/lib/rmtfs -maxdepth 2 -type f -name 'modem_fs*' -printf '%p %s bytes\n' | sort -V || true" || echo "/var/lib/rmtfs no existe"
[ -d /var/lib/rmtfs ] && RUN "find /var/lib/rmtfs -maxdepth 5 -type f -name 'mcfg_sw.*' -printf '%p %s bytes\n' | sort -V || true" || true
[ -d /var/lib/rmtfs ] && RUN "ls -la /var/lib/rmtfs | sed -n '1,200p'" || true

detect_qmi_dev() {
  # 1) Usuario forzó
  if [ -n "$QMI_DEV" ]; then
    echo "$QMI_DEV"
    return 0
  fi
  # 2) QRTR_NODE forzado
  if [ -n "$QRTR_NODE" ]; then
    echo "qrtr://$QRTR_NODE"
    return 0
  fi
  # 3) Probar QRTR nodos 0..7
  if HAVE qmicli; then
    i=0
    while [ $i -le 7 ]; do
      if qmicli -d "qrtr://$i" --timeout=4 --get-service-version-info >/dev/null 2>&1; then
        echo "qrtr://$i"
        return 0
      fi
      i=$((i+1))
    done
  fi
  # 4) Probar /dev/cdc-wdm*
  for dev in /dev/cdc-wdm*; do
    [ -e "$dev" ] || continue
    if qmicli -d "$dev" --timeout=4 --get-service-version-info >/dev/null 2>&1; then
      echo "$dev"
      return 0
    fi
  done
  # 5) Probar /dev/wwan0qmi (pista del usuario)
  if [ -e /dev/wwan0qmi ]; then
    echo "/dev/wwan0qmi"
    return 0
  fi
  # 6) Probar map desde interfaz NET_HINT -> cdc-wdm
  if [ -d "/sys/class/net/$NET_HINT/qmi" ]; then
    ctl="$(readlink -f "/sys/class/net/$NET_HINT/qmi" 2>/dev/null || true)"
    wdm="$(printf '%s' "$ctl" | awk -F/ '{ for (i=1;i<=NF;i++) if ($i ~ /cdc-wdm/) print "/dev/"$i }')"
    if [ -n "$wdm" ] && [ -e "$wdm" ]; then
      echo "$wdm"
      return 0
    fi
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
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --verbose --get-service-version-info"

  SECTION "QMI: identidad y registro de red"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --dms-get-ids"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --nas-get-home-network || true"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --nas-get-serving-system || true"

  SECTION "QMI: perfiles 3GPP (APN)"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=12 --wds-get-profile-list=3gpp || true"

  SECTION "QMI: PDC/MCFG (si disponible)"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=15 --pdc-list-configs || true"
  RUN "qmicli -d \"$QMI_DEV\" --timeout=8 --help-pdc | sed -n '1,120p' || true"
fi

SECTION "Interfaces de datos (rmnet/wwan)"
RUN "ip -d link show | grep -E 'rmnet|wwan|ipa' -n || true"
RUN "ip a | sed -n '1,300p'"

SECTION "Hecho"
echo "Fin de diagnóstico. Adjuntar este log completo al reporte."
