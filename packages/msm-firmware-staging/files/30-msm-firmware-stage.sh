#!/bin/sh

msm_fw_stage() {
	# Logs mínimos y rápidos en preinit
	[ -e /proc/consoles ] && echo "[preinit] msm-fw: start" > /dev/kmsg 2>/dev/null

	# Asegurar sysfs y fijar ruta preferente de firmware
	mountpoint -q /sys || mount -t sysfs sysfs /sys
	STAGE="/run/firmware"
	mkdir -p "$STAGE/wlan/prima"
	echo -n "$STAGE" > /sys/module/firmware_class/parameters/path

	# Puntos de montaje temporales
	MNT="/tmp/msmfw"
	mkdir -p "$MNT/modem" "$MNT/persist"

	mount -t vfat -o ro,nosuid,nodev,noexec,iocharset=iso8859-1,codepage=437 /dev/mmcblk0p3 "$MNT/modem" 2>/dev/null
	mount -t ext4 -o ro,nosuid,nodev,noexec /dev/mmcblk0p6 "$MNT/persist" 2>/dev/null

	# Enlaces: MBA, WCNSS/modem MDT + fragmentos
	[ -f "$MNT/modem/image/mba.mbn" ] && ln -sf "$MNT/modem/image/mba.mbn" "$STAGE/mba.mbn"

	for f in modem.* wcnss.* WCNSS_*; do
		for p in $MNT/modem/image/$f $MNT/persist/$f; do
			[ -f "$p" ] && ln -sf "$p" "$STAGE/$(basename "$p")"
		done
	done

	for p in $MNT/modem/image/wcnss.mdt $MNT/modem/image/wcnss.b*; do
		[ -f "$p" ] && ln -sf "$p" "$STAGE/$(basename "$p")"
	done

	for p in $MNT/modem/image/modem.mdt $MNT/modem/image/modem.b*; do
		[ -f "$p" ] && ln -sf "$p" "$STAGE/$(basename "$p")"
	done

	# NV de Wi‑Fi en la ubicación esperada
	if [ -f "$STAGE/wlan/prima/WCNSS_qcom_wlan_nv.bin" ]; then
		:
	elif [ -f "$MNT/persist/WCNSS_qcom_wlan_nv.bin" ]; then
		ln -sf "$MNT/persist/WCNSS_qcom_wlan_nv.bin" "$STAGE/wlan/prima/WCNSS_qcom_wlan_nv.bin"
	elif [ -f "$MNT/modem/image/wlan/prima/WCNSS_qcom_wlan_nv.bin" ]; then
		ln -sf "$MNT/modem/image/wlan/prima/WCNSS_qcom_wlan_nv.bin" "$STAGE/wlan/prima/WCNSS_qcom_wlan_nv.bin"
	fi

	echo "[preinit] msm-fw: staged in $STAGE" > /dev/kmsg 2>/dev/null
}

boot_hook_add preinit_main msm_fw_stage
