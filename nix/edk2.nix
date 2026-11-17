# SPDX-License-Identifier: MIT
{
  lib,
  runCommand,
  gitMinimal,
  ipxe,
  inputs,
}:
let
  ipxeDriver = ipxe.override {
    enableDefaultPlatformTargets = false;
    additionalTargets."bin-x86_64-efi/ipxe.efidrv" = null;
    firmwareBinary = "ipxe.efidrv";
    additionalOptions = [ "EFI_DOWNGRADE_UX" ];
  };
in
runCommand "edk2-bootleg-src"
  {
    nativeBuildInputs = [ gitMinimal ];
    # iPXE as configured for the driver above (GPL-2.0 source for the release).
    passthru.ipxeSource = ipxeDriver.overrideAttrs {
      name = "ipxe-bootleg-source";
      dontBuild = true;
      installPhase = "cp -r . $out";
      dontFixup = true;
    };
  }
  ''
  cp -r ${inputs.edk2} $out
  chmod -R u+w $out
  for p in ${lib.concatStringsSep " " (lib.filesystem.listFilesRecursive ../patches/edk2)}; do
    git -C $out apply $p
  done
  install -Dm644 -t $out/UefiPayloadPkg/NetworkDrivers ${ipxeDriver}/ipxe.efidrv
''
