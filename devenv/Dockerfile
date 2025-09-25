FROM ubuntu:22.04 AS base

LABEL maintainer="OpenWrt Builder"

# Install required dependencies
COPY devenv/dependencies.sh /install_dependencies
RUN chmod +x /install_dependencies && \
    /install_dependencies && \
    rm -rf /install_dependencies

# Create a non-root user for building
RUN useradd -G sudo -m -u 1000 builder

USER builder
WORKDIR /home/builder

FROM base

# ENV BRANCH openwrt-24.10
ENV BRANCH main

RUN git clone --depth=1 -b ${BRANCH} https://git.openwrt.org/openwrt/openwrt.git openwrt
#RUN git clone --depth=1 -b ${BRANCH} https://github.com/openwrt/openwrt.git openwrt

COPY enable_wcn36xx_mac80211.patch .
RUN git apply enable_wcn36xx_mac80211.patch

# COPY ../github.feeds.conf.default openwrt/feeds.conf.default

RUN openwrt/scripts/feeds update -a && \
    openwrt/scripts/feeds install -a && \
    rm -rf openwrt/tmp

CMD ["/bin/bash"]
