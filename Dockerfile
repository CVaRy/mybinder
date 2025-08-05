# Start from the Jupyter base image
FROM andrewosh/binder-base

# Switch to root to install system dependencies
USER root

# Install Playwright system dependencies and other required packages
RUN apt-get update && \
    apt-get install -y \
    # Playwright core dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxcb1 \
    libxkbcommon0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libgtk-3-0 \
    libx11-xcb1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    # Additional dependencies that might be needed
    libglib2.0-0 \
    libgdk-pixbuf2.0-0 \
    libstdc++6 \
    libgcc1 \
    libxtst6 \
    libxrender1 \
    libfontconfig1 \
    libpci3 \
    libuuid1 \
    # Tools and utilities
    wget \
    gnupg \
    git \
    curl \
    unzip \
    # Fonts
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-freefont-ttf \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for some Playwright features)
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g playwright

# Switch back to jovyan user
USER ${NB_UID}

# Install Python dependencies
RUN pip install --no-cache-dir \
    playwright \
    pandas \
    numpy \
    matplotlib \
    jupyterlab \
    ipywidgets \
    beautifulsoup4 \
    requests \
    selenium \
    pytest \
    # Additional useful packages
    scipy \
    scikit-learn \
    seaborn \
    plotly

# For Jupyter widgets support
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Set environment variables
ENV PLAYWRIGHT_BROWSERS_PATH=/home/jovyan/.cache/ms-playwright
