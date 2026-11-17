#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Signs the capsule in ./result (nix build .#<board>-capsule) and writes the release files to
# ./dist: the capsule, its fwupd cabinet, the fwupd metadata with its .jcat, and the complete
# source with the third-party licence notice.
# Usage: release.sh <board>. Needs CAPSULE_SIGNER (signer key + certificate, PEM) and
# GITHUB_REPOSITORY (owner/repo).
set -euo pipefail

board=$1
version=$(<result/capsule-version)
guid=$(<result/capsule-guid)
repo=${GITHUB_REPOSITORY,,}
id=io.github.${repo/\//.}.$board
url=https://github.com/$GITHUB_REPOSITORY/releases/download/$version
timestamp=$(git log -1 --format=%ct)
edk2=$(nix flake archive --json | jq -r .inputs.edk2.path)
keys=$PWD/keys

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
(umask 077 && printf '%s\n' "$CAPSULE_SIGNER" > "$work/signer.pem")
openssl pkey -in "$work/signer.pem" -out "$work/signer.key"
openssl x509 -in "$work/signer.pem" -out "$work/signer.crt"
sign() { jcat-tool self-sign --kind sha256 "$@" && jcat-tool sign "$@" "$work/signer.crt" "$work/signer.key"; }

mkdir -p dist
cap=bootleg-$board-$version.cap
PYTHONPATH=$edk2/BaseTools/Source/Python python3 \
  "$edk2/BaseTools/Source/Python/Capsule/GenerateCapsule.py" --encode --output "dist/$cap" \
  --guid "$guid" --capflag PersistAcrossReset --fw-version "$version" --lsv "$version" \
  --signer-private-cert "$work/signer.pem" --other-public-cert "$keys/capsule-intermediate.pem" \
  --trusted-public-cert "$keys/capsule-root.pem" \
  result/coreboot.rmap.rom

# Shared by the metainfo in the cabinet and the remote metadata.
component() {
  cat <<EOF
  <component type="firmware">
    <id>$id</id>
    <name>bootleg</name>
    <summary>coreboot firmware for the $board</summary>
    <description><p>coreboot and EDK2, built by bootleg.</p></description>
    <url type="homepage">https://github.com/$GITHUB_REPOSITORY</url>
    <metadata_license>MIT</metadata_license>
    <project_license>GPL-2.0-only</project_license>
    <developer_name>bootleg</developer_name>
    <provides><firmware type="flashed">$guid</firmware></provides>
    <custom>
      <value key="LVFS::VersionFormat">number</value>
      <value key="LVFS::UpdateProtocol">org.uefi.capsule</value>
    </custom>
    <releases>
      <release version="$version" timestamp="$timestamp">
        <description><p>Built from commit ${GITHUB_SHA:-$(git rev-parse HEAD)}.</p></description>
        $1
      </release>
    </releases>
  </component>
EOF
}

cab=bootleg-$board-$version.cab
mkdir "$work/cab"
cp "dist/$cap" "$work/cab/firmware.bin"
(
  cd "$work/cab"
  { echo '<?xml version="1.0" encoding="UTF-8"?>'
    component '<checksum type="sha256" filename="firmware.bin" target="content"/>'; } > firmware.metainfo.xml
  sign firmware.jcat firmware.bin
  sign firmware.jcat firmware.metainfo.xml
  gcab -c -n "$OLDPWD/dist/$cab" firmware.bin firmware.metainfo.xml firmware.jcat
)

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<components origin="bootleg">'
  component "<location>$url/$cab</location>
        <checksum type=\"sha256\" target=\"container\">$(sha256sum "dist/$cab" | cut -d' ' -f1)</checksum>
        <size type=\"download\">$(stat -c %s "dist/$cab")</size>"
  echo '</components>'
} | zstd -q -o dist/firmware.xml.zst
(cd dist && sign firmware.xml.zst.jcat firmware.xml.zst)

name=bootleg-$board-$version-source
src=$(nix build --no-link --print-out-paths ".#$board-capsule.source")
tar -C "$src" -cf - --sort=name --owner=0 --group=0 --numeric-owner --mtime="@$timestamp" \
  --transform "s|^\.|$name|" . | xz -T0 -6 > "dist/$name.tar.xz"
cp docs/third-party.md dist/THIRD-PARTY.md

echo "$version" > dist/version
