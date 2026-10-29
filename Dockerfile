FROM golang:1.24-alpine AS wgbuild

ARG WIREGUARD_GO_VERSION=0.0.20250522

RUN apk add --no-cache git \
    && git clone --depth 1 --branch "${WIREGUARD_GO_VERSION}" \
       https://github.com/WireGuard/wireguard-go.git /src
WORKDIR /src
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o /out/wireguard-go .

FROM envoyproxy/envoy:v1.37.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    wireguard-tools \
    iproute2 \
    iptables \
    && rm -rf /var/lib/apt/lists/*

COPY --from=wgbuild /out/wireguard-go /usr/local/bin/wireguard-go

ENV WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]
