# Dockerfile — Debian tabanlı, systemd + Python3 hazır
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus \
      python3 python3-venv python3-pip ca-certificates tzdata \
      iproute2 iputils-ping curl nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Locale/TZ opsiyonel (gerekirse aç)
# ENV TZ=UTC
# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Varsayılan: systemd ile başlat (rootfs benzeri deneyim)
CMD ["/sbin/init"]
