#!/usr/bin/env bash
# Prerequisites: EDL mode.
# Usage: Execute from bin/targets/XXX/YYY/ directory

# Function to check if image is sparse
is_sparse() {
    local file="$1"
    [ -f "$file" ] || return 1
    [ "$(hexdump -n 4 -e '4/1 "%02x"' "$file" 2>/dev/null)" = "3aff26ed" ]
}

# Function to find file by pattern in directory
find_image() {
    local dir="$1"
    local pattern="$2"
    local file
    
    file=$(find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | head -n 1)
    
    if [[ -z "$file" ]]; then
        echo "Error: No se encontró imagen con patrón: $pattern" >&2
        return 1
    fi
    
    echo "$file"
}

# Ask filesystem type
echo "=== Filesystem Selection ==="
echo "1) SquashFS (requires rootfs_data)"
echo "2) EXT4 (full writable, no rootfs_data)"
read -p "Select filesystem type (1/2): " fs_choice

case "$fs_choice" in
    1)
        FS_TYPE="squashfs"
        NEEDS_ROOTFS_DATA=false
        GPT_PATTERN="*-squashfs_gpt_both0.bin"
        BOOT_PATTERN="*-squashfs-boot.img"
        SYSTEM_PATTERN="*-squashfs-system.img"
        ROOTFS_DATA_PATTERN="*-squashfs_rootfs_data.img"
        ;;
    2)
        FS_TYPE="ext4"
        NEEDS_ROOTFS_DATA=false
        GPT_PATTERN="*-ext4_gpt_both0.bin"
        BOOT_PATTERN="*-ext4-boot.img"
        SYSTEM_PATTERN="*-ext4-system.img"
        ;;
    *)
        echo "Error: Invalid choice"
        exit 1
        ;;
esac

echo "Selected: $FS_TYPE"
echo

# OpenWrt images are in current directory
openwrt_dir="."
echo "=== OpenWrt Images Directory ==="
echo "Usando directorio actual: $(pwd)"
echo

# Find required OpenWrt images
echo "Detectando imágenes OpenWrt en directorio actual..."
gpt_path=$(find_image "$openwrt_dir" "$GPT_PATTERN") || exit 1
boot_path=$(find_image "$openwrt_dir" "$BOOT_PATTERN") || exit 1
system_path=$(find_image "$openwrt_dir" "$SYSTEM_PATTERN") || exit 1

echo "✓ GPT: $(basename "$gpt_path")"
echo "✓ Boot: $(basename "$boot_path")"
echo "✓ Rootfs: $(basename "$system_path")"

if [ "$NEEDS_ROOTFS_DATA" = true ]; then
    rootfs_data_path=$(find_image "$openwrt_dir" "$ROOTFS_DATA_PATTERN") || exit 1
    echo "✓ rootfs_data: $(basename "$rootfs_data_path")"
fi

# Ask for firmware directory (where .mbn files are)
echo
echo "=== Firmware Qualcomm Directory ==="
read -e -r -p "Arrastra la carpeta con los archivos .mbn (aboot, hyp, rpm, sbl1, tz): " firmware_dir

# Clean quotes and spaces
firmware_dir="${firmware_dir//\"/}"
firmware_dir="${firmware_dir//\'/}"
firmware_dir="${firmware_dir// /}"

# Validate directory exists
if [[ -z "$firmware_dir" ]]; then
    echo "Error: Debes especificar el directorio con los archivos .mbn"
    exit 1
fi

if [[ ! -d "$firmware_dir" ]]; then
    echo "Error: Directorio no encontrado: $firmware_dir"
    exit 1
fi

echo "Buscando firmware en: $firmware_dir"
echo

# Check for firmware partitions (.mbn files)
echo "Verificando particiones de firmware Qualcomm..."
missing_mbn=false
for part in aboot hyp rpm sbl1 tz; do
    if [[ ! -f "$firmware_dir/${part}.mbn" ]]; then
        echo "✗ ${part}.mbn no encontrado"
        missing_mbn=true
    else
        echo "✓ ${part}.mbn"
    fi
done

if [ "$missing_mbn" = true ]; then
    echo
    echo "ERROR: Faltan archivos .mbn necesarios para el flasheo."
    echo "Estos archivos deben extraerse del firmware Android original."
    echo "Colócalos en: $firmware_dir"
    exit 1
fi

echo
read -p "¿Continuar con el flasheo? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelado"
    exit 0
fi

mkdir -p saved

# Backup important partitions
echo
echo "=== Backup de particiones ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "Backing up partition $n ..."
    edl r "$n" "saved/$n.bin" || { echo "Error backing up $n"; exit 1; }
done

# Install aboot
echo
echo "=== Flasheo de particiones ==="
echo "Flashing aboot via EDL..."
edl w aboot "$firmware_dir/aboot.mbn" || { echo "Error flashing aboot"; exit 1; }

# Reboot to fastboot
echo "Rebooting to fastboot..."
edl e boot || { echo "Error rebooting to fastboot"; exit 1; }
edl reset || { echo "Error resetting device"; exit 1; }

# Wait for fastboot mode
echo "Esperando modo fastboot (5 segundos)..."
sleep 5

# Flash firmware
echo
echo "Flashing partitions via fastboot..."
fastboot flash partition "$gpt_path" || { echo "Error flashing partition"; exit 1; }

fastboot flash aboot "$firmware_dir/aboot.mbn" || { echo "Error flashing aboot"; exit 1; }
fastboot flash hyp "$firmware_dir/hyp.mbn" || { echo "Error flashing hyp"; exit 1; }
fastboot flash rpm "$firmware_dir/rpm.mbn" || { echo "Error flashing rpm"; exit 1; }
fastboot flash sbl1 "$firmware_dir/sbl1.mbn" || { echo "Error flashing sbl1"; exit 1; }
fastboot flash tz "$firmware_dir/tz.mbn" || { echo "Error flashing tz"; exit 1; }

fastboot flash boot "$boot_path" || { echo "Error flashing boot"; exit 1; }
fastboot flash rootfs "$system_path" || { echo "Error flashing rootfs"; exit 1; }

# Erase rootfs_data only for squashfs (partition doesn't exist in ext4 GPT)
if [ "$NEEDS_ROOTFS_DATA" = true ]; then
    echo "Erasing rootfs_data partition..."
    fastboot erase rootfs_data || { echo "Error erasing rootfs_data"; exit 1; }
fi

echo "Rebooting to EDL mode..."
fastboot oem reboot-edl || { echo "Error rebooting to EDL"; exit 1; }

# Wait for EDL mode
echo "Esperando modo EDL (3 segundos)..."
sleep 3

# Restore original partitions
echo
echo "=== Restauración de particiones ==="
for n in fsc fsg modemst1 modemst2 modem persist sec; do
    echo "Restoring partition $n ..."
    edl w "$n" "saved/$n.bin" || { echo "Error restoring $n"; exit 1; }
done

# Flash rootfs_data via EDL (REQUIRED for squashfs)
if [ "$NEEDS_ROOTFS_DATA" = true ]; then
    echo
    echo "=== Flasheo de rootfs_data via EDL ==="
    
    echo "Detected sparse image, converting..."
    unsparsed="$(mktemp --suffix=.raw.img)"
    simg2img "$rootfs_data_path" "$unsparsed" || { echo "simg2img failed"; exit 1; }
    
    edl w rootfs_data "$unsparsed" || { echo "Error flashing rootfs_data via EDL"; exit 1; }
    
    # Cleanup temp file if created
    if [[ "$unsparsed" != "$rootfs_data_path" ]]; then
        rm -f "$unsparsed"
    fi
    
    echo "rootfs_data flashed successfully."
else
    echo
    echo "EXT4 mode: rootfs_data partition not present in GPT"
fi

echo
echo "=== Process completed successfully ==="
echo "Device should reboot to OpenWrt automatically."
