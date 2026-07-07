# Mohavise FortiGate Adblock

This repository is the FortiGate child/output repo of the main Mohavise adblock core project.

It builds FortiGate-friendly external domain threat feeds from the validated parent core lists.
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

FortiGate refreshes the external resource based on the configured `refresh-rate`.

## Output Strategy

This repo now supports separate endpoint lists.

```text
adblock list = ads / trackers
adult list   = adult / NSFW domains
combined     = adblock + adult together
```

For normal production use, create two separate FortiGate external resources:

```text
fortigate-adblock-domains.txt
fortigate-adult-domains.txt
```

This is better than only one combined feed because you can apply, disable, log, or troubleshoot adblock and adult blocking separately.

## Materials / Output Files

| File | Format | Main Use |
| --- | --- | --- |
| `fortigate-adblock-domains.txt` | Plain domain list with no header comments | FortiGate external domain feed for ads / trackers |
| `fortigate-adult-domains.txt` | Plain domain list with no header comments | FortiGate external domain feed for adult / NSFW domains |
| `fortigate-domains.txt` | Plain domain list with no header comments | Compatibility combined feed for old/simple installs |

Simple explanation:

```text
fortigate-adblock-domains.txt = main adblock external feed
fortigate-adult-domains.txt   = main adult external feed
fortigate-domains.txt         = old combined compatibility feed
```

## Use In FortiGate

Use these raw URLs as external domain threat feeds:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adblock-domains.txt
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adult-domains.txt
```

The generated files are plain domain lists with no header comments:

```text
example-ad-domain.com
tracker.example.net
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

After adding the external resources, attach them to the FortiGate DNS filter or security profile path appropriate for your FortiOS version.

## Optional Combined URL

Use this only if you want one simple combined feed instead of two separate feeds:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-domains.txt
```

## Files

| File | Purpose |
| --- | --- |
| `fortigate-adblock-domains.txt` | Final generated FortiGate adblock category feed |
| `fortigate-adult-domains.txt` | Final generated FortiGate adult category feed |
| `fortigate-domains.txt` | Final generated combined compatibility feed |
| `scripts/build-fortigate-adblock.sh` | Downloads category core lists and builds FortiGate outputs |
| `.github/workflows/update-fortigate-adblock.yml` | Daily GitHub Actions build workflow |

## Build

```bash
./scripts/build-fortigate-adblock.sh
```

The build script reads:

```text
core-domains.txt
core-adblock-domains.txt
core-adult-domains.txt
```

and generates FortiGate-ready combined, adblock-only, and adult-only outputs.

## Signature

Generated items use this signature:

```text
managed-by=mohavise-fortigate-adblock
project=mohavise-fortigate-adblock
```

The signature makes future updates safer because generated outputs can be clearly identified as managed by this project.

## Update-Ready Approach

```text
Parent/core repo validates and publishes category lists.
Child repo converts category lists into FortiGate-ready outputs.
FortiGate refreshes the final output through the external resource schedule.
Managed items are marked with a clear signature.
Future changes should update managed outputs only, not unrelated user configuration.
```

## Future Vision

```text
One clean parent system.
Separate category outputs.
Multiple child platform outputs.
Same timing.
Same signature style.
Safe daily updates.
Easy rollback and future category expansion.
```

Planned future categories can include malware, gambling, social media, crypto, telemetry, and other DNS/security feeds.

## Logic

```text
core-adblock-domains.txt → fortigate-adblock-domains.txt
core-adult-domains.txt   → fortigate-adult-domains.txt
core-domains.txt         → fortigate-domains.txt
```

## Cleanup Policy

Before removing any file from this repository, read `CLEANUP_POLICY.md`.

Generated outputs, compatibility files, FortiGate feed endpoints, workflows, and scripts are intentional parts of the process. Do not delete them only because they look duplicated, old, large, or generated.
