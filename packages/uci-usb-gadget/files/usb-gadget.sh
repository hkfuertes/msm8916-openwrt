#!/bin/sh
# Universal USB Gadget Manager for OpenWrt
# Compatible with ash/busybox sh

set -e

# Load UCI library
. /lib/functions.sh

# ============================================================================
# Configuration
# ============================================================================

CFG_ENABLED=""
CFG_GADGET_NAME=""
CFG_GADGET_PATH=""
CFG_CONFIG_PATH=""
CFG_FUNCTIONS_PATH=""

CFG_VENDOR_ID=""
CFG_PRODUCT_ID=""
CFG_DEVICE_VERSION=""
CFG_MANUFACTURER=""
CFG_PRODUCT=""
CFG_UDC_DEVICE=""

CFG_RNDIS=""
CFG_ECM=""
CFG_NCM=""
CFG_ACM=""
CFG_UMS=""

CFG_ACM_SHELL=""

CFG_UMS_IMAGE=""
CFG_UMS_SIZE=""
CFG_UMS_READONLY=""

load_config() {
    config_load usbgadget
    
    # Global enable/disable
    config_get_bool CFG_ENABLED usb enabled 1
    
    # Gadget name
    config_get CFG_GADGET_NAME usb gadget_name "g1"
    
    # Paths
    CFG_GADGET_PATH="/sys/kernel/config/usb_gadget/${CFG_GADGET_NAME}"
    CFG_CONFIG_PATH="${CFG_GADGET_PATH}/configs/c.1"
    CFG_FUNCTIONS_PATH="${CFG_GADGET_PATH}/functions"
    
    # USB Device IDs
    config_get CFG_VENDOR_ID usb vendor_id "0x1d6b"
    config_get CFG_PRODUCT_ID usb product_id "0x0104"
    config_get CFG_DEVICE_VERSION usb device_version "0x0100"
    config_get CFG_MANUFACTURER usb manufacturer "OpenWrt"
    config_get CFG_PRODUCT usb product "USB Gadget"
    config_get CFG_UDC_DEVICE usb udc_device ""
    
    # Functions (boolean)
    config_get_bool CFG_RNDIS rndis enabled 0
    config_get_bool CFG_ECM ecm enabled 0
    config_get_bool CFG_NCM ncm enabled 0
    config_get_bool CFG_ACM acm enabled 0
    config_get_bool CFG_UMS ums enabled 0
    
    # ACM options
    config_get_bool CFG_ACM_SHELL acm shell 1
    
    # UMS options
    config_get CFG_UMS_IMAGE ums image_path "/var/lib/usb-gadget/storage.img"
    config_get CFG_UMS_SIZE ums image_size "512M"
    config_get_bool CFG_UMS_READONLY ums readonly 0
}

# ============================================================================
# Logging
# ============================================================================

log() {
    logger -t usb-gadget "$*"
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    log "ERROR: $*"
    exit 1
}

# ============================================================================
# Utilities
# ============================================================================

get_serial_number() {
    if [ -f /etc/machine-id ]; then
        sha256sum < /etc/machine-id | cut -d' ' -f1 | cut -c1-16
        return
    fi
    echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)"
}

generate_mac() {
    local prefix="$1"
    local serial="$(get_serial_number)"
    local hash="$(echo "${serial}${prefix}" | md5sum | cut -c1-12)"
    
    # Extract bytes
    local b1="$(echo "$hash" | cut -c1-2)"
    local b2="$(echo "$hash" | cut -c3-4)"
    local b3="$(echo "$hash" | cut -c5-6)"
    local b4="$(echo "$hash" | cut -c7-8)"
    local b5="$(echo "$hash" | cut -c9-10)"
    local b6="$(echo "$hash" | cut -c11-12)"
    
    # Set locally administered, unicast
    b1="$(printf '%02x' $((0x${b1} & 0xfe | 0x02)))"
    
    echo "${b1}:${b2}:${b3}:${b4}:${b5}:${b6}"
}

find_udc() {
    # Return configured UDC if set
    if [ -n "$CFG_UDC_DEVICE" ]; then
        echo "$CFG_UDC_DEVICE"
        return
    fi
    
    # Auto-detect UDC - works on ALL hardware
    local udc="$(ls /sys/class/udc/ 2>/dev/null | head -1)"
    
    if [ -z "$udc" ]; then
        error "No UDC device found. Is USB gadget support enabled?"
    fi
    
    echo "$udc"
}

sysfs_write() {
    local path="$1"
    local value="$2"
    echo "$value" > "$path" || error "Failed to write '$value' to $path"
}

# ============================================================================
# USB Functions Setup
# ============================================================================

setup_rndis() {
    log "Enabling RNDIS"
    local func="${CFG_FUNCTIONS_PATH}/rndis.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac rndis-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac rndis-dev)"
    ln -sf "$func" "${CFG_CONFIG_PATH}/"
    
    # Windows compatibility
    sysfs_write "${CFG_GADGET_PATH}/os_desc/use" "1"
    sysfs_write "${CFG_GADGET_PATH}/os_desc/b_vendor_code" "0xcd"
    sysfs_write "${CFG_GADGET_PATH}/os_desc/qw_sign" "MSFT100"
    sysfs_write "${func}/os_desc/interface.rndis/compatible_id" "RNDIS"
    sysfs_write "${func}/os_desc/interface.rndis/sub_compatible_id" "5162001"
    ln -sf "${CFG_CONFIG_PATH}" "${CFG_GADGET_PATH}/os_desc/"
    
    echo "+RNDIS"
}

setup_ecm() {
    log "Enabling ECM"
    local func="${CFG_FUNCTIONS_PATH}/ecm.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac ecm-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac ecm-dev)"
    ln -sf "$func" "${CFG_CONFIG_PATH}/"
    
    echo "+ECM"
}

setup_ncm() {
    log "Enabling NCM"
    local func="${CFG_FUNCTIONS_PATH}/ncm.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac ncm-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac ncm-dev)"
    ln -sf "$func" "${CFG_CONFIG_PATH}/"
    
    echo "+NCM"
}

setup_acm() {
    log "Enabling ACM"
    local func="${CFG_FUNCTIONS_PATH}/acm.GS0"
    
    mkdir -p "$func"
    ln -sf "$func" "${CFG_CONFIG_PATH}/"
    
    # Manage shell in inittab
    if [ "$CFG_ACM_SHELL" = "1" ]; then
        log "Enabling serial shell on ttyGS0"
        sed -i '/ttyGS0/d' /etc/inittab
        echo "ttyGS0::askfirst:/usr/libexec/login.sh" >> /etc/inittab
    else
        log "ACM in raw TTY mode (removing shell from inittab)"
        sed -i '/ttyGS0/d' /etc/inittab
    fi
    
    kill -HUP 1 2>/dev/null || true
    
    echo "+ACM"
}

setup_ums() {
    local image="$CFG_UMS_IMAGE"
    
    # Create image if doesn't exist
    if [ ! -f "$image" ]; then
        log "Creating storage image: $image ($CFG_UMS_SIZE)"
        mkdir -p "$(dirname "$image")"
        truncate -s "$CFG_UMS_SIZE" "$image" || \
            dd if=/dev/zero of="$image" bs=1M count="${CFG_UMS_SIZE%M}"
    fi
    
    log "Enabling UMS"
    local func="${CFG_FUNCTIONS_PATH}/mass_storage.0"
    
    mkdir -p "$func"
    sysfs_write "${func}/lun.0/ro" "$CFG_UMS_READONLY"
    sysfs_write "${func}/lun.0/file" "$image"
    ln -sf "$func" "${CFG_CONFIG_PATH}/"
    
    echo "+UMS"
}

# ============================================================================
# Network Configuration
# ============================================================================

add_to_bridge() {
    local ifname_file="$1"
    
    [ -f "$ifname_file" ] || return
    
    local iface="$(cat "$ifname_file")"
    log "Adding $iface to bridge"
    
    # Add the inteface to bridge
    uci -q del_list "network.@device[0].ports=$iface" 2>/dev/null || true
    uci add_list "network.@device[0].ports=$iface"
}

setup_network() {
    sleep 1
    
    [ "$CFG_RNDIS" = "1" ] && add_to_bridge "${CFG_FUNCTIONS_PATH}/rndis.usb0/ifname"
    [ "$CFG_ECM" = "1" ] && add_to_bridge "${CFG_FUNCTIONS_PATH}/ecm.usb0/ifname"
    [ "$CFG_NCM" = "1" ] && add_to_bridge "${CFG_FUNCTIONS_PATH}/ncm.usb0/ifname"
    
    uci commit network
    /etc/init.d/network reload
}

# ============================================================================
# Main Gadget Management
# ============================================================================

setup_gadget() {
    # Load configuration
    load_config
    
    # Check if gadget is enabled
    if [ "$CFG_ENABLED" != "1" ]; then
        log "USB Gadget is disabled in config (usb.enabled=0)"
        log "USB port available for host mode"
        return 0
    fi
    
    log "Setting up USB gadget"
    log "Gadget name: $CFG_GADGET_NAME"
    log "Gadget path: $CFG_GADGET_PATH"
    
    # Prepare system
    modprobe libcomposite || error "Failed to load libcomposite module"
    
    if ! mountpoint -q /sys/kernel/config; then
        log "Mounting configfs"
        mount -t configfs none /sys/kernel/config
    fi
    
    # Create gadget directory
    mkdir -p "$CFG_GADGET_PATH" || error "Failed to create gadget directory"
    cd "$CFG_GADGET_PATH" || error "Cannot change directory"
    
    # Device descriptors
    sysfs_write idVendor "$CFG_VENDOR_ID"
    sysfs_write idProduct "$CFG_PRODUCT_ID"
    sysfs_write bcdDevice "$CFG_DEVICE_VERSION"
    
    # Composite device class
    sysfs_write bDeviceClass "0xEF"
    sysfs_write bDeviceSubClass "0x02"
    sysfs_write bDeviceProtocol "0x01"
    
    # Strings (USB descriptors)
    mkdir -p strings/0x409
    sysfs_write strings/0x409/serialnumber "$(get_serial_number)"
    sysfs_write strings/0x409/manufacturer "$CFG_MANUFACTURER"
    sysfs_write strings/0x409/product "$CFG_PRODUCT"
    
    # Configuration
    mkdir -p "${CFG_CONFIG_PATH}/strings/0x409"
    
    local config_string=""
    local has_wakeup=0
    
    # Setup enabled functions in order
    # RNDIS must be first for Windows compatibility
    if [ "$CFG_RNDIS" = "1" ]; then
        config_string="${config_string}$(setup_rndis)"
        has_wakeup=1
    fi
    
    if [ "$CFG_ACM" = "1" ]; then
        config_string="${config_string}$(setup_acm)"
    fi
    
    if [ "$CFG_ECM" = "1" ] && [ "$CFG_NCM" != "1" ]; then
        config_string="${config_string}$(setup_ecm)"
        has_wakeup=1
    fi
    
    if [ "$CFG_NCM" = "1" ]; then
        config_string="${config_string}$(setup_ncm)"
        has_wakeup=1
    fi
    
    if [ "$CFG_UMS" = "1" ]; then
        config_string="${config_string}$(setup_ums)"
    fi
    
    # Check if any function was enabled
    if [ -z "$config_string" ]; then
        log "WARNING: No USB functions enabled"
        log "Enable at least one function (rndis, ecm, ncm, acm, or ums)"
        cd /sys/kernel/config/usb_gadget
        rmdir "$CFG_GADGET_NAME" 2>/dev/null || true
        return 1
    fi
    
    # Configuration attributes
    if [ "$has_wakeup" = "1" ]; then
        sysfs_write "${CFG_CONFIG_PATH}/bmAttributes" "0xe0"
    else
        sysfs_write "${CFG_CONFIG_PATH}/bmAttributes" "0xc0"
    fi
    
    sysfs_write "${CFG_CONFIG_PATH}/MaxPower" "250"
    
    # Set configuration string (remove leading +)
    config_string="$(echo "$config_string" | sed 's/^+//')"
    sysfs_write "${CFG_CONFIG_PATH}/strings/0x409/configuration" "$config_string"
    
    # Find and enable UDC
    local udc="$(find_udc)"
    log "Enabling UDC: $udc"
    sysfs_write UDC "$udc"
    
    # Wait for ACM device if enabled
    if [ "$CFG_ACM" = "1" ]; then
        log "Waiting for ttyGS0 device..."
        local i=0
        while [ $i -lt 10 ]; do
            [ -c /dev/ttyGS0 ] && break
            sleep 1
            i=$((i + 1))
        done
        
        if [ ! -c /dev/ttyGS0 ]; then
            log "Warning: /dev/ttyGS0 not found after 10s"
        fi
    fi
    
    # Configure network
    setup_network
    
    log "USB Gadget setup complete"
}

teardown_gadget() {
    log "Tearing down USB gadget"
    
    # Load config to get paths
    load_config
    
    if [ ! -d "$CFG_GADGET_PATH" ]; then
        log "Gadget not found, nothing to tear down"
        return
    fi
    
    cd "$CFG_GADGET_PATH" || return
    
    # Disable gadget
    echo "" > UDC 2>/dev/null || true
    
    # Remove from network bridge
    for ifname in functions/*/ifname; do
        if [ -f "$ifname" ]; then
            local iface="$(cat "$ifname")"
            uci -q del_list "network.@device[0].ports=$iface" 2>/dev/null || true
        fi
    done
    uci commit network
    /etc/init.d/network reload
    
    # Remove configuration links
    rm -f configs/c.1/* 2>/dev/null || true
    rm -f os_desc/c.1 2>/dev/null || true
    rmdir configs/c.1/strings/0x409 2>/dev/null || true
    rmdir configs/c.1 2>/dev/null || true
    
    # Remove function directories
    for func in functions/*; do
        [ -d "$func" ] && rmdir "$func" 2>/dev/null || true
    done
    
    # Remove strings
    rmdir strings/0x409 2>/dev/null || true
    
    # Remove gadget
    cd /sys/kernel/config/usb_gadget
    rmdir "$CFG_GADGET_NAME" 2>/dev/null || true
    
    # Clean shell from inittab
    sed -i '/ttyGS0/d' /etc/inittab
    kill -HUP 1 2>/dev/null || true
    
    log "Teardown complete"
    log "USB port available for host mode"
}

status() {
    load_config
    
    # Check if globally disabled
    if [ "$CFG_ENABLED" != "1" ]; then
        echo "USB Gadget: Disabled in configuration"
        echo "Status: Inactive (host mode available)"
        echo ""
        echo "To enable: uci set usbgadget.usb.enabled='1' && uci commit"
        return 1
    fi
    
    if [ -d "$CFG_GADGET_PATH" ] && [ -s "${CFG_GADGET_PATH}/UDC" ]; then
        echo "USB Gadget: $CFG_GADGET_NAME"
        echo "Status: Active (device mode)"
        echo "UDC: $(cat "${CFG_GADGET_PATH}/UDC")"
        echo ""
        echo "Enabled functions:"
        ls -1 "$CFG_CONFIG_PATH" 2>/dev/null | grep -v strings | sed 's/^/  - /'
        
        # Show ACM status
        if [ "$CFG_ACM" = "1" ]; then
            echo ""
            echo "Serial console:"
            if [ -c /dev/ttyGS0 ]; then
                if [ "$CFG_ACM_SHELL" = "1" ]; then
                    echo "  /dev/ttyGS0 - Available (with shell)"
                else
                    echo "  /dev/ttyGS0 - Available (raw TTY)"
                fi
            else
                echo "  /dev/ttyGS0 - Not found"
            fi
        fi
        
        # Show network interfaces
        echo ""
        echo "Network interfaces:"
        for ifname in "${CFG_FUNCTIONS_PATH}"/*/ifname; do
            if [ -f "$ifname" ]; then
                local iface="$(cat "$ifname")"
                local state="$(cat /sys/class/net/$iface/operstate 2>/dev/null || echo unknown)"
                echo "  - $iface ($state)"
            fi
        done
        
        return 0
    else
        echo "USB Gadget: $CFG_GADGET_NAME"
        echo "Status: Inactive"
        echo ""
        echo "Start with: /etc/init.d/usb-gadget start"
        return 1
    fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

case "${1:-}" in
    start)
        teardown_gadget
        setup_gadget
        ;;
    stop)
        teardown_gadget
        ;;
    restart)
        teardown_gadget
        setup_gadget
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Universal USB Gadget Manager for OpenWrt"
        echo "Configure via: uci set usbgadget.<option>=<value>"
        exit 1
        ;;
esac
