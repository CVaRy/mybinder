# Binder ile uyumlu, Jupyter ve Terminal hazır
FROM jupyter/base-notebook:python-3.11

# Root’a geç (build sırasında)
USER root

# Faydalı araçlar + proot
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      proot wget ca-certificates tzdata locales less vim nano curl \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 22.04 (Jammy) minimal rootfs indir ve aç
ARG UBUNTU_BASE_URL=https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-amd64.tar.gz
RUN mkdir -p /opt/ubuntu-rootfs && \
    wget -O /tmp/ubuntu-rootfs.tgz "${UBUNTU_BASE_URL}" && \
    tar -xzf /tmp/ubuntu-rootfs.tgz -C /opt/ubuntu-rootfs && \
    rm -f /tmp/ubuntu-rootfs.tgz

# Rootfs için küçük ağ/locale dokunuşları
# (DNS yoksa çöksün istemeyiz; ilk girişte proot scripti de kontrol ediyor)
RUN echo "nameserver 1.1.1.1" > /opt/ubuntu-rootfs/etc/resolv.conf || true && \
    chown -R ${NB_UID}:${NB_GID} /opt/ubuntu-rootfs

# Rootfs'e giriş kısayolu
# - Çalıştığınız klasörü rootfs içine bağlar
# - /proc, /sys, /dev, /tmp’yi bağlar
# - rootfs içinde /bin/bash --login açar (root yetkili gibi)
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -e' \
'ROOTFS="/opt/ubuntu-rootfs"' \
'if [ ! -s "$ROOTFS/etc/resolv.conf" ]; then' \
'  mkdir -p "$ROOTFS/etc"; echo "nameserver 1.1.1.1" > "$ROOTFS/etc/resolv.conf"' \
'fi' \
'exec proot -0 -r "$ROOTFS" \' \
'  -b /proc -b /sys -b /dev -b /tmp \' \
'  -b "$PWD":"$PWD" -w "$PWD" \' \
'  /bin/bash --login' \
> /usr/local/bin/rootfs && \
chmod +x /usr/local/bin/rootfs

# Jupyter kullanıcısına dön
USER ${NB_UID}

# Terminal açıldığında ipucu ver
RUN echo '' >> ~/.bashrc && \
    echo '# === RootFS (Ubuntu 22.04) ===' >> ~/.bashrc && \
    echo 'echo "RootFS (Ubuntu 22.04) için: rootfs komutunu çalıştırın (proot ile root)."' >> ~/.bashrc

# Binder, repo2docker ile otomatik olarak Jupyter’i başlatır.
# Ekstra bir CMD/ENTRYPOINT gerekmez.
