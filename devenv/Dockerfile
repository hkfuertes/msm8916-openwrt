FROM ubuntu:22.04 AS base

LABEL maintainer="OpenWrt Builder"

# Install required dependencies
COPY devenv/dependencies.sh /install_dependencies
RUN chmod +x /install_dependencies && \
    /install_dependencies && \
    rm -rf /install_dependencies

# Create a non-root user with sudo access (no password required)
RUN useradd -m -u 1000 -G sudo builder && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER builder
WORKDIR /home/builder

FROM base AS openwrt

ENV BRANCH=main

# Clone OpenWrt repository
RUN git clone https://git.openwrt.org/openwrt/openwrt.git openwrt && \
    git -C openwrt checkout 00ceb1ed1763f7479df6edf92ffada948f0e7d45

# Apply patch inside openwrt directory
COPY enable_wcn36xx_mac80211.patch .
RUN git apply enable_wcn36xx_mac80211.patch

# Update and install feeds
RUN cd openwrt && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a && \
    rm -rf tmp

# Fix LuCI getFeatures crash when odhcpd is present (upstream bug: ??= doesn't override false)
RUN sed -i 's/result\.odhcpd = false;/result.odhcpd = {};/' \
    openwrt/feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci

WORKDIR /home/builder/openwrt

CMD ["/bin/bash"]
