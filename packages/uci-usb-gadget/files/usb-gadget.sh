#!/bin/bash
# Universal USB Gadget Manager for Linux
# Requires: bash, UCI (OpenWrt)
# Compatible: OpenWrt, Raspberry Pi, any device with USB gadget support

set -e

# Load UCI library
. /lib/functions.sh

# ============================================================================
# Configuration 
# ============================================================================

declare -A CFG

load_config() {
    config_load usbgadget
    
    # Gadget name (configurable, works on any hardware)
    config_get CFG[gadget_name] usb gadget_name "g1"
    
    # Paths
    CFG[gadget_path]="/sys/kernel/config/usb_gadget/${CFG[gadget_name]}"
    CFG[config_path]="${CFG[gadget_path]}/configs/c.1"
    CFG[functions_path]="${CFG[gadget_path]}/functions"
    
    # USB Device IDs
    config_get CFG[vendor_id] usb vendor_id "0x1d6b"
    config_get CFG[product_id] usb product_id "0x0104"
    config_get CFG[device_version] usb device_version "0x0100"
    config_get CFG[manufacturer] usb manufacturer "Linux"
    config_get CFG[product] usb product "USB Gadget"
    config_get CFG[udc_device] usb udc_device ""
    
    # Functions (boolean)
    config_get_bool CFG[rndis] rndis enabled 0
    config_get_bool CFG[ecm] ecm enabled 0
    config_get_bool CFG[ncm] ncm enabled 0
    config_get_bool CFG[acm] acm enabled 0
    config_get_bool CFG[ums] ums enabled 0
    
    # ACM options
    config_get_bool CFG[acm_shell] acm shell 1
    
    # UMS options
    config_get CFG[ums_image] ums image_path "/var/lib/usb-gadget/storage.img"
    config_get CFG[ums_size] ums image_size "512M"
    config_get_bool CFG[ums_readonly] ums readonly 0
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
    [[ -f /etc/machine-id ]] && {
        sha256sum < /etc/machine-id | cut -d' ' -f1 | cut -c1-16
        return
    }
    echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)"
}

generate_mac() {
    local prefix="$1"
    local serial="$(get_serial_number)"
    local hash="$(echo "${serial}${prefix}" | md5sum | cut -c1-12)"
    
    # Set locally administered, unicast
    local b1="$(printf '%02x' $((0x${hash:0:2} & 0xfe | 0x02)))"
    
    echo "${b1}:${hash:2:2}:${hash:4:2}:${hash:6:2}:${hash:8:2}:${hash:10:2}"
}

find_udc() {
    # Return configured UDC if set
    [[ -n "${CFG[udc_device]}" ]] && {
        echo "${CFG[udc_device]}"
        return
    }
    
    # Auto-detect UDC - works on ALL hardware:
    # - Raspberry Pi (dwc2): 20980000.usb, fe980000.usb, 1000480000.usb
    # - MSM8916 (ci_hdrc): ci_hdrc.0
    # - Orange Pi (musb): musb-hdrc.4.auto
    # - etc...
    local udc="$(ls /sys/class/udc/ 2>/dev/null | head -1)"
    
    [[ -n "$udc" ]] || error "No UDC device found. Is USB gadget support enabled?"
    
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
    local func="${CFG[functions_path]}/rndis.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac rndis-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac rndis-dev)"
    ln -sf "$func" "${CFG[config_path]}/"
    
    # Windows compatibility
    sysfs_write "${CFG[gadget_path]}/os_desc/use" "1"
    sysfs_write "${CFG[gadget_path]}/os_desc/b_vendor_code" "0xcd"
    sysfs_write "${CFG[gadget_path]}/os_desc/qw_sign" "MSFT100"
    sysfs_write "${func}/os_desc/interface.rndis/compatible_id" "RNDIS"
    sysfs_write "${func}/os_desc/interface.rndis/sub_compatible_id" "5162001"
    ln -sf "${CFG[config_path]}" "${CFG[gadget_path]}/os_desc/"
    
    echo "+RNDIS"
}

setup_ecm() {
    log "Enabling ECM"
    local func="${CFG[functions_path]}/ecm.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac ecm-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac ecm-dev)"
    ln -sf "$func" "${CFG[config_path]}/"
    
    echo "+ECM"
}

setup_ncm() {
    log "Enabling NCM"
    local func="${CFG[functions_path]}/ncm.usb0"
    
    mkdir -p "$func"
    sysfs_write "${func}/host_addr" "$(generate_mac ncm-host)"
    sysfs_write "${func}/dev_addr" "$(generate_mac ncm-dev)"
    ln -sf "$func" "${CFG[config_path]}/"
    
    echo "+NCM"
}

setup_acm() {
    log "Enabling ACM"
    local func="${CFG[functions_path]}/acm.GS0"
    
    mkdir -p "$func"
    ln -sf "$func" "${CFG[config_path]}/"
    
    # Manage shell (OpenWrt specific)
    if [[ -f /etc/inittab ]]; then
        sed -i '/ttyGS0/d' /etc/inittab
        [[ "${CFG[acm_shell]}" == "1" ]] && \
            echo "ttyGS0::askfirst:/usr/libexec/login.sh" >> /etc/inittab
        kill -HUP 1 2>/dev/null || true
    fi
    
    echo "+ACM"
}

setup_ums() {
    local image="${CFG[ums_image]}"
    
    # Create image if doesn't exist
    [[ ! -f "$image" ]] && {
        log "Creating storage image: $image (${CFG[ums_size]})"
        mkdir -p "$(dirname "$image")"
        truncate -s "${CFG[ums_size]}" "$image" || \
            dd if=/dev/zero of="$image" bs=1M count="${CFG[ums_size]%M}"
    }
    
    log "Enabling UMS"
    local func="${CFG[functions_path]}/mass_storage.0"
    
    mkdir -p "$func"
    sysfs_write "${func}/lun.0/ro" "${CFG[ums_readonly]}"
    sysfs_write "${func}/lun.0/file" "$image"
    ln -sf "$func" "${CFG[config_path]}/"
    
    echo "+UMS"
}

# ============================================================================
# Network Configuration (OpenWrt specific)
# ============================================================================

add_to_bridge() {
    local ifname_file="$1"
    [[ ! -f "$ifname_file" ]] && return
    
    local iface="$(cat "$ifname_file")"
    log "Adding $iface to bridge"
    
    uci -q delete "network.@device[0].ports=$iface" 2>/dev/null || true
    uci add_list "network.@device[0].ports=$iface"
}

setup_network() {
    # Skip if not OpenWrt
    command -v uci &>/dev/null || {
        log "Not OpenWrt, skipping network configuration"
        return
    }
    
    sleep 1
    
    [[ "${CFG[rndis]}" == "1" ]] && add_to_bridge "${CFG[functions_path]}/rndis.usb0/ifname"
    [[ "${CFG[ecm]}" == "1" ]] && add_to_bridge "${CFG[functions_path]}/ecm.usb0/ifname"
    [[ "${CFG[ncm]}" == "1" ]] && add_to_bridge "${CFG[functions_path]}/ncm.usb0/ifname"
    
    uci commit network
    /etc/init.d/network reload
}

# ============================================================================
# Main Gadget Management
# ============================================================================

setup_gadget() {
    log "Setting up USB gadget"
    
    # Load configuration
    load_config
    
    log "Gadget name: ${CFG[gadget_name]}"
    log "Gadget path: ${CFG[gadget_path]}"
    
    # Prepare system
    modprobe libcomposite || error "Failed to load libcomposite module"
    
    mountpoint -q /sys/kernel/config || {
        log "Mounting configfs"
        mount -t configfs none /sys/kernel/config
    }
    
    # Create gadget directory
    mkdir -p "${CFG[gadget_path]}" || error "Failed to create gadget directory"
    cd "${CFG[gadget_path]}"
    
    # Device descriptors
    sysfs_write idVendor "${CFG[vendor_id]}"
    sysfs_write idProduct "${CFG[product_id]}"
    sysfs_write bcdDevice "${CFG[device_version]}"
    
    # Composite device class
    sysfs_write bDeviceClass "0xEF"
    sysfs_write bDeviceSubClass "0x02"
    sysfs_write bDeviceProtocol "0x01"
    
    # Strings (USB descriptors)
    mkdir -p strings/0x409
    sysfs_write strings/0x409/serialnumber "$(get_serial_number)"
    sysfs_write strings/0x409/manufacturer "${CFG[manufacturer]}"
    sysfs_write strings/0x409/product "${CFG[product]}"
    
    # Configuration
    mkdir -p "${CFG[config_path]}/strings/0x409"
    
    local config_string=""
    local has_wakeup=0
    
    # Setup enabled functions in order
    # RNDIS must be first for Windows compatibility
    if [[ "${CFG[rndis]}" == "1" ]]; then
        config_string+="$(setup_rndis)"
        has_wakeup=1
    fi
    
    [[ "${CFG[acm]}" == "1" ]] && config_string+="$(setup_acm)"
    
    if [[ "${CFG[ecm]}" == "1" ]] && [[ "${CFG[ncm]}" != "1" ]]; then
        config_string+="$(setup_ecm)"
        has_wakeup=1
    fi
    
    if [[ "${CFG[ncm]}" == "1" ]]; then
        config_string+="$(setup_ncm)"
        has_wakeup=1
    fi
    
    [[ "${CFG[ums]}" == "1" ]] && config_string+="$(setup_ums)"
    
    # Configuration attributes
    if [[ $has_wakeup -eq 1 ]]; then
        sysfs_write "${CFG[config_path]}/bmAttributes" "0xe0"  # Self-powered + remote wakeup
    else
        sysfs_write "${CFG[config_path]}/bmAttributes" "0xc0"  # Self-powered
    fi
    
    sysfs_write "${CFG[config_path]}/MaxPower" "250"  # 500mA
    
    # Set configuration string (remove leading +)
    sysfs_write "${CFG[config_path]}/strings/0x409/configuration" "${config_string#+}"
    
    # Find and enable UDC
    local udc="$(find_udc)"
    log "Enabling UDC: $udc"
    sysfs_write UDC "$udc"
    
    # Wait for ACM device if enabled
    if [[ "${CFG[acm]}" == "1" ]]; then
        log "Waiting for ttyGS0 device..."
        for i in {1..10}; do
            [[ -c /dev/ttyGS0 ]] && break
            sleep 1
        done
        
        [[ ! -c /dev/ttyGS0 ]] && log "Warning: /dev/ttyGS0 not found after 10s"
    fi
    
    # Configure network (OpenWrt only)
    setup_network
    
    log "USB Gadget setup complete"
}

teardown_gadget() {
    log "Tearing down USB gadget"
    
    # Load config to get paths
    load_config
    
    [[ ! -d "${CFG[gadget_path]}" ]] && {
        log "Gadget not found, nothing to tear down"
        return
    }
    
    cd "${CFG[gadget_path]}"
    
    # Disable gadget
    echo "" > UDC 2>/dev/null || true
    
    # Remove from network bridge (OpenWrt)
    if command -v uci &>/dev/null; then
        for ifname in functions/*/ifname; do
            [[ -f "$ifname" ]] && {
                local iface="$(cat "$ifname")"
                uci -q delete "network.@device[0].ports=$iface" 2>/dev/null || true
            }
        done
        uci commit network
        /etc/init.d/network reload
    fi
    
    # Remove configuration links
    rm -f configs/c.1/* 2>/dev/null || true
    rm -f os_desc/c.1 2>/dev/null || true
    rmdir configs/c.1/strings/0x409 2>/dev/null || true
    rmdir configs/c.1 2>/dev/null || true
    
    # Remove function directories
    for func in functions/*; do
        [[ -d "$func" ]] && rmdir "$func" 2>/dev/null || true
    done
    
    # Remove strings
    rmdir strings/0x409 2>/dev/null || true
    
    # Remove gadget
    cd /sys/kernel/config/usb_gadget
    rmdir "${CFG[gadget_name]}" 2>/dev/null || true
    
    # Clean shell from inittab
    if [[ -f /etc/inittab ]]; then
        sed -i '/ttyGS0/d' /etc/inittab
        kill -HUP 1 2>/dev/null || true
    fi
    
    log "Teardown complete"
}

status() {
    load_config
    
    if [[ -d "${CFG[gadget_path]}" ]] && [[ -s "${CFG[gadget_path]}/UDC" ]]; then
        echo "USB Gadget: ${CFG[gadget_name]}"
        echo "Status: Active"
        echo "UDC: $(cat "${CFG[gadget_path]}/UDC")"
        echo ""
        echo "Enabled functions:"
        ls -1 "${CFG[config_path]}" 2>/dev/null | grep -v strings | sed 's/^/  - /'
        
        # Show ACM status
        if [[ "${CFG[acm]}" == "1" ]]; then
            echo ""
            echo "Serial console:"
            if [[ -c /dev/ttyGS0 ]]; then
                if [[ "${CFG[acm_shell]}" == "1" ]]; then
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
        for ifname in "${CFG[functions_path]}"/*/ifname; do
            [[ -f "$ifname" ]] && {
                local iface="$(cat "$ifname")"
                local state="$(cat /sys/class/net/$iface/operstate 2>/dev/null || echo unknown)"
                echo "  - $iface ($state)"
            }
        done
        
        return 0
    else
        echo "USB Gadget: ${CFG[gadget_name]}"
        echo "Status: Inactive"
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
        echo "Universal USB Gadget Manager"
        echo "Compatible with any Linux device with USB gadget support"
        exit 1
        ;;
esac
