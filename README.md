<!-- SPDX-License-Identifier: CC-BY-4.0 -->

```text
 █████                        █████    ████
░░███                        ░░███    ░░███
 ░███████   ██████   ██████  ███████   ░███   ██████   ███████
 ░███░░███ ███░░███ ███░░███░░░███░    ░███  ███░░███ ███░░███
 ░███ ░███░███ ░███░███ ░███  ░███     ░███ ░███████ ░███ ░███
 ░███ ░███░███ ░███░███ ░███  ░███ ███ ░███ ░███░░░  ░███ ░███
 ████████ ░░██████ ░░██████   ░░█████  █████░░██████ ░░███████
░░░░░░░░   ░░░░░░   ░░░░░░     ░░░░░  ░░░░░  ░░░░░░   ░░░░░███
                                                      ███ ░███
                                                     ░░██████
                                                      ░░░░░░
```

# bootleg

bootleg is a coreboot distribution for servers and personal computers, built with Nix flakes. It
takes upstream coreboot with the MrChromebox EDK2 payload and adds platform features, security
fixes and bug fixes on top.

The only supported board for now is the Dell OptiPlex 3050 Micro (`optiplex-3050`).

## Features

- UEFI: coreboot + MrChromebox EDK2
- Secure Boot: Microsoft keys enrolled, off by default; own keys can be enrolled via setup mode
- TPM 2.0 support, measured boot: one event log from coreboot and EDK2; SHA-1 and SHA-256 banks
- Flash protection: descriptor and ME locked, BIOS Lock (SMM-only writes)
- Setup menu for the platform options: power, CPU, PCIe, devices, watchdog, console
- Network boot: iPXE as the UEFI NIC driver, PXEv4 and PXEv6
- Wake-on-LAN from S5, watchdog, serial console
- Platform features from Dell's firmware: AC Recovery, POST alerts, beep codes, LED diagnostics, chassis intrusion, fan monitoring
- Signed UEFI capsule updates through fwupd
- Intel ME disabled (HAP and me_cleaner), Boot Guard bypassed (deguard)
- Latest Intel microcode
- Reproducible Nix build

## Why bootleg?

Libreboot supports more hardware than any other coreboot distribution, which made it the de facto
standard for open source firmware. Over the years it has piled up a lot of technical debt, though:
it isn't stable enough for production machines, and its security is weak.

bootleg starts from upstream coreboot and patches it until it behaves like vendor firmware on a
server. Everything is set in the setup menu, updates are signed capsules through fwupd, boot is
measured, and the same flake always builds the same image.

### Features compared to Libreboot

| | bootleg | Libreboot |
|---|---|---|
| Setup menu | Yes | No |
| Measured boot | coreboot + EDK2 event log, all banks and setup options in PCR1 | No |
| Updates | Signed capsules, fwupd, BIOS Lock stays on | Reflash only |
| Descriptor and ME region | Locked to the CPU | Unlocked |
| BIOS region | BIOS Lock (SMM-only writes) | Writable |
| TPM pin lock | LPC and PLTRST# locked | No |
| Hyper-Threading | On, setup option | Off |
| AC Recovery | Off, On, Last State, all working | Config is ignored, the EC powers on anyway |
| Watchdog | Boot Only / Boot and OS | No |
| Diagnostics | LED codes, beep codes and POST alerts | No |
| Chassis intrusion | Alert, PCR1 | No |
| Fans | Failure alert, speed in Linux | No |
| Device switches | USB ports, SATA, M.2, audio, speaker, USB boot | No |
| PCIe power management | ASPM, L1 substates, clock PM, LTR on all ports | Upstream defaults |
| Build | Nix flake, reproducible | lbmk |

### Security fixes

| Patch | Issue |
|---|---|
| edk2 `0021` | GPT: 32-bit overflow of the entry array size, reads up to 4 GiB past the buffer |
| edk2 `0022` | FAT: looping directory cluster chain hangs the firmware when a USB stick is plugged in |
| edk2 `0023` | Authenticode: unchecked content size, out-of-bounds reads in signature checks |
| edk2 `0019` | Secure Boot stays in Custom mode when booting from setup |
| edk2 `0003` | TPM platform hierarchy left open to the OS |
| coreboot `0021` | coreboot rewrote setup variables as runtime-accessible: the OS could change them |
| coreboot `0024` | TPM reply overflows a stack buffer (up to 252 bytes) |
| board `0012` | TPM reset from the OS through GPIO (TPM GPIO fail) |
| coreboot `0019` | Watchdog never resets once SMM is up |

### Bug fixes

| Patch | Issue |
|---|---|
| coreboot `0027` | Coffee Lake: voltage regulators unconfigured (Icc max and loadlines 0) |
| coreboot `0025` | Coffee Lake: `MSR_BIOS_DONE` #GP, bricked the board |
| coreboot `0026` | PCH-H GPIO controller reported as PCH-LP: OS uses the wrong pad layout |
| board `0006` | Power off after AC loss ignored: the SCH5555 powers on |
| board `0003` | WiFi M.2 hotplug: a NIC there disappears and comes back as a new device |
| board `0007` | No LTR on LAN and WLAN ports: package C-states stop at PC3; DDI E lanes warning |
| edk2 `0011` | HPET: unbounded nested timer interrupts overflow the DXE stack |
| edk2 `0020` | Secure Boot: enrolling KEK, db, dbx, dbt from a file broken |
| edk2 `0017` | Nothing to boot: endless logo, no way into setup |
| edk2 `0009` | Capsules on disk never applied, ESRT reports the old version |
| edk2 `0010` | ESP of a short-form boot entry not found for capsules |
| coreboot `0013` | TPM 1.2 log: no digest compiled in, PCR extend fails |
| coreboot `0014` | TPM 2.0 log header disagrees with its events |
| coreboot `0016` | EDK2 build needs network access |
| coreboot `0029` | Build date breaks reproducible builds outside git |

## Boards

| Board | Docs | Status |
|---|---|---|
| Dell OptiPlex 3050 Micro | [docs/optiplex-3050.md](docs/optiplex-3050.md) | Fully working |

## Documentation

- [Building](docs/building.md)
- [Installing](docs/install.md)
- [Updates](docs/updates.md)
- [Security](docs/security.md)

## Credits

- [coreboot](https://coreboot.org), the base
- [EDK2](https://github.com/tianocore/edk2) and [MrChromebox EDK2](https://github.com/MrChromebox/edk2) for the payload
- [Libreboot](https://libreboot.org) ([lbmk](https://codeberg.org/libreboot/lbmk)) for the idea and several patches
- [deguard](https://review.coreboot.org/admin/repos/deguard,general)
- [me_cleaner](https://github.com/corna/me_cleaner)
- [Dasharo](https://github.com/Dasharo) ([coreboot](https://github.com/Dasharo/coreboot), [EDK2](https://github.com/Dasharo/edk2)) for patches and reference code
- [System76 coreboot](https://github.com/system76/coreboot) and [firmware-open](https://github.com/system76/firmware-open) for reference code
- [iPXE](https://ipxe.org)
- [Snowboot](https://codeberg.org/hustlerone/Snowboot) and [coreboot-flake](https://codeberg.org/mateidibu/coreboot-flake) for showing how to build coreboot with Nix
- [nixpkgs](https://github.com/NixOS/nixpkgs)
- Intel: FSP, microcode

## Licences

Each file is licensed on its own, as in coreboot: source files and docs carry an SPDX header, and
the licence texts are in `LICENSES/`.

| Files | Licence |
|---|---|
| Nix code | MIT |
| Docs, logo (`assets/logo.png`) | CC-BY-4.0 |
| coreboot and board patches | GPL-2.0-only |
| EDK2 patches | BSD-2-Clause-Patent |

The flash descriptor in `boards/*/blobs/` comes from Dell's stock firmware; bootleg doesn't
license it.

The firmware image itself contains coreboot (GPL-2.0-only), EDK2 (BSD-2-Clause-Patent), iPXE
(GPL-2.0-or-later), and Intel FSP and microcode under Intel's licences. Each release includes the
complete source it was built from; the components and their licences are listed in
[docs/third-party.md](docs/third-party.md).
