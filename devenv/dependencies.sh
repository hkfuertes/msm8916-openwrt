#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get install -y --no-install-recommends \
    xz-utils \
    asciidoc \
    bash \
    bc \
    binutils \
    bzip2 \
    flex \
    git \
    g++ \
    gcc \
    time \
    util-linux \
    gawk \
    gzip \
    help2man \
    intltool \
    libelf-dev \
    zlib1g-dev \
    make \
    libncurses5-dev \
    libssl-dev \
    patch \
    perl \
    perl-modules \
    python3-dev \
    python3-setuptools \
    rsync \
    swig \
    tar \
    unzip \
    wget \
    gettext \
    xsltproc \
    sudo \
    android-sdk-libsparse-utils \
    mkbootimg \
    zstd \
    e2fsprogs \
    fdisk \
    nano \
    && rm -rf /var/lib/apt/lists/*
