# droidtop patches on top of GameNative/proton-wine

This fork exists so droidtop can carry Wine changes that upstream doesn't
need, while still tracking upstream's Android port. It is a real GitHub
fork of [GameNative/proton-wine](https://github.com/GameNative/proton-wine)
(itself a fork of ValveSoftware/wine), with a daily automated merge — see
`.github/workflows/sync-upstream.yml`, which fails loudly on a genuine
conflict rather than resolving one automatically.

Builds are produced by upstream's own `build-proton.yml` (Android/bionic,
SDK 28, 16KB pages, x86_64 + arm64ec). droidtop consumes the resulting
container pattern through gamenative-tux's
`container_files_download.json` manifest, which already supports
components fetched from arbitrary hosts — so shipping a patched Wine is a
manifest entry pointing at a build from this repository, alongside rather
than instead of the stock one.

## Why this fork exists

droidtop's standing problem is running games that live on **user-accessible
storage** — internal shared storage or an SD card — rather than in
app-private storage. That is a hard requirement on the droidtop side
(games must be reachable by the user, by other apps, and over MTP), and
it is exactly where Wine has been reported to fail.

Android mounts every `/storage/*` path `noexec`, which blocks not only
`execve()` but also **file-backed `mmap(PROT_EXEC)`** — the mapping Wine
performs when it loads a PE image's code sections. That is the same
constraint seen from two directions: "it's a memory-mapping problem" and
"it's the noexec mount flag" describe one root cause, not two.

## Patch status

**None yet — deliberately.** Diagnosis on real hardware is still
narrowing down which failure is actually being hit, and the candidates
need very different fixes:

| Hypothesis | Fix shape | Status |
|---|---|---|
| `mmap(PROT_EXEC)` refused on a `noexec` mount | Fall back to `PROT_READ` when the image will be translated by box64 anyway (the CPU never executes those pages), or stage code images into a `memfd_create()` region and map from there | Not yet confirmed on hardware |
| Wine prefix cannot live on exFAT | Nothing to patch — `symlink()` returns `ENOSYS` there; keep the prefix on ext4 and map the game in as a drive | Confirmed on-device: exFAT rejects symlinks |
| exFAT filename restrictions | Nothing to patch — `:` and `?` are rejected outright; needs handling at the install/copy layer | Confirmed on-device |

Building a Wine fork to fix an unconfirmed bug is the expensive way to
discover the guess was wrong, so patches land here only once a specific
failure has a captured syscall error behind it. This file is the marker
the sync workflow checks for, and the record of what has actually been
established rather than assumed.
