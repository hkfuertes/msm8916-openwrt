#!/usr/bin/env bash
# Prerequisites: EDL mode and fastboot.
# Usage: Execute from bin/targets/XXX/YYY/ directory
# Notes:
# - Automatically detects "*-firmware.zip" in the current directory, extracts .mbn files to a temp dir, and uses them.
# - Falls back to manual directory selection if the ZIP is not found.

set -euo pipefail

# Find a file by pattern at a given directory depth.
find_image() {
    local dir="$1"
    local pattern="$2"
    local file
    file=$(find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | head -n 1 || true)
    if [[ -z "${file:-}" ]]; then
        echo "[-] Error: Image not found with pattern: $pattern" >&2
        return 1
    fi
    echo "$file"
}

echo "=== OpenWrt EXT4 Flash Script ==="
echo "[*] Filesystem: EXT4 (full writable)"
echo

# Use current directory for images.
openwrt_dir="."
echo "[*] Using current directory: $(pwd)"
echo

# Detect required OpenWrt images.
echo "[*] Detecting OpenWrt images..."
gpt_path=$(find_image "$openwrt_dir" "*-gpt_both0.bin") || exit 1
boot_path=$(find_image "$openwrt_dir" "*-ext4-boot.img") || exit 1
system_path=$(find_image "$openwrt_dir" "*-ext4-system.img") || exit 1

echo "[+] GPT: $(basename "$gpt_path")"
echo "[+] Boot: $(basename "$boot_path")"
echo "[+] Rootfs: $(basename "$system_path")"

# Detect firmware ZIP and extract .mbn files.
echo
echo "=== Firmware bundle (.zip) ==="
zip_path="$(find_image "$openwrt_dir" "*-firmware.zip" || true)"

firmware_tmp=""
firmware_dir=""

if [[ -n "${zip_path:-}" ]]; then
    echo "[*] Found firmware ZIP: $(basename "$zip_path")"
    firmware_tmp="$(mktemp -d)"
    trap 'if [[ -n "$firmware_tmp" && -d "$firmware_tmp" ]]; then rm -rf "$firmware_tmp"; fi' EXIT
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
    # Normalize quotes and spaces (useful for drag-and-drop from GUI).
    firmware_dir="${firmware_dir//\"/}"
    firmware_dir="${firmware_dir//\'/}"
    firmware_dir="${firmware_dir// /}"
fi

# Validate firmware directory.
if [[ -z "$firmware_dir" || ! -d "$firmware_dir" ]]; then
    echo "[-] Error: Invalid firmware directory: $firmware_dir"
    exit 1
fi

echo "[*] Using firmware directory: $firmware_dir"
echo

# Verify required .mbn files.
echo "[*] Verifying Qualcomm firmware partitions..."
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
    echo
    echo "[-] ERROR: Missing required .mbn files for flashing."
    echo "[!] Ensure ZIP extraction succeeded or provide a correct directory."
    exit 1
fi

# Confirm before flashing.
echo
read -p "Continue with flashing? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "[!] Cancelled"
    exit 0
fi

mkdir -p saved

# Backup critical partitions via EDL.
echo
echo "=== Partition Backup (EDL) ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Backing up partition $n ..."
    edl r "$n" "saved/$n.bin" || { echo "[-] Error backing up $n"; exit 1; }
done

# Flash aboot via EDL to get a known-good aboot.
echo
echo "=== Flashing Partitions (EDL) ==="
echo "[*] Flashing aboot via EDL..."
edl w aboot "$firmware_dir/aboot.mbn" || { echo "[-] Error flashing aboot"; exit 1; }

# Reboot to fastboot using EDL commands.
echo "[*] Rebooting to fastboot..."
edl e boot || { echo "[-] Error rebooting to fastboot"; exit 1; }
edl reset || { echo "[-] Error resetting device"; exit 1; }

# Wait for fastboot to come up.
echo "[*] Waiting for fastboot mode (up to 10s)..."
for i in {1..10}; do
    if fastboot devices | grep -qE "fastboot$"; then
        echo "[+] Fastboot device detected"
        break
    fi
    sleep 1
    if [[ $i -eq 10 ]]; then
        echo "[-] Error: Fastboot device not detected"
        exit 1
    fi
done

# Flash GPT and firmware via fastboot.
echo
echo "=== Flashing partitions (fastboot) ==="
echo "[*] Flashing GPT..."
fastboot flash partition "$gpt_path" || { echo "[-] Error flashing partition"; exit 1; }

echo "[*] Flashing firmware (.mbn files)..."
fastboot flash aboot "$firmware_dir/aboot.mbn" || { echo "[-] Error flashing aboot"; exit 1; }
fastboot flash hyp   "$firmware_dir/hyp.mbn"   || { echo "[-] Error flashing hyp"; exit 1; }
fastboot flash rpm   "$firmware_dir/rpm.mbn"   || { echo "[-] Error flashing rpm"; exit 1; }
fastboot flash sbl1  "$firmware_dir/sbl1.mbn"  || { echo "[-] Error flashing sbl1"; exit 1; }
fastboot flash tz    "$firmware_dir/tz.mbn"    || { echo "[-] Error flashing tz"; exit 1; }

echo "[*] Flashing OpenWrt images..."
fastboot flash boot   "$boot_path"   || { echo "[-] Error flashing boot"; exit 1; }
fastboot flash rootfs "$system_path" || { echo "[-] Error flashing rootfs"; exit 1; }

# Reboot back to EDL to restore radio-cal data partitions.
echo "[*] Rebooting to EDL mode..."
fastboot oem reboot-edl || { echo "[-] Error rebooting to EDL"; exit 1; }

# Small wait for EDL to be available.
echo "[*] Waiting for EDL mode (3 seconds)..."
sleep 3

# Restore backed-up partitions via EDL.
echo
echo "=== Partition Restoration (EDL) ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Restoring partition $n ..."
    edl w "$n" "saved/$n.bin" || { echo "[-] Error restoring $n"; exit 1; }
done

echo
echo "[+] Process completed successfully"
