#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt}"
DOMAIN_OUTPUT_FILE="${DOMAIN_OUTPUT_FILE:-$REPO_DIR/fortigate-domains.txt}"

if [[ -f "$CORE_URL" ]]; then
    cat "$CORE_URL"
else
    curl -fsSL "$CORE_URL"
fi |
    awk '
        {
            line = tolower($0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line != "" && line !~ /^#/) print line
        }
    ' |
    sort -u > "$DOMAIN_OUTPUT_FILE"

domain_count="$(wc -l < "$DOMAIN_OUTPUT_FILE" | tr -d ' ')"
echo "Generated $DOMAIN_OUTPUT_FILE with $domain_count blocked domains."

