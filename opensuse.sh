#!/bin/sh -eux
docker run --rm -i --platform linux/386 -v ./packages:/usr/src/packages opensuse/tumbleweed <<EOF
zypper -n install rpm-build
zypper addrepo http://download.opensuse.org/source/tumbleweed/repo/oss/ main-source
zypper -n source-install kernel-source kernel-default
rpmbuild -bf --target i586 /usr/src/packages/SPECS/kernel-default.spec
EOF

docker run --rm -i --platform linux/386 -v ./packages:/usr/src/packages debian:${DEBIAN_TAG:-unstable} <<EOF
set -eux
apt-get update
apt-get install -y build-essential \
	debhelper bc bison cpio flex kmod libdw-dev:native libelf-dev:native libssl-dev:native libssl-dev python3:native rsync \
	gawk
cd /usr/src/packages/BUILD/kernel-default-*-build/kernel-default-*/linux-*/linux-obj
patch -p 0 -d .. <<'PATCH_EOF'
--- Makefile.orig
+++ Makefile
@@ -1203,3 +1203,3 @@
 define filechk_suse_version
-	\$(CONFIG_SHELL) \$(srctree)/scripts/gen-suse_version_h.sh
+	/bin/bash \$(srctree)/scripts/gen-suse_version_h.sh
 endef
PATCH_EOF
make -j \$(nproc) bindeb-pkg
EOF
