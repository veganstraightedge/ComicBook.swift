//
// CBR.swift
// ComicBook
//

import ComicInfo
import Foundation
import Unrar

/// Adapter for CBR (RAR) archives.
///
/// Read-only (RAR creation is proprietary), decoded in-process by Unrar.swift (RARLAB's unrar code),
/// so it works on both macOS and iOS.
struct CBR: ComicBookAdapter {
  let path: String

  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("CBR archiving not supported (RAR is proprietary)")
  }

  /// Every file member of the archive, as Entries (paths are the in-archive entry names).
  func entries() throws -> [ComicBook.Entry] {
    try fileEntries(in: try openForReading()).map { ComicBook.Entry(path: $0.fileName) }
  }

  /// Read `ComicInfo.xml` from the archive, if present.
  func info() throws -> ComicBook.Info? {
    let archive = try openForReading()
    guard let entry = try fileEntries(in: archive).first(where: { $0.fileName == "ComicInfo.xml" }) else {
      return nil
    }
    let data = try read(entry, from: archive)
    guard let xml = String(data: data, encoding: .utf8) else { return nil }
    return try ComicInfo.load(fromXML: xml)
  }

  /// Extract the archive into a folder (default `<basename>.cb`).
  ///
  /// Returns the destination path.
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    let destination = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb", to: options.to)
    let destinationURL = URL(fileURLWithPath: destination).standardizedFileURL

    do {
      let archive = try openForReading()
      try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
      for entry in try fileEntries(in: archive) {
        if options.imagesOnly && !ComicBook.isImageFile(entry.fileName) { continue }
        let fileURL = destinationURL.appendingPathComponent(entry.fileName).standardizedFileURL
        // Refuse entries that would land outside the destination (`../` in the entry name).
        guard fileURL.path.hasPrefix(destinationURL.path + "/") else {
          throw ComicBookError.extractionError("Refusing to extract '\(entry.fileName)' outside the destination")
        }
        try FileManager.default.createDirectory(
          at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try read(entry, from: archive).write(to: fileURL)
      }
    } catch let error as ComicBookError {
      throw error
    } catch {
      throw ComicBookError.extractionError(error.localizedDescription)
    }

    if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
    return destination
  }

  private func openForReading() throws -> Unrar.Archive {
    do {
      return try Unrar.Archive(path: path)
    } catch {
      throw ComicBookError.extractionError("Could not open '\(path)': \(error)")
    }
  }

  private func fileEntries(in archive: Unrar.Archive) throws -> [Unrar.Entry] {
    do {
      return try archive.entries().filter { !$0.directory }
    } catch {
      throw ComicBookError.extractionError("Could not list '\(path)': \(error)")
    }
  }

  private func read(_ entry: Unrar.Entry, from archive: Unrar.Archive) throws -> Data {
    do {
      return try archive.extract(entry)
    } catch {
      throw ComicBookError.extractionError("Could not extract '\(entry.fileName)' from '\(path)': \(error)")
    }
  }
}
