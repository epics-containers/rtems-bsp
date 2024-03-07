#!/bin/bash

THIS=$(realpath $(dirname $0))
RSB=${RTEMS_TOP}/rsb

set -xe

mkdir -p $RSB/rtems/patches
cp $THIS/gcc.patch $RSB/rtems/patches

cp $THIS/rtems-gcc-13.2-newlib-head.cfg $RSB/rtems/config/tools/rtems-gcc-13.2-newlib-head.cfg
