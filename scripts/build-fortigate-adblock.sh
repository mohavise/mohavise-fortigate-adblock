#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adblock-domains.txt}"
OUTPUT_FILE="${OUTPUT_FILE:-$REPO_DIR/fortigate-adblock-domains.txt}"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-10000}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -f "$CORE_URL" ]]; then
    cat "$CORE_URL"
else
    curl -fsSL "$CORE_URL"
fi |
    awk '{
        line = tolower($0)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line != "" && line !~ /^#/) print line
    }' |
    sort -u > "$TMP_DIR/domains.txt"

count="$(wc -l < "$TMP_DIR/domains.txt" | tr -d ' ')"
if (( count < MIN_DOMAIN_COUNT )); then
    echo "Domain count $count is below minimum $MIN_DOMAIN_COUNT; refusing to overwrite output." >&2
    exit 1
fi

cp "$TMP_DIR/domains.txt" "$OUTPUT_FILE"

echo "Generated FortiGate domain feed with $count blocked domains."
