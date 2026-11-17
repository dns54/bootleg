<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Building

Building bootleg takes one `nix build`, but you need to know the Nix basics.

## Requirements

- Nix with flakes
- An `x86_64-linux` build host, or a builder for it:
  - remote builder (`builders` in `nix.conf`)
  - nix-darwin `nix.linux-builder` with Rosetta (Apple silicon)
  - NixOS `boot.binfmt.emulatedSystems = [ "x86_64-linux" ]`

## Outputs

Each `boards/<board>/` has two outputs.

| Command | Result |
|---|---|
| `nix build .#<board>` | Full image: `result/bootleg-<board>-<version>.rom`. Contains the Intel ME, so don't publish it |
| `nix build .#<board>-capsule` | No ME: unsigned capsule payload (`coreboot.rmap.rom`), BIOS region, descriptor |

## Full image

- Pulls the cached ME-less build
- Fetches the ME donor
- Runs me_cleaner and deguard
- Checks: ME hash, both regions, descriptor locks

## Version

- The commit date, `YYMMDDHHMM` in UTC
- Shown as `bootleg <version>+g<commit>` (SMBIOS BIOS version); the same number is the ESRT version

## Board layout

```
boards/<board>/
  default.nix
  defconfig
  patches/      # optional
  blobs/        # optional
```
