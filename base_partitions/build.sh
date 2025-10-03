#!/bin/bash
set -e

OUTPUT_DIR="$1"
TMPDIR=$(mktemp -d)

# Cleanup on exit
trap "rm -rf $TMPDIR" EXIT

if [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <output_directory>"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clone repositories
for repo in qhypstub:qhypstub lk2nd:lk2nd qtestsign:qtestsign; do
    name="${repo%:*}"
    dir="${repo#*:}"
    if [ ! -d "$TMPDIR/$dir" ]; then
        echo "[+] Cloning $name..."
        git clone https://github.com/msm8916-mainline/$name.git "$TMPDIR/$dir"
    fi
done

# Check dependencies
for cmd in aarch64-linux-gnu-gcc arm-none-eabi-gcc python3 wget unzip; do
    command -v $cmd >/dev/null 2>&1 || { echo "Error: $cmd not found"; exit 1; }
done

# Compile qhypstub
echo "[+] Compiling qhypstub..."
make -C "$TMPDIR/qhypstub" clean CROSS_COMPILE=aarch64-linux-gnu- || true
make -C "$TMPDIR/qhypstub" CROSS_COMPILE=aarch64-linux-gnu-

# Patch and compile lk2nd
echo "[+] Compiling lk2nd..."
cd "$TMPDIR/lk2nd"
grep -qxF 'DEFINES += USE_TARGET_HS200_CAPS=1' project/lk1st-msm8916.mk || \
    echo 'DEFINES += USE_TARGET_HS200_CAPS=1' >> project/lk1st-msm8916.mk

make clean || true
make LK2ND_BUNDLE_DTB="msm8916-512mb-mtp.dtb" \
     LK2ND_COMPATIBLE="yiming,uz801-v3" \
     TOOLCHAIN_PREFIX=arm-none-eabi- \
     lk1st-msm8916

# Download Qualcomm firmware
echo "[+] Downloading Qualcomm firmware..."
wget -q --show-progress -P "$TMPDIR" \
    https://github.com/Mio-sha512/openstick-stuff/raw/refs/heads/main/builder-stuff/dragonboard-410c-bootloader-emmc-linux-176.zip

# Extract firmware files
mkdir -p "$TMPDIR/files"
unzip -o -j -d "$TMPDIR/files/" "$TMPDIR/dragonboard-410c-bootloader-emmc-linux-176.zip" \
    dragonboard-410c-bootloader-emmc-linux-176/rpm.mbn \
    dragonboard-410c-bootloader-emmc-linux-176/sbl1.mbn \
    dragonboard-410c-bootloader-emmc-linux-176/tz.mbn

# Sign binaries
echo "[+] Signing binaries..."
python3 "$TMPDIR/qtestsign/qtestsign.py" hyp \
    "$TMPDIR/qhypstub/qhypstub.elf" -o "$TMPDIR/files/hyp.mbn"

python3 "$TMPDIR/qtestsign/qtestsign.py" aboot \
    "$TMPDIR/lk2nd/build-lk1st-msm8916/emmc_appsboot.mbn" -o "$TMPDIR/files/aboot.mbn"

# Copy to output directory
echo "[+] Copying files to output directory..."
cp -v "$TMPDIR/files"/*.mbn "$OUTPUT_DIR/"

echo "[+] Build completed successfully"
echo "[+] Output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.mbn
