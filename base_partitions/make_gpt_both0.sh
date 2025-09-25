#!/bin/sh -e
# make_gpt_both0.sh — Genera gpt_both0.bin (uso avanzado/recuperación).
# ADVERTENCIA: sólo para restaurar GPT cuando está corrupto y sabiendo lo que se hace.

set -euo pipefail
FILES_DIR="files"
TMPDIR="$(mktemp -d)"
mkdir -p "${FILES_DIR}"

IMG="${TMPDIR}/gpt.img"
# Tamaño DEMO; ajustar a la geometría real si se pretende usar.
truncate -s 179323904 "${IMG}"

cat << 'EOF' | sfdisk "${IMG}"
label: gpt
label-id: DB708ACF-2E04-8DE2-BAFE-30C9B26444C5
unit: sectors
first-lba: 34
last-lba: 350208
sector-size: 512

gpt.img1 : start=        4096, size=           2, type=57B90A16-22C9-E33B-8F5D-0E81686A68CB, name="fsc"
gpt.img2 : start=        4098, size=        3072, type=638FF8E2-22C9-E33B-8F5D-0E81686A68CB, name="fsg"
gpt.img3 : start=        7170, size=      131072, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7, name="modem"
gpt.img4 : start=      138242, size=        3072, type=EBBEADAF-22C9-E33B-8F5D-0E81686A68CB, name="modemst1"
gpt.img5 : start=      141314, size=        3072, type=0A288B1F-22C9-E33B-8F5D-0E81686A68CB, name="modemst2"
gpt.img6 : start=      144386, size=       65536, type=6C95E238-E343-4BA8-B489-8681ED22AD0B, name="persist"
gpt.img7 : start=      209922, size=          32, type=303E6AC3-AF15-4C54-9E9B-D9A8FBECF401, name="sec"
gpt.img8 : start=      209954, size=        1024, type=E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A, name="hyp"
gpt.img9 : start=      210978, size=        1024, type=098DF793-D712-413D-9D4E-89D711772228, name="rpm"
gpt.img10 : start=      212002, size=        1024, type=DEA0BA2C-CBDD-4805-B4F9-F428251C3E98, name="sbl1"
gpt.img11 : start=      213026, size=        2048, type=A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4, name="tz"
gpt.img12 : start=      215074, size=        2048, type=400FFDCD-22E0-47E7-9A23-F16ED9382388, name="aboot"
gpt.img13 : start=      217122, size=      131072, type=20117F86-E985-4357-B9EE-374BC1D8487D, name="boot"
gpt.img14 : start=      348194, size=        2015, type=1B81E7E6-F50D-419B-A739-2AEEF8DA3335, name="rootfs"
EOF

# Empaquetar Primary+Backup GPT en gpt_both0.bin
dd if="${IMG}" of="${FILES_DIR}/gpt_both0.bin" bs=512 count=34
dd if="${IMG}" bs=512 skip=2 count=32 >> "${FILES_DIR}/gpt_both0.bin"
dd if="${IMG}" bs=512 skip=350241 >> "${FILES_DIR}/gpt_both0.bin"

echo "gpt_both0.bin generado en ${FILES_DIR} (no usar salvo recuperación)."
rm -rf "${TMPDIR}"
