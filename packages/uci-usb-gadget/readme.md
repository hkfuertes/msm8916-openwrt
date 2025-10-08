# USB Gadget Manager - UCI Configuration Guide

Universal USB Gadget Manager for OpenWrt using configfs interface.

## Quick Start

```bash
# View current configuration
uci show usbgadget

# Enable/start the service
/etc/init.d/usb-gadget enable
/etc/init.d/usb-gadget start

# Check status
/etc/init.d/usb-gadget status
```

## Configuration File

Location: `/etc/config/usbgadget`

## Common Tasks

### Enable/Disable USB Gadget Mode

```bash
# Disable gadget (enable host mode - for USB storage, etc.)
uci set usbgadget.usb.enabled='0'
uci commit usbgadget
/etc/init.d/usb-gadget restart

# Enable gadget mode
uci set usbgadget.usb.enabled='1'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

### Network Functions

#### RNDIS (Windows Ethernet)

```bash
# Enable RNDIS
uci set usbgadget.rndis.enabled='1'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

**Compatible with:** Windows (all versions, plug-and-play)

#### ECM (macOS/Linux Ethernet)

```bash
# Enable ECM
uci set usbgadget.ecm.enabled='1'
uci set usbgadget.rndis.enabled='0'  # Disable RNDIS
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

**Compatible with:** macOS ≤10.14, Linux (all)

#### NCM (Modern High-Performance Ethernet)

```bash
# Enable NCM (best performance)
uci set usbgadget.ncm.enabled='1'
uci set usbgadget.rndis.enabled='0'  # Disable RNDIS
uci set usbgadget.ecm.enabled='0'     # Disable ECM
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

**Compatible with:** Windows 11+, macOS ≥10.15, Linux (all)

**Note:** Network interfaces are automatically added to the LAN bridge.

### Serial Console (ACM)

#### Enable Serial Console with Login Shell

```bash
# Enable ACM with shell access
uci set usbgadget.acm.enabled='1'
uci set usbgadget.acm.shell='1'
uci commit usbgadget
/etc/init.d/usb-gadget restart

# Access from host:
# Linux/macOS: screen /dev/ttyACM0 115200
# Windows: Use PuTTY or similar on COMx port
```

#### Enable Raw TTY (No Shell)

```bash
# Enable ACM without shell (raw serial port)
uci set usbgadget.acm.enabled='1'
uci set usbgadget.acm.shell='0'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

### Mass Storage (UMS)

```bash
# Enable USB mass storage
uci set usbgadget.ums.enabled='1'
uci set usbgadget.ums.image_path='/var/lib/usb-gadget/storage.img'
uci set usbgadget.ums.image_size='1G'
uci set usbgadget.ums.readonly='0'  # 0=read-write, 1=read-only
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

**Note:** Image file is created automatically on first use.

### Device Information

```bash
# Change USB vendor/product name
uci set usbgadget.usb.manufacturer='MyCompany'
uci set usbgadget.usb.product='My USB Device'
uci commit usbgadget
/etc/init.d/usb-gadget restart

# Change USB IDs (advanced)
uci set usbgadget.usb.vendor_id='0x1234'
uci set usbgadget.usb.product_id='0x5678'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

### Custom Gadget Name

```bash
# Change internal gadget name (optional)
uci set usbgadget.usb.gadget_name='my-device'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

## Common Scenarios

### Scenario 1: Quick Network Access (Windows PC)

```bash
uci set usbgadget.usb.enabled='1'
uci set usbgadget.rndis.enabled='1'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

Connect USB cable. Windows will detect "Remote NDIS Compatible Device" and get DHCP from OpenWrt.

### Scenario 2: Maximum Performance (Modern OS)

```bash
uci set usbgadget.usb.enabled='1'
uci set usbgadget.ncm.enabled='1'
uci set usbgadget.rndis.enabled='0'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

### Scenario 3: Serial Console + Network

```bash
uci set usbgadget.usb.enabled='1'
uci set usbgadget.rndis.enabled='1'
uci set usbgadget.acm.enabled='1'
uci set usbgadget.acm.shell='1'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

Provides both network access and serial console on the same USB connection.

### Scenario 4: USB Storage + Network

```bash
uci set usbgadget.usb.enabled='1'
uci set usbgadget.rndis.enabled='1'
uci set usbgadget.ums.enabled='1'
uci set usbgadget.ums.image_size='2G'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

### Scenario 5: Switch to USB Host Mode

```bash
# Disable gadget to use USB port for storage, etc.
uci set usbgadget.usb.enabled='0'
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

Now you can connect USB storage devices to the OpenWrt device.

## Service Management

```bash
# Start
/etc/init.d/usb-gadget start

# Stop
/etc/init.d/usb-gadget stop

# Restart (applies new configuration)
/etc/init.d/usb-gadget restart

# Status
/etc/init.d/usb-gadget status

# Enable on boot
/etc/init.d/usb-gadget enable

# Disable on boot
/etc/init.d/usb-gadget disable
```

## Viewing Configuration

```bash
# View all settings
uci show usbgadget

# View specific section
uci show usbgadget.usb
uci show usbgadget.rndis
uci show usbgadget.acm

# Export to file
uci export usbgadget > /tmp/usbgadget-backup.conf

# Import from file
uci import usbgadget < /tmp/usbgadget-backup.conf
```

## Troubleshooting

### Check if gadget is active

```bash
/etc/init.d/usb-gadget status
```

### View logs

```bash
logread | grep usb-gadget
```

### Check USB controller

```bash
ls /sys/class/udc/
# Should show: ci_hdrc.0 (MSM8916), 20980000.usb (RPi), etc.
```

### Verify network interface

```bash
ip link show
# Look for: usb0, usb1, etc.

# Check if added to bridge
uci show network.@device[0].ports
```

### Reset to defaults

```bash
rm /etc/config/usbgadget
/etc/init.d/usb-gadget restart
```

This will recreate the config with default values.

### Common Issues

**"No UDC device found"**
- USB gadget kernel support not enabled
- Install: 
  - `opkg install kmod-usb-gadget kmod-usb-configfs`
  - `apk add kmod-usb-gadget kmod-usb-configfs`

**"ttyGS0 not found"**
- ACM function takes ~10 seconds to initialize
- Check: `ls -l /dev/ttyGS0`

**Network not working**
- Verify function is enabled: `uci show usbgadget.rndis.enabled`
- Check if interface exists: `ip link show usb0`
- Verify bridge: `brctl show br-lan`

## Hardware Compatibility

**Auto-detects USB controller on:**
- Raspberry Pi (all models with USB OTG)
- Qualcomm MSM8916/MSM89xx devices
- Orange Pi, Banana Pi
- Any device with USB gadget kernel support

**No hardware-specific configuration needed!**

## Advanced: Manual UDC Selection

If auto-detection fails:

```bash
# Check available UDC
ls /sys/class/udc/

# Set manually
uci set usbgadget.usb.udc_device='ci_hdrc.0'  # Example
uci commit usbgadget
/etc/init.d/usb-gadget restart
```

## Configuration Reference

### Device Section (`config device 'usb'`)

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `1` | Enable/disable gadget (0=host mode, 1=device mode) |
| `gadget_name` | `g1` | Internal gadget name (any string) |
| `vendor_id` | `0x1d6b` | USB Vendor ID (Linux Foundation) |
| `product_id` | `0x0104` | USB Product ID (Multifunction Composite) |
| `device_version` | `0x0100` | Device version (BCD format) |
| `manufacturer` | `OpenWrt` | Manufacturer string shown to host |
| `product` | `USB Gadget` | Product string shown to host |
| `udc_device` | _(empty)_ | UDC device name (auto-detect if empty) |

### Function Sections

Each function has:
- `enabled`: `0` or `1`
- `description`: Human-readable description (not used by system)

#### RNDIS Function (`config function 'rndis'`)
No additional options.

#### ECM Function (`config function 'ecm'`)
No additional options.

#### NCM Function (`config function 'ncm'`)
No additional options.

#### ACM Function (`config function 'acm'`)
- `shell`: `0` or `1` - Enable login shell on serial console

#### UMS Function (`config function 'ums'`)
- `image_path`: Path to image file
- `image_size`: Size when creating (e.g., `512M`, `1G`, `2G`)
- `readonly`: `0` (read-write) or `1` (read-only)

## Tips

- **Multiple functions:** You can enable multiple functions simultaneously (e.g., RNDIS + ACM)
- **Network priority:** Only one network function should be enabled at a time (RNDIS, ECM, or NCM)
- **Serial number:** Auto-generated from `/etc/machine-id` for uniqueness
- **MAC addresses:** Auto-generated deterministically (same device = same MACs)
- **Storage persistence:** UMS image persists across reboots (in `/var` which is `/tmp`)

## Learn More

- OpenWrt USB Gadget: https://openwrt.org/docs/guide-user/hardware/usb_gadget
- Linux USB Gadget API: https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html
- UCI Documentation: https://openwrt.org/docs/guide-user/base-system/uci
