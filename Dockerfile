FROM ubuntu:22.04 as environment

ENV VIRTUALENV /venv
ENV RTEMS_MAJOR=6
ENV RTEMS_MINOR=1-rc2
ENV RTEMS_VERSION=${RTEMS_MAJOR}.${RTEMS_MINOR}
ENV RTEMS_ARCH=powerpc
ENV RTEMS_BSP=beatnik
ENV RTEMS_BASE=/rtems${RTEMS_VERSION}-${RTEMS_BSP}-legacy
ENV RTEMS_PREFIX=${RTEMS_BASE}/rtems/${RTEMS_VERSION}
ENV PATH=${RTEMS_PREFIX}/bin:${PATH}
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
RUN ../source-builder/sb-set-builder --prefix=${RTEMS_PREFIX} ${RTEMS_MAJOR}/rtems-${RTEMS_ARCH} && \
    strip $(find ${RTEMS_PREFIX}) 2> /dev/null || true


# get the kernel
WORKDIR ${RTEMS_BASE}
RUN curl https://ftp.rtems.org/pub/rtems/releases/${RTEMS_MAJOR}/rc/${RTEMS_VERSION}/sources/rtems-${RTEMS_VERSION}.tar.xz \
    | tar -xJ && \
    mv rtems-${RTEMS_VERSION} kernel

# restore indexes on stripped libraries
RUN ranlib $(find ${RTEMS_PREFIX} -name '*.a')

# # patch the kernel
WORKDIR ${RTEMS_BASE}/kernel
COPY VMEConfig.patch .
RUN git apply VMEConfig.patch && \
    ./waf bspdefaults --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} > config.ini && \
    sed -i -e "s|RTEMS_POSIX_API = False|RTEMS_POSIX_API = True|" config.ini && \
    ./waf configure --prefix=${RTEMS_PREFIX}

# build the Board Support Package with patched kernel
RUN ./waf && \
    ./waf install

RUN git clone git://git.rtems.org/rtems-net-legacy.git ${RTEMS_BASE}/rtems-net-legacy

# add in the legacy network stack
WORKDIR ${RTEMS_BASE}/rtems-net-legacy
RUN git submodule init && \
    git submodule update && \
    ./waf configure --prefix=${RTEMS_PREFIX} --rtems-bsps=${RTEMS_ARCH}/${RTEMS_BSP} && \
    ./waf && \
    ./waf install

from environment AS runtime_prep

# To make this container much smaller we take just the BSP and remove any
# unecessary files.
#
# At present epics-base will not build in github with the developer version
# because of the 7GB limit on the size GHA filesystem. Therefore this 'runtime'
# container is used there.
#
# Note: stripping the rtems libraries causes final executable link failure.

COPY --from=developer ${RTEMS_PREFIX} ${RTEMS_PREFIX}

# remove the gcc compiler variants and libs that we do not need
RUN for i in m403 m505 m603e m604 m8540 m860 me6500 nof m7400/nof ; do \
    rm -r ${RTEMS_PREFIX}/lib/gcc/powerpc-rtems6/*/${i} ; \
    rm -r ${RTEMS_PREFIX}/powerpc-rtems6/lib/${i} ; \
    done

from environment AS runtime

COPY --from=runtime_prep ${RTEMS_PREFIX} ${RTEMS_PREFIX}

