FROM ubuntu:22.04 AS base

LABEL maintainer="OpenWrt Builder"

# Install required dependencies
COPY ./dependencies.sh /install_dependencies
RUN chmod +x /install_dependencies && \
    /install_dependencies && \
    rm -rf /install_dependencies

# Create a non-root user for building
RUN useradd -G sudo -m -u 1000 builder

USER builder
WORKDIR /home/builder

FROM base

RUN git clone --depth=1 https://github.com/openwrt/openwrt openwrt

COPY mods/ath.mk openwrt/package/kernel/mac80211/ath.mk
COPY mods/netdevices.mk openwrt/package/kernel/linux/modules/netdevices.mk
COPY mods/power openwrt/package/base-files/files/etc/rc.button/power


RUN openwrt/scripts/feeds update -a && \
    openwrt/scripts/feeds install -a && \
    rm -rf openwrt/tmp

CMD ["/bin/bash"]
