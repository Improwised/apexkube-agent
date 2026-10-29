#!/usr/bin/env bash
set -e

cleanup() {
    echo "Shutting down WireGuard..."
    wg-quick down wg0 2>/dev/null || true
}
trap cleanup EXIT

echo "Starting ApexKube Agent..."

wg-quick up wg0

for i in $(seq 1 15); do
    if ip link show wg0 >/dev/null 2>&1; then
        echo "WireGuard wg0 is up ($(wg show wg0 public-key 2>/dev/null || echo key-unavailable))"
        break
    fi
    sleep 1
    [ "$i" -eq 15 ] && echo "ERROR: wg0 did not come up within 15s" && exit 1
done

exec /docker-entrypoint.sh envoy -c /etc/envoy/envoy.yaml
