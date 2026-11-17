<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Updates

- Signed UEFI capsule, capsule-on-disk, ESRT
- Rewrites only the `COREBOOT` region. Descriptor, ME, EFI variables, flash layout unchanged
- Works with BIOS Lock on: SMM allows full-flash writes only in a boot where the OS requested an update
- EDK2 resets at the end of the update boot, before booting anything
- Independent of the bootloader and Secure Boot
- Refuses older versions (`YYMMDDHHMM`, the commit date)

## fwupd

<!-- TODO: remote config: releases/latest/download/firmware.xml.zst + .jcat -->

```sh
fwupdmgr refresh
fwupdmgr update
```

## Manual

- Copy the capsule to `\EFI\UpdateCapsule\` on the ESP
- Set bit 2 of `OsIndications`
- Reboot

<!-- TODO: commands -->

- EDK2 finds the ESP through the first active boot entry: it must name a file on the ESP

## Signing

Sign with EDK2's `GenerateCapsule.py` (`BaseTools/Source/Python/Capsule/` in an EDK2 checkout).
The GUID and version must match the ROM, so take them from the build output:

```sh
nix build .#<board>-capsule
v=$(<result/capsule-version)
PYTHONPATH=edk2/BaseTools/Source/Python python3 \
  edk2/BaseTools/Source/Python/Capsule/GenerateCapsule.py --encode --output out.cap \
  --guid "$(<result/capsule-guid)" --capflag PersistAcrossReset \
  --fw-version "$v" --lsv "$v" \
  --signer-private-cert signer.pem --other-public-cert intermediate.pub.pem \
  --trusted-public-cert root.pub.pem \
  result/coreboot.rmap.rom
```

- The ROM trusts `keys/capsule-root.pem`
- Private keys stay outside the repo

## Risks and limits

- One firmware copy: power loss during the write (about one minute) needs an external programmer
- Not by capsule: flash layout, descriptor, ME. Use internal flashing with BIOS Lock off, or external
