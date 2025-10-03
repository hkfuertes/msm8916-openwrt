#!/usr/bin/env bash
# Prerequisites: EDL mode.
# Usage: Execute from bin/targets/XXX/YYY/ directory

# Function to find file by pattern in directory
find_image() {
    local dir="$1"
    local pattern="$2"
    local file
    
    file=$(find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | head -n 1)
    
    if [[ -z "$file" ]]; then
        echo "[-] Error: Image not found with pattern: $pattern" >&2
        return 1
    fi
    
    echo "$file"
}

echo "=== OpenWrt EXT4 Flash Script ==="
echo "[*] Filesystem: EXT4 (full writable)"
echo

# OpenWrt images are in current directory
openwrt_dir="."
echo "[*] Using current directory: $(pwd)"
echo

# Find required OpenWrt images
echo "[*] Detecting OpenWrt images..."
gpt_path=$(find_image "$openwrt_dir" "*-ext4_gpt_both0.bin") || exit 1
boot_path=$(find_image "$openwrt_dir" "*-ext4-boot.img") || exit 1
system_path=$(find_image "$openwrt_dir" "*-ext4-system.img") || exit 1

echo "[+] GPT: $(basename "$gpt_path")"
echo "[+] Boot: $(basename "$boot_path")"
echo "[+] Rootfs: $(basename "$system_path")"

# Ask for firmware directory (where .mbn files are)
echo
echo "=== Qualcomm Firmware Directory ==="
read -e -r -p "Drag the folder with .mbn files (aboot, hyp, rpm, sbl1, tz): " firmware_dir

# Clean quotes and spaces
firmware_dir="${firmware_dir//\"/}"
firmware_dir="${firmware_dir//\'/}"
firmware_dir="${firmware_dir// /}"

# Validate directory exists
if [[ -z "$firmware_dir" ]]; then
    echo "[-] Error: You must specify the directory with .mbn files"
    exit 1
fi

if [[ ! -d "$firmware_dir" ]]; then
    echo "[-] Error: Directory not found: $firmware_dir"
    exit 1
fi

echo "[*] Searching for firmware in: $firmware_dir"
echo

# Check for firmware partitions (.mbn files)
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

if [ "$missing_mbn" = true ]; then
    echo
    echo "[-] ERROR: Missing required .mbn files for flashing."
    echo "[!] These files must be extracted from the original Android firmware."
    echo "[!] Place them in: $firmware_dir"
    exit 1
fi

echo
read -p "Continue with flashing? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "[!] Cancelled"
    exit 0
fi

mkdir -p saved

# Backup important partitions
echo
echo "=== Partition Backup ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Backing up partition $n ..."
    edl r "$n" "saved/$n.bin" || { echo "[-] Error backing up $n"; exit 1; }
done

# Install aboot
echo
echo "=== Flashing Partitions ==="
echo "[*] Flashing aboot via EDL..."
edl w aboot "$firmware_dir/aboot.mbn" || { echo "[-] Error flashing aboot"; exit 1; }

# Reboot to fastboot
echo "[*] Rebooting to fastboot..."
edl e boot || { echo "[-] Error rebooting to fastboot"; exit 1; }
edl reset || { echo "[-] Error resetting device"; exit 1; }

# Wait for fastboot mode
echo "[*] Waiting for fastboot mode (5 seconds)..."
sleep 5

# Flash firmware
echo
echo "=== Flashing partitions via fastboot ==="
echo "[*] Flashing GPT..."
fastboot flash partition "$gpt_path" || { echo "[-] Error flashing partition"; exit 1; }

echo "[*] Flashing firmware..."
fastboot flash aboot "$firmware_dir/aboot.mbn" || { echo "[-] Error flashing aboot"; exit 1; }
fastboot flash hyp "$firmware_dir/hyp.mbn" || { echo "[-] Error flashing hyp"; exit 1; }
fastboot flash rpm "$firmware_dir/rpm.mbn" || { echo "[-] Error flashing rpm"; exit 1; }
fastboot flash sbl1 "$firmware_dir/sbl1.mbn" || { echo "[-] Error flashing sbl1"; exit 1; }
fastboot flash tz "$firmware_dir/tz.mbn" || { echo "[-] Error flashing tz"; exit 1; }

echo "[*] Flashing OpenWrt..."
fastboot flash boot "$boot_path" || { echo "[-] Error flashing boot"; exit 1; }
fastboot flash rootfs "$system_path" || { echo "[-] Error flashing rootfs"; exit 1; }

echo "[*] Rebooting to EDL mode..."
fastboot oem reboot-edl || { echo "[-] Error rebooting to EDL"; exit 1; }

# Wait for EDL mode
echo "[*] Waiting for EDL mode (3 seconds)..."
sleep 3

# Restore original partitions
echo
echo "=== Partition Restoration ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "[*] Restoring partition $n ..."
    edl w "$n" "saved/$n.bin" || { echo "[-] Error restoring $n"; exit 1; }
done

echo
echo "[+] Process completed successfully"
echo "[*] Device should reboot to OpenWrt automatically"
echo
echo "[!] Note: EXT4 filesystem - full writable rootfs, no overlay needed"
