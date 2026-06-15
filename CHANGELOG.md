# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial Swift port of the Ruby `comicbook` gem, mirroring ComicInfo.swift's architecture.
- **Core**: `ComicBook` namespace, `ComicBook.Comic` (load + type detection), `ComicBook.Page`,
  `ComicBook.Info` (= `ComicInfo.Issue`), and `ComicBookError`.
- **Operations**: `extract`, `archive`, `pages`, `info` across formats via a `ComicBookAdapter`.
- **CBZ** (ZIPFoundation), **CBT** (SWCompression TAR), and **CB**/folder (FileManager) adapters —
  full archive / extract / pages / info. Archiving is images-only, matching the gem.
- **PDF** adapter (CoreGraphics + ImageIO): list pages and extract each page to a JPEG (extract-only).
- **CLI** (`comicbook`, swift-argument-parser): `extract`, `archive`, `info`
  (verbose / terse / json / yaml, with `--only` / `--except`), `pages`, `version`.

### Pending

- CB7 (SWCompression read + `7zz` write) and CBR (`lsar`/`unar`, read-only) adapters are stubbed and
  throw "not yet ported". CBA (ACE) is unsupported, matching the gem.
- See `PLAN.md` and the umbrella `TODO.md` for the remaining work and open decisions.
