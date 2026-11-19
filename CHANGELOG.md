# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Mislabelled archives now open**: a comic's type is told from the bytes the file starts with, so a RAR named `.cbz` (common in the wild) loads with `type == .cbr` and is read as one. ZIP, RAR, 7-Zip, TAR, PDF and ACE are recognised. The extension still decides which files are comics at all (a `.zip` is refused as before) and is used when the contents are not recognised.

## [0.7.0] - 2026-11-18

### Changed

- **ComicInfo.swift 1.7.0** (was 1.5.0) is the minimum version.
- **`.cbt` is read and written with PLzmaSDK**, the library already used for `.cb7`. A `.cbt` is now read from disk instead of being loaded into memory whole. The files written are ordinary TAR archives, as before.

### Removed

- **SWCompression dependency** (and BitByteData, which came with it). Nothing else used it.

## [0.6.0] - 2026-11-16

### Added

- **`ComicBook.arrangePages(_:)`**: make a folder's page images exactly the given files, in order. Reorders, deletes, and adds pages of an extracted comic in one step: pages are renumbered `page_001…`, stay in the subfolder they were in, and the folder's `ComicInfo.xml` (if any) has its `<Page>` entries and `PageCount` updated to follow them.
- **Format support is public**, so apps need not keep their own lists. `ComicBook.ArchiveType` is `CaseIterable` and gains `isReadable` (everything but `.cba`), `isWritable` (`.cbz`, `.cb7`, `.cbt`, `.cb`), `fileExtension`, and `init?(fileExtension:)`.
- `ComicBook.imageFileExtensions` and a public `ComicBook.isImageFile(_:)`: the file extensions that count as page images.

### Changed

- **ComicInfo.swift 1.5.0** (was 1.3.0).

## [0.5.0] - 2026-11-16

### Fixed

- **The library now builds for iOS.** It declared iOS but could not build there, because ComicInfo.swift read and wrote XML with API that Foundation only has on macOS. CI now builds the library for iOS.

### Changed

- **ComicInfo.swift 1.3.0** (was 1.2.0), which builds for iOS.

- **CBR is now read in-process** with [Unrar.swift](https://github.com/mtgto/Unrar.swift) (RARLAB's unrar code) instead of spawning the bundled `lsar` / `unar` tools. No helper binaries ship with the package, nothing is copied to a cache, and the CBR code is no longer macOS-only. Directory members are no longer listed as entries, and an entry whose name would land outside the destination is refused.
- **Raised the minimum Swift toolchain to 6.4** (was 6.3) **and the minimum platforms to macOS / iOS 27** (was 26); `swift-tools-version`, `platforms`, and the documented requirements bumped to match. Building needs Xcode 27+.
- `platforms` now declares only macOS and iOS; the other Apple platforms are no longer declared or documented.
- CI runs on GitHub's `xcode-27` runner (macOS 27, in preview); there is no `macos-27` label yet.
- **PLzmaSDK 1.6.3** (was 1.6.2), our fork rebuilt on upstream's latest source (LZMA SDK build 1466, was 1448). `doc/plzmasdk-fork.md` documents the fork and how to sync it.

### Removed

- `ComicBook.rarToolsDirectory`: there are no helper tools left to point at.
- `ComicBookError.dependencyMissing`: nothing can throw it now.

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
