# Mohavise FortiGate Adblock

FortiGate child/output repo for the Mohavise adblock system.

It publishes one FortiGate-friendly external domain feed from the validated core list.

## Source

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Output

```text
fortigate-adblock-domains.txt
```

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adblock-domains.txt
```

## Example FortiGate external resource

```fortios
config system external-resource
    edit "mohavise-adblock-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/mohavise-fortigate-adblock/main/fortigate-adblock-domains.txt"
        set refresh-rate 1440
    next
end
```

## Files

```text
fortigate-adblock-domains.txt
scripts/build-fortigate-adblock.sh
.github/workflows/update-fortigate-adblock.yml
```
