#!/bin/sh
FLAG="/RESIZED"

[ -f "$FLAG" ] && return 0

rootpart=$(findmnt -n -o SOURCE /)
mount -o ro,remount /
tune2fs -O^resize_inode ${rootpart}
fsck.ext4 -yDf ${rootpart} > /dev/null
mount -o rw,remount /
resize2fs ${rootpart} > /dev/null

touch "$FLAG"
