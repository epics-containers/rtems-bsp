#!/bin/bash

THIS=$(realpath $(dirname $0))
RSB=$(realpath ${THIS}/../rsb)
set -xe

cp $THIS/gcc.patch $RSB/rtems/patches
cp $THIS/rtems-gcc-13.2-newlib-head.cfg $RSB/rtems/config/tools
cp $THIS/rtems-default-tools.bset $RSB/rtems/config/tools