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
}
