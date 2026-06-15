# ComicBook.swift

A Swift package and CLI for reading, extracting, archiving, and inspecting comic book archives —
the Swift port of the Ruby [`comicbook`](https://github.com/veganstraightedge/comicbook) gem.

⚠️ Under construction.

## Features

- 📦 Read / extract / archive comic book archives: **`.cbz`**, **`.cbt`**, **`.cb`** folders.
- 🔎 List image **pages** and read **`ComicInfo.xml`** metadata (via ComicInfo.swift).
- 🧰 A `comicbook` command-line tool.
- 🚧 In progress: **`.cb7`** (7-Zip), **`.cbr`** (RAR, read-only), and **PDF**→images. `.cba` (ACE) unsupported.

## Requirements

- Swift 6.2+
- macOS 26+ / iOS 26+ (archiving/extracting shell-outs for CB7/CBR are macOS-only)

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/veganstraightedge/ComicBook.swift.git", from: "0.1.0")
]
```

## Library usage

```swift
import ComicBook

let comic = try ComicBook.load("Issue1.cbz")
print(comic.type)                 // .cbz
let pages = try comic.pages()     // [ComicBook.Page]
let info = try comic.info()       // ComicBook.Info? (== ComicInfo.Issue?)

// Extract into a folder (default <name>.cb)
let folder = try comic.extract()

// Archive a folder of images into a .cbz
let cbz = try ComicBook.archive("./pages", options: .init(to: "Issue1.cbz"))
```

Archiving includes image files only (matching the gem); extraction is lossless unless `imagesOnly`.

## CLI

```
comicbook extract <input> [--to <path>] [--dpi <n>] [--images-only] [--delete-original]
comicbook archive <folder> [--to <path>] [--delete-original]
comicbook info    <input> [--format verbose|terse|json|yaml] [--only F,F] [--except F,F]
comicbook pages   <input>
comicbook version
```

## License

MIT — see [LICENSE.md](LICENSE.md).

## Acknowledgments

- The [Anansi Project](https://anansi-project.github.io/) for the ComicInfo standard.
- [The Unarchiver](https://theunarchiver.com/) (`unar`/`lsar`) for RAR support.
