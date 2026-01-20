# Select base image (Debian 11 / bullseye)
ARG BASE_IMAGE=debian:bullseye-slim
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime libraries including Boost 1.74
RUN apt-get update && apt-get install -y \
    libboost-filesystem1.74.0 \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    libace-dev \
    libssl3 \
    libmariadb3 \
    libreadline8 \
    libncurses6 \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default working directory
WORKDIR /app

# Default command (can be overridden by ENV)
ENV START_AUTH="./bin/authserver"

ENTRYPOINT ["/entrypoint.sh"]
