# ----------------------
# Builder Stage
# ----------------------
FROM alpine:3.22 AS builder

RUN apk add --no-cache build-base clang llvm lld cmake git jemalloc openssl-dev linux-headers util-linux-dev libunwind-dev curl-dev

WORKDIR /keydb
COPY . .

RUN make -j$(nproc) && make install

# ----------------------
# Final Stage
# ----------------------
FROM alpine:3.22

# Install runtime dependencies
RUN apk add --no-cache jemalloc openssl su-exec libuuid libcurl libunwind

# Create keydb user and group
RUN addgroup -S keydb && adduser -S keydb -G keydb

# Copy binaries from builder
COPY --from=builder /usr/local/bin/keydb-server /usr/local/bin/keydb-server
COPY --from=builder /usr/local/bin/keydb-cli /usr/local/bin/keydb-cli

# Add default config (can be overridden by volume)
COPY keydb.conf /etc/keydb/keydb.conf

# Set Kubernetes-friendly defaults
RUN sed -i 's/^bind 127.0.0.1 -::1$/bind 0.0.0.0/' /etc/keydb/keydb.conf && \
    sed -i 's/^protected-mode yes$/protected-mode no/' /etc/keydb/keydb.conf

# Entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create data directory and set ownership
RUN mkdir -p /data && chown keydb:keydb /data

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD keydb-cli ping || exit 1

VOLUME /data
WORKDIR /data

EXPOSE 6379

# Use exec form for proper signal handling
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["keydb-server", "/etc/keydb/keydb.conf"]