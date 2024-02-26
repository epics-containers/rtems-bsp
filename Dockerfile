FROM ubuntu:22.04 as developer

ENV VERSION 6.1-rc2
ENV VIRTUALENV /venv

# build tools for x86 including python
# https://docs.rtems.org/branches/master/user/start/preparation.html#host-computer
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    bison \
    ca-certificates \
    curl \
    build-essential \
    busybox \
    flex \
    git \
    libreadline-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    ssh-client \
    vim \
    && rm -rf /var/lib/apt/lists/* \
    && busybox --install

# setup a python venv
RUN python3 -m venv ${VIRTUALENV}
ENV PATH=${VIRTUALENV}/bin:${PATH}

# get the sources for RTEMS Source Builder (RSB) and Kernel
WORKDIR  /rtems/src
RUN curl https://ftp.rtems.org/pub/rtems/releases/6/rc/${VERSION}/sources/rtems-source-builder-${VERSION}.tar.xz \
    | tar xJf - && \
    mv rtems-source-builder* rsb
    # && \
    # curl https://ftp.rtems.org/pub/rtems/releases/6/rc/${VERSION}/sources/rtems-${VERSION}.tar.xz \
    # | tar xJf -

WORKDIR  /rtems/src/rsb/rtems
# build the tool suite
RUN ../source-builder/sb-set-builder --prefix=/rtems/prefix 6/rtems-powerpc

# build the BSP
RUN ../source-builder/sb-set-builder --prefix /rtems/prefix/ --target=powerpc-rtems6 \
    --with-rtems-bsp=powerpc/beatnik 6/rtems-kernel
