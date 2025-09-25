#!/bin/bash
set -euo pipefail

OUT_DIR="${PWD}/mcfg_out"
TMP_DIR="$(mktemp -d)"
APK="${TMP_DIR}/firmware-fp5-modem.apk"
URL_BASE="https://mirror.math.princeton.edu/pub/postmarketos/v24.12/aarch64"
APK_NAME="firmware-fairphone-fp5-modem-20240417-r1.apk"

echo "[*] Descargando ${APK_NAME}..."
wget -O "${APK}" "${URL_BASE}/${APK_NAME}"

echo "[*] Extrayendo APK (formato Alpine tar)..."
EXTRACT_DIR="${TMP_DIR}/unpacked"
mkdir -p "${EXTRACT_DIR}"
# bsdtar maneja mejor headers APK-TOOLS; tar GNU también sirve
bsdtar -C "${EXTRACT_DIR}" -xf "${APK}" || tar -C "${EXTRACT_DIR}" -xf "${APK}"

echo "[*] Buscando MCFG Orange España dentro del árbol extraído..."
CANDIDATE="$(find "${EXTRACT_DIR}" -path "*/modem_pr/mcfg/configs/mcfg_sw/generic/EU/Orange/Commercial/Spain/mcfg_sw.mbn" | head -n1)"
if [ -z "${CANDIDATE}" ]; then
  echo "No se encontró mcfg_sw.mbn de Orange España; verifica paquete/versión." >&2
  echo "Sugerencia: comprueba el índice del paquete firmware-fairphone-fp5-modem para confirmar la ruta." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
cp "${CANDIDATE}" "${OUT_DIR}/mcfg_sw_orange_spain.mbn"
echo "[*] Copiado en ${OUT_DIR}/mcfg_sw_orange_spain.mbn"

rm -rf "${TMP_DIR}"
echo "[*] Listo."
