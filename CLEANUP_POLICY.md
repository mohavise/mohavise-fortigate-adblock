# Cleanup Policy

This repository is part of the Mohavise adblock pipeline. Do not delete files only because they look duplicated, old, large, or generated.

## Safe cleanup rule

A file can be removed only when all of these are true:

```text
not used by a GitHub Actions workflow
not used by a build script
not documented as an output
not used by a firewall/device-side process
not used as a raw URL endpoint
not kept for compatibility or fallback
not needed for future scheduled generation
```

If any item is false or unknown, keep the file.

## Required review before deletion

Before deleting any file:

1. Check `.github/workflows/` for `git add`, script calls, and output references.
2. Check `scripts/` for input and output variables.
3. Check `README.md` for documented public URLs and compatibility notes.
4. Check FortiGate external-resource usage and raw URL endpoints.
5. Prepare a removal report with risk level.
6. Delete only after explicit approval.

## Current intentional files

These files are intentional and must not be removed without a full process change:

```text
fortigate-adblock-domains.txt
fortigate-adult-domains.txt
fortigate-domains.txt
scripts/build-fortigate-adblock.sh
.github/workflows/update-fortigate-adblock.yml
```

## Notes

`fortigate-domains.txt` is the combined compatibility feed. The category outputs are kept for separate FortiGate external resources and future expansion.
