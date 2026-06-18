# ComicBook.swift

A Swift package and CLI for reading, extracting, archiving, and inspecting comic book archives.

A [`comicbook`](https://github.com/veganstraightedge/comicbook) Ruby gem is also available.

![Swift](https://img.shields.io/badge/swift-6.3%2B-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

⚠️ Under construction.

## Features

- 📦 Read / extract / archive comic book archives: **`.cbz`**, **`.cbt`**, **`.cb`** folders.
- 🔎 List image **pages** and read **`ComicInfo.xml`** metadata
  (via [ComicInfo.swift](https://github.com/veganstraightedge/ComicInfo.swift)).
- 🧰 A `comicbook` command-line tool.
- 🚧 In progress: **`.cb7`** (7-Zip), **`.cbr`** (RAR, read-only), and **PDF**→images. `.cba` (ACE) unsupported.

## Requirements

- Swift 6.3+
- macOS 26+ / iOS 26+ (archiving/extracting shell-outs for CB7/CBR are macOS-only)

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/veganstraightedge/ComicBook.swift.git", from: "0.3.0")
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

Archiving includes all files by default; `ArchiveOptions.contents` selects `.all` / `.imagesOnly` / `.imagesAndInfo` (images + `ComicInfo.xml` / `MetronInfo.xml`). Extraction is lossless unless `imagesOnly`.

## CLI

```sh
comicbook extract <input>  [--to <path>] [--dpi <n>] [--images-only] [--delete-original]
comicbook archive <folder> [--to <path>] [--delete-original]
comicbook info    <input>  [--format verbose|terse|json|yaml] [--only F,F] [--except F,F]
comicbook pages   <input>
comicbook version
```

## License

MIT — see [LICENSE.md](LICENSE.md).

## Acknowledgments

- The [Anansi Project](https://anansi-project.github.io/) for the ComicInfo standard.
- [The Unarchiver](https://theunarchiver.com/) (`unar`/`lsar`) for RAR support.
