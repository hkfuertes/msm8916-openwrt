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

ARG OPENWRT_VERSION=main

# Clone OpenWrt repository
RUN git clone https://git.openwrt.org/openwrt/openwrt.git openwrt && \
    git -C openwrt checkout ${OPENWRT_VERSION}

# Apply mac80211 patches (wcn36xx/ath10k-sdio support)
COPY --chmod=755 apply_patches.sh ./
RUN ./apply_patches.sh openwrt

# Update and install feeds
RUN cd openwrt && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a && \
    rm -rf tmp

# Fix LuCI getFeatures crash when odhcpd is present (conditional - may be fixed in release)
RUN LUCI_FILE="openwrt/feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci" && \
    if [ -f "$LUCI_FILE" ] && grep -q 'result\.odhcpd = false;' "$LUCI_FILE"; then \
      sed -i 's/result\.odhcpd = false;/result.odhcpd = {};/' "$LUCI_FILE"; \
    fi

WORKDIR /home/builder/openwrt

CMD ["/bin/bash"]
