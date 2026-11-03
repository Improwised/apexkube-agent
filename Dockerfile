FROM golang:1.27-alpine AS wgbuild

ARG WIREGUARD_GO_VERSION=0.0.20250522
ARG X_CRYPTO_VERSION=v0.58.0
ARG X_NET_VERSION=v0.62.0
ARG X_SYS_VERSION=v0.49.0

RUN apk add --no-cache git \
    && git clone --depth 1 --branch "${WIREGUARD_GO_VERSION}" \
       https://github.com/WireGuard/wireguard-go.git /src
WORKDIR /src
RUN go get "golang.org/x/crypto@${X_CRYPTO_VERSION}" \
           "golang.org/x/net@${X_NET_VERSION}" \
           "golang.org/x/sys@${X_SYS_VERSION}" \
    && go mod tidy \
    && CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o /out/wireguard-go .

FROM envoyproxy/envoy:v1.40.0@sha256:764744499999f43faf0c5bc791c3cc81b62c2b9b5bc1b5828e1bc681647c170c

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
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
