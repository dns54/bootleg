# SPDX-License-Identifier: MIT
{
  lib,
  pkgs,
  inputs,
  release,
  rev,
  sourceDate,
}:
lib.makeScope pkgs.newScope (self: {
  inherit
    inputs
    release
    rev
    sourceDate
    ;
  edk2 = self.callPackage ./edk2.nix { };
  bootsplash = self.callPackage ./bootsplash.nix { };
  deguard = self.callPackage ./deguard.nix { };
  mkIntelMe = self.callPackage ./intel-me.nix { };
  mkCoreboot = self.callPackage ./coreboot.nix { };
  mkFullImage = self.callPackage ./image.nix { };
})
