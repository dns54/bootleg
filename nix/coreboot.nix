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
  version = "${release}+g${rev}";
  corebootVersion = "g${inputs.coreboot.shortRev}";

  # The complete source the firmware is built from, published with each release. The build below
  # runs from this tree, so anything pruned here that the build needs makes it fail.
  source = stdenvNoCC.mkDerivation {
    name = "${pname}-source";
    src = inputs.coreboot;

    patches =
      lib.filesystem.listFilesRecursive ../patches/coreboot
      ++ lib.optionals (builtins.pathExists (board + "/patches")) (
        lib.filesystem.listFilesRecursive (board + "/patches")
      );

    postPatch = ''
      rm -r 3rdparty/intel-microcode
      cp -r ${inputs.microcode} 3rdparty/intel-microcode

      w=payloads/external/edk2/workspace/mrchromebox
      mkdir -p $(dirname $w)
      cp -r ${edk2} $w
      cp -r ${edk2.ipxeSource} ipxe
      cp ${../docs/third-party.md} THIRD-PARTY.md
      chmod -R u+w .

      # Not used by this build.
      rm -r 3rdparty/{amd_blobs,arm-trusted-firmware,qc_blobs,opensbi,stm}
      find 3rdparty/fsp -maxdepth 1 -name '*FspBinPkg' ! -name KabylakeFspBinPkg -exec rm -r {} +
      # EDK2 checks that the include directories its .dec files declare exist, so keep those.
      rm -r $w/SecurityPkg/DeviceSecurity/SpdmLib/libspdm/os_stub/{openssllib,mbedtlslib} \
        $w/LvglPkg/Library/LvglLib/lvgl/{tests,docs,demos,examples} \
        $w/CryptoPkg/Library/OpensslLib/openssl/{test,fuzz} \
        $w/CryptoPkg/Library/MbedTlsLib/mbedtls/tests \
        $w/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli/tests
    '';

    dontConfigure = true;
    dontBuild = true;
    installPhase = "cp -r . $out";
    dontFixup = true;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname;
  inherit version;
  src = source;
  passthru = { inherit source; };

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
