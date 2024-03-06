FROM ubuntu:22.04 as environment

ENV VIRTUALENV /venv
ENV RTEMS_MAJOR=6
ENV RTEMS_MINOR=1-rc2
ENV RTEMS_VERSION=${RTEMS_MAJOR}.${RTEMS_MINOR}
ENV RTEMS_ARCH=powerpc
ENV RTEMS_BSP=beatnik
ENV RTEMS_BASE=/rtems6-${RTEMS_BSP}-legacy
ENV RTEMS_PREFIX=${RTEMS_BASE}/rtems/${RTEMS_VERSION}
ENV PATH=${RTEMS_PREFIX}/bin:${PATH}

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

# add in a gcc patch to only build for m7400
COPY local_patch local_patch
RUN local_patch/patch-rsb.sh

# build the cross compilation tool suite and strip symbols to minimize size
WORKDIR rsb/rtems
RUN ../source-builder/sb-set-builder --prefix=${RTEMS_PREFIX} ${RTEMS_MAJOR}/rtems-${RTEMS_ARCH} && \
    strip $(find ${RTEMS_PREFIX}) 2> /dev/null || true && \
    ranlib $(find ${RTEMS_PREFIX} -name '*.a')

# get the kernel
WORKDIR ${RTEMS_BASE}
RUN curl https://ftp.rtems.org/pub/rtems/releases/${RTEMS_MAJOR}/rc/${RTEMS_VERSION}/sources/rtems-${RTEMS_VERSION}.tar.xz \
    | tar -xJ && \
    mv rtems-${RTEMS_VERSION} kernel

# patch the kernel
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

# To make this container target smaller we take just the BSP
COPY --from=developer ${RTEMS_PREFIX} ${RTEMS_PREFIX}

# remove files that are not required
RUN rm -r \
    ${RTEMS_PREFIX}/share/doc \
    ${RTEMS_PREFIX}/share/man \
    ${RTEMS_PREFIX}/share/info \
    ${RTEMS_PREFIX}/powerpc-rtems6/lib/ldscripts

from runtime_prep AS runtime

COPY --from=runtime_prep ${RTEMS_PREFIX} ${RTEMS_PREFIX}

