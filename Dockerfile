FROM ubuntu:22.04 as developer


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

ENV VIRTUALENV /venv
ENV RTEMS_VERSION=6
ENV RTEMS_RELEASE=0
ENV RTEMS_ARCH=powerpc
ENV RTEMS_BSP=beatnik
ENV RTEMS_BASE=/dls_sw/work/targetOS/rtems/rtems${RTEMS_VERSION}-${RTEMS_BSP}-legacy
ENV RTEMS_INSTALL_DIR=rtems
ENV RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_INSTALL_DIR}/${RTEMS_VERSION}
ENV PATH=${RTEMS_ROOT}/bin:${PATH}
ENV LANG=en_GB.UTF-8

# setup a python venv - requried by the RSB to find 'python'
RUN python3 -m venv ${VIRTUALENV}
ENV PATH=${VIRTUALENV}/bin:${PATH}

WORKDIR ${RTEMS_BASE}
# RUN mkdir ${RTEMS_INSTALL_DIR}

# clone the RTEMS Source Builder and the kernel
RUN git clone git://git.rtems.org/rtems-source-builder.git rsb && \
    git clone git://git.rtems.org/rtems.git kernel

# build the cross compilation tool suite
WORKDIR rsb/rtems
RUN ../source-builder/sb-set-builder --jobs=3 --prefix=${RTEMS_ROOT} ${RTEMS_VERSION}/rtems-${RTEMS_ARCH}

# patch the kernel
WORKDIR ${RTEMS_BASE}/kernel
COPY VMEConfig.patch ..
RUN git apply ../VMEConfig.patch && \
    ./waf bspdefaults --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} > config.ini && \
    sed -i \
        -e "s|RTEMS_POSIX_API = False|RTEMS_POSIX_API = True|" \
        -e "s|BUILD_TESTS = False|BUILD_TESTS = True|" \
        config.ini && \
    ./waf configure --prefix=${RTEMS_ROOT}

# build the Board Support Package with patched kernel
RUN ./waf && \
    ./waf install

# get the legacy network stack
RUN git clone git://git.rtems.org/rtems-net-legacy.git ${RTEMS_BASE}/rtems-net-legacy

# add in the legacy network stack
WORKDIR ${RTEMS_BASE}/rtems-net-legacy
RUN git submodule init && \
    git submodule update && \
    ./waf configure --prefix=${RTEMS_ROOT} --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} && \
    ./waf && \
    ./waf install



