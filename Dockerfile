# Base: Python + minimal Debian
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Istanbul

# Sistem araçları + proot + debootstrap
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash sudo tini locales ca-certificates curl git \
    proot debootstrap xz-utils gnupg \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# JupyterLab + terminal desteği
RUN pip install --no-cache-dir \
    jupyterlab==4.* \
    jupyter_server_terminals==0.*

# Çalışma dizini (root)
WORKDIR /root/work

# -------- Fake OS (proot + debootstrap) --------
ARG DEBIAN_SUITE=bookworm
RUN mkdir -p /fakeos && \
    debootstrap --variant=minbase ${DEBIAN_SUITE} /fakeos http://deb.debian.org/debian && \
    echo "deb http://deb.debian.org/debian ${DEBIAN_SUITE} main" > /fakeos/etc/apt/sources.list && \
    echo "nameserver 1.1.1.1" > /fakeos/etc/resolv.conf

# Fake OS'e tek komutla girme script'i
RUN printf '%s\n' '#!/usr/bin/env bash' \
    'set -e' \
    'exec proot -R /fakeos -b /proc -b /sys -b /dev -b /tmp -w /root /bin/bash --login' \
  > /usr/local/bin/fakeos && chmod +x /usr/local/bin/fakeos

# -------- Jupyter varsayılanları: tokensiz / allows root --------
# Not: Jupyter'i sen başlatacağın için burada yalnızca config bırakıyoruz.
RUN mkdir -p /root/.jupyter && \
    printf '%s\n' \
    "c = get_config()" \
    "c.ServerApp.token = ''" \
    "c.ServerApp.password = ''" \
    "c.ServerApp.open_browser = False" \
    "c.ServerApp.allow_root = True" \
    "c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}" \
    > /root/.jupyter/jupyter_server_config.py

# (İsteğe bağlı) dışarıdan bağlayacağın dizinler için mount noktaları
VOLUME ["/root/work"]

# Jupyter'i nasıl başlatacağın sana ait; bu yüzden ENTRYPOINT/CMD yok.
# Örn: container içinde (başlatma senaryonda) şunu çalıştırırsın:
# jupyter lab --ip=0.0.0.0 --port=8888
