FROM debian:bullseye-slim

ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

COPY ./conf/sources.list /etc/apt/sources.list
# COPY ./conf/debian.sources /etc/apt/sources.list.d/debian.sources

RUN useradd -ms /bin/bash shaw && \
    apt-get update -y && \
    apt-get install -y ca-certificates && \
    sed -i 's_http:_https:_' /etc/apt/sources.list && \
    apt-get full-upgrade -y && \
    apt-get install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd

USER shaw

WORKDIR /home/shaw

COPY --chown=shaw:shaw ./setup.sh /home/shaw/setup.sh
COPY --chown=shaw:shaw ./entrypoint.sh /home/shaw/entrypoint.sh
COPY --chown=shaw:shaw ./conf/feeds.custom.conf /home/shaw/conf/feeds.custom.conf
COPY --chown=shaw:shaw ./conf/initial_script.sh /home/shaw/conf/initial_script.sh

RUN chmod +x /home/shaw/setup.sh /home/shaw/entrypoint.sh && \
    mkdir -p /home/shaw/output && \
    /home/shaw/setup.sh -b openwrt-24.10 -p https://ghfast.top

VOLUME /home/shaw/output

WORKDIR /home/shaw/immortalwrt

ENTRYPOINT ["/home/shaw/entrypoint.sh"]
CMD ["shell"]