# SPDX-License-Identifier: MIT
{ runCommand, coreboot-utils }:
{
  pname,
  coreboot,
  me,
  platform,
  flashSize,
}:
let
  name = "${pname}-${coreboot.version}";
in
runCommand name
  {
    nativeBuildInputs = [ coreboot-utils ];
    meta.hydraPlatforms = [ ];
  }
  ''
    head -c ${flashSize} /dev/zero | tr '\0' '\377' > blank.rom
    dd if=${coreboot}/descriptor.bin of=blank.rom conv=notrunc status=none
    ifdtool -p ${platform} -i ME:${me} blank.rom -O me.rom
    mkdir $out
    ifdtool -p ${platform} -i BIOS:${coreboot}/bios.bin me.rom -O $out/${name}.rom

    ifdtool -p ${platform} -x $out/${name}.rom
    cmp flashregion_0_flashdescriptor.bin ${coreboot}/descriptor.bin
    cmp flashregion_1_bios.bin ${coreboot}/bios.bin
    cmp flashregion_2_intel_me.bin ${me}
    [ "$(dd if=flashregion_2_intel_me.bin bs=1 skip=16 count=4 status=none)" = '$FPT' ]
  ''
