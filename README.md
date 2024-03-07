RTEMS Board Support Packages
============================

A container that makes the RTEMS Board Support Packages (BSPs).

This container gets the sources from RTEMS releases, builds the toolchain and then compiles the BSP.

The developer target serves as an archive for the source code. The runtime target is a minimal container with the RTEMS BSP only, intended to be used as a base image for epics-base builds (see https://github.com/epics-containers/epics-base)

Supported BSPs
--------------

The repo is designed to allow for multiple target architectures. At present the list of BSPs is only 1 long:

- mvme5500
  - rtems version: 6.1-rc2
  - patches for MVME5500 boards used at DLS
  - legacy network stack
  - processor is m4700 with hardware floating point support


Acknowledgements
================

This is all possible due to the hard work of the RTEMS community.

See https://docs.rtems.org/branches/master/user/start/index.html
