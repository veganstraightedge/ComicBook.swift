# ComicBook.swift — Build Plan

> **STATUS — EXECUTED / largely complete (see CHANGELOG.md + ../TODO.md for the authoritative state).**
> All formats are implemented and committed (26 tests green): CB/folder, CBZ, CBT, CB7, CBR, PDF
> (CBA intentionally unimplemented). **Zero system/Homebrew deps.** Notable changes from this
> original plan during the build:
> - **CB7**: now **PLzmaSDK** (bundled LZMA SDK, read+write) — NOT the planned "SWCompression read +
>   `7zz` shell-out". Pinned to commit `f449bc3…` (1.6.1) due to PLzmaSDK's unsafe-flags SPM rule.
> - **CBR**: **bundled** `lsar`/`unar` (vendored, MPL, no user install) — not a system shell-out.
>   macOS-only; `ComicBook.rarToolsDirectory` override for sandboxed apps.
> - **PDF**: CoreGraphics/ImageIO (the plan already noted PDFKit-family over libvips).
> The sections below are the original pre-build plan, kept for context.

Swift port of the Ruby `comicbook` gem (v0.3.0), matching ComicInfo.swift's style/arch/testing.
**Working solo + autonomously. All commits on `main`. No pushes, no PRs.** Decisions that need
review are logged in the umbrella `../TODO.md` under "ComicBook.swift".

## What the Ruby gem does (the spec)

A library + CLI for comic-book archives. Top-level ops: **extract**, **archive**, **info**, **pages**.

Format matrix (port targets):

| Format | Ext            | Mechanism (Ruby)    | Swift approach                                | extract     | archive  | info  | pages |
| ------ | -------------- | ------------------- | --------------------------------------------- | ----------- | -------- | ----- | ----- |
| CBZ    | `.cbz`         | rubyzip             | **ZIPFoundation** 0.9.20                      | ✅          | ✅       | ✅    | ✅    |
| CBT    | `.cbt`         | stdlib TAR          | **SWCompression** 4.9.1 (TarContainer)        | ✅          | ✅       | ✅    | ✅    |
| CB7    | `.cb7`         | seven-zip (native)  | SWCompression (read 7z) + shell `7zz` (write) | ✅          | ✅\*     | ✅    | ✅    |
| CBR    | `.cbr`         | shell lsar/unar     | shell `lsar`/`unar` (read-only)               | ✅          | ❌       | ✅    | ✅    |
| CB     | `.cb` (folder) | uncompressed folder | FileManager                                   | ❌(already) | ✅(move) | ✅    | ✅    |
| PDF    | `.pdf`         | ruby-vips→jpg       | **PDFKit + ImageIO** (native, no dep)         | ✅          | ❌       | ⛔nil | ✅    |
| CBA    | `.cba`         | stubs raise         | stubs throw "not implemented"                 | ❌          | ❌       | ❌    | ❌    |

`*` CB7 write shells out to `7zz` (installed at /opt/homebrew/bin). If absent → throw with install hint.

## Dependencies (decisions — logged in umbrella TODO)

- **ZIPFoundation** `from: "0.9.20"` — CBZ read/write.
- **SWCompression** `from: "4.9.1"` — CBT (TAR read/write) + CB7 (7z read).
- **ComicInfo.swift** via **local path** `.package(path: "../ComicInfo.swift")` — `ComicBook.Info = ComicInfo.Issue`,
  parsing ComicInfo.xml found inside archives. (TODO: switch to URL once ComicInfo.swift is published/tagged.)
- **PDFKit / ImageIO** — system frameworks, no SPM dep. PDF→JPG (replaces Ruby's libvips).
- **swift-argument-parser** `from: "1.8.2"` — CLI (matches ComicInfo.swift).
- CBR: shell out to `lsar`/`unar` (system PATH, like the gem's Linux path). Not vendoring binaries (TODO).
- CB7 write: shell out to `7zz`.

## Architecture (mirror ComicInfo.swift exactly)

- Namespace: `public enum ComicBook` (caseless, pure namespace). Nested types via `extension ComicBook { ... }`.
- One top-level error type: `ComicBookError` (in `Errors.swift`), like `ComicInfoError`.
- Per-type files, each with the `//\n// File.swift\n// ComicBook\n//` header.
- Library target `ComicBook`, CLI target `ComicBookCLI` → binary `comicbook`, tests `ComicBookTests`.
- Package.swift: tools 6.2, platforms `.v26` ×4, `resources: [.copy("Fixtures")]`.
- Swift Testing (`import Testing`, `@Test`, `#expect`, `struct XTests`), `loadFixture` helper via `Bundle.module`.
- `.swift-format`, `.gitignore`, `.github/workflows/ci.yml`, `Makefile`, `scripts/install.sh`, README/AGENT/
  CHANGELOG/LICENSE(MIT)/CODE_OF_CONDUCT — copied from ComicInfo.swift with name substitutions.
  FIX the stale `script/build`/`script/run` (drop Longbox/xcodebuild → `swift build`/`swift run comicbook`)
  and `script/lint`/`script/format` dir loop (point at Sources/Tests).

## Source layout

```
Sources/ComicBook/
  ComicBook.swift     namespace + load/archive/extract entry points, type detection
  Errors.swift        ComicBookError
  Version.swift       ComicBook.Version.current
  Page.swift          Page value type (path, name)
  Adapter.swift       Adapter protocol (archive/extract/pages/info)
  ImageFile.swift     IMAGE_EXTENSIONS + image detection + glob helpers
  Info.swift          typealias ComicBook.Info = ComicInfo.Issue
  CB.swift            folder adapter (+ Archiver/Extractor)
  CBZ.swift           ZIPFoundation adapter (+ Archiver/Extractor)
  CBT.swift           SWCompression TAR adapter
  CB7.swift           SWCompression read + 7zz write adapter
  CBR.swift           lsar/unar read-only adapter
  CBA.swift           stubs (throw notImplemented)
  PDF.swift           PDFKit extractor
  CLIHelpers.swift    shell-out helpers (lsar/unar/7zz via Process)
Sources/ComicBookCLI/
  main.swift          argument-parser CLI: extract / archive / info (+ version)
```

## Key behaviors to replicate faithfully

- Type detection: dir ending `.cb` → `.cb`; other dir → `:folder`; file ext → format; else throw.
- **Archiving is images-only** (glob `*.{jpg,jpeg,png,gif,bmp,webp}`, recursive, sorted) — ComicInfo.xml/other
  files are NOT carried into a new archive. Extraction is lossless unless `imagesOnly`.
- Default extract dir = `<basename>.cb`; default archive ext = format native (default `.cbz`).
- Options: `to`, `extension`, `deleteOriginal`, `imagesOnly`, `dpi` (pdf). All return the output path.
- `info` returns `ComicBook.Info?` (= `ComicInfo.Issue?`) or nil; reads `ComicInfo.xml` entry.
- Page `path` semantics: archive→entry name; CB→relative; top-level folder→absolute. Sorted by name.
- Image detection: extension-based, case-insensitive: `.jpg .jpeg .png .gif .bmp .webp`.
- PDF: 1-indexed `page_%03d.jpg`, default 300 dpi, extract-only, info always nil.
- CBR: lsar first output line is the archive header → drop it. unar flags `-o <dst> -f -D`.
- Errors: single `ComicBookError` (+ propagate ComicInfoError). CLI catches all → `"Error: …"` + exit 1.

## CLI (subcommands, argument-parser)

`comicbook extract <input> [--to] [--dpi] [--images-only] [--delete-original]`
`comicbook archive <folder> [--to] [--delete-original]` (reject .cbr/.cba targets)
`comicbook info <input> [--format verbose|terse|json|yaml] [--only F,F] [--except F,F]`
`comicbook pages <input>` (gem exposes pages via lib; add a CLI subcommand for parity/utility)
`comicbook version` + auto `--help`/`--version`.
Decision: add `pages` as a CLI subcommand (gem has it on the library; surfacing it is useful) — logged in TODO.

## Build order (commit each milestone, build+test green between)

1. ✅ repo + PLAN.md ← (this commit)
2. Scaffold: Package.swift, configs, CI, scripts, docs, empty Sources/Tests that compile.
3. Core: ComicBook namespace, Error, Version, Page, Adapter, ImageFile, Info, type detection. Tests.
4. CB (folder) adapter. Tests + fixtures.
5. CBZ (ZIPFoundation). Tests + fixtures.
6. CBT (SWCompression). Tests.
7. PDF (PDFKit). Tests.
8. CB7 (read + 7zz). Tests.
9. CBR (lsar/unar). Tests.
10. CBA stubs. Tests.
11. CLI (all subcommands). Smoke tests.
12. Fixtures generation script + integration tests + README/AGENT/CHANGELOG fill-in.

Fixtures: generate `.cbz/.cbt/.cb7` test archives from source dirs (simple/mixed/nested/text_only/empty/
with_comicinfo) via a `scripts/make-fixtures` Ruby/Swift script (committed) so they're reproducible; CBR
fixtures must be pre-made (can't create RAR) — note if missing.

## Open decisions (also in umbrella TODO)

- Local-path dep on ComicInfo.swift vs waiting for a published version.
- CB7 write via `7zz` shell-out (vs read-only). CBR read via system `lsar`/`unar` (vs vendoring binaries).
- PDFKit/ImageIO instead of libvips (different engine; output should be equivalent JPGs).
- Whether to keep CLI-side validation duplication (gem does) or rely on the model.
- `pages` as a CLI subcommand (gem only has it in the library).
- Delete the empty `../ComicBook.swift [TODO]/` placeholder dir.
