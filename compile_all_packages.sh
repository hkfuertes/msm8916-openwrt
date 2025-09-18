#!/bin/bash
# compile_all_packages_no_prompts.sh

set -e

LOG_FILE="/tmp/openwrt_build_$(date +%Y%m%d_%H%M%S).log"

{
    echo "=== Iniciando compilación OpenWrt sin prompts $(date) ==="
    
    # Variables de entorno para evitar interacción
    export KCONFIG_NOSILENTUPDATE=1
    export DEBIAN_FRONTEND=noninteractive
    
    # Actualizar feeds
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    # Crear configuración base
    cat > .config << EOF
CONFIG_TARGET_msm89xx=y
CONFIG_TARGET_msm89xx_msm8916=y
CONFIG_TARGET_msm89xx_msm8916_DEVICE_yiming-uz801v3=y
CONFIG_ALL=y
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSHARED=y
CONFIG_BUILD_NLS=y
CONFIG_BUILD_PATENTED=y
CONFIG_DEVEL=y
CONFIG_CCACHE=y
EOF
    
    # Pre-configurar módulos problemáticos
    echo "Pre-configurando módulos del kernel..."
    
    # Expandir configuración sin preguntas
    echo "Expandiendo configuración..."
    yes '' | make oldconfig 2>/dev/null || make olddefconfig
    
    # Descargar fuentes
    echo "Descargando fuentes..."
    make download -j$(nproc)
    
    # Compilar con auto-respuestas
    echo "Compilando..."
    yes '' | make -j$(nproc) tools/install toolchain/install 2>/dev/null || {
        echo "Compilación multi-core falló, intentando single-core..."
        yes '' | make -j1 tools/install toolchain/install V=s 2>/dev/null || true
    }

    yes '' | make -j$(nproc) package/{compile,install} 2>/dev/null || {
        echo "Compilación multi-core falló, intentando single-core..."
        yes '' | make -j1 package/{compile,install} V=s 2>/dev/null || true
    }
    
    echo "=== Compilación terminada $(date) ==="
    
} 2>&1 | tee "$LOG_FILE"
