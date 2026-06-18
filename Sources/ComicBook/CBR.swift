//
// CBR.swift
// ComicBook
//

import ComicInfo
import Foundation

/// Adapter for CBR (RAR) archives.
///
/// Read-only (RAR creation is proprietary), via the bundled `lsar`/`unar` (macOS only — process
/// spawning is unavailable in the iOS/tvOS/watchOS sandbox).
struct CBR: ComicBookAdapter {
  let path: String

  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("CBR archiving not supported (RAR is proprietary)")
  }

  #if os(macOS)
    /// Every member of the archive, as Entries (paths are the names lsar reports).
    func entries() throws -> [ComicBook.Entry] {
      try CLIHelpers.lsarList(path).map { ComicBook.Entry(path: $0) }
    }

    /// Image pages inside the archive, sorted by basename.
    func pages() throws -> [ComicBook.Page] {
      try CLIHelpers.lsarList(path)
        .filter { ComicBook.isImageFile($0) }
        .map { ComicBook.Page(path: $0, name: ($0 as NSString).lastPathComponent) }
        .sorted { $0.name < $1.name }
    }

    /// Read `ComicInfo.xml` (extracting to a temp folder, since RAR has no random access here).
    func info() throws -> ComicBook.Info? {
      guard try CLIHelpers.lsarList(path).contains("ComicInfo.xml") else { return nil }
      let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: tempDir) }

      try CLIHelpers.unarExtract(path, to: tempDir.path)
      let xmlPath = tempDir.appendingPathComponent("ComicInfo.xml").path
      guard FileManager.default.fileExists(atPath: xmlPath) else { return nil }
      return try ComicInfo.load(from: xmlPath)
    }

    /// Extract the archive into a folder (default `<basename>.cb`).
    ///
    /// Returns the destination path.
    func extract(options: ComicBook.ExtractOptions) throws -> String {
      let destination = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb", to: options.to)
      do {
        try FileManager.default.createDirectory(
          at: URL(fileURLWithPath: destination), withIntermediateDirectories: true)
        try CLIHelpers.unarExtract(path, to: destination)
        if options.imagesOnly {
          // unar can't filter, so remove the non-images afterward (matching the gem).
          for entry in try CLIHelpers.lsarList(path) where !ComicBook.isImageFile(entry) {
            try? FileManager.default.removeItem(atPath: (destination as NSString).appendingPathComponent(entry))
          }
        }
      } catch let error as ComicBookError {
        throw error
      } catch {
        throw ComicBookError.extractionError(error.localizedDescription)
      }

      if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
      return destination
    }
  #else
    func entries() throws -> [ComicBook.Entry] {
      throw ComicBookError.notSupported("CBR (RAR) is only supported on macOS")
    }
    func pages() throws -> [ComicBook.Page] {
      throw ComicBookError.notSupported("CBR (RAR) is only supported on macOS")
    }
    func info() throws -> ComicBook.Info? {
      throw ComicBookError.notSupported("CBR (RAR) is only supported on macOS")
    }
    func extract(options: ComicBook.ExtractOptions) throws -> String {
      throw ComicBookError.notSupported("CBR (RAR) is only supported on macOS")
    }
  #endif
}
