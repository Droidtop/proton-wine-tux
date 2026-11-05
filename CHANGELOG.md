# Changelog

All notable changes this fork makes are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Upstream's own
changes arrive through the upstream sync and are recorded in GameNative/proton-wine's history; the
fork does not cut versioned releases of its own, so its changes are recorded
under Unreleased.

## [Unreleased]

### Added

- ICU 68.2's DLLs (icuuc68, icuin68, icudt68) in the package, the same Unicode Consortium builds Proton ships: Wine's icu.dll forwards to them, and without them every .NET 5 or later program failed at start (2026-11-05).
- Wine takes its Windows locale and code pages from LC_ALL or LANG on Android: bionic's setlocale answers C.UTF-8 for every other locale, so a Japanese game's ja_JP.UTF-8 left Wine on en-US and code page 437 (2026-11-05).
- The daily upstream sync (2026-08-31), the same technique as in gamenative-tux, and a README on why the fork exists and what has actually been established (2026-08-31).

### Changed

- The release token is scoped to the release job and actions are pinned by commit (2026-09-24).
