#!/usr/bin/env bash
# Prerequisites: EDL mode.

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
gpt_path=$(read_path "Drag the gpt_both0 image: ")
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

rootfs_data_path=$(read_path "Drag the rootfs_data image: ")
fastboot flash rootfs_data "$rootfs_data_path" || { echo "Error flashing rootfs_data"; exit 1; }

echo "Rebooting to EDL mode..."
fastboot oem reboot-edl || { echo "Error rebooting to EDL"; exit 1; }

# Restore original partitions
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "Restoring partition $n ..."
    edl w "$n" "saved/$n.bin" || { echo "Error restoring $n"; exit 1; }
done

echo "Process completed successfully."
