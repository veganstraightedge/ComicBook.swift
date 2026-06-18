# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-06-18

Version jumps 0.2.0 → 0.4.0 to track the `comicbook` gem (0.3.0 was never released).

### Added
- `ComicBook.files(type:)` — list a comic's files, filtered by `.all` (default), `.images`, or `.imagesAndInfo` (images plus `ComicInfo.xml` / `MetronInfo.xml`), as `ComicBook.Entry` values that answer `isImage` / `isInfo`. Mirrors the `comicbook` gem 0.4.0.

### Changed
- **The loaded comic is now `ComicBook` itself, not `ComicBook.Comic`.** `ComicBook` is a `struct` you construct directly — `ComicBook(path:).pages()` — mirroring the gem's `ComicBook.new(path).pages`. `ComicBook.load(_:)` now returns a `ComicBook`. Nested types (`ComicBook.Page`, `ComicBook.Info`, …) and the static entry points are unchanged.
- **`archive` now includes every file in the source folder by default** (was images-only). `ArchiveOptions.contents` (a `ComicBook.Contents`) selects what to write: `.all` (default), `.images` (the previous behavior), or `.imagesAndInfo` (images plus `ComicInfo.xml` / `MetronInfo.xml`). Applies to CBZ / CBT / CB7; CB (folder) already keeps the whole folder. Mirrors the `comicbook` gem 0.4.0.
- Pages are ordered by full entry path; folder pages now use folder-relative paths (previously absolute), consistent with `.cb` and archive sources.

## [0.2.0] - 2026-06-17

### Changed
- **PLzmaSDK is now consumed by version, from a fork** ([veganstraightedge/PLzmaSDK](https://github.com/veganstraightedge/PLzmaSDK) `1.6.2`) with the `unsafeFlags` (`-fPIC`/`-fno-rtti`) removed. Those flags forced a `revision:` pin on PLzmaSDK, which made **ComicBook.swift itself unconsumable via `from:`** by downstream packages (SPM rejects depending by version on a package with a revision-pinned/unstable dependency). With the fork, ComicBook resolves cleanly via `from:`. No CB7 behavior change — read and write are unchanged.

## [0.1.0] - 2026-06-16

### Added

- Initial Swift port of the Ruby `comicbook` gem, mirroring ComicInfo.swift's architecture.
  Requires Swift 6.3+ (`swift-tools-version: 6.3`).
- **Core**: `ComicBook` namespace, `ComicBook.Comic` (load + type detection), `ComicBook.Page`,
  `ComicBook.Info` (= `ComicInfo.Issue`), and `ComicBookError`.
- **Operations**: `extract`, `archive`, `pages`, `info` across formats via a `ComicBookAdapter`.
- **CBZ** (ZIPFoundation), **CBT** (SWCompression TAR), and **CB**/folder (FileManager) adapters —
  full archive / extract / pages / info. Archiving is images-only, matching the gem.
- **CB7** adapter (PLzmaSDK — bundled LZMA SDK, **no system 7-Zip / Homebrew needed**): archive,
  extract, pages, info. Read and write.
- **CBR** adapter (read-only) via **bundled** `lsar`/`unar` (The Unarchiver, MPL) — pages, info,
  extract, with **no user install**. macOS only (process spawning). `ComicBook.rarToolsDirectory`
  lets a sandboxed app point at its own code-signed copies.
- **PDF** adapter (CoreGraphics + ImageIO): list pages and extract each page to a JPEG (extract-only).
- **CLI** (`comicbook`, swift-argument-parser): `extract`, `archive`, `info`
  (verbose / terse / json / yaml, with `--only` / `--except`), `pages`, `version`.

### Pending

- CBA (ACE) is unsupported, matching the gem. All other formats are implemented.
