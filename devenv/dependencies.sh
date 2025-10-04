#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# Install all dependencies for OpenWrt and lk2nd/qhypstub compilation
# Including: build essentials, ARM toolchains, development libraries, and utilities
apt-get update && apt-get install -y --no-install-recommends \
    android-sdk-libsparse-utils mkbootimg \
    asciidoc help2man xsltproc \
    bash bc binutils bzip2 make patch time \
    device-tree-compiler \
    e2fsprogs fdisk util-linux \
    flex gawk rsync swig \
    g++ gcc gcc-aarch64-linux-gnu gcc-arm-none-eabi \
    gettext intltool \
    git \
    gzip tar unzip xz-utils zstd zip \
    libelf-dev libfdt-dev libncurses5-dev libssl-dev zlib1g-dev \
    nano sudo \
    perl perl-modules \
    python3-dev python3-setuptools python3-cryptography \
    wget \
    && rm -rf /var/lib/apt/lists/*
