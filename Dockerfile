# Dockerfile

FROM debian:bookworm-slim

# Gerekiyorsa temel paketleri yükleyelim (örnek: systemd)
RUN apt-get update && apt-get install -y systemd && apt-get clean

# systemd init ile başlat
CMD ["/sbin/init"]
