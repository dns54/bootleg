<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Installing

This page covers the first install. Later updates go through capsules: [updates.md](updates.md).

The jumper, the chip location and disassembly are on the board's page.

## Before you start

- Build the full image: [building.md](building.md)
- Back up the current ROM: read it twice and compare the two reads

```sh
flashprog -p <programmer> -r backup1.rom
flashprog -p <programmer> -r backup2.rom
diff backup1.rom backup2.rom
```

## Internal flashing

- Unlock the flash (board-specific: service jumper, BIOS Lock off)
- Boot Linux without kernel lockdown (lockdown blocks flashprog)

```sh
flashprog -p internal -w bootleg-<board>-<version>.rom
```

- Cut power after `VERIFIED`: stock firmware may write EFI variables on shutdown

## External flashing

- Remove all power
- The programmer must drive 3.3 V on the data lines (many cheap CH341A units drive 5 V)

```sh
flashprog -p ch341a_spi -w bootleg-<board>-<version>.rom
```

## Recovery

- Flash the backup or a known-good image externally
