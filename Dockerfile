FROM ubuntu:22.04 as environment

ENV VIRTUALENV /venv
ENV RTEMS_MAJOR=6
ENV RTEMS_MINOR=1-rc2
ENV RTEMS_VERSION=${RTEMS_MAJOR}.${RTEMS_MINOR}
ENV RTEMS_ARCH=powerpc
ENV RTEMS_BSP=beatnik
ENV RTEMS_BASE=/rtems${RTEMS_VERSION}-${RTEMS_BSP}-legacy
ENV RTEMS_ROOT=${RTEMS_BASE}/rtems/${RTEMS_VERSION}
ENV PATH=${RTEMS_ROOT}/bin:${PATH}
ENV LANG=en_GB.UTF-8

FROM environment AS developer

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


# get the RTEMS Source Builder
WORKDIR ${RTEMS_BASE}
RUN curl https://ftp.rtems.org/pub/rtems/releases/${RTEMS_MAJOR}/rc/${RTEMS_VERSION}/sources/rtems-source-builder-${RTEMS_VERSION}.tar.xz \
    | tar -xJ && \
    mv rtems-source-builder-${RTEMS_VERSION} rsb

# build the cross compilation tool suite
WORKDIR rsb/rtems
RUN ../source-builder/sb-set-builder --jobs=6 --prefix=${RTEMS_ROOT} ${RTEMS_MAJOR}/rtems-${RTEMS_ARCH}

# get the kernel
WORKDIR ${RTEMS_BASE}
RUN curl https://ftp.rtems.org/pub/rtems/releases/${RTEMS_MAJOR}/rc/${RTEMS_VERSION}/sources/rtems-${RTEMS_VERSION}.tar.xz \
    | tar -xJ && \
    mv rtems-${RTEMS_VERSION} kernel

# # patch the kernel
WORKDIR ${RTEMS_BASE}/kernel
COPY VMEConfig.patch .
RUN git apply VMEConfig.patch && \
    ./waf bspdefaults --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} > config.ini && \
    sed -i \
        -e "s|RTEMS_POSIX_API = False|RTEMS_POSIX_API = True|" \
        -e "s|BUILD_TESTS = False|BUILD_TESTS = True|" \
        config.ini && \
    ./waf configure --prefix=${RTEMS_ROOT}

# build the Board Support Package with patched kernel
RUN ./waf && \
    ./waf install

RUN git clone git://git.rtems.org/rtems-net-legacy.git ${RTEMS_BASE}/rtems-net-legacy

# add in the legacy network stack
WORKDIR ${RTEMS_BASE}/rtems-net-legacy
RUN git submodule init && \
    git submodule update && \
    ./waf configure --prefix=${RTEMS_ROOT} --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} && \
    ./waf && \
    ./waf install

from environment AS runtime-prep

# to make this container much smaller we take just the BSP and strip it
# At present epics-base will not build in github with the developer version
# because of the 7GB limit on the size GHA filesystem. Therefore this 'runtime'
# container is used there.

COPY from=developer ${RTEMS_ROOT} ${RTEMS_ROOT}

RUN powerpc-rtems6-strip $(find ${RTEMS_ROOT}) 2>/dev/null
RUN strip $(find ${RTEMS_ROOT}) 2>/dev/null

from environment AS runtime

COPY from=developer ${RTEMS_ROOT} ${RTEMS_ROOT}

