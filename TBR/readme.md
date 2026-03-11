# TBR - Deprecated Device Support (MF68E, M9S)

These files were removed from the main build but are kept here for reference.
They supported MiFi-style devices (MF68E, M9S) with displays, battery monitoring
and power button handling.

## How to re-integrate

### 1. Device definitions

Add the contents of `msm8916.mk.devices` to `msm89xx/image/msm8916.mk`,
before the `endif` line.

### 2. Kernel patches

Copy the patches back into `msm89xx/patches-6.12/`:

```sh
cp patches/802-arm64-dts-qcom-add-msm8916-generic-mf68e.patch ../msm89xx/patches-6.12/
cp patches/805-arm64-dts-qcom-add-msm8916-generic-m9s.patch   ../msm89xx/patches-6.12/
cp patches/901-fbtft-fb_gc9107.patch                           ../msm89xx/patches-6.12/
```

The `801-...patch.orig` only adds mf68e and m9s (UF02 is already handled
by the active `801` patch). Both patches touch different lines so they
apply cleanly one after another.

### 3. Packages

Move the packages back into the `packages/` directory:

```sh
cp -r packages/configs-mifi   ../packages/
cp -r packages/router-display  ../packages/
cp -r packages/fbtft-gc9107    ../packages/
```

These packages provide:
- **configs-mifi**: UCI defaults, LED hotplugs, battery monitoring, power button
  handling, and a pre-built Tailscale APK for MiFi devices.
- **router-display**: SPI display manager (GC9107) with boot/shutdown logos and
  status display for MF68E.
- **fbtft-gc9107**: Kernel module for the GC9107 framebuffer (SPI display).

### 4. Diffconfigs

Move `diffconfig_m9s` and `diffconfig_mf68e` back to the repository root.

### 5. CI/CD

Add `m9s` and `mf68e` back to the device matrix in `.github/workflows/build-all.yml`
and the choice options in `.github/workflows/build.yml`.
