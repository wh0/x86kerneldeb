#!/bin/sh -eux
git init void-packages
(
	cd void-packages
	git remote add origin https://github.com/void-linux/void-packages.git
	git fetch origin "${VOID_PACKAGES_COMMIT:-master}" --depth 1
	git checkout FETCH_HEAD
)

docker run --rm -i --platform linux/i386 -v ./void-packages:/root/void-packages -v ./builddir:/builddir "ghcr.io/void-linux/void-glibc-full:${VOID_TAG:-latest}" <<EOF
set -eux
xbps-install -Sy bash git base-devel
git config --global --add safe.directory /root/void-packages
cd /root/void-packages
ln -s / masterdir
XBPS_CHROOT_CMD=ethereal XBPS_ALLOW_CHROOT_BREAKOUT=yes ./xbps-src configure linux6.12
EOF

docker run --rm -i --platform linux/i386 -v ./builddir:/builddir "debian:${DEBIAN_TAG:-unstable}" <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	debhelper bc bison cpio flex kmod libelf-dev:native libssl-dev:native libssl-dev rsync
cd /builddir/linux*-*
./scripts/config \
	--set-str CONFIG_LOCALVERSION -1
make -j \$(nproc) ARCH=i386 bindeb-pkg
EOF
