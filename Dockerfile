# Dockerfile — Docker-in-Docker (DinD)
FROM docker:27-dind

# Opsiyonel: Python3 veya başka araçları da kurabilirsin
RUN apk add --no-cache bash curl python3 py3-pip

# Varsayılan olarak Docker daemon çalıştır
CMD ["dockerd-entrypoint.sh"]
