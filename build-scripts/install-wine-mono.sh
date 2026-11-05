#!/bin/bash
# Puts Wine Mono into the packaged Wine tree, the way Proton does (the wine-mono section of its Makefile.in):
# the release tarball unpacked into share/wine/mono.
#
# Without it, a .NET Framework program (XNA and FNA games among them) exits at once: mscoree finds no runtime
# in the prefix and none beside Wine. With it, mscoree loads the runtime straight from Wine's data folder
# (dlls/mscoree/metahost.c, get_mono_path_datadir: $WINEDATADIR\mono\wine-mono-<version>), so no prefix needs an
# install and a prefix made from a prebuilt prefix pack works too. The version is the one this tree's mscoree
# asks for (WINE_MONO_VERSION in dlls/mscoree/mscoree_private.h); the script refuses to package another.
#
# Usage: install-wine-mono.sh <packaged tree, e.g. $HOME/compiled-files-x86_64>
set -euo pipefail

out="${1:?packaged tree}"
root="$(cd "$(dirname "$0")/.." && pwd)"
version=10.4.1
sha256=a16606ef0724202e6a6848ece6e0cbba64d11e2f11aefe744af1d93c6d9f99bb

wanted=$(sed -n 's/^#define WINE_MONO_VERSION "\(.*\)"/\1/p' "$root/dlls/mscoree/mscoree_private.h")
if [ "$wanted" != "$version" ]; then
  echo "install-wine-mono.sh: mscoree asks for Wine Mono $wanted, this script packages $version; update both" >&2
  exit 1
fi

tarball="wine-mono-$version-x86.tar.xz"
work="${RUNNER_TEMP:-/tmp}/wine-mono"
mkdir -p "$work"
[ -f "$work/$tarball" ] || curl -fsSL --retry 4 -o "$work/$tarball" \
  "https://github.com/madewokherd/wine-mono/releases/download/wine-mono-$version/$tarball"
echo "$sha256  $work/$tarball" | sha256sum -c -

mkdir -p "$out/share/wine/mono"
tar --no-same-owner -xJf "$work/$tarball" -C "$out/share/wine/mono"
test -d "$out/share/wine/mono/wine-mono-$version/lib"
du -sh "$out/share/wine/mono/wine-mono-$version"
