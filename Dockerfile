FROM jupyter/base-notebook:python-3.11

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Gerekli araçlar
RUN apt-get update && apt-get install -y --no-install-recommends \
      proot wget ca-certificates xz-utils tzdata locales curl vim nano less \
    && rm -rf /var/lib/apt/lists/*

# Hangi sürüm? (jammy=22.04, noble=24.04)
ARG UBUNTU_SERIES=jammy
# Canonical core cloud rootfs (daha kapsayıcı)
ARG UBUNTU_ROOTFS_URL=https://partner-images.canonical.com/core/${UBUNTU_SERIES}/current/ubuntu-${UBUNTU_SERIES}-core-cloudimg-amd64-root.tar.xz

# Rootfs'i indir ve aç
RUN mkdir -p /opt/ubuntu-rootfs && \
    wget -O /tmp/ubuntu-rootfs.txz "${UBUNTU_ROOTFS_URL}" && \
    tar -xJf /tmp/ubuntu-rootfs.txz -C /opt/ubuntu-rootfs && \
    rm -f /tmp/ubuntu-rootfs.txz

# --- Build zamanında rootfs içine paketleri kur (listeyi istediğin gibi genişlet) ---
RUN APT_PKGS="build-essential git curl wget iproute2 iputils-ping dnsutils ca-certificates python3 python3-pip vim nano" && \
    proot -0 -r /opt/ubuntu-rootfs -b /proc -b /sys -b /dev -b /tmp \
      /bin/bash -lc "apt-get update && apt-get install -y --no-install-recommends $APT_PKGS && \
                     apt-get clean && rm -rf /var/lib/apt/lists/*"

# Rootfs'e giriş betiği (bind YOK) — DNS'i host'tan kopyala, gerekirse fallback
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'ROOTFS="/opt/ubuntu-rootfs"' \
'RS="$ROOTFS/etc/resolv.conf"' \
'HS="$ROOTFS/etc/hosts"' \
'# 1) Host /etc/resolv.conf içeriğini kopyala' \
'CONTENT=""' \
'if [ -r /etc/resolv.conf ]; then CONTENT="$(cat /etc/resolv.conf || true)"; fi' \
'# 2) 127.0.0.53 veya boş ise fallback kullan' \
'NEEDS_FALLBACK=0' \
'if [ -z "${CONTENT}" ]; then NEEDS_FALLBACK=1; fi' \
'if printf "%s" "$CONTENT" | grep -qE "127\\.0\\.0\\.53"; then NEEDS_FALLBACK=1; fi' \
'if [ "$NEEDS_FALLBACK" -eq 1 ]; then' \
'  CONTENT="nameserver 1.1.1.1\nnameserver 8.8.8.8\noptions timeout:2 attempts:2"' \
'fi' \
'mkdir -p "$ROOTFS/etc"' \
'printf "%b\n" "$CONTENT" > "$RS"' \
'# 3) hosts temel satırlar' \
'if [ ! -s "$HS" ]; then' \
'  printf "127.0.0.1\tlocalhost\n::1\tlocalhost ip6-localhost ip6-loopback\n" > "$HS"' \
'fi' \
'# 4) rootfs içine proot ile gir' \
'exec proot -0 -r "$ROOTFS" \' \
'  -b /proc -b /sys -b /dev -b /tmp \' \
'  -b "$PWD":"$PWD" -w "$PWD" \' \
'  /bin/bash --login' \
> /usr/local/bin/rootfs && chmod +x /usr/local/bin/rootfs

# İzinler ve kullanıcı
RUN chown -R ${NB_UID}:${NB_GID} /opt/ubuntu-rootfs
USER ${NB_UID}
RUN echo '' >> ~/.bashrc && \
    echo '# RootFS (Ubuntu core cloud) için terminalde "rootfs" yaz.' >> ~/.bashrc && \
    echo '# DNS hosttan kopyalanır; gerekirse 1.1.1.1/8.8.8.8 fallback kullanılır.' >> ~/.bashrc
