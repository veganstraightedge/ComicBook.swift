//
// ImageFile.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// Recognized image file extensions (lowercased, with leading dot), matching the Ruby gem.
  static let imageExtensions: Set<String> = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"]

  /// True if the given file name has a recognized image extension (case-insensitive).
  static func isImageFile(_ name: String) -> Bool {
    let ext = "." + (name as NSString).pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }

  /// Recursively collect image files under `directory` as `(relativePath, fileURL)` pairs, sorted by
  /// relative path. Used by the archivers (archiving includes images only, matching the Ruby gem).
  static func imageFiles(in directory: URL) -> [(relativePath: String, fileURL: URL)] {
    let fileManager = FileManager.default
    let base = directory.resolvingSymlinksInPath()
    let baseComponentCount = base.pathComponents.count
    guard let enumerator = fileManager.enumerator(at: base, includingPropertiesForKeys: nil) else {
      return []
    }

    var results: [(relativePath: String, fileURL: URL)] = []
    for case let url as URL in enumerator where isImageFile(url.lastPathComponent) {
      let relative = url.resolvingSymlinksInPath().pathComponents.dropFirst(baseComponentCount).joined(separator: "/")
      results.append((relative, url))
    }
    return results.sorted { $0.relativePath < $1.relativePath }
  }
}
