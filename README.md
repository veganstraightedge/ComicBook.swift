# ComicBook.swift

A Swift package and CLI for reading, extracting, archiving, and inspecting comic book archives.

A [`comicbook`](https://github.com/veganstraightedge/comicbook) Ruby gem is also available.

![Swift](https://img.shields.io/badge/swift-6.4%2B-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

⚠️ Under construction.

## Features

- 📦 Read / extract / archive comic book archives: **`.cbz`**, **`.cbt`**, **`.cb7`** (7-Zip), **`.cb`** folders.
- 📤 Extract only: **`.cbr`** (RAR) and **PDF**→images. `.cba` (ACE) is unsupported.
- 🔎 List image **pages** and read **`ComicInfo.xml`** metadata
  (via [ComicInfo.swift](https://github.com/veganstraightedge/ComicInfo.swift)).
- 🧰 A `comicbook` command-line tool.

## Requirements

- Swift 6.4+
- macOS 27+ / iOS 27+

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/veganstraightedge/ComicBook.swift.git", from: "0.9.0")
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

Reorder, delete, and add pages of an extracted comic, then archive it again:

```swift
let extracted = try ComicBook.load(folder)
// Each source is a page already in the folder (relative path) or any image file (absolute path).
try extracted.arrangePages(["page3.jpg", "page1.jpg", "/Users/me/Desktop/extra.png"])
try extracted.archive(options: .init(to: "Issue1.cbz"))
```

Pages are renumbered `page_001…` in the given order, page images left out are deleted, and a `ComicInfo.xml` in the folder has its `<Page>` entries and `PageCount` updated to match.

Pass a template to name the page files another way. It can use `{page}` and the comic's details, and the names always sort in page order:

```swift
try extracted.arrangePages(sources, template: "{series}_{number:3}_{page:4}")  // Saga_007_0001.jpg …
```

A comic's `type` comes from what the file contains, not its extension, so a mislabelled archive still opens:

```swift
try ComicBook.load("Actually-a-RAR.cbz").type         // .cbr
```

Which formats can be opened or written is public, as is what counts as a page image:

```swift
ComicBook.ArchiveType.allCases.filter(\.isReadable)   // every type but .cba
ComicBook.ArchiveType.allCases.filter(\.isWritable)   // .cb, .cb7, .cbt, .cbz
ComicBook.ArchiveType(fileExtension: "CBR")           // .cbr
ComicBook.imageFileExtensions                         // ["bmp", "gif", "jpeg", "jpg", "png", "webp"]
ComicBook.isImageFile("page1.JPG")                    // true
```

Archiving includes all files by default; `ArchiveOptions.contents` selects `.all` / `.images` / `.imagesAndInfo` (images + `ComicInfo.xml` / `MetronInfo.xml`). Extraction is lossless unless `imagesOnly`.

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
- [Unrar.swift](https://github.com/mtgto/Unrar.swift) and RARLAB's [UnRAR](https://www.rarlab.com/rar_add.htm) source for RAR support. UnRAR source code may be used in any software to handle RAR archives without limitations free of charge, but cannot be used to develop RAR (WinRAR) compatible archiver and to re-create RAR compression algorithm, which is proprietary.
