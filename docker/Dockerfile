FROM ubuntu:22.04
LABEL maintainer="haiker <ni@renzhen.la>"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get upgrade -y && \
    apt install -y build-essential checkinstall autoconf libtool pkg-config && \
    apt install -y git wget curl jq clang gcc g++ zlib1g-dev libmpc-dev libmpfr-dev libgmp-dev && \
    apt install -y cmake gcc-mingw-w64 libxml2 libxml2-dev openssl libssl-dev zip upx binutils && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y && \
    git clone https://github.com/tpoechtrager/osxcross /opt/osxcross && cd /opt/osxcross && \
    wget -nc https://s3.dockerproject.org/darwin/v2/MacOSX10.10.sdk.tar.xz -P /opt/osxcross/tarballs/ && \
    UNATTENDED=yes OSX_VERSION_MIN=10.7 ./build.sh

COPY entrypoint.sh /entrypoint.sh
COPY targets /targets
ENV PATH "/root/.cargo/bin:/opt/osxcross/target/bin:$PATH"

WORKDIR /build
ENTRYPOINT ["/entrypoint.sh"]
