FROM fedora:34

# Setup system
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel ;\
    useradd \
     --create-home \
     --home-dir '/home/builder' \
     --groups   'wheel' \
     --shell    '/bin/bash' \
     builder ;\
    touch /home/builder/.sudo_as_admin_successful

# Install package tools
RUN dnf install -y \
     rpmdevtools \
     rpmlint ;\
    dnf clean all

# Install build tools
RUN dnf install -y \
     meson \
     ninja-build \
     gcc \
     vala ;\
    dnf clean all

# Install dependencies
RUN dnf install -y gtk3-devel ;\
    dnf clean all

# Finish image
RUN mkdir /app ; chown builder:builder /app
USER builder
WORKDIR /home/builder
