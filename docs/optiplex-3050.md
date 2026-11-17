<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Dell OptiPlex 3050 Micro

A small desktop with a Kaby Lake board that also runs 8th and 9th gen Coffee Lake CPUs. Its
Boot Guard is fused on, so bootleg uses deguard and a donor ME to boot on it. bootleg is tested
on an i3-9100T with the Nuvoton TPM.

Generic steps: [building](building.md), [installing](install.md), [updates](updates.md),
[security](security.md).

## Specifications

| Item | Value |
|---|---|
| coreboot board | `src/mainboard/dell/sklkbl_desktops`, variant `optiplex_3050`, `CONFIG_BOARD_DELL_OPTIPLEX_3050` |
| SoC / PCH | Kaby Lake, 200-series PCH-H (Sunrise Point), FSP 2.0 |
| CPU | 6th/7th gen; 8th/9th gen Coffee Lake (tested: i3-9100T) |
| Memory | 2× DDR4 SO-DIMM. Dell: 32 GB max. Coffee Lake: 64 GB (2× 32 GB) |
| Flash | 16 MiB SPI, SOIC-8, soldered, next to the RAM. Descriptor VSCC: Winbond W25Q128, Macronix MX25L128, GigaDevice GD25Q128, Micron N25Q128 |
| TPM | TPM 2.0 on LPC, TIS at `0xfed40000`. Nuvoton NPCT650JB2YX (UF1) or NationZ Z32H320TC (UF2) |
| NIC | Realtek GbE on `pcie_rp5`, no GbE flash region |
| Super I/O / EC | SMSC SCH5555: serial, fans, power LED, AC power-on |
| Audio | Realtek ALC3234 (ALC255) |
| Intel ME | Disabled: HAP, me_cleaner, deguard. No AMT, no PTT |

## Get the image

```sh
nix build .#optiplex-3050
```

## Internal flashing

- Setup → **BIOS Lock** off
- Short the service jumper (near the RAM, under the drive bay). It lifts the descriptor and ME locks (FDOPSS = 0)
- Boot without kernel lockdown, flash with flashprog: [install.md](install.md#internal-flashing)
- Cut power after verifying

## External flashing

- Remove all power
- CH341A at 3.3 V: [install.md](install.md#external-flashing)

## Setup menu

| Menu | Form | Options (default) |
|---|---|---|
| System Features | Security Options | BIOS Lock (on) |
| | Networking Options | Enable UEFI Network Stack (off) |
| | USB Configuration | Enable Boot Support (on) |
| | Console | Console Log Level (7, Debug), Serial Console (off) |
| Platform Setup Menu | CPU Configuration | Hyper-Threading, SpeedStep, Turbo Boost, CPU power states (C-states) (all on) |
| | Chipset Configuration | VT-d (on), IGD DVMT Size (64 MB), IGD Aperture Size (256 MB), Watchdog Timer Support (Boot Only) |
| | PCI/PCIe Configuration | PCIe PCH RP ASPM (Auto), PCIe L1 Substates (L1.2), PCIe Clock Power Management (on) |
| | Power Management Options | Restore AC power after loss (Previous state), Deep Sleep Control (Disabled), Fan Control Override (off), Block Sleep (off), Enable USB Wake Support (off) |
| | Devices | Enable Front/Rear USB Ports, SATA-0, M.2 PCIe SSD-0, Enable Audio, Enable Internal Speaker (all on), Beep Codes (Errors) |
| | Chassis | Chassis Intrusion (Enabled), Clear Intrusion Warning (off) |
