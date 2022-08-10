#
# Created Date: Monday, February 15th 2021, 10:14:40 pm
# Author: MiGoller
# 
# Copyright (c) 2021 MiGoller
#

# Set the base Nextcloud image's tag
ARG NEXTCLOUDTAG="24-fpm"

# Set the base image to use for subsequent instructions.
FROM nextcloud:${NEXTCLOUDTAG}

# Set S6-Overlay version
ARG ARG_S6_OVERLAY_VERSION="2.2.0.3"

# Basic build-time metadata as defined at http://label-schema.org
LABEL \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="MiGoller" \
    org.label-schema.vendor="MiGoller" \
    org.label-schema.version="${NEXTCLOUDTAG}" \
    org.label-schema.description="Nextcloud image with S6-overlay, cron service and more." \
    org.label-schema.url="https://github.com/MiGoller/nextcloud-docker" \
    org.label-schema.vcs-type="Git" \
    # org.label-schema.vcs-ref="${ARG_APP_COMMIT}" \
    org.label-schema.vcs-url="https://github.com/MiGoller/nextcloud-docker.git" \
    maintainer="MiGoller" \
    Author="MiGoller" \
    # org.opencontainers.image.created= \
    org.opencontainers.image.documentation="https://github.com/MiGoller/nextcloud-docker" \
    org.opencontainers.image.licenses="MIT-License" \
    # org.opencontainers.image.revision= \
    org.opencontainers.image.source="https://github.com/MiGoller/nextcloud-docker" \
    org.opencontainers.image.title="Nextcloud" \
    # org.opencontainers.image.url= \
    # org.opencontainers.image.version=7.10.1 \
    org.opencontainers.image.vendor="MiGoller"

ENV NEXTCLOUD_UPDATE=1

# Install additional stuff
RUN \
    # Install cron-daemon
    apt-get update -y \
    && apt-get install -y --no-install-recommends cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Determine S6 arch to download and to install S6-overlay
    && S6_ARCH="" \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) S6_ARCH='amd64';; \
        ppc64el) S6_ARCH='ppc64le';; \
        arm64) S6_ARCH='armhf';; \
        arm) S6_ARCH='arm';; \
        armel) S6_ARCH='arm';; \
        armhf) S6_ARCH='armhf';; \
        i386) S6_ARCH='x86';; \
        *) echo "Unsupported architecture for S6: ${dpkgArch}"; exit 1 ;; \ 
    esac \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${ARG_S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    && echo "S6 Overlay v${ARG_S6_OVERLAY_VERSION} (${S6_ARCH} for dpkArch ${dpkgArch}) installed on ${BUILDPLATFORM} for ${TARGETPLATFORM}."

# Copy S6-overlay files...
COPY ./s6_overlay/etc /etc/

# Patch entrypoint.sh not to start the Docker CMD! (Remove last line!)
RUN sed -i '$d' /entrypoint.sh

# Set container entrpoint to S6-Overlay!
ENTRYPOINT ["/init"]

CMD [ "php-fpm" ]
