#!/bin/bash

THIS=$(realpath $(dirname $0))
RSB=${RTEMS_BASE}/rsb

set -xe

mkdir -p $RSB/rtems/patches
cp $THIS/gcc.patch $RSB/rtems/patches

# patch the gcc config file to use the above patch
echo '
--- a/rsb/rtems/config/tools/rtems-gcc-13.2-newlib-head.cfg
+++ b/rsb/rtems/config/tools/rtems-gcc-13.2-newlib-head.cfg
@@ -13,12 +13,8 @@
 %hash sha512 newlib-%{newlib_version}.tar.gz \
   ia0ce+bdENUO3qYj00jrZB8FjSejmTWuRqEdNE8nI2llf30mh8leUn5fCoHB0Oa7rRVBjEu3n0F12ZK9skuegQ==

-%patch add gcc file:///local_patch/gcc.patch
-%hash sha256 gcc.patch f3fd225acc18ddd16543e02d014a2cc1541216c9d9e9dd0143aa5cf74c09b54b
-
 %define with_threads 1
 %define with_plugin 0
 %define with_iconv 1

 %include %{_configdir}/gcc-13.cfg
-
' | git apply
