#!/bin/sh -eux
git init packages
(
	cd packages
	git remote add origin https://git.adelielinux.org/adelie/packages.git
	git fetch origin "${PACKAGES_COMMIT:-current}" --depth 1
	git checkout FETCH_HEAD
)

mkdir -p patches
curl -f \
	-o patches/linux-bc133e43cb565db50af64b4062889c99fa8541aa.patch 'https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=bc133e43cb565db50af64b4062889c99fa8541aa' \
	-o patches/linux-b480d2b5dcc909a212ce614c187c6b463c043624.patch 'https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=b480d2b5dcc909a212ce614c187c6b463c043624' \
	-o patches/linux-e5fe2d01dd97dae89656d227648b97301b2ad835.patch 'https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=e5fe2d01dd97dae89656d227648b97301b2ad835'
sha256sum -c <<EOF
b957302d82ab05e6d4c135744b06a8e671877c3ee716eaed3ba5993d751becce  patches/linux-bc133e43cb565db50af64b4062889c99fa8541aa.patch
f7a77a8d94675934eff4a44a948e2d9450ca8f9d400fd02390c7dc58abef8ca8  patches/linux-b480d2b5dcc909a212ce614c187c6b463c043624.patch
758853dd061b1da26738a3237045d96c3a52193ed135a652c3e7c49731dccbb3  patches/linux-e5fe2d01dd97dae89656d227648b97301b2ad835.patch
EOF

docker run --rm -i --platform linux/386 -v ./packages:/root/packages "adelielinux/adelie:${ADELIE_TAG:-latest}" <<EOF
set -eux
apk add build-tools
cd /root/packages/system/easy-kernel
newgrp abuild <<'NEWGRP_EOF'
abuild -Fr builddeps fetch unpack prepare
NEWGRP_EOF
EOF

docker run --rm -i --platform linux/i386 -v ./packages:/root/packages -v ./patches:/root/patches "debian:${DEBIAN_TAG:-unstable}" <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	bc debhelper rsync kmod cpio bison flex libssl-dev:native \
	lzop
cd /root/packages/system/easy-kernel/src/linux-src
patch -p 1 </root/patches/linux-bc133e43cb565db50af64b4062889c99fa8541aa.patch
patch -p 1 </root/patches/linux-b480d2b5dcc909a212ce614c187c6b463c043624.patch
patch -p 1 </root/patches/linux-e5fe2d01dd97dae89656d227648b97301b2ad835.patch
make -j \$(nproc) bindeb-pkg
EOF
