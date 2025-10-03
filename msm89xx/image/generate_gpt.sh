#!/bin/sh -e
# Usage: generate-gpt.sh <OUTFILE>

OUTFILE="$1"
TMPDIR="$(mktemp -d)"
IMG="${TMPDIR}/gpt.img"
SECTOR_SIZE=512
SECTORS_TOTAL=7634944
truncate -s $((SECTORS_TOTAL*SECTOR_SIZE)) "${IMG}"

sfdisk "${IMG}" < gpt.table

{
  dd if="${IMG}" bs=${SECTOR_SIZE} count=34 status=none
  dd if="${IMG}" bs=${SECTOR_SIZE} skip=$((SECTORS_TOTAL - 33)) count=33 status=none
} > "${OUTFILE}"

echo "Wrote: ${OUTFILE}"

rm -rf "${TMPDIR}"