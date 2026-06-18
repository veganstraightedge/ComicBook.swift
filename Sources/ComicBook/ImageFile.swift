//
// ImageFile.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// Recognized image file extensions (lowercased, with leading dot), matching the Ruby gem.
  static let imageExtensions: Set<String> = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"]

  /// Metadata sidecar filenames included by the `.imagesAndInfo` archive mode (lowercased).
  static let infoFilenames: Set<String> = ["comicinfo.xml", "metroninfo.xml"]

  /// True if the given file name has a recognized image extension (case-insensitive).
  static func isImageFile(_ name: String) -> Bool {
    let ext = "." + (name as NSString).pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }

  /// True if the given file name is a ComicInfo.xml / MetronInfo.xml sidecar (case-insensitive).
  static func isInfoFile(_ name: String) -> Bool {
    infoFilenames.contains(name.lowercased())
  }

  /// The files under `directory` to archive for `contents`, as `(relativePath, fileURL)` pairs.
  ///
  /// Sorted by relative path; hidden files are skipped.
  static func archiveFiles(
    in directory: URL, contents: Contents
  ) -> [(relativePath: String, fileURL: URL)] {
    let fileManager = FileManager.default
    let base = directory.resolvingSymlinksInPath()
    let baseComponentCount = base.pathComponents.count
    guard
      let enumerator = fileManager.enumerator(
        at: base, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
    else {
      return []
    }

    var results: [(relativePath: String, fileURL: URL)] = []
    for case let url as URL in enumerator {
      let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
      guard !isDirectory else { continue }

      let name = url.lastPathComponent
      let include =
        switch contents {
        case .all: true
        case .images: isImageFile(name)
        case .imagesAndInfo: isImageFile(name) || isInfoFile(name)
        }
      guard include else { continue }

      let relative = url.resolvingSymlinksInPath().pathComponents.dropFirst(baseComponentCount).joined(separator: "/")
      results.append((relative, url))
    }
    return results.sorted { $0.relativePath < $1.relativePath }
  }
}
