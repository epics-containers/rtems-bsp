#!/bin/bash

THIS=$(realpath $(dirname $0))
RSB=${RTEMS_BASE}/rsb

set -xe

mkdir -p $RSB/rtems/patches
cp $THIS/gcc.patch $RSB/rtems/patches

cp $THIS/rtems-gcc-13.2-newlib-head.cfg /rtems6-beatnik-legacy/rsb/rtems/config/tools/rtems-gcc-13.2-newlib-head.cfg
