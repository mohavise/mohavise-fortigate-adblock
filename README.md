# Mohavise FortiGate Adblock

This project builds FortiGate-friendly outputs from the shared Mohavise adblock core list.

Source and allowlist changes are managed in the core repo:

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Daily Timing

GitHub Actions runs at `23:30 UTC`, which is `03:00 Asia/Tehran`.

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
| `fortigate-hosts.txt` | Optional hosts-format output |
| `scripts/build-fortigate-adblock.ps1` | Downloads the core list and builds the final FortiGate files |

## Marker

Generated files use this marker:

```text
managed-by=mohavise-fortigate-adblock
```

## Logic

```text
upstream sources + custom blocklist - allowlist = final FortiGate domain feed
```
