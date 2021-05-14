FROM alpine:3.13
MAINTAINER Joseph Lee <joseph@zeronsoftn.com>

RUN sed -i -e 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add \
    ca-certificates bash curl wget git python3 \
    sudo shadow \
    tar xz bzip2 gzip \
    abuild automake autoconf libtool pkgconf asciidoc make cmake gcc g++ lzo-dev zstd-dev libarchive-dev \
    ccache file

RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/wheel && \
    echo 'Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy"' | tee /etc/sudoers.d/proxy && \
    useradd -m -s /bin/bash -G wheel,abuild user

ARG ICECC_URL=https://github.com/icecc/icecream/releases/download/1.3.1/icecc-1.3.1.tar.xz
ARG ICECC_SHA256=3929394254ff064b448f5c86a0b41009d9b70d11ee32a13569b9a9c6dfbe6495
RUN wget -O /tmp/icecc.tar.xz "${ICECC_URL}" && \
    echo "${ICECC_SHA256}  /tmp/icecc.tar.xz" | sha256sum -c

RUN mkdir -p /tmp/icecc && \
    cd /tmp/icecc && \
    tar --strip-components 1 -xf /tmp/icecc.tar.xz && \
    [ -f ./autogen.sh ] && ./autogen.sh || true && \
    ./configure --prefix=/usr --without-libcap_ng && \
    make -j4 && \
    make install

RUN apk add \
	alsa-lib-dev \
        bison flex \
        bsd-compat-headers \
        bzip2-dev \
        clang-dev \
        dbus-glib-dev \
        elfutils-dev \
        eudev-dev \
        ffmpeg-dev \
        findutils \
        freetype-dev \
        gnutls-dev \
        gperf \
        gzip \
        harfbuzz-dev \
        hunspell-dev \
        hwids-usb \
        jpeg-dev \
        jsoncpp-dev \
        krb5-dev \
        lcms2-dev \
        libbsd-dev \
        libcap-dev \
        libevent-dev \
        libexif-dev \
        libgcrypt-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libusb-dev \
        libva-dev \
        libwebp-dev \
        libxcomposite-dev \
        libxcursor-dev \
        libxinerama-dev \
        libxml2-dev \
        libxrandr-dev \
        libxscrnsaver-dev \
        libxslt-dev \
        linux-headers \
        lld \
        minizip-dev \
        nodejs \
        nss-dev \
        opus-dev \
        pciutils-dev \
        perl \
        python2 \
        re2-dev \
        snappy-dev \
        speex-dev \
        sqlite-dev \
        zlib-dev \
        py2-setuptools \
        libdrm-dev \
        libxkbcommon-dev atk-dev at-spi2-atk-dev pango-dev mesa-dev gtk+3.0-dev flac-dev \
        openjdk11-jre-headless

USER user
RUN mkdir -p $HOME/work && \
    touch $HOME/work/envs

RUN cd $HOME/work && \
    git clone https://github.com/ninja-build/ninja.git -b v1.8.2 && \
    cd ninja && \
    ./configure.py --bootstrap && \
    echo "export PATH=$PWD:\$PATH" | tee -a $HOME/work/envs

#ARG MINIGBM_GIT_URL=https://chromium.googlesource.com/chromiumos/platform/minigbm
#ARG MINIGBM_GIT_TAG=8ed9b31127ce03dbc8b5c8b78b03809af3ca8995
#RUN git clone ${MINIGBM_GIT_URL} $HOME/work/minigbm && \
#    cd $HOME/work/minigbm && \
#    git checkout -f ${MINIGBM_GIT_TAG} && \

RUN mkdir -p $HOME/work/icecc-files && \
    cd $HOME/work/icecc-files && \
    CLANG_BIN=$(which clang) && \
    icecc-create-env --clang $CLANG_BIN /usr/libexec/icecc/compilerwrapper | tee /tmp/clang-icecc-create-env.out && \
    GENERATED_FILE_NAME=$(cat /tmp/clang-icecc-create-env.out | grep creating | cut -d' ' -f2) && \
    echo "export ICECC_VERSION=$HOME/work/icecc-files/${GENERATED_FILE_NAME}" | tee -a $HOME/work/envs

COPY [ "apkbuild-chromium", "/home/user/work/apkbuild-chromium" ]
RUN sudo chown user:user -R /home/user/work/apkbuild-chromium

ARG _chromium_src_mirror=

WORKDIR /home/user/work/apkbuild-chromium
RUN abuild -d sanitycheck builddeps clean fetch unpack prepare
#RUN abuild -d prepare_clang

# ENV USE_SCHEDULER=
ENV CCACHE_PREFIX=icecc
ENV ICECC_CLANG_REMOTE_CPP=1
ENV SCRIPT_FILE_BEFORE_BUILD=
ENV SCRIPT_FILE_AFTER_BUILD=
ENV USE_EPHEMERAL_PACKAGER_PRIVKEY=n
ENV PACKAGER_PRIVKEY=
ENV RUN_BASH_AFTER_BUILD=n
ENV OUTPUT_COPY_DIRECTORY=

VOLUME /home/user/.ccache

ENV USE_BUILD_TMPFS=y
COPY [ "entrypoint.sh", "build.sh", "/home/user/" ]
RUN sudo chmod +x $HOME/*.sh
ENTRYPOINT [ "/home/user/entrypoint.sh" ]

