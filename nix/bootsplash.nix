# SPDX-License-Identifier: MIT
{ runCommand, imagemagick }:

runCommand "bootleg-bootsplash.bmp" { nativeBuildInputs = [ imagemagick ]; } ''
  magick ${../assets/logo.png} -background black -flatten -monochrome BMP3:$out
''
