#!/bin/sh -e
# build_and_pack.sh — UZ801 (MSM8916):
#  - Clona qhypstub, lk2nd (lk1st) y qtestsign
#  - Descarga DB410c 17.09 (tz/sbl1/rpm)
#  - Compila y firma hyp (qhypstub) y aboot (lk1st)
#  - NO flashea; deja artefactos en files/

set -eu pipefail

# Requisitos en host: git, wget, unzip, python3, toolchains aarch64-linux-gnu- y arm-none-eabi-
need() { command -v "$1" >/dev/null || { echo "Falta dependencia: $1"; exit 1; }; }
need git; need wget; need unzip; need python3

export CROSS_AARCH64="${CROSS_AARCH64:-aarch64-linux-gnu-}"
export CROSS_ARM="${CROSS_ARM:-arm-none-eabi-}"

ROOT="${PWD}"
PKG="${ROOT}/packages"
FILES="${ROOT}/files"
TMP="${ROOT}/.tmp_dl"
mkdir -p "${PKG}" "${FILES}" "${TMP}"

QHYPSTUB_URL="https://github.com/msm8916-mainline/qhypstub.git"
LK2ND_URL="https://github.com/msm8916-mainline/lk2nd.git"
QTESTSIGN_URL="https://github.com/msm8916-mainline/qtestsign.git"
DB410C_BOOT_ZIP_URL="https://releases.linaro.org/96boards/dragonboard410c/linaro/rescue/17.09/dragonboard410c_bootloader_emmc_android-88.zip"

clone_or_update() {
  local url="$1" dir="$2"
  if [ -d "$2/.git" ]; then
    git -C "$2" fetch --all --tags -q
    git -C "$2" pull --ff-only -q
  else
    git clone --depth=1 "$1" "$2"
  fi
}

echo "[*] Clonando repos..."
clone_or_update "$QHYPSTUB_URL"   "${PKG}/qhypstub"
clone_or_update "$LK2ND_URL"      "${PKG}/lk2nd"
clone_or_update "$QTESTSIGN_URL"  "${PKG}/qtestsign"

echo "[*] Descargando DB410c 17.09..."
DBZIP="${TMP}/db410c_17.09.zip"
[ -s "${DBZIP}" ] || wget -O "${DBZIP}" "${DB410C_BOOT_ZIP_URL}"

# Función para extraer por basename desde el zip (independiente de la ruta interna)
extract_by_basename() {
  local zip="$1" base="$2" out="$3"
  # localizar la ruta interna por basename (case-insensitive)
  local path
  path="$(unzip -Z1 "${zip}" | awk -v b="$base" 'tolower($0) ~ "/" tolower(b) "$" || tolower($0) ~ "^" tolower(b) "$" {print $0; exit}')"
  [ -n "${path}" ] || { echo "No se encontró ${base} en el ZIP"; return 1; }
  # extraer al directorio de salida "files/" descartando rutas (-j) y sobrescribiendo (-o)
  unzip -j -o "${zip}" "${path}" -d "$(dirname "${out}")" >/dev/null
  # ruta real del fichero extraído (mismo basename bajo files/)
  local tmp="$(dirname "${out}")/$(basename "${path}")"
  # si el nombre ya coincide con el destino, no intentes mover
  if [ "$(readlink -f "${tmp}")" != "$(readlink -f "${out}")" ]; then
    mv -f "${tmp}" "${out}"
  fi
  echo "Extraído ${base} -> ${out} (desde ${path})"
}


echo "[*] Extrayendo tz/sbl1/rpm por nombre..."
extract_by_basename "${DBZIP}" "tz.mbn"   "${FILES}/tz.mbn"
extract_by_basename "${DBZIP}" "sbl1.mbn" "${FILES}/sbl1.mbn" || true
extract_by_basename "${DBZIP}" "rpm.mbn"  "${FILES}/rpm.mbn"  || true

echo "[*] Compilando qhypstub..."
make -C "${PKG}/qhypstub" CROSS_COMPILE="${CROSS_AARCH64}"

echo "[*] Ajuste HS200 opcional en lk1st..."
grep -qxF 'DEFINES += USE_TARGET_HS200_CAPS=1' "${PKG}/lk2nd/project/lk1st-msm8916.mk" || \
  echo 'DEFINES += USE_TARGET_HS200_CAPS=1' >> "${PKG}/lk2nd/project/lk1st-msm8916.mk"

echo "[*] Compilando lk1st (aboot) para UZ801..."
make -C "${PKG}/lk2nd" \
  LK2ND_BUNDLE_DTB="msm8916-512mb-mtp.dtb" \
  LK2ND_COMPATIBLE="yiming,uz801-v3" \
  TOOLCHAIN_PREFIX="${CROSS_ARM}" \
  lk1st-msm8916

echo "[*] Firmando qhypstub y lk1st con qtestsign..."
python3 "${PKG}/qtestsign/qtestsign.py" hyp  "${PKG}/qhypstub/qhypstub.elf" \
  -o "${FILES}/hyp.mbn"
python3 "${PKG}/qtestsign/qtestsign.py" aboot "${PKG}/lk2nd/build-lk1st-msm8916/emmc_appsboot.mbn" \
  -o "${FILES}/aboot.mbn"

echo "[+] Artefactos listos en ${FILES}:"
ls -l "${FILES}"
echo "[i] Generados: hyp.mbn (qhypstub), aboot.mbn (lk1st); extraídos: tz.mbn y sbl1.mbn (DB410c 17.09); rpm.mbn opcional."
