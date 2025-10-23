#!/bin/sh -eux
mkdir -p slackware
curl -fL \
	-o slackware/kernel-source.txz "https://mirrors.slackware.com/slackware/$SLACKWARE_LINUX_KERNEL_SOURCE_PATH" \
	-o slackware/config "https://mirrors.slackware.com/slackware/$SLACKWARE_LINUX_CONFIG_PATH" \
	-o slackware/linux-b3bee1e7c3f2b1b77182302c7b2131c804175870.patch 'https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=b3bee1e7c3f2b1b77182302c7b2131c804175870'
sha256sum -c <<EOF
$SLACKWARE_LINUX_KERNEL_SOURCE_SHA256  slackware/kernel-source.txz
$SLACKWARE_LINUX_CONFIG_SHA256  slackware/config
2334c160fce0901263a9bdc44bead8caaeb87a97556643a798c21f94f9e40434  slackware/linux-b3bee1e7c3f2b1b77182302c7b2131c804175870.patch
EOF

docker run --rm -i --platform linux/i386 -v ./slackware:/root/slackware "debian:${DEBIAN_TAG:-unstable}" <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	bc rsync kmod cpio bison flex libssl-dev:native \
	python3 libelf-dev
cd /root/slackware
mkdir kernel-source
(
	cd kernel-source
	tar -xf ../kernel-source.txz
	sh ./install/doinst.sh
)
patch -d kernel-source/usr/src/linux -p 1 <linux-b3bee1e7c3f2b1b77182302c7b2131c804175870.patch
cp config kernel-source/usr/src/linux/.config
(
	cd kernel-source/usr/src/linux
	make olddefconfig
	make -j \$(nproc) bindeb-pkg
)
EOF
