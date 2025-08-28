FROM jupyter/base-notebook:python-3.11

USER root
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      proot wget ca-certificates tzdata locales curl nano vim less \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 22.04 minimal rootfs
ARG UBUNTU_BASE_URL=https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-amd64.tar.gz
RUN mkdir -p /opt/ubuntu-rootfs && \
    wget -O /tmp/ubuntu-rootfs.tgz "${UBUNTU_BASE_URL}" && \
    tar -xzf /tmp/ubuntu-rootfs.tgz -C /opt/ubuntu-rootfs && \
    rm -f /tmp/ubuntu-rootfs.tgz

# Rootfs'e giriş scripti (bind YOK, DNS'i kopyala + fallback)
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'ROOTFS="/opt/ubuntu-rootfs"' \
'RS="$ROOTFS/etc/resolv.conf"' \
'# 1) Host resolv.conf içeriğini almaya çalış' \
'CONTENT=""' \
'if [ -r /etc/resolv.conf ]; then' \
'  CONTENT="$(cat /etc/resolv.conf || true)"' \
'fi' \
'# 2) Eğer 127.0.0.53 (systemd stub) içeriyorsa veya boşsa fallback kullan' \
'NEEDS_FALLBACK=0' \
'if [ -z "${CONTENT}" ]; then NEEDS_FALLBACK=1; fi' \
'if printf "%s" "$CONTENT" | grep -qE "127\\.0\\.0\\.53"; then NEEDS_FALLBACK=1; fi' \
'if [ "$NEEDS_FALLBACK" -eq 1 ]; then' \
'  CONTENT="nameserver 1.1.1.1\nnameserver 8.8.8.8\noptions timeout:2 attempts:2"' \
'fi' \
'mkdir -p "$ROOTFS/etc"' \
'printf "%b\n" "$CONTENT" > "$RS"' \
'# hosts yoksa en azından localhost satırlarını koy' \
'HS="$ROOTFS/etc/hosts"' \
'if [ ! -s "$HS" ]; then' \
'  printf "127.0.0.1\tlocalhost\n::1\tlocalhost ip6-localhost ip6-loopback\n" > "$HS"' \
'fi' \
'# 3) proot ile rootfs içine gir' \
'exec proot -0 -r "$ROOTFS" \' \
'  -b /proc -b /sys -b /dev -b /tmp \' \
'  -b "$PWD":"$PWD" -w "$PWD" \' \
'  /bin/bash --login' \
> /usr/local/bin/rootfs && chmod +x /usr/local/bin/rootfs

# Kullanıcı ayarları
RUN chown -R ${NB_UID}:${NB_GID} /opt/ubuntu-rootfs
USER ${NB_UID}
RUN echo '' >> ~/.bashrc && \
    echo '# RootFS (Ubuntu 22.04) için: terminalde "rootfs" yazın. DNS otomatik kopyalanır, gerekirse 1.1.1.1/8.8.8.8 fallback kullanılır.' >> ~/.bashrc
