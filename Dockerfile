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

COPY ath.patch .
RUN git apply ath.patch

RUN openwrt/scripts/feeds update -a && \
    openwrt/scripts/feeds install -a && \
    rm -rf openwrt/tmp

CMD ["/bin/bash"]
