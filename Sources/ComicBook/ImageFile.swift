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
}
