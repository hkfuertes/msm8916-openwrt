#!/bin/bash

set -e

LOG_FILE="/tmp/openwrt_build_$(date +%Y%m%d_%H%M%S).log"

{
    export KCONFIG_NOSILENTUPDATE=1
    export DEBIAN_FRONTEND=noninteractive
    
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    cat > .config << EOF
CONFIG_TARGET_msm89xx=y
CONFIG_TARGET_msm89xx_msm8916=y
CONFIG_TARGET_msm89xx_msm8916_DEVICE_yiming-uz801v3=y
CONFIG_ALL_KMODS=y
EOF
    
    yes '' | make oldconfig 2>/dev/null || make olddefconfig
    
    make download -j1 V=s
    yes '' | make tools/install toolchain/install -j1 -k V=s 2>/dev/null
    yes '' | make package/{compile,install} -j1 -k V=s 2>/dev/null   
    make package/apk-index 2>/dev/null 
} 2>&1 | tee "$LOG_FILE"
