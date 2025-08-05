# Resmi Jupyter taban imajından başla
FROM dorowu/ubuntu-desktop-lxde-vnc

# Root olarak sistem bağımlılıklarını yükle
USER root

# 2. Node.js için gerekli depoları ekle
RUN curl -fsSL https://deb.nodesource.com/setup_21.x | bash -


# Playwright ortam değişkenleri
ENV PLAYWRIGHT_BROWSERS_PATH=/home/jovyan/.cache/ms-playwright
