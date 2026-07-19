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
MAX_DROP_PERCENT="${MAX_DROP_PERCENT:-20}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fetch_source() {
    local source="$1"
    local destination="$2"

    if [[ -f "$source" ]]; then
        cp -- "$source" "$destination"
    else
        curl \
            --fail \
            --silent \
            --show-error \
            --location \
            --retry 3 \
            --retry-delay 2 \
            --retry-all-errors \
            --connect-timeout 15 \
            --max-time 120 \
            --output "$destination" \
            "$source"
    fi
}

normalize_and_validate() {
    local source_file="$1"
    local output_file="$2"
    local label="$3"

    python3 - "$source_file" "$output_file" "$label" <<'PY'
import ipaddress
import re
import sys
from pathlib import Path

source = Path(sys.argv[1])
output = Path(sys.argv[2])
label = sys.argv[3]

label_re = re.compile(r"^(?!-)[a-z0-9-]{1,63}(?<!-)$")
domains: set[str] = set()
errors: list[str] = []

for line_number, raw_line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
    domain = raw_line.strip().lower()
    if not domain or domain.startswith("#"):
        continue

    if domain.endswith("."):
        domain = domain[:-1]

    valid = True
    reason = ""

    if any(character.isspace() for character in domain):
        valid = False
        reason = "contains whitespace"
    elif len(domain) > 253:
        valid = False
        reason = "is longer than 253 characters"
    else:
        try:
            ipaddress.ip_address(domain)
        except ValueError:
            labels = domain.split(".")
            if len(labels) < 2 or any(not label_re.fullmatch(item) for item in labels):
                valid = False
                reason = "is not a valid ASCII domain"
        else:
            valid = False
            reason = "is an IP address"

    if not valid:
        if len(errors) < 20:
            errors.append(f"{label}: line {line_number}: {domain!r} {reason}")
        continue

    domains.add(domain)

if errors:
    print("\n".join(errors), file=sys.stderr)
    print(f"{label}: validation failed; refusing to publish output.", file=sys.stderr)
    raise SystemExit(1)

output.write_text("".join(f"{domain}\n" for domain in sorted(domains)), encoding="utf-8")
PY
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

    printf '%s\n' "$count"
}

validate_drop() {
    local new_file="$1"
    local current_file="$2"
    local label="$3"

    [[ -f "$current_file" ]] || return 0

    local new_count old_count minimum_allowed
    new_count="$(wc -l < "$new_file" | tr -d ' ')"
    old_count="$(wc -l < "$current_file" | tr -d ' ')"

    (( old_count > 0 )) || return 0
    minimum_allowed=$(( old_count * (100 - MAX_DROP_PERCENT) / 100 ))

    if (( new_count < minimum_allowed )); then
        echo "$label dropped from $old_count to $new_count entries, more than the allowed ${MAX_DROP_PERCENT}%; refusing to overwrite output." >&2
        exit 1
    fi
}

validate_subset() {
    local category_file="$1"
    local combined_file="$2"
    local label="$3"
    local missing_file="$TMP_DIR/${label// /-}-missing.txt"

    comm -23 "$category_file" "$combined_file" > "$missing_file"
    if [[ -s "$missing_file" ]]; then
        echo "$label contains domains missing from the combined list; refusing to publish outputs." >&2
        head -n 20 "$missing_file" >&2
        exit 1
    fi
}

fetch_source "$CORE_URL" "$TMP_DIR/combined.raw"
fetch_source "$CORE_ADBLOCK_URL" "$TMP_DIR/adblock.raw"
fetch_source "$CORE_ADULT_URL" "$TMP_DIR/adult.raw"

normalize_and_validate "$TMP_DIR/combined.raw" "$TMP_DIR/combined.txt" "Combined core"
normalize_and_validate "$TMP_DIR/adblock.raw" "$TMP_DIR/adblock.txt" "Adblock core"
normalize_and_validate "$TMP_DIR/adult.raw" "$TMP_DIR/adult.txt" "Adult core"

combined_count="$(validate_min_count "$TMP_DIR/combined.txt" "$MIN_DOMAIN_COUNT" "Combined core")"
adblock_count="$(validate_min_count "$TMP_DIR/adblock.txt" "$MIN_ADBLOCK_DOMAIN_COUNT" "Adblock core")"
adult_count="$(validate_min_count "$TMP_DIR/adult.txt" "$MIN_ADULT_DOMAIN_COUNT" "Adult core")"

validate_subset "$TMP_DIR/adblock.txt" "$TMP_DIR/combined.txt" "Adblock core"
validate_subset "$TMP_DIR/adult.txt" "$TMP_DIR/combined.txt" "Adult core"

validate_drop "$TMP_DIR/combined.txt" "$DOMAIN_OUTPUT_FILE" "Combined feed"
validate_drop "$TMP_DIR/adblock.txt" "$FORTIGATE_ADBLOCK_OUTPUT_FILE" "Adblock feed"
validate_drop "$TMP_DIR/adult.txt" "$FORTIGATE_ADULT_OUTPUT_FILE" "Adult feed"

install -m 0644 "$TMP_DIR/combined.txt" "$DOMAIN_OUTPUT_FILE"
install -m 0644 "$TMP_DIR/adblock.txt" "$FORTIGATE_ADBLOCK_OUTPUT_FILE"
install -m 0644 "$TMP_DIR/adult.txt" "$FORTIGATE_ADULT_OUTPUT_FILE"

echo "Generated combined FortiGate feed with $combined_count blocked domains."
echo "Generated adblock FortiGate feed with $adblock_count blocked domains."
echo "Generated adult FortiGate feed with $adult_count blocked domains."
