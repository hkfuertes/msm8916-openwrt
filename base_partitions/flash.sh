#!/usr/bin/env bash
# Prerequisites: EDL mode.

# Function to check if image is sparse
is_sparse() {
    local file="$1"
    [ -f "$file" ] || return 1
    [ "$(hexdump -n 4 -e '4/1 "%02x"' "$file" 2>/dev/null)" = "3aff26ed" ]
}

# Function to read file path with validation and quote cleanup
read_path() {
    local prompt="$1"
    local path_var

    read -e -r -p "$prompt" path_var
    # Remove single and double quotes
    path_var="${path_var//\"/}"
    path_var="${path_var//\'/}"

    # Validate not empty and file exists
    if [[ -z "$path_var" ]]; then
        echo "Error: No path provided."
        exit 1
    fi
    if [[ ! -f "$path_var" ]]; then
        echo "Error: File not found: $path_var"
        exit 1
    fi

    echo "$path_var"
}

# Ask filesystem type
echo "=== Filesystem Selection ==="
echo "1) SquashFS (requires rootfs_data)"
echo "2) EXT4 (full writable, no rootfs_data)"
read -p "Select filesystem type (1/2): " fs_choice

case "$fs_choice" in
    1)
        FS_TYPE="squashfs"
        NEEDS_ROOTFS_DATA=true
        ;;
    2)
        FS_TYPE="ext4"
        NEEDS_ROOTFS_DATA=false
        ;;
    *)
        echo "Error: Invalid choice"
        exit 1
        ;;
esac

echo "Selected: $FS_TYPE"
echo

mkdir -p saved

# Backup important partitions
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "Backing up partition $n ..."
    edl r "$n" "saved/$n.bin" || { echo "Error backing up $n"; exit 1; }
done

# Install `aboot`
echo "Flashing aboot..."
edl w aboot aboot.mbn || { echo "Error flashing aboot"; exit 1; }

# Reboot to fastboot
echo "Rebooting to fastboot..."
edl e boot || { echo "Error rebooting to fastboot"; exit 1; }
edl reset || { echo "Error resetting device"; exit 1; }

# Flash firmware
echo "Flashing partitions..."
if [ "$FS_TYPE" = "squashfs" ]; then
    gpt_path=$(read_path "Drag the squashfs_gpt_both0.bin image: ")
else
    gpt_path=$(read_path "Drag the ext4_gpt_both0.bin image: ")
fi
fastboot flash partition "$gpt_path" || { echo "Error flashing partition"; exit 1; }

fastboot flash aboot aboot.mbn || { echo "Error flashing aboot"; exit 1; }
fastboot flash hyp hyp.mbn || { echo "Error flashing hyp"; exit 1; }
fastboot flash rpm rpm.mbn || { echo "Error flashing rpm"; exit 1; }
fastboot flash sbl1 sbl1.mbn || { echo "Error flashing sbl1"; exit 1; }
fastboot flash tz tz.mbn || { echo "Error flashing tz"; exit 1; }

boot_path=$(read_path "Drag the boot image: ")
fastboot flash boot "$boot_path" || { echo "Error flashing boot"; exit 1; }

system_path=$(read_path "Drag the system image: ")
fastboot flash rootfs "$system_path" || { echo "Error flashing system"; exit 1; }

# Erase rootfs_data only for squashfs (partition doesn't exist in ext4 GPT)
if [ "$NEEDS_ROOTFS_DATA" = true ]; then
    echo "Erasing rootfs_data partition..."
    fastboot erase rootfs_data || { echo "Error erasing rootfs_data"; exit 1; }
fi

echo "Rebooting to EDL mode..."
fastboot oem reboot-edl || { echo "Error rebooting to EDL"; exit 1; }

# Restore original partitions
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "Restoring partition $n ..."
    edl w "$n" "saved/$n.bin" || { echo "Error restoring $n"; exit 1; }
done

# Flash rootfs_data via EDL (REQUIRED for squashfs)
if [ "$NEEDS_ROOTFS_DATA" = true ]; then
    rootfs_data_path=$(read_path "Drag the rootfs_data.img: ")
    
    echo "Flashing rootfs_data via EDL..."
    unsparsed="$rootfs_data_path"
    
    if is_sparse "$rootfs_data_path"; then
        echo "Detected sparse image, converting..."
        unsparsed="$(mktemp --suffix=.raw.img)"
        simg2img "$rootfs_data_path" "$unsparsed" || { echo "simg2img failed"; exit 1; }
    fi
    
    edl w rootfs_data "$unsparsed" || { echo "Error flashing rootfs_data via EDL"; exit 1; }
    
    # Cleanup temp file if created
    if [[ "$unsparsed" != "$rootfs_data_path" ]]; then
        rm -f "$unsparsed"
    fi
    
    echo "rootfs_data flashed successfully."
else
    echo "EXT4 mode: rootfs_data partition not present in GPT"
fi

echo "Process completed successfully."
