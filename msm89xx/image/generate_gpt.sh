#!/bin/sh -e
# Usage: generate-gpt.sh <OUTDIR> [GPT_TABLE_FILE] [GPT_OUTPUT_NAME]

OUTDIR="$1"
GPT_TABLE="${2:-gpt-squashfs.table}"
GPT_OUTPUT="${3:-squashfs_gpt_both0.bin}"
TMPDIR="$(mktemp -d)"
IMG="${TMPDIR}/gpt.img"
SECTOR_SIZE=512

[ -z "${OUTDIR}" ] && { echo "Error: OUTDIR not specified"; exit 1; }
[ ! -f "${GPT_TABLE}" ] && { echo "Error: GPT table '${GPT_TABLE}' not found"; exit 1; }

mkdir -p "${OUTDIR}"

SECTORS_TOTAL=7634944
truncate -s $((SECTORS_TOTAL*SECTOR_SIZE)) "${IMG}"

sfdisk "${IMG}" < "${GPT_TABLE}"

# Generar GPT blob con nombre configurable
{
  dd if="${IMG}" bs=${SECTOR_SIZE} count=34 status=none
  dd if="${IMG}" bs=${SECTOR_SIZE} skip=$((SECTORS_TOTAL - 33)) count=33 status=none
} > "${OUTDIR}/${GPT_OUTPUT}"

echo "Wrote: ${OUTDIR}/${GPT_OUTPUT}"

# Check if rootfs_data partition exists
if grep -q 'name="rootfs_data"' "${GPT_TABLE}"; then
  echo "rootfs_data partition detected, creating rootfs_data.img..."
  
  UD_LINE="$(sfdisk --dump "${IMG}" | awk -F: '/name="rootfs_data"/{print $2}')"
  UD_SECTORS="$(printf '%s\n' "${UD_LINE}" | sed -n 's/.*size=\s*\([0-9]\+\).*/\1/p')"
  
  [ -z "${UD_SECTORS}" ] && { echo "Failed to resolve rootfs_data size"; exit 1; }
  UD_BYTES=$((UD_SECTORS*SECTOR_SIZE))
  
  RAW="${TMPDIR}/rootfs_data.raw"
  SPARSE="${OUTDIR}/rootfs_data.img"
  truncate -s "${UD_BYTES}" "${RAW}"
  mke2fs -t ext4 -F -L rootfs_data -O ^has_journal "${RAW}"
  img2simg "${RAW}" "${SPARSE}"
  
  echo "Wrote: ${SPARSE}"
else
  echo "No rootfs_data partition in table, skipping rootfs_data.img"
fi

rm -rf "${TMPDIR}"
