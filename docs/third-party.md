<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Third-party components

A bootleg capsule contains the components below. Each release has the complete source they are
built from (`bootleg-<board>-<version>-source.tar.xz`). The licence paths are relative to that
tarball's root.

| Component | Licence | In the source tarball |
|---|---|---|
| coreboot, with bootleg's patches | GPL-2.0-only, some files GPL-2.0-or-later or BSD | `COPYING`, `LICENSES/` |
| libgfxinit, libhwbase (graphics init) | GPL-2.0-or-later | `3rdparty/libgfxinit/COPYING`, `3rdparty/libhwbase/COPYING` |
| MrChromebox EDK2, with bootleg's patches | BSD-2-Clause-Patent, bundled libraries under their own | `payloads/external/edk2/workspace/mrchromebox/License.txt` |
| iPXE (UEFI network driver) | GPL-2.0-or-later, some files UBDL | `ipxe/COPYING*` |
| Intel FSP (Kaby Lake) | Intel FSP licence, binary | `3rdparty/fsp/FSP_License.pdf` |
| Intel microcode | Intel microcode licence, binary | `3rdparty/intel-microcode/license` |
| Video BIOS Table (OptiPlex 3050) | binary data from Dell's firmware, shipped in coreboot's tree | `src/mainboard/dell/sklkbl_desktops/variants/optiplex_3050/data.vbt` |

The Intel ME is not part of a capsule or a release. The full image adds it locally.
