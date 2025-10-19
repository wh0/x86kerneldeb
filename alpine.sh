#!/bin/sh -eux
git init aports
(
	cd aports
	git remote add origin https://gitlab.alpinelinux.org/alpine/aports.git
	git fetch origin "${PORTS_COMMIT:-master}" --depth 1
	git checkout FETCH_HEAD
)

docker run --rm -i --platform linux/386 -v ./aports:/root/aports "alpine:${ALPINE_TAG:-edge}" <<EOF
set -eux
apk add alpine-sdk
cd /root/aports/main/linux-lts
abuild -Fr builddeps fetch unpack prepare prepareconfigs
EOF

docker run --rm -i --platform linux/i386 -v ./aports:/root/aports "debian:${DEBIAN_TAG:-unstable}" <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	debhelper bc bison cpio flex kmod libelf-dev:native libssl-dev:native libssl-dev rsync
cd /root/aports/main/linux-lts/src/build-lts.x86
../linux-*/scripts/config \
	-d CONFIG_MODULE_COMPRESS_GZIP \
	-e CONFIG_MODULE_COMPRESS_XZ
make -j \$(nproc) bindeb-pkg
EOF
