# Resmi Jupyter taban imajından başla
FROM dorowu/ubuntu-desktop-lxde-vnc

# Root olarak sistem bağımlılıklarını yükle
USER root

# 1. Önce temel sistem güncellemelerini yap
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gnupg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js için gerekli depoları ekle
RUN curl -fsSL https://deb.nodesource.com/setup_21.x | bash -

# 3. Tüm bağımlılıkları tek seferde yükle
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Temel grafik kütüphaneleri
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libdrm2 libgbm1 libx11-6 libxcb1 libxcomposite1 \
    libxdamage1 libxext6 libxfixes3 libxrandr2 \
    
    # GStreamer ve multimedya
    gstreamer1.0-libav gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
    
    # Diğer gerekli kütüphaneler
    libpango-1.0-0 libcairo2 libasound2 libatspi2.0-0 \
    libglib2.0-0 libgdk-pixbuf2.0-0 libxtst6 libxrender1 \
    libfontconfig1 libpci3 libxslt1.1 libvpx7 libopus0 \
    libwebpdemux2 libwebpmux3 libharfbuzz-icu0 libatomic1 \
    
    # Araçlar
    git unzip sudo \
    
    # Fontlar
    fonts-liberation fonts-noto fonts-freefont-ttf \
    
    # Node.js
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# 4. Playwright'ı global olarak yükle
RUN npm install -g playwright@latest

# 5. Tarayıcıları ve bağımlılıkları yükle
RUN npx playwright install --with-deps

# 6. Jovyan kullanıcısı için izinleri ayarla
RUN chown -R jovyan:users /home/jovyan && \
    chmod -R 775 /home/jovyan && \
    echo "jovyan ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Jovyan kullanıcısına geç ve çalışma dizinini ayarla
USER jovyan
WORKDIR /home/jovyan
ENV HOME=/home/jovyan

# Playwright ortam değişkenleri
ENV PLAYWRIGHT_BROWSERS_PATH=/home/jovyan/.cache/ms-playwright
