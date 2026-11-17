# SPDX-License-Identifier: MIT
{
  description = "bootleg: coreboot for servers and homelabs";

  nixConfig = {
    extra-substituters = [ "https://bootleg.cachix.org" ];
    extra-trusted-public-keys = [ "bootleg.cachix.org-1:pZu08w/U/cxnjYWNxprVZRzpb8wf9vDBHfpWjxvMTZE=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    coreboot = {
      url = "git+https://review.coreboot.org/coreboot?submodules=1";
      flake = false;
    };
    edk2 = {
      url = "git+https://github.com/MrChromebox/edk2?submodules=1";
      flake = false;
    };
    microcode = {
      url = "github:intel/Intel-Linux-Processor-Microcode-Data-Files";
      flake = false;
    };
    deguard = {
      url = "git+https://review.coreboot.org/deguard";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      buildSystem = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${buildSystem};
      hostSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      bootleg = import ./nix {
        inherit lib pkgs inputs;
        # Commit date as YYMMDDHHMM (UTC); fits the 32-bit ESRT version until 2042.
        release = builtins.substring 2 10 self.lastModifiedDate;
        rev = self.shortRev or self.dirtyShortRev or "unknown";
        sourceDate = self.lastModified;
      };

      boards = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./boards));
      boardPackages =
        name: lib.filterAttrs (_: lib.isDerivation) (bootleg.callPackage (./boards + "/${name}") { });

      packages = lib.mergeAttrsList (map boardPackages boards);
    in
    {
      packages = lib.genAttrs hostSystems (_: packages);
    };
}
