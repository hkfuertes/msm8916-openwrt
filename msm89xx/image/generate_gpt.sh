#!/bin/sh -e
# Usage: generate-gpt.sh <OUTDIR> [GPT_TABLE_FILE] [GPT_OUTPUT_NAME]

OUTDIR="$1"
GPT_TABLE="${2:-gpt-ext4.table}"
GPT_OUTPUT="${3:-gpt_both0.bin}"
TMPDIR="$(mktemp -d)"
IMG="${TMPDIR}/gpt.img"
SECTOR_SIZE=512

[ -z "${OUTDIR}" ] && { echo "[-] Error: OUTDIR not specified"; exit 1; }
[ ! -f "${GPT_TABLE}" ] && { echo "[-] Error: GPT table '${GPT_TABLE}' not found"; exit 1; }

mkdir -p "${OUTDIR}"

# Total sectors for 3.7GB eMMC
SECTORS_TOTAL=7634944
truncate -s $((SECTORS_TOTAL*SECTOR_SIZE)) "${IMG}"

# Generate GPT with ext4 table
sfdisk "${IMG}" < "${GPT_TABLE}"

# Extract GPT blob (primary + backup)
{
  dd if="${IMG}" bs=${SECTOR_SIZE} count=34 status=none
  dd if="${IMG}" bs=${SECTOR_SIZE} skip=$((SECTORS_TOTAL - 33)) count=33 status=none
} > "${OUTDIR}/${GPT_OUTPUT}"

echo "[+] GPT generated: ${OUTDIR}/${GPT_OUTPUT}"

# Cleanup
rm -rf "${TMPDIR}"
