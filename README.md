# Mohavise FortiGate Adblock

This repository is the FortiGate child/output repo of the main Mohavise adblock core project.

It builds a FortiGate-friendly external domain threat feed from the shared core domain list.
Source lists, upstream changes, custom blocks, allowlists, and data validation are managed in the parent core repo:

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Relationship

```text
mohavise-adblock-core
        ↓
mohavise-fortigate-adblock
        ↓
FortiGate external domain threat feed
```

## Daily Timing

GitHub Actions runs at `00:00 UTC`, which is `03:30 Asia/Tehran`.

## Materials / Output Files

This repo has one final FortiGate material:

| File | Format | Main Use |
| --- | --- | --- |
| `fortigate-domains.txt` | Plain domain list with no header comments | Main file used as a FortiGate external domain threat feed |

The parent repo is responsible for cleaning and validating the data before this repo builds the FortiGate output.

## Use In FortiGate

Use this raw URL as an external domain threat feed:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-domains.txt
```

The generated file is a plain domain list with no header comments:

```text
example-ad-domain.com
tracker.example.net
```

## Example External Resource

```fortios
config system external-resource
    edit "mohavise-adblock-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-domains.txt"
        set refresh-rate 1440
    next
end
```

After adding the external resource, attach it to the FortiGate DNS filter or security profile path appropriate for your FortiOS version.

## Files

| File | Purpose |
| --- | --- |
| `fortigate-domains.txt` | Final generated FortiGate domain feed |
| `scripts/build-fortigate-adblock.sh` | Downloads the core list and builds the final FortiGate file |

## Build

```bash
./scripts/build-fortigate-adblock.sh
```

## Signature

Generated items use this signature:

```text
managed-by=mohavise-fortigate-adblock
project=mohavise-fortigate-adblock
```

The signature makes future updates safer because generated outputs can be clearly identified as managed by this project.

## Update-Ready Approach

```text
Parent/core repo validates and publishes the canonical list.
Child repo converts the canonical list into a FortiGate-ready output.
FortiGate refreshes the final output through the external resource schedule.
Managed items are marked with a clear signature.
Future changes should update managed outputs only, not unrelated user configuration.
```

## Future Vision

```text
One clean parent list.
Multiple child outputs.
Same structure.
Same timing.
Same signature style.
Safe daily updates.
Easy rollback and future platform expansion.
```

Planned child/output targets can include MikroTik, Pi-hole, FortiGate, and other DNS/security platforms that can consume domain feeds.

## Logic

```text
mohavise-adblock-core/core-domains.txt = validated canonical source
mohavise-fortigate-adblock/fortigate-domains.txt = FortiGate-ready output
```
