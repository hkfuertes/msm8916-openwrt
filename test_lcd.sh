#!/bin/sh
# check-st7735s.sh — Diagnóstico rápido ST7735S/GC9106 tinyDRM (OpenWrt)

OUT=/tmp/display_diag.txt
LOG() { echo "$@" | tee -a "$OUT"; }

echo "=== ST7735S/GC9106 display quick diag === $(date)" > "$OUT"

# 1) Driver y fb
LOG "\n[Driver/FB]"
dmesg | grep -i -e st7735s -e mipi_dbi | tail -n 50 | tee -a "$OUT" >/dev/null
if [ -e /sys/class/graphics/fb0/bits_per_pixel ]; then
  LOG "bpp=$(cat /sys/class/graphics/fb0/bits_per_pixel)"
  LOG "stride=$(cat /sys/class/graphics/fb0/stride 2>/dev/null)"
  LOG "virt=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null)"
else
  LOG "fb0 no presente"; exit 1
fi

# 2) GPIOs
LOG "\n[GPIO]"
if [ -e /sys/kernel/debug/gpio ]; then
  grep -E "gpio11|gpio30" /sys/kernel/debug/gpio | tee -a "$OUT"
else
  LOG "debugfs gpio no disponible"
fi

# 3) Backlight al máximo
LOG "\n[Backlight]"
for f in /sys/class/backlight/*/brightness; do
  [ -e "$f" ] || continue
  echo 255 > "$f" 2>/dev/null
  LOG "$f=$(cat $f)"
done

# 4) Buffers RGB565 (128x128: 16384 píxeles * 2 bytes)
LOG "\n[Buffers RGB565]"
gen_raw() {
  local file=$1 val_hi=$2 val_lo=$3
  i=0; : > "$file"
  while [ $i -lt 16384 ]; do
    printf "\\x$val_hi\\x$val_lo" >> "$file"
    i=$((i+1))
  done
}
gen_raw /tmp/red.raw   F8 00   # 11111000 00000000
gen_raw /tmp/green.raw 07 E0   # 00000111 11100000
gen_raw /tmp/blue.raw  00 1F   # 00000000 00011111
gen_raw /tmp/white.raw FF FF

# 5) Volcados al framebuffer
LOG "\n[Volcados /dev/fb0]"
for c in red green blue white; do
  LOG "Mostrando $c..."
  cat /tmp/$c.raw > /dev/fb0
  sleep 1
  LOG "fb0 head (64 bytes):"
  dd if=/dev/fb0 bs=64 count=1 2>/dev/null | hexdump -C | head -n 4 | tee -a "$OUT" >/dev/null
done

# 6) Estado DRM
LOG "\n[DRM state]"
if [ -e /sys/kernel/debug/dri/0/state ]; then
  cat /sys/kernel/debug/dri/0/state | tee -a "$OUT" >/dev/null
else
  LOG "debugfs DRM no disponible"
fi

# 7) Resumen rápido
LOG "\n[Resumen]"
BPP=$(cat /sys/class/graphics/fb0/bits_per_pixel)
STRIDE=$(cat /sys/class/graphics/fb0/stride 2>/dev/null)
VIRT=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null)
GPIO=$(grep -E "gpio11|gpio30" /sys/kernel/debug/gpio 2>/dev/null | tr '\n' ';')
LOG "BPP=$BPP STRIDE=$STRIDE VIRT=$VIRT"
LOG "GPIO: $GPIO"

LOG "\nInforme: $OUT"
exit 0