#!/bin/sh
# MSM8916 eMMC sysupgrade - kernel (Android boot image) + rootfs (squashfs)
#
# The sysupgrade bundle is a tar containing:
#   boot   - Android boot image for the kernel
#   rootfs - squashfs root filesystem

REQUIRE_IMAGE_METADATA=1

platform_check_image() {
    local tar_file="$1"
    local member

    # Must be a tar archive
    if ! tar -tf "$tar_file" > /tmp/sysupgrade-members 2>/dev/null; then
        echo "sysupgrade: not a valid tar archive"
        return 1
    fi

    # Must contain both 'boot' and 'rootfs' members
    if ! grep -q '^boot$' /tmp/sysupgrade-members; then
        echo "sysupgrade: missing 'boot' member in image"
        return 1
    fi
    if ! grep -q '^rootfs$' /tmp/sysupgrade-members; then
        echo "sysupgrade: missing 'rootfs' member in image"
        return 1
    fi

    # Validate squashfs magic in the rootfs member
    local magic
    magic=$(tar -xOf "$tar_file" rootfs 2>/dev/null | dd bs=4 count=1 2>/dev/null | hexdump -v -n 4 -e '1/4 "%08x"')
    case "$magic" in
        73717368)
            ;;
        *)
            echo "sysupgrade: rootfs member does not look like squashfs (magic: $magic)"
            return 1
            ;;
    esac

    return 0
}

platform_do_upgrade() {
    local tar_file="$1"
    local boot_part rootfs_part

    # Locate partitions by GPT label
    boot_part=$(find_mmc_part "boot")
    rootfs_part=$(find_mmc_part "rootfs")

    if [ -z "$boot_part" ]; then
        echo "sysupgrade: cannot find 'boot' partition"
        return 1
    fi
    if [ -z "$rootfs_part" ]; then
        echo "sysupgrade: cannot find 'rootfs' partition"
        return 1
    fi

    echo "sysupgrade: writing kernel to $boot_part"
    tar -xOf "$tar_file" boot 2>/dev/null | \
        dd of="$boot_part" bs=4096 conv=fsync

    echo "sysupgrade: writing rootfs to $rootfs_part"
    tar -xOf "$tar_file" rootfs 2>/dev/null | \
        dd of="$rootfs_part" bs=4096 conv=fsync

    sync
}

platform_copy_config() {
    local overlay_part mnt

    overlay_part=$(find_mmc_part "rootfs_data")
    [ -z "$overlay_part" ] && return 0

    mnt=$(mktemp -d)
    mount -t ext4 "$overlay_part" "$mnt" 2>/dev/null || {
        rmdir "$mnt"
        return 0
    }

    mkdir -p "$mnt/.overlay"
    cp -af "$UPGRADE_BACKUP" "$mnt/.overlay/sysupgrade.tgz" 2>/dev/null

    umount "$mnt"
    rmdir "$mnt"
}
