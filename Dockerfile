FROM ubuntu:22.04 as developer

ENV VERSION 6.1-rc2
ENV VIRTUALENV /venv

# build tools for x86 including python and busybox (for unzip and others)
# https://docs.rtems.org/branches/master/user/start/preparation.html#host-computer
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    bison \
    busybox \
    curl \
    build-essential \
    diffutils \
    flex \
    git \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/* && \
    busybox --install

# setup a python venv - requried by the RSB to find 'python'
RUN python3 -m venv ${VIRTUALENV}
ENV PATH=${VIRTUALENV}/bin:${PATH}

WORKDIR /rtems

# get the RTEMS Source Builder (RSB) with - no releases so using latest
RUN git clone git://git.rtems.org/rtems-source-builder.git /rtems/rsb

# build the cross compilation tool suite
WORKDIR /rtems/rsb/rtems
RUN mkdir /rtems/toolchain && \
    ../source-builder/sb-set-builder --prefix=/rtems/toolchain 6/rtems-powerpc
ENV PATH=/toolchain/bin:${PATH}

# build the Board Support Package (BSP) for the Beatnik
RUN ../source-builder/sb-set-builder --prefix /rtems/bsp/ --with-rtems-bsp=powerpc/beatnik 6/rtems-kernel
# add in the legacy networking stack
RUN ../source-builder/sb-set-builder --prefix /rtems/bsp/ --with-rtems-bsp=powerpc/beatnik 6/rtems-net-legacy.bset
