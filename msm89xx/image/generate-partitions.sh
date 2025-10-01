#!/bin/sh -e
# Integrated GPT + rootfs_data generator for OpenWRT build
# Called automatically during image generation

OUTDIR="$1"  # Passed by OpenWRT build system
TMPDIR="$(mktemp -d)"
IMG="${TMPDIR}/gpt.img"
SECTOR_SIZE=512

mkdir -p "${OUTDIR}"

# Exact eMMC size
SECTORS_TOTAL=7634944
truncate -s $((SECTORS_TOTAL*SECTOR_SIZE)) "${IMG}"

# Write GPT
cat << 'EOF' | sfdisk "${IMG}"
label: gpt
unit: sectors
sector-size: 512

p1 : start=     4096, size=      2,     type=57B90A16-22C9-E33B-8F5D-0E81686A68CB, name="fsc"
p2 : start=     4098, size=   3072,     type=638FF8E2-22C9-E33B-8F5D-0E81686A68CB, name="fsg"
p3 : start=     7170, size= 131072,     type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7, name="modem"
p4 : start=   138242, size=   3072,     type=EBBEADAF-22C9-E33B-8F5D-0E81686A68CB, name="modemst1"
p5 : start=   141314, size=   3072,     type=0A288B1F-22C9-E33B-8F5D-0E81686A68CB, name="modemst2"
p6 : start=   144386, size=  65536,     type=6C95E238-E343-4BA8-B489-8681ED22AD0B, name="persist"
p7 : start=   209922, size=     32,     type=303E6AC3-AF15-4C54-9E9B-D9A8FBECF401, name="sec"
p8 : start=   209954, size=   1024,     type=E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A, name="hyp"
p9 : start=   210978, size=   1024,     type=098DF793-D712-413D-9D4E-89D711772228, name="rpm"
p10: start=   212002, size=   1024,     type=DEA0BA2C-CBDD-4805-B4F9-F428251C3E98, name="sbl1"
p11: start=   213026, size=   2048,     type=A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4, name="tz"
p12: start=   215074, size=   2048,     type=400FFDCD-22E0-47E7-9A23-F16ED9382388, name="aboot"
p13: start=   217122, size= 131072,     type=20117F86-E985-4357-B9EE-374BC1D8487D, name="boot"
p14: start=   348194, size= 262144,     type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="rootfs"
p15: start=   610338,                    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="rootfs_data"
EOF

# Build GPT blob
{
  dd if="${IMG}" bs=${SECTOR_SIZE} count=34 status=none
  dd if="${IMG}" bs=${SECTOR_SIZE} skip=$((SECTORS_TOTAL - 33)) count=33 status=none
} > "${OUTDIR}/gpt_both0.bin"

# Calculate rootfs_data size
UD_LINE="$(sfdisk --dump "${IMG}" | awk -F: '/name="rootfs_data"/{print $2}')"
UD_SECTORS="$(printf '%s\n' "${UD_LINE}" | sed -n 's/.*size=\s*\([0-9]\+\).*/\1/p')"
[ -n "${UD_SECTORS}" ] || { echo "Failed to resolve rootfs_data size"; exit 1; }
UD_BYTES=$((UD_SECTORS*SECTOR_SIZE))

# Create rootfs_data (no journal)
RAW="${TMPDIR}/rootfs_data.raw"
SPARSE="${OUTDIR}/rootfs_data.img"
truncate -s "${UD_BYTES}" "${RAW}"
mke2fs -t ext4 -F -L rootfs_data -O ^has_journal -m 0 "${RAW}" >/dev/null 2>&1

# Convert to Android sparse
img2simg "${RAW}" "${SPARSE}"

echo "Generated: gpt_both0.bin ($(stat -c%s ${OUTDIR}/gpt_both0.bin) bytes)"
echo "Generated: rootfs_data.img ($(stat -c%s ${SPARSE}) bytes)"

rm -rf "${TMPDIR}"
