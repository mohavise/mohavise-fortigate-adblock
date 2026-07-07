#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt}"
CORE_ADBLOCK_URL="${CORE_ADBLOCK_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adblock-domains.txt}"
CORE_ADULT_URL="${CORE_ADULT_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adult-domains.txt}"

DOMAIN_OUTPUT_FILE="${DOMAIN_OUTPUT_FILE:-$REPO_DIR/fortigate-domains.txt}"
FORTIGATE_ADBLOCK_OUTPUT_FILE="${FORTIGATE_ADBLOCK_OUTPUT_FILE:-$REPO_DIR/fortigate-adblock-domains.txt}"
FORTIGATE_ADULT_OUTPUT_FILE="${FORTIGATE_ADULT_OUTPUT_FILE:-$REPO_DIR/fortigate-adult-domains.txt}"

MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-10000}"
MIN_ADBLOCK_DOMAIN_COUNT="${MIN_ADBLOCK_DOMAIN_COUNT:-10000}"
MIN_ADULT_DOMAIN_COUNT="${MIN_ADULT_DOMAIN_COUNT:-1000}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fetch_domains() {
    local source_url="$1"
    local output_file="$2"

    if [[ -f "$source_url" ]]; then
        cat "$source_url"
    else
        curl -fsSL "$source_url"
    fi |
        awk '
            {
                line = tolower($0)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line != "" && line !~ /^#/) print line
            }
        ' |
        sort -u > "$output_file"
}

validate_min_count() {
    local file="$1"
    local minimum="$2"
    local label="$3"
    local count

    count="$(wc -l < "$file" | tr -d ' ')"
    if (( count < minimum )); then
        echo "$label domain count $count is below minimum $minimum; refusing to overwrite outputs." >&2
        exit 1
    fi

    echo "$count"
}

fetch_domains "$CORE_URL" "$TMP_DIR/combined.txt"
fetch_domains "$CORE_ADBLOCK_URL" "$TMP_DIR/adblock.txt"
fetch_domains "$CORE_ADULT_URL" "$TMP_DIR/adult.txt"

combined_count="$(validate_min_count "$TMP_DIR/combined.txt" "$MIN_DOMAIN_COUNT" "Combined core")"
adblock_count="$(validate_min_count "$TMP_DIR/adblock.txt" "$MIN_ADBLOCK_DOMAIN_COUNT" "Adblock core")"
adult_count="$(validate_min_count "$TMP_DIR/adult.txt" "$MIN_ADULT_DOMAIN_COUNT" "Adult core")"

cp "$TMP_DIR/combined.txt" "$DOMAIN_OUTPUT_FILE"
cp "$TMP_DIR/adblock.txt" "$FORTIGATE_ADBLOCK_OUTPUT_FILE"
cp "$TMP_DIR/adult.txt" "$FORTIGATE_ADULT_OUTPUT_FILE"

echo "Generated combined FortiGate feed with $combined_count blocked domains."
echo "Generated adblock FortiGate feed with $adblock_count blocked domains."
echo "Generated adult FortiGate feed with $adult_count blocked domains."
