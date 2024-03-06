A container that makes the RTEMS powerpc beatnik Board Support Package (BSP).

This container gets the sources from RTEMS releases, builds the toolchain and then compiles the BSP.

The developer target serves as an archive for the source code. The runtime target is a minmal container with the RTEMS powerpc-beatnik BSP only, intended to be used as a base for epics-base builds.

The current configuration is:-
- rtems version: 6.1-rc2
- patches for MVME5500 boards used at DLS
- legacy network stack

This container can be run to experiment with building components with the RSP and prebuilt rtems6 toolchain.

See https://docs.rtems.org/branches/master/user/start/index.html
