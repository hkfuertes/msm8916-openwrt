### Enter DIAG
```shell
adb shell
setprop service.adb.root 1; busybox killall adbd
adb shell
setprop sys.usb.config diag,adb

adb shell "setprop service.adb.root 1; busybox killall adbd"
adb shell "setprop sys.usb.config diag,adb"
```

> If in linux, now connect to Windows VM and open QXDM