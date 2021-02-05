FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Setup system
RUN apt-get -yq update ;\
    apt-get -yq --no-install-recommends install sudo ;\
    rm -rf /var/lib/apt/lists/* ;\
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/sudo ;\
    useradd \
     --create-home \
     --home-dir '/home/builder' \
     --groups   'sudo' \
     --shell    '/bin/bash' \
     builder ;\
    touch /home/builder/.sudo_as_admin_successful

# Install package tools
RUN apt-get -yq update ;\
    apt-get -yq --no-install-recommends install \
     dpkg-dev \
     fakeroot \
     lintian ;\
    rm -rf /var/lib/apt/lists/*

# Install build tools
RUN apt-get -yq update ;\
    apt-get -yq --no-install-recommends install \
     meson \
     ninja-build \
     gcc \
     valac ;\
    rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN apt-get -yq update ;\
    apt-get -yq --no-install-recommends install \
     gpg \
     libgtk-3-dev ;\
    rm -rf /var/lib/apt/lists/*

# Finish image
RUN mkdir /app ; chown builder:builder /app
USER builder
WORKDIR /home/builder
