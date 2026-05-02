#!/bin/sh -eux
mkdir -p tinycore
curl -f \
	-o tinycore/source.tar.xz "http://tinycorelinux.net/$TINYCORE_SRC_KERNEL_LINUX_PATCHED_PATH" \
	-o tinycore/config "http://tinycorelinux.net/$TINYCORE_SRC_KERNEL_CONFIG_PATH"
sha256sum -c <<EOF
$TINYCORE_SRC_KERNEL_LINUX_PATCHED_SHA256  tinycore/source.tar.xz
$TINYCORE_SRC_KERNEL_CONFIG_SHA256  tinycore/config
EOF

docker run --rm -i --platform linux/386 -v ./tinycore:/root/tinycore "debian:${DEBIAN_TAG:-unstable}" <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	debhelper bc bison flex gcc-i686-linux-gnu kmod libdw-dev:native libelf-dev:native libssl-dev:native libssl-dev python3:native rsync
cd /root/tinycore
tar -xf source.tar.xz
cd linux-*
cp ../config .config
./scripts/config \
	-e CONFIG_DEVTMPFS
make -j \$(nproc) bindeb-pkg
EOF
