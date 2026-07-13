#!/bin/bash

source "$(dirname "$0")/.env"

if [[ -z "$ABUSEIPDB_API_KEY" ]]; then
    echo "ERROR: ABUSEIPDB_API_KEY not set in .env"
    exit 1
fi

WHITELIST=()

while read -r ip; do
    WHITELIST+=("$ip")
done < <(curl -s https://www.cloudflare.com/ips-v4/ | awk -F'/' '{print $1}')

while read -r ip; do
    WHITELIST+=("$ip")
done < <(curl -s https://www.cloudflare.com/ips-v6/ | awk -F'/' '{print $1}')

HOSTNAME=$(hostname)

declare -A reported_ips

is_whitelisted() {
    local ip="$1"

    for whitelist_ip in "${WHITELIST[@]}"; do
        [[ "$ip" == "$whitelist_ip"* ]] && return 0
    done

    return 1
}

is_local_ip() {
    local ip="$1"

    [[ "$ip" =~ ^(10\.|192\.168\.|127\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|::1|fe80:|fc00:|fd00:) ]] && return 0

    return 1
}

was_reported_recently() {
    local ip="$1"
    local now=$(date +%s)

    [[ -n "${reported_ips[$ip]}" && $((now - reported_ips[$ip])) -lt 900 ]]
}

cleanup_old_entries() {
    local now=$(date +%s)

    for ip in "${!reported_ips[@]}"; do
        if (( now - reported_ips[$ip] >= 900 )); then
            unset "reported_ips[$ip]"
        fi
    done
}

echo "AbuseIPDB UFW Reporter started on $HOSTNAME"

journalctl -f -o short-iso | stdbuf -oL grep '\[UFW BLOCK\]' | while read -r line; do

    src_ip=$(echo "$line" | grep -o 'SRC=[^ ]*' | cut -d '=' -f2)
    blocked_port=$(echo "$line" | grep -o 'DPT=[^ ]*' | cut -d '=' -f2)

    [[ -z "$src_ip" ]] && continue
    is_whitelisted "$src_ip" && continue
    is_local_ip "$src_ip" && continue
    was_reported_recently "$src_ip" && continue

    reported_ips["$src_ip"]=$(date +%s)

    curl -s "https://api.abuseipdb.com/api/v2/report" \
        -H "Key: $ABUSEIPDB_API_KEY" \
        -H "Accept: application/json" \
        -d "ip=$src_ip" \
        -d "categories=14" \
        -d "comment=[$HOSTNAME] Unauthorized connection attempt to port $blocked_port from $src_ip"

    cleanup_old_entries

done
