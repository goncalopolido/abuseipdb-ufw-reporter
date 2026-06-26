#!/bin/bash

LOG_FILE=./reports.log

source "$(dirname "$0")/.env"

is_already_logged() {
    local ip="$1"
    grep -q "$ip" "$LOG_FILE"
}

journalctl -f -o short-iso | grep --line-buffered '\[UFW BLOCK\]' | while read -r line; do
    src_ip=$(echo "$line" | grep -o 'SRC=[^ ]*' | cut -d '=' -f 2)
    dst_ip=$(echo "$line" | grep -o 'DST=[^ ]*' | cut -d '=' -f 2)
    blocked_port=$(echo "$line" | grep -o 'DPT=[^ ]*' | cut -d '=' -f 2)

    if is_already_logged "$src_ip"; then
        continue
    fi

    if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt 500 ]; then
        rm "$LOG_FILE"
        touch "$LOG_FILE"
    fi

    echo "$(date +'%Y-%m-%d %H:%M:%S') $src_ip" >> "$LOG_FILE"

    curl -s "https://api.abuseipdb.com/api/v2/report" \
        -H "Key: $ABUSEIPDB_API_KEY" \
        -d "ip=$src_ip" \
        -d "categories=14" \
        -d "comment=Unauthorized connection attempt to port $blocked_port from $src_ip"
done
