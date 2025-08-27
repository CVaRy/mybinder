# Base image: Kali Linux
FROM kalilinux/kali-rolling

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ARCH=arm64
ENV ROOTFS_DIR=/rootfs
ENV OUTPUT_DIR=/output

# Install dependencies and utilities
RUN echo "Installing dependencies..." && \
    apt update && apt install -y \
    debootstrap \
    qemu-user-static \
    device-tree-compiler \
    lzma \
    lzop \
    u-boot-tools \
    pixz \
    git-core \
    binutils \
    ca-certificates \
    locales \
    console-common \
    vim \
    less \
    passwd \
    sudo && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Set up the ARM64 build environment
RUN echo "Setting up Kali Linux rootfs..." && \
    mkdir -p $ROOTFS_DIR && \
    debootstrap --foreign --arch $ARCH kali-rolling $ROOTFS_DIR/kali-$ARCH http://http.kali.org/kali && \
    cp /usr/bin/qemu-aarch64-static $ROOTFS_DIR/kali-$ARCH/usr/bin/ && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH /debootstrap/debootstrap --second-stage && \
    echo "Debootstrap setup complete."

# Add Mecha Comet-specific repository
RUN echo "Adding Mecha Comet repository..." && \
    echo "deb [trusted=yes] http://debian.mecha.build apollo main" >> $ROOTFS_DIR/kali-$ARCH/etc/apt/sources.list

# Install Mecha Comet-specific kernel and firmware
RUN echo "Installing Mecha Comet kernel and firmware..." && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt update && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt install -y \
    linux-image-6.6.36+mecha+ \
    linux-headers-6.6.36+mecha+ \
    linux-libc-dev=6.6.36-g2cf9194da72b-1 \
    imx-sdma-firmware \
    bluez-firmware=1.0-1 && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt clean && \
    rm -rf $ROOTFS_DIR/kali-$ARCH/var/lib/apt/lists/*

# Install Kali Linux tools
RUN echo "Installing Kali Linux tools inside rootfs..." && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt update && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt install --no-install-recommends -y kali-linux-core && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH apt clean && \
    rm -rf $ROOTFS_DIR/kali-$ARCH/var/lib/apt/lists/*

# Copy third-stage script
COPY third-stage $ROOTFS_DIR/kali-$ARCH/third-stage

# Run third-stage setup
RUN chmod +x $ROOTFS_DIR/kali-$ARCH/third-stage && \
    LANG=C chroot $ROOTFS_DIR/kali-$ARCH /third-stage && \
    rm -f $ROOTFS_DIR/kali-$ARCH/third-stage

# Archive the final root filesystem
RUN echo "Creating final rootfs archive..." && \
    mkdir -p $OUTPUT_DIR && \
    tar -czvf $OUTPUT_DIR/kali-arm64-rootfs.tar.gz -C $ROOTFS_DIR/kali-$ARCH . && \
    echo "RootFS archive created at $OUTPUT_DIR/kali-arm64-rootfs.tar.gz"

# Expose a volume for the root filesystem
VOLUME ["$OUTPUT_DIR"]

# Default command: enter the container
CMD ["/bin/bash"]
