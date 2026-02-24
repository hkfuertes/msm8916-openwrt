#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Flash OpenWrt to MSM8916 devices entirely via EDL.
# Prerequisites: edl, simg2img
# Usage: run from the build output directory (bin/targets/...)

set -euo pipefail

# Must match TOT_SECTORS in generate_squashfs_gpt.sh
TOT_SECTORS=7569408

# Temp files - cleaned up on exit
firmware_tmp=""
rootfs_raw=""
gpt_tmp=""
trap 'rm -rf "$firmware_tmp" "$rootfs_raw" "$gpt_tmp"' EXIT

find_image() {
    local dir="$1" pattern="$2" file
    file=$(find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | head -n 1 || true)
    if [[ -z "${file:-}" ]]; then
        echo "[-] Error: Image not found with pattern: $pattern" >&2
        return 1
    fi
    echo "$file"
}

echo "=== OpenWrt MSM8916 EDL Flash Script ==="
echo

# Detect required OpenWrt images.
echo "[*] Detecting OpenWrt images..."
gpt_path=$(find_image "." "*-squashfs-gpt_both0.bin") || exit 1
boot_path=$(find_image "." "*-squashfs-boot.img")     || exit 1
rootfs_path=$(find_image "." "*-squashfs-system.img") || exit 1

echo "[+] GPT:    $(basename "$gpt_path")"
echo "[+] Boot:   $(basename "$boot_path")"
echo "[+] Rootfs: $(basename "$rootfs_path")"

# Detect firmware ZIP and extract .mbn files.
echo
echo "=== Firmware bundle (.zip) ==="
zip_path="$(find_image "." "*-firmware.zip" || true)"

if [[ -n "${zip_path:-}" ]]; then
    echo "[*] Found firmware ZIP: $(basename "$zip_path")"
    firmware_tmp="$(mktemp -d)"
    echo "[*] Extracting .mbn files..."
    unzip -q -j -d "$firmware_tmp" "$zip_path" "*.mbn" || {
        echo "[-] Error: Failed to extract .mbn files from ZIP"
        exit 1
    }
    firmware_dir="$firmware_tmp"
else
    echo "[!] No firmware ZIP found in the current directory"
    echo "=== Qualcomm Firmware Directory (fallback) ==="
    read -e -r -p "Drag the folder with .mbn files (aboot, hyp, rpm, sbl1, tz): " firmware_dir
    firmware_dir="${firmware_dir//\"/}"
    firmware_dir="${firmware_dir//\'/}"
    firmware_dir="${firmware_dir// /}"
fi

if [[ -z "$firmware_dir" || ! -d "$firmware_dir" ]]; then
    echo "[-] Error: Invalid firmware directory: $firmware_dir"
    exit 1
fi

echo "[*] Using firmware directory: $firmware_dir"
echo

# Verify required .mbn files.
echo "[*] Verifying firmware partitions..."
missing_mbn=false
for part in aboot hyp rpm sbl1 tz; do
    if [[ ! -f "$firmware_dir/${part}.mbn" ]]; then
        echo "[-] ${part}.mbn not found"
        missing_mbn=true
    else
        echo "[+] ${part}.mbn"
    fi
done

if [[ "$missing_mbn" == true ]]; then
    echo "[-] ERROR: Missing required .mbn files."
    exit 1
fi

# Convert sparse rootfs to raw if needed (simg2img).
echo
echo "[*] Checking rootfs format..."
if file "$rootfs_path" | grep -q "Android sparse image"; then
    echo "[*] Sparse image detected, converting to raw..."
    rootfs_raw="$(mktemp --suffix=.img)"
    simg2img "$rootfs_path" "$rootfs_raw" || { echo "[-] simg2img failed"; exit 1; }
    rootfs_flash="$rootfs_raw"
    echo "[+] Converted: $(du -h "$rootfs_raw" | cut -f1)"
else
    rootfs_flash="$rootfs_path"
    echo "[+] Raw image, no conversion needed"
fi

# Confirm before flashing.
echo
read -r -p "Continue with flashing? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "[!] Cancelled"
    exit 0
fi

mkdir -p saved

# Backup critical partitions.
echo
echo "=== Partition Backup (EDL) ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Backing up $n..."
    edl r "$n" "saved/$n.bin" || { echo "[-] Error backing up $n"; exit 1; }
done

# Flash new GPT via raw sector writes first, so all subsequent flashes
# use the correct partition offsets from the OpenWrt GPT.
# gpt_both0.bin layout: [34 sectors primary] [32 sectors backup entries] [1 sector backup header]
echo
echo "=== Flashing GPT (EDL) ==="
gpt_tmp="$(mktemp -d)"
dd if="$gpt_path" bs=512 count=34         of="${gpt_tmp}/primary.bin"        2>/dev/null
dd if="$gpt_path" bs=512 skip=34 count=32 of="${gpt_tmp}/backup_entries.bin" 2>/dev/null
dd if="$gpt_path" bs=512 skip=66 count=1  of="${gpt_tmp}/backup_header.bin"  2>/dev/null
edl ws 0                      "${gpt_tmp}/primary.bin"        || { echo "[-] Error flashing primary GPT"; exit 1; }
edl ws $((TOT_SECTORS - 33)) "${gpt_tmp}/backup_entries.bin" || { echo "[-] Error flashing GPT backup entries"; exit 1; }
edl ws $((TOT_SECTORS - 1))  "${gpt_tmp}/backup_header.bin"  || { echo "[-] Error flashing GPT backup header"; exit 1; }

# Flash firmware, boot, rootfs (new GPT now active, correct offsets).
echo
echo "=== Flashing Firmware + OpenWrt images (EDL) ==="
edl w aboot "$firmware_dir/aboot.mbn" || { echo "[-] Error flashing aboot"; exit 1; }
edl w hyp   "$firmware_dir/hyp.mbn"   || { echo "[-] Error flashing hyp";   exit 1; }
edl w rpm   "$firmware_dir/rpm.mbn"   || { echo "[-] Error flashing rpm";   exit 1; }
edl w sbl1  "$firmware_dir/sbl1.mbn"  || { echo "[-] Error flashing sbl1";  exit 1; }
edl w tz    "$firmware_dir/tz.mbn"    || { echo "[-] Error flashing tz";    exit 1; }
edl w boot   "$boot_path"             || { echo "[-] Error flashing boot";   exit 1; }
edl w rootfs "$rootfs_flash"          || { echo "[-] Error flashing rootfs"; exit 1; }
edl e rootfs_data                     || { echo "[-] Error erasing rootfs_data"; exit 1; }

# Restore radio partitions.
echo
echo "=== Partition Restoration (EDL) ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Restoring $n..."
    edl w "$n" "saved/$n.bin" || { echo "[-] Error restoring $n"; exit 1; }
done

echo
echo "[+] Flash completed successfully"
echo "[*] Rebooting..."
edl reset || { echo "[-] Error resetting device"; exit 1; }
