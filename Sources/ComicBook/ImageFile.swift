//
// ImageFile.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// Recognized image file extensions (lowercased, with leading dot), matching the Ruby gem.
  static let imageExtensions: Set<String> = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"]

  /// The file extensions that count as page images, lowercased, without dots, in alphabetical order.
  public static let imageFileExtensions: [String] = imageExtensions.map { String($0.dropFirst()) }.sorted()

  /// Metadata sidecar filenames included by the `.imagesAndInfo` archive mode (lowercased).
  static let infoFilenames: Set<String> = ["comicinfo.xml", "metroninfo.xml"]

  /// True if the given file name or path has a recognized image extension (case-insensitive).
  public static func isImageFile(_ name: String) -> Bool {
    let ext = "." + (name as NSString).pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }

  /// True if `path` is something macOS added to an archive, not part of the comic.
  ///
  /// That is an AppleDouble member (`._page1.jpg`, which `tar` writes beside a file that has
  /// extended attributes) or anything in a `__MACOSX` folder (where Finder's Compress puts the
  /// same data). Such members are never listed, counted as pages, or extracted.
  static func isMacOSMetadata(_ path: String) -> Bool {
    path.split(separator: "/").contains { $0 == "__MACOSX" || $0.hasPrefix("._") }
  }

  /// True if the given file name is a ComicInfo.xml / MetronInfo.xml sidecar (case-insensitive).
  static func isInfoFile(_ name: String) -> Bool {
    infoFilenames.contains(name.lowercased())
  }
}
