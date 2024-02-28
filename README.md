# rtems6-powerpc

A container that makes the RTEMS powerpc beatnik Board Support Package (BSP).

This container gets the sources from RTEMS releases, builds the toolchain and then compiles the BSP.

The current configuration is:-
- rtems version: 6.1-rc2
- patches for MVME5500 boards used at DLS
- legacy network stack

This container can be run to experiment with building components with the RSP and prebuilt rtems6 toolchain.

See https://docs.rtems.org/branches/master/user/start/index.html

To just get the Board Support Package (BSP) with toolchain, you can extract these products into your own container with:

```
ENV RTEMS_VERSION=6.1-rc2
ENV RTEMS_TOP=/rtems${RTEMS_VERSION}-beatnik-legacy/rtems/${RTEMS_VERSION}/
ENV RTEMS_BSP_IMAGE=ghcr.io/epics-containers/rtems6-powerpc-linux-developer

COPY --from=${RTEMS_BSP_IMAGE}:${RTEMS_VERSION} ${RTEMS_TOP} ${RTEMS_TOP}
```

Or you can get the BSP locally with:
```
docker run --rm -v $(pwd):/workdir ghcr.io/epics-containers/rtems6-powerpc-linux-developer:6.1-rc2
# in another terminal
mkdir -p /rtems6-beatnik-legacy/rtems/
docker cp $(docker ps -lq):/rtems6-beatnik-legacy/rtems/6.1-rc2/ /rtems6-beatnik-legacy/rtems/6.1-rc2/
```

IMPORTANT: the BSP contains absolute paths so you must copy it to the same path as inside the container.
