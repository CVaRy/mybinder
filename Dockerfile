# Start from the Jupyter base image
FROM jupyter/base-notebook:python-3.9

# Switch to root to install system dependencies
USER root

# Install Playwright system dependencies and other required packages
RUN apt-get update && \
    apt-get install -y \
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
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    wget \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright browsers as root (they'll be available to all users)
RUN playwright install chromium && \
    playwright install firefox && \
    playwright install webkit

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
    pytest

# For Jupyter widgets support
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Set environment variables
ENV PLAYWRIGHT_BROWSERS_PATH=/home/jovyan/.cache/ms-playwright
