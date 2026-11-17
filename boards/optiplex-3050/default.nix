# SPDX-License-Identifier: MIT
{
  runCommand,
  coreboot-utils,
  mkCoreboot,
  mkIntelMe,
  mkFullImage,
}:
let
  descriptor =
    runCommand "descriptor-optiplex-3050.bin" { nativeBuildInputs = [ coreboot-utils ]; }
      ''
        ifdtool -p sklkbl -M 1 ${./blobs/descriptor.bin} -O $out
        chmod u+w $out

        printf '\x00\x0f\xa0\x00' | dd of=$out bs=1 seek=$((0x80)) conv=notrunc

        printf '\x12\x01\xff\x0f\x01\x00\x11\x01' | dd of=$out bs=1 seek=$((0x44)) conv=notrunc

        printf '\xa0' | dd of=$out bs=1 seek=$((0x307)) conv=notrunc

        ifdtool -p sklkbl -d $out > layout.txt
        grep -q 'HAP bit is set' layout.txt
        grep -q 'Flash Region 1 (BIOS): 00112000 - 00ffffff' layout.txt
        grep -q 'FLMSTR1:   0x00a00f00' layout.txt
        [ "$(od -An -tx1 -j $((0x307)) -N1 $out | tr -d ' ')" = a0 ]
      '';

  coreboot = mkCoreboot {
    board = ./.;
    pname = "bootleg-optiplex-3050-capsule";
    inherit descriptor;
    capsuleCert = ../../keys/capsule-root.pem;
  };

  me = mkIntelMe {
    platform = "sklkbl-h";
    deguardDelta = "optiplex_3050";
    sha512 = "3231ddb79be81f0a631926fc0e533ee7bce2d10032d7d45e56ae8a9894bcf9b4ca0b4f6fd3bc4daa185a464e771e0bf3d1b771a3180739b6896cec911758145b";
  };
in
{
  optiplex-3050 = mkFullImage {
    pname = "bootleg-optiplex-3050";
    inherit coreboot me;
    platform = "sklkbl";
    flashSize = "16M";
  };
  optiplex-3050-capsule = coreboot;
}
