# SPDX-License-Identifier: MIT
{
  lib,
  runCommand,
  fetchurl,
  unzip,
  python3,
  inputs,
  deguard,
}:
{
  platform,
  deguardDelta ? null,
  sha512,
}:
let
  donors = {
    sklkbl-h = {
      src = fetchurl {
        name = "H110M-DGS-7.30.zip";
        urls = [
          "https://download.asrock.com/BIOS/1151/H110M-DGS(7.30)ROM.zip"
          "https://web.archive.org/web/20230822134231/https://download.asrock.com/BIOS/1151/H110M-DGS(7.30)ROM.zip"
        ];
        sha512 = "976bbb1e625f64df276d8343757d910c88b8a781f953bc2c41a7dd15184ec70d55f8081de2a0aaa83cddb8e73bdc2df6288fde6e0897e4928c48ca4bb30bea2d";
      };
      nativeBuildInputs = [ unzip ];
      unpack = src: ''
        unzip ${src}
        image=H11MDGS7.30
      '';
      clean = "-w MFS -O cleaned.rom -M me.bin";
      deguard = "--version 11.6.0.1126 --pch H --sku 2M";
    };
  };

  donor = donors.${platform} or (throw "intel-me: no donor for ${platform}");
in
assert lib.assertMsg (
  deguardDelta == null || donor ? deguard
) "intel-me: deguard doesn't support the ${platform} ME";
runCommand "me-${platform}${lib.optionalString (deguardDelta != null) "-${deguardDelta}"}.bin"
  {
    nativeBuildInputs = [
      python3
    ]
    ++ donor.nativeBuildInputs
    ++ lib.optional (deguardDelta != null) deguard;
  }
  (
    donor.unpack donor.src
    + ''
      python3 ${inputs.coreboot}/util/me_cleaner/me_cleaner.py -t ${donor.clean} "$image"
    ''
    + (
      if deguardDelta == null then
        "cp me.bin $out\n"
      else
        ''
          deguard ${donor.deguard} \
            --delta ${deguard}/share/deguard/data/delta/${deguardDelta} \
            --fake-fpfs ${deguard}/share/deguard/data/fpfs/zero \
            --input me.bin --output $out
        ''
    )
    + ''
      echo "${sha512}  $out" | sha512sum -c
    ''
  )
