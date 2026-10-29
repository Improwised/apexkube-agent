#!/bin/sh
# Healthy only when a WireGuard handshake completed recently, which proves the
# tunnel is actually passing traffic. A handshake timestamp never resets, so the
# age is checked against a window.
now=$(date +%s)
max_age=${WG_HEALTHCHECK_MAX_AGE:-300}
wg show wg0 latest-handshakes 2>/dev/null | awk -v now="$now" -v max="$max_age" \
    '$2 > 0 && now - $2 < max { found = 1 } END { exit !found }'
