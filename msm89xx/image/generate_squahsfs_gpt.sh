#!/bin/sh -e
# Creates GPT table with fixed TOT_SECTORS=7569408 (512B logical sectors)
# To get TOT_SECTORS automatically from EDL:
#   HEX=$(edl printgpt 2>&1 | sed -n 's/.*sectors:\(0x[0-9A-Fa-f]\+\).*/\1/p' | tail -n1)
#   TOT_SECTORS=$((HEX))

OUTFILE=${1:-gpt_both0.bin}
TMPDIR=$(mktemp -d)
IMG="${TMPDIR}/gpt.img"

# Total size in 512B sectors
TOT_SECTORS=7569408

# GPT boundaries
FIRST_LBA=34
LAST_LBA=$((TOT_SECTORS - 34))

# rootfs: 128 MiB = 262144 sectors
ROOTFS_START=348194
ROOTFS_SIZE=262144
ROOTFS_END=$((ROOTFS_START + ROOTFS_SIZE - 1))

# rootfs_data: remaining space
ROOTFSDATA_START=$((ROOTFS_END + 1))
ROOTFSDATA_SIZE=$((LAST_LBA - ROOTFSDATA_START + 1))

# Validation
[ ${ROOTFSDATA_SIZE} -gt 0 ] || { echo "ERROR: No space for rootfs_data"; exit 1; }

# Create image with exact size
truncate -s $((TOT_SECTORS * 512)) "${IMG}"

# Generate GPT table
sfdisk "${IMG}" <<EOF
label: gpt
label-id: DB708ACF-2E04-8DE2-BAFE-30C9B26444C5
unit: sectors
first-lba: ${FIRST_LBA}
last-lba: ${LAST_LBA}
sector-size: 512

gpt.img1  : start=4096, size=2, type=57B90A16-22C9-E33B-8F5D-0E81686A68CB, name="fsc"
gpt.img2  : start=4098, size=3072, type=638FF8E2-22C9-E33B-8F5D-0E81686A68CB, name="fsg"
gpt.img3  : start=7170, size=131072, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7, name="modem"
gpt.img4  : start=138242, size=3072, type=EBBEADAF-22C9-E33B-8F5D-0E81686A68CB, name="modemst1"
gpt.img5  : start=141314, size=3072, type=0A288B1F-22C9-E33B-8F5D-0E81686A68CB, name="modemst2"
gpt.img6  : start=144386, size=65536, type=6C95E238-E343-4BA8-B489-8681ED22AD0B, name="persist"
gpt.img7  : start=209922, size=32, type=303E6AC3-AF15-4C54-9E9B-D9A8FBECF401, name="sec"
gpt.img8  : start=209954, size=1024, type=E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A, name="hyp"
gpt.img9  : start=210978, size=1024, type=098DF793-D712-413D-9D4E-89D711772228, name="rpm"
gpt.img10 : start=212002, size=1024, type=DEA0BA2C-CBDD-4805-B4F9-F428251C3E98, name="sbl1"
gpt.img11 : start=213026, size=2048, type=A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4, name="tz"
gpt.img12 : start=215074, size=2048, type=400FFDCD-22E0-47E7-9A23-F16ED9382388, name="aboot"
gpt.img13 : start=217122, size=131072, type=20117F86-E985-4357-B9EE-374BC1D8487D, name="boot"
gpt.img14 : start=${ROOTFS_START}, size=${ROOTFS_SIZE}, type=1B81E7E6-F50D-419B-A739-2AEEF8DA3335, name="rootfs"
gpt.img15 : start=${ROOTFSDATA_START}, type=1B81E7E6-F50D-419B-A739-2AEEF8DA3335, name="rootfs_data"
EOF

# size=${ROOTFSDATA_SIZE},

# Build gpt_both0.bin (primary + entries + backup header)
dd if="${IMG}" of="${OUTFILE}" bs=512 count=34
dd if="${IMG}" bs=512 skip=2 count=32 >> "${OUTFILE}"
dd if="${IMG}" bs=512 skip=$((TOT_SECTORS - 1)) count=1 >> "${OUTFILE}"

echo "Generated: ${OUTFILE}"
