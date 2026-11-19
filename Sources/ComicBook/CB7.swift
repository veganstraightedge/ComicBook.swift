//
// CB7.swift
// ComicBook
//

import Foundation

/// Adapter for CB7 (7-Zip) archives, backed by PLzmaSDK (bundled LZMA SDK — no system 7z needed).
struct CB7: ComicBookAdapter {
  let path: String

  private var archive: PLzmaArchive {
    PLzmaArchive(path: path, fileType: .sevenZ, fileExtension: "cb7")
  }

  /// Every file member of the archive, as Entries (paths are the in-archive entry names).
  func entries() throws -> [ComicBook.Entry] {
    try archive.entries()
  }

  /// Read `ComicInfo.xml` from the archive, if present.
  func info() throws -> ComicBook.Info? {
    try archive.info()
  }

  /// Create a CB7 from the source folder's files (filtered by `options.contents`).
  ///
  /// Returns the output path.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    try archive.archive(options: options)
  }

  /// Extract the archive into a folder (default `<basename>.cb`).
  ///
  /// Returns the destination path.
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    try archive.extract(options: options)
  }
}
