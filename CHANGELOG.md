# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- See the umbrella `PLAN.md` and `TODO.md` for the remaining work and open decisions.
