# SPDX-License-Identifier: MIT
{
  runCommand,
  makeWrapper,
  python3,
  inputs,
}:

runCommand "deguard" { nativeBuildInputs = [ makeWrapper ]; } ''
  mkdir -p $out/share
  cp -r ${inputs.deguard} $out/share/deguard
  makeWrapper ${python3.interpreter} $out/bin/deguard --add-flags $out/share/deguard/finalimage.py
''
