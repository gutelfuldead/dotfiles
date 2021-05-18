#!/bin/bash
# Installation for CentOS 7.1
here=$(pwd)

mkdir -pv ~/git && cd ~/git

# pre-reqs for i3-gaps and i3status
sudo yum install -y -q "xcb-util*-devel" \
        "xorg-x11-font*" \
        autoconf \
        automake \
        gcc \
        git \
        libev-devel \
        libX11-devel \
        libxcb-devel \
        libXinerama-devel \
        libxkbcommon-devel \
        libxkbcommon-x11-devel \
        libXrandr-devel \
        libconfuse-devel \
        pulseaudio-libs-devel \
        libnl-devel \
        libnl3-devel \
        alsa-lib-devel
        make \
        pango-devel \
        pcre-devel \
        startup-notification-devel \
        wget \
        xcb-util-cursor-devel \
        xcb-util-devel \
        xcb-util-keysyms-devel \
        xcb-util-wm-devel \
        xcb-util-xrm-devel \
        xorg-x11-util-macros \
        yajl-devel \
        xterm

git clone --recursive https://github.com/Airblader/xcb-util-xrm \
 && cd xcb-util-xrm \
 && git submodule update --init \
 && ./autogen.sh --prefix=/usr --libdir=/usr/lib64 \
 && make \
 && sudo make install
cd ..

# i3-gaps
git clone https://www.github.com/Airblader/i3 i3-gaps
cd i3-gaps
mkdir -p build && cd build
meson ..
ninja
sudo make install
cd ..

git clone https://github.com/i3/i3status.git i3-status
cd i3-status
autoreconf -fi
mkdir build
cd build
../configure --disable-sanitizers
make -j$(nproc)
sudo make install
cd ..

cd $here
