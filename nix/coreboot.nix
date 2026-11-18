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

      rm -r 3rdparty/{amd_blobs,arm-trusted-firmware,qc_blobs,opensbi,stm,blobs} 3rdparty/vboot/tests
      find 3rdparty/fsp -maxdepth 1 -name '*FspBinPkg' ! -name KabylakeFspBinPkg -exec rm -r {} +
      rm -r $w/SecurityPkg/DeviceSecurity/SpdmLib/libspdm/os_stub/{openssllib,mbedtlslib} \
        $w/LvglPkg/Library/LvglLib/lvgl/{tests,docs,demos,examples} \
        $w/CryptoPkg/Library/OpensslLib/openssl/{test,fuzz} \
        $w/CryptoPkg/Library/MbedTlsLib/mbedtls/tests \
        $w/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli/tests

      if grep -rlaZF '$FPT' . | xargs -0r grep -LIF '$FPT' | grep .; then
        echo "Intel ME firmware in the source" >&2
        exit 1
      fi
    '';

    dontConfigure = true;
    dontBuild = true;
    installPhase = "cp -r . $out";
    dontFixup = true;
  };

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

  boardConfig = ''
    install -m644 ${board + "/defconfig"} .config
    cp ${bootsplash} logo.bmp
    echo 'CONFIG_EDK2_BOOTSPLASH_FILE="logo.bmp"' >> .config
    echo 'CONFIG_DRIVERS_EFI_CAPSULE_TRUSTED_PUBLIC_CERT="${capsuleCert}"' >> .config
  '';

  payload = stdenvNoCC.mkDerivation {
    name = "${pname}-edk2";
    src = source;
    strictDeps = true;
    inherit depsBuildBuild;
    postPatch = "patchShebangs util payloads/external/edk2/workspace/mrchromebox/BaseTools";
    configurePhase = boardConfig + "make olddefconfig";
    buildPhase = "make build/UEFIPAYLOAD.fd";
    installPhase = "cp build/UEFIPAYLOAD.fd $out";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname;
  inherit version;
  src = source;
  passthru = { inherit source payload; };

  strictDeps = true;
  inherit depsBuildBuild;
  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs util

    cp ${descriptor} descriptor.bin
  '';

  configurePhase = ''
    runHook preConfigure
    ${boardConfig}
    export SOURCE_DATE_EPOCH=${toString sourceDate}
    printf 'CONFIG_DRIVERS_EFI_MAIN_FW_VERSION=0x%x\n' ${release} >> .config
    echo 'CONFIG_LOCALVERSION="bootleg ${version}"' >> .config
    echo 'CONFIG_PAYLOAD_FILE="${payload}"' >> .config
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
