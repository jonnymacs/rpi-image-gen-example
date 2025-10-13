FROM debian:bookworm AS base

RUN apt-get update && apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      ca-certificates \
      sudo \
      gpg \
      gpg-agent \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://archive.raspberrypi.com/debian/raspberrypi.gpg.key \
  | gpg --dearmor > /usr/share/keyrings/raspberrypi-archive-keyring.gpg

ARG RPIIG_GIT_SHA=e5766aa9b2f5a6a09b241c5553833aaa3d4ac4c3
RUN git clone --no-checkout https://github.com/raspberrypi/rpi-image-gen.git && cd rpi-image-gen && git checkout ${RPIIG_GIT_SHA}

ARG TARGETARCH
RUN echo "Building for architecture: ${TARGETARCH}"
# Example: Install different packages based on architecture
RUN /bin/bash -c '\
  case "${TARGETARCH}" in \
    arm64) echo "Building for arm64" && \
      apt-get update && \
      rpi-image-gen/install_deps.sh ;; \
    amd64) echo "Try to Build for amd64. \
      As of Apr 2025 rpi-image-gen install_deps exits if arm arch is not detected. \
      Override binfmt_misc_required flag and install known amd64 deps that are not \
      provided in the depends file" && \

      sed -i "s|\"\${binfmt_misc_required}\" == \"1\"|! -z \"\"|g" rpi-image-gen/scripts/dependencies_check && \

      if cat /proc/filesystems | grep -q binfmt_misc; then \
        echo \"binfmt_misc is supported\" ; \
      else \
        echo \"binfmt_misc is not supported. Install binfmt-support on your host machine\" ; \
        exit 1 ; \
      fi && \

      apt-get update && \
      apt-get install --no-install-recommends -y \
        qemu-user-static \
        dirmngr \
        slirp4netns \
        quilt \
        parted \
        debootstrap \
        zerofree \
        libcap2-bin \
        libarchive-tools \
        xxd \
        file \
        kmod \
        bc \
        pigz \
        arch-test && \
      rpi-image-gen/install_deps.sh ;; \
    *) echo "Architecture $ARCH is not arm64 or amd64. Skipping package installation." ;; \
  esac'

ENV USER imagegen
RUN useradd -u 4000 -ms /bin/bash "$USER" && echo "${USER}:${USER}" | chpasswd && adduser ${USER} sudo # only add to sudo if build scripts require it
USER ${USER}
WORKDIR /home/${USER}

RUN /bin/bash -c 'cp -r /rpi-image-gen ~/'
