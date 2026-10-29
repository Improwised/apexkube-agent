FROM masipcat/wireguard-go:0.0.20230223 AS wg

FROM envoyproxy/envoy:v1.37.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    wireguard-tools=1.0.20210914-1ubuntu2 \
    iproute2=5.15.0-1ubuntu2.2 \
    iptables=1.8.7-1ubuntu5.2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=wg /usr/bin/wireguard-go /usr/local/bin/wireguard-go
COPY --from=wg /lib/ld-musl-x86_64.so.1 /lib/
RUN ln -s ld-musl-x86_64.so.1 /lib/libc.musl-x86_64.so.1

ENV WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD ["wg", "show", "wg0"]

ENTRYPOINT ["/entrypoint.sh"]