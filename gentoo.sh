#!/bin/sh -eux
docker run --rm -i --platform linux/386 -v ./portage:/var/tmp/portage gentoo/stage3:${GENTOO_TAG:-latest} <<EOF
set -eux
emerge-webrsync -q
ebuild /var/db/repos/gentoo/sys-kernel/gentoo-kernel/gentoo-kernel-$GENTOO_VERSION.ebuild configure
EOF

docker run --rm -i --platform linux/386 -v ./portage:/var/tmp/portage debian:${DEBIAN_TAG:-unstable} <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	debhelper bc bison cpio flex kmod libelf-dev:native libssl-dev:native libssl-dev rsync
cd /var/tmp/portage/sys-kernel/gentoo-kernel-*/work/build
make -j \$(nproc) bindeb-pkg
EOF
