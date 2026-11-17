# SPDX-License-Identifier: MIT
{
  lib,
  stdenvNoCC,
  pkgsBuildBuild,
  coreboot-toolchain,
  gitMinimal,
  imagemagick,
  libuuid,
  openssl,
  python3,
  coreboot-utils,
  inputs,
  edk2,
  bootsplash,
  release,
  rev,
  sourceDate,
}:
{
  board,
  pname,
  descriptor,
  capsuleCert,
}:

let
  src = inputs.coreboot;
  version = "${release}+g${rev}";
  corebootVersion = "g${src.shortRev}";
in
stdenvNoCC.mkDerivation {
  inherit pname;
  inherit version;
  inherit src;

  patches =
    lib.filesystem.listFilesRecursive ../patches/coreboot
    ++ lib.optionals (builtins.pathExists (board + "/patches")) (
      lib.filesystem.listFilesRecursive (board + "/patches")
    );

  strictDeps = true;
  depsBuildBuild = [
    pkgsBuildBuild.stdenv.cc
    coreboot-toolchain.i386
    gitMinimal
    imagemagick
    libuuid
    openssl
    python3
    coreboot-utils
  ];
  enableParallelBuilding = true;

  postPatch = ''
    rm -r 3rdparty/intel-microcode
    cp -r ${inputs.microcode} 3rdparty/intel-microcode

    mkdir -p payloads/external/edk2/workspace
    cp -r ${edk2} payloads/external/edk2/workspace/mrchromebox
    chmod -R u+w 3rdparty/intel-microcode payloads/external/edk2/workspace

    patchShebangs util payloads/external/edk2/workspace/mrchromebox/BaseTools

    cp ${descriptor} descriptor.bin
  '';

  configurePhase = ''
    runHook preConfigure
    install -m644 ${board + "/defconfig"} .config
    export SOURCE_DATE_EPOCH=${toString sourceDate}
    printf 'CONFIG_DRIVERS_EFI_MAIN_FW_VERSION=0x%x\n' ${release} >> .config
    echo 'CONFIG_LOCALVERSION="bootleg ${version}"' >> .config
    cp ${bootsplash} logo.bmp
    echo 'CONFIG_EDK2_BOOTSPLASH_FILE="logo.bmp"' >> .config
    echo 'CONFIG_DRIVERS_EFI_CAPSULE_TRUSTED_PUBLIC_CERT="${capsuleCert}"' >> .config
    make olddefconfig

    if dropped=$(grep -E '^(CONFIG_|# CONFIG_.* is not set$)' ${board + "/defconfig"} | grep -vxF -f .config); then
      echo "olddefconfig dropped these defconfig lines:" >&2
      echo "$dropped" >&2
      exit 1
    fi
    runHook postConfigure
  '';

  makeFlags = [
    "KERNELVERSION=${corebootVersion}"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out .config

    ifdtool -x build/coreboot.rom
    cmp flashregion_0_flashdescriptor.bin ${descriptor}
    install -m644 flashregion_0_flashdescriptor.bin $out/descriptor.bin
    install -m644 flashregion_1_bios.bin $out/bios.bin

    python3 payloads/external/edk2/workspace/mrchromebox/UefiPayloadPkg/Tools/AppendRmapManifest.py \
      -r COREBOOT -o $out/coreboot.rmap.rom build/coreboot.rom
    sed -n 's/^CONFIG_DRIVERS_EFI_MAIN_FW_GUID="\(.*\)"$/\1/p' .config > $out/capsule-guid
    echo ${release} > $out/capsule-version
    runHook postInstall
  '';
}
