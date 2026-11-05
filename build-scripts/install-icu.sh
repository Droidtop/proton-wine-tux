#!/bin/bash
# Puts ICU 68.2's DLLs (icuuc68, icuin68, icudt68) into the packaged Wine tree.
#
# Wine's icu.dll (dlls/icu, Proton commit 99d77fc "icu: Forward function to Unicode library v68",
# CW-Bug-Id 24402) only forwards its exports to icuuc68.dll and icuin68.dll. Without them every
# .NET 5+ program fails at start: .NET finds icu.dll, takes the ICU globalization path, and the
# forwarded exports do not resolve. Proton ships the same DLLs (its icu/ folder and the ICU section
# of its Makefile.in): The Unicode Consortium's own MSVC builds of release-68-2, because the DLLs
# export C++ symbols and cannot be built along with Wine. This script fetches those same release
# archives, checks them against the hashes Proton records in icu/README.md, and copies only the
# three DLLs that are needed.
#
# Placement: next to Wine's own PE modules, in lib/wine/<arch>-windows, so the container setup that
# copies those folders into a new prefix (system32 and syswow64) copies these too. Wine's loader does
# not take them as builtins there (they carry no "Wine builtin DLL" mark), so they load only as the
# native DLLs in the prefix, as on Windows and as in Proton. arm64ec gets the x86_64 build, as in
# Proton (its Makefile.in: "TODO: Build ICU for arm64(ec/x)"); x64 code runs under emulation there.
#
# Usage: install-icu.sh <packaged tree, e.g. $HOME/compiled-files-x86_64> <x86_64|arm64ec>
set -euo pipefail

out="${1:?packaged tree}"
arch="${2:?x86_64 or arm64ec}"
case "$arch" in
  x86_64) dir64=x86_64-windows ;;
  arm64ec) dir64=aarch64-windows ;;
  *) echo "install-icu.sh: unknown arch $arch" >&2; exit 1 ;;
esac

release=https://github.com/unicode-org/icu/releases/download/release-68-2
work="${RUNNER_TEMP:-/tmp}/icu-68.2"
mkdir -p "$work"

fetch() { # name sha256
  local f="$work/$1"
  [ -f "$f" ] || curl -fsSL --retry 4 -o "$f" "$release/$1"
  echo "$2  $f" | sha256sum -c -
}
fetch icu4c-68_2-Win64-MSVC2019.zip 4d17a70dab1059f333b1f321a8c7bcdb4b8bfbf7c5ac32705397af6da3a0c81a
fetch icu4c-68_2-Win32-MSVC2019.zip 33d7603c7e59e81347583fce5b98ee53b66d5a87a5b6b12f906b6f7908868b69

place() { # zip folder-in-zip destination "name sha256"...
  local zip="$1" from="$2" dest="$3"; shift 3
  mkdir -p "$dest"
  for entry in "$@"; do
    set -- $entry
    unzip -p "$work/$zip" "$from/$1" > "$dest/$1"
    echo "$2  $dest/$1" | sha256sum -c -
  done
}
# The hashes are the ones in Proton's icu/README.md for the same files.
place icu4c-68_2-Win64-MSVC2019.zip bin64 "$out/lib/wine/$dir64" \
  "icuuc68.dll c85a5848628cc5e17253e894bbea98868b76766714fe72673bd6ffefa0521f52" \
  "icuin68.dll 87956cf4f8f8eb9e1860628fc5ce31e762d85ad3cfddad0824f0d45aaa4d5d78" \
  "icudt68.dll cf4479a3f39d95c77058f39c5f49d104ec4f6d43e365aa13a2312066d2f5b024"
place icu4c-68_2-Win32-MSVC2019.zip bin "$out/lib/wine/i386-windows" \
  "icuuc68.dll 720c5009b6cc4ea641fc5bc803db9b425807989e8312512fc65b563268f284df" \
  "icuin68.dll c7b8d528589f8e95e77ee42fe360b7d0be604bdb5ff2658d6ce15be2bec31d37" \
  "icudt68.dll fb652b4d18e452fae886f8fed404d6b430587e744a117ffaa32e05e73e839a97"

mkdir -p "$out/share/wine/icu"
cp "$(dirname "$0")/../icu/LICENSE" "$out/share/wine/icu/LICENSE"
ls -la "$out/lib/wine/$dir64"/icu*68.dll "$out/lib/wine/i386-windows"/icu*68.dll
