#
# firefox Dockerfile
#
# https://github.com/jlesage/docker-firefox
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.15-v3

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG JSONLZ4_VERSION=c4305b8
ARG LZ4_VERSION=1.8.1.2
#ARG PROFILE_CLEANER_VERSION=2.36

# Define software download URLs.
ARG JSONLZ4_URL=https://github.com/avih/dejsonlz4/archive/${JSONLZ4_VERSION}.tar.gz
ARG LZ4_URL=https://github.com/lz4/lz4/archive/v${LZ4_VERSION}.tar.gz
#ARG PROFILE_CLEANER_URL=https://github.com/graysky2/profile-cleaner/raw/v${PROFILE_CLEANER_VERSION}/common/profile-cleaner.in

# Define working directory.
WORKDIR /tmp

# Install JSONLZ4 tools.
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        build-base \
        && \
    mkdir jsonlz4 && \
    mkdir lz4 && \
    curl -# -L {$JSONLZ4_URL} | tar xz --strip 1 -C jsonlz4 && \
    curl -# -L {$LZ4_URL} | tar xz --strip 1 -C lz4 && \
    mv jsonlz4/src/ref_compress/*.c jsonlz4/src/ && \
    cp lz4/lib/lz4.* jsonlz4/src/ && \
    cd jsonlz4 && \
    gcc -static -Wall -o dejsonlz4 src/dejsonlz4.c src/lz4.c && \
    gcc -static -Wall -o jsonlz4 src/jsonlz4.c src/lz4.c && \
    strip dejsonlz4 jsonlz4 && \
    cp -v dejsonlz4 /usr/bin/ && \
    cp -v jsonlz4 /usr/bin/ && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install Firefox.
RUN \
    add-pkg --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
            --upgrade chromium

# Install extra packages.
RUN \
    add-pkg \
        desktop-file-utils \
        adwaita-icon-theme \
        ttf-dejavu \
        ffmpeg-libs \
        # The following package is used to send key presses to the X process.
        xdotool

RUN wget --no-check-certificate https://github.com/samuelngs/apple-emoji-linux/releases/download/v16.4/AppleColorEmoji.ttf -O /usr/share/fonts/AppleColorEmoji.ttf
RUN wget https://github.com/anthonyfok/fonts-wqy-microhei/raw/master/wqy-microhei.ttc -O /usr/share/fonts/wqy-microhei.ttc
RUN wget https://github.com/ITboy/font/raw/master/wqy-zenhei/debian/usr/share/fonts/wenquanyi/wqy-zenhei/wqy-zenhei.ttc -O /usr/share/fonts/wqy-zenhei.ttc
RUN fc-cache -f -v

# Adjust the openbox config.
RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Chromium">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Chromium">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://upload.wikimedia.org/wikipedia/commons/f/f3/Chromium_Material_Icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Chromium"

# Define mountable directories.
VOLUME ["/config"]

# Metadata.
LABEL \
      org.label-schema.name="chromium" \
      org.label-schema.description="Docker container for Chromium" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/overclockedllama/docker-chromium" \
      org.label-schema.schema-version="1.0"
