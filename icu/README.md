International Components for Unicode
------------------------------------

Wine's `icu.dll` (`dlls/icu`) only forwards its exports to `icuuc68.dll` and
`icuin68.dll`. Without those two (and `icudt68.dll`, their data) every .NET 5
or later program fails at start, because .NET finds `icu.dll` and takes the ICU
globalization path. The package therefore carries ICU 68.2's DLLs, the same
files Proton ships (its `icu/` folder and the ICU section of its `Makefile.in`).

**Project URL:** https://github.com/unicode-org/icu

**License:** `LICENSE` in this folder (also packaged as `share/wine/icu/LICENSE`)

**Source:** https://github.com/unicode-org/icu/tree/release-68-2

**Release:** https://github.com/unicode-org/icu/releases/tag/release-68-2

```
icu4c-68_2-Win64-MSVC2019.zip  4d17a70dab1059f333b1f321a8c7bcdb4b8bfbf7c5ac32705397af6da3a0c81a
icu4c-68_2-Win32-MSVC2019.zip  33d7603c7e59e81347583fce5b98ee53b66d5a87a5b6b12f906b6f7908868b69
```

`build-scripts/install-icu.sh` downloads both archives in CI, checks them, and
copies three DLLs from each, checked against the hashes Proton records:

```
c85a5848628cc5e17253e894bbea98868b76766714fe72673bd6ffefa0521f52  x86_64 icuuc68.dll
87956cf4f8f8eb9e1860628fc5ce31e762d85ad3cfddad0824f0d45aaa4d5d78  x86_64 icuin68.dll
cf4479a3f39d95c77058f39c5f49d104ec4f6d43e365aa13a2312066d2f5b024  x86_64 icudt68.dll
720c5009b6cc4ea641fc5bc803db9b425807989e8312512fc65b563268f284df  x86    icuuc68.dll
c7b8d528589f8e95e77ee42fe360b7d0be604bdb5ff2658d6ce15be2bec31d37  x86    icuin68.dll
fb652b4d18e452fae886f8fed404d6b430587e744a117ffaa32e05e73e839a97  x86    icudt68.dll
```

They go into `lib/wine/x86_64-windows` (`lib/wine/aarch64-windows` in the
arm64ec build, which, as in Proton, uses the x86_64 DLLs under emulation) and
`lib/wine/i386-windows`. A frontend that copies those folders into a new
prefix's `system32` and `syswow64` (droidtop's container setup, from GameNative, does) copies ICU
along. Wine does not load them as builtins from there: they carry no Wine
builtin mark, so they only load as native DLLs from the prefix.

Compilation
-----------

As Proton notes, the DLLs export C++ symbols, so building them needs MSVC or
clang on Windows; the Unicode Consortium's own builds are used instead.
