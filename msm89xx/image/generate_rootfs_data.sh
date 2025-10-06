#!/bin/sh -e

OUTFILE=${1:-rootfs_data.img}
SIZE_GB=${2:-1}  # Tamaño en GB, por defecto 1GB
TMPRAWFILE=$(mktemp)
trap "rm -f $TMPRAWFILE" EXIT

# Calcular tamaño en bytes
SIZE_BYTES=$((SIZE_GB * 1024 * 1024 * 1024))
SIZE_SECTORS=$((SIZE_BYTES / 512))
SIZE_MB=$((SIZE_BYTES / 1024 / 1024))

echo "Creating rootfs_data image:"
echo "  Size: ${SIZE_MB} MB (${SIZE_SECTORS} sectors, ${SIZE_GB} GB)"

# Crear imagen raw del tamaño completo
truncate -s $SIZE_BYTES "$TMPRAWFILE"

# Formatear como ext4 con label rootfs_data
mkfs.ext4 -F -L rootfs_data "$TMPRAWFILE" > /dev/null 2>&1

# Convertir a formato sparse de Android
img2simg "$TMPRAWFILE" "$OUTFILE"

echo "Rootfs_data image created: $OUTFILE"
