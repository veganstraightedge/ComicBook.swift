# Agent

Dev-process and architecture notes for ComicBook.swift. Mirrors ComicInfo.swift's conventions.

## Project overview

- **Source**: the Ruby gem `comicbook` (at `../comicbook`). Swift target: this package.
- **Sibling**: ComicInfo.swift (`../ComicInfo.swift`), depended on for `ComicInfo.xml` parsing.
- TDD: small failing test → make pass → commit, staying green.

## Development

- Swift 6.2+, Swift Testing (not XCTest), `swift format` (2-space, `.swift-format`).
- `swift build` / `swift test` / `swift format lint --recursive Sources Tests`.
- One type per file; file header `//\n// File.swift\n// ComicBook\n//`.

## Architecture (CRITICAL — same pattern as ComicInfo.swift)

- `public enum ComicBook` is a **caseless namespace** enum. All domain types are nested and spread
  across files via `extension ComicBook { ... }` (Swift can't declare nested types in extensions of
  *other* files, so each file reopens the namespace).
- The one top-level type is `ComicBookError` (in `Errors.swift`), like `ComicInfoError`.
- `ComicBook.Comic` is the loaded comic (path + detected `ArchiveType`); the gem's `ComicBook` class.
- `ComicBook.Info` is a `typealias` for `ComicInfo.Issue` (the gem's `ComicBook::Info = ComicInfo::Issue`).
- Per-format adapters conform to the internal `ComicBookAdapter` protocol (`pages`/`info`/`archive`/
  `extract`). One file per format: `CB`, `CBZ`, `CBT`, `CB7`, `CBR`, `CBA`, `PDF`.

## Format strategy

| Format | Library | Notes |
|---|---|---|
| CBZ | ZIPFoundation | read + write |
| CBT | SWCompression (TAR) | read + write |
| CB7 | SWCompression (read) + `7zz` (write) | write shells out (macOS) |
| CBR | `lsar`/`unar` | read-only, shells out (macOS) |
| PDF | PDFKit / ImageIO | extract-only, native |
| CB / folder | FileManager | uncompressed |
| CBA | — | ACE; unimplemented stubs (matches gem) |

## Key behaviors (match the gem)

- Archiving is **images-only**; extraction is lossless unless `imagesOnly`.
- Default extract dir = `<basename>.cb`; default archive ext = `.cbz`.
- Page `path`: archive → entry name; `.cb` → relative; top-level folder → absolute.
- Image detection is extension-based, case-insensitive: `.jpg .jpeg .png .gif .bmp .webp`.

## Status & plan

See the umbrella `../PLAN.md` (full build plan + open decisions) and `../TODO.md`.
