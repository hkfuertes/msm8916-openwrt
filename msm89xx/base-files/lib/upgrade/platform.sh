#!/bin/sh
# MSM8916 eMMC sysupgrade - kernel (Android boot image) + rootfs (squashfs)

PART_NAME=firmware
REQUIRE_IMAGE_METADATA=1

platform_check_image() {
    local fw_image="$1"
    local boardname="$(board_name | tr -d '-' | tr ',' '-')"

    # Must be a tar archive
    local control_len=$( (tar xf $fw_image sysupgrade-$boardname/CONTROL -O | wc -c) 2> /dev/null)

    # check if valid sysupgrade tar archive
    if [ "$control_len" = "0" ]; then
        echo "Invalid sysupgrade file: $fw_image"
        return 1
    fi

    return 0
}

platform_do_upgrade() {
    local tar_file="$1"
    local boot_part rootfs_part
    local board_dir=$(tar tf $tar_file | grep -m 1 '^sysupgrade-.*/$')
    board_dir=${board_dir%/}

    # Locate partitions by GPT label
    boot_part=$(find_mmc_part "boot")
    rootfs_part=$(find_mmc_part "rootfs")

    [ -z "$boot_part" ] && { echo "sysupgrade: cannot find 'boot' partition"; return 1; }
    [ -z "$rootfs_part" ] && { echo "sysupgrade: cannot find 'rootfs' partition"; return 1; }

    echo "sysupgrade: writing kernel to $boot_part"
    tar -xOf "$tar_file" ${board_dir}/kernel 2>/dev/null | \
        dd of="$boot_part" bs=4096 conv=fsync

    echo "sysupgrade: writing rootfs to $rootfs_part"
    tar -xOf "$tar_file" ${board_dir}/root 2>/dev/null | \
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

    cp -f "$UPGRADE_BACKUP" "$mnt/.overlay-sysupgrade.tgz" 2>/dev/null

    umount "$mnt"
    rmdir "$mnt"
}
