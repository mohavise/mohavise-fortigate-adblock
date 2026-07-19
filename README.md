# Mohavise FortiGate Adblock

FortiGate-ready external domain feeds generated from the validated parent repository:

```text
mohavise-adblock-core
        ↓
mohavise-fortigate-adblock
        ↓
FortiGate external domain resource
```

## Output Files

| File | Purpose |
| --- | --- |
| `fortigate-adblock-domains.txt` | Ads and trackers domain feed |
| `fortigate-adult-domains.txt` | Optional adult/NSFW domain feed |
| `fortigate-domains.txt` | Combined compatibility feed |

All output files contain one plain domain per line with no header comments.

## Recommended Use

Create separate external resources for:

```text
fortigate-adblock-domains.txt
fortigate-adult-domains.txt
```

This allows each category to be enabled, disabled, logged, and troubleshot independently.

Do not use the combined feed together with both separate feeds because that duplicates the same domains.

## Feed URLs

Normal adblock:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adblock-domains.txt
```

Optional adult blocking:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adult-domains.txt
```

Optional combined feed:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-domains.txt
```

## Example External Resources

```fortios
config system external-resource
    edit "mohavise-adblock-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adblock-domains.txt"
        set refresh-rate 1440
    next
    edit "mohavise-adult-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adult-domains.txt"
        set refresh-rate 1440
    next
end
```

The security-profile attachment method can vary by FortiOS version and configuration design.

## Repository Validation

Before replacing published feeds, the build verifies:

```text
HTTPS download success with retries and timeouts
→ valid ASCII domain format
→ no IP addresses
→ no whitespace records
→ duplicate removal and deterministic sorting
→ minimum entry counts
→ adblock and adult lists are subsets of the combined list
→ no sudden reduction greater than 20%
→ output replacement only after every check passes
```

A failed check stops the workflow and keeps the previous published feeds unchanged.

## Automation

GitHub Actions runs daily at:

```text
00:00 UTC
```

FortiGate refreshes each external resource according to its configured `refresh-rate`.

The workflow includes:

```text
15-minute timeout
single-run concurrency protection
no commit when outputs are unchanged
rebase before push
```

## Local Build

```bash
./scripts/build-fortigate-adblock.sh
```

The build reads:

```text
core-domains.txt
core-adblock-domains.txt
core-adult-domains.txt
```

and generates the three FortiGate feeds.

## Repository Files

| File | Purpose |
| --- | --- |
| `scripts/build-fortigate-adblock.sh` | Downloads, validates, and builds feeds |
| `.github/workflows/update-fortigate-adblock.yml` | Daily build and publication workflow |
| `CLEANUP_POLICY.md` | Rules for removing repository files |

## Cleanup Policy

Before removing repository files, read `CLEANUP_POLICY.md`. Generated feeds, compatibility outputs, workflows, and scripts are intentional parts of this project.
