## NOT WORKING
There is no fine control tu run the init in openwrt before kernel asks for drivers, so luckily modem gets activated, but not wifi:
- Working if manually enabled, as it seems that asks for wifi driver before persist is mounted.
```shell
    echo start > /sys/class/remoteproc/remoteproc0/state
    echo start > /sys/class/remoteproc/remoteproc1/state
```
- https://gitlab.postmarketos.org/postmarketOS/msm-firmware-loader/
- Investigate if this can be replicated in wrt:
```shell
    #!/sbin/openrc-run

    name="MSM Firmware Loader"
    description="Load firmware that is located on dedicated partitions of qcom devices"

    depend() { # <-----------------
    need sysfs devfs
    before udev
    }

    start() {
    ebegin "Starting msm-firmware-loader"
    # This script must be executed before udev, block other services until it's done.
    /usr/sbin/msm-firmware-loader.sh
    eend $?
    }
```