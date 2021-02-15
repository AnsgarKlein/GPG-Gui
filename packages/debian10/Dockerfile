FROM debian:10

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
     python3 python3-pip python3-wheel python3-setuptools \
     ninja-build \
     gcc \
     valac ;\
    rm -rf /var/lib/apt/lists/* ;\
    python3 -m pip install --no-input --no-cache-dir --upgrade pip ;\
    python3 -m pip install --no-input --no-cache-dir meson==0.50

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
