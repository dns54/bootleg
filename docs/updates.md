<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Updates

- Signed UEFI capsule, capsule-on-disk, ESRT
- Rewrites only the `COREBOOT` region. Descriptor, ME, EFI variables, flash layout unchanged
- Works with BIOS Lock on: SMM allows full-flash writes only in a boot where the OS requested an update
- EDK2 resets at the end of the update boot, before booting anything
- Independent of the bootloader and Secure Boot
- Refuses older versions (`YYMMDDHHMM`, the commit date)

## fwupd

Each push to `main` publishes a release: the signed capsule, its fwupd cabinet, and the
metadata (`firmware.xml.zst` plus `.jcat`). fwupd trusts both once it has bootleg's root and
intermediate certificates:

```sh
for d in /etc/pki/fwupd /etc/pki/fwupd-metadata; do
  sudo install -Dm644 -t $d keys/capsule-root.pem keys/capsule-intermediate.pem
done
sudo tee /etc/fwupd/remotes.d/bootleg.conf <<'EOF'
[fwupd Remote]
Enabled=true
Title=bootleg
MetadataURI=https://github.com/dns54/bootleg/releases/latest/download/firmware.xml.zst
EOF
fwupdmgr refresh
fwupdmgr update
```

## Manual

Copy the capsule (`.cap` from the release) to `\EFI\UpdateCapsule\` on the ESP, set bit 2 of
`OsIndications`, and reboot. With the ESP at `/boot`:

```sh
sudo install -Dm644 -t /boot/EFI/UpdateCapsule bootleg-*.cap
v=/sys/firmware/efi/efivars/OsIndications-8be4df61-93ca-11d2-aa0d-00e098032b8c
[ -e $v ] && sudo chattr -i $v
printf '\x07\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00' | sudo tee $v > /dev/null
sudo reboot
```

- EDK2 finds the ESP through the first active boot entry: it must name a file on the ESP

## Signing

CI signs with `.github/release.sh`, which runs EDK2's `GenerateCapsule.py` and builds the
cabinet and metadata. To sign by hand with your own keys:

```sh
nix build .#<board>-capsule
CAPSULE_SIGNER="$(<signer.pem)" GITHUB_REPOSITORY=<owner>/<repo> \
  nix shell --inputs-from . nixpkgs#libjcat nixpkgs#gcab nixpkgs#zstd nixpkgs#python3 \
  nixpkgs#openssl nixpkgs#jq nixpkgs#gnutar nixpkgs#xz -c .github/release.sh <board>
```

- Chain: root (`keys/capsule-root.pem`, built into the ROM) → intermediate
  (`keys/capsule-intermediate.pem`) → signer, which signs both the capsule and the fwupd files
- `signer.pem` holds the signer key and certificate. CI has it as the `CAPSULE_SIGNER` secret
- The root and intermediate keys stay offline
- A leaked signer can't be revoked: the firmware accepts any certificate under the root, and
  doesn't check expiry. With it and root access, anyone can install their own capsule, even one
  with a version high enough to block later updates. To recover, make a new root and chain, and
  release firmware that trusts the new root, signed with the old chain. A machine stays exposed
  until it runs that release

## Risks and limits

- A ROM built from your own commit has that commit's date as its version. Releases from older
  commits aren't offered until upstream commits after it; flash a release to get back on track
- One firmware copy: power loss during the write (about one minute) needs an external programmer
- Not by capsule: flash layout, descriptor, ME. Use internal flashing with BIOS Lock off, or external
