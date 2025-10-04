#!/bin/sh -e

OUTFILE=${1:-gpt_both0.bin}
TMPDIR=$(mktemp -d)

# create GPT
truncate -s 179323904 ${TMPDIR}/gpt.img

cat ./gpt_ext4.table | sfdisk ${TMPDIR}/gpt.img

# create fastboot compatible partition image
# primary gpt
dd if=${TMPDIR}/gpt.img of="$OUTFILE" bs=512 count=34
# backup gpt
dd if=${TMPDIR}/gpt.img bs=512 skip=2 count=32 >> "$OUTFILE"
dd if=${TMPDIR}/gpt.img bs=512 skip=350241 >> "$OUTFILE"
