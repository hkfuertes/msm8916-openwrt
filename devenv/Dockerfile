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
RUN git clone --depth=1 -b ${BRANCH} https://git.openwrt.org/openwrt/openwrt.git openwrt

# Apply patch inside openwrt directory
COPY enable_wcn36xx_mac80211.patch .
RUN git apply enable_wcn36xx_mac80211.patch

# Update and install feeds
RUN cd openwrt && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a && \
    rm -rf tmp

WORKDIR /home/builder/openwrt

CMD ["/bin/bash"]
