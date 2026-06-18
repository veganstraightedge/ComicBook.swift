//
// CBT.swift
// ComicBook
//

import ComicInfo
import Foundation
import SWCompression

/// Adapter for CBT (TAR) archives, backed by SWCompression.
struct CBT: ComicBookAdapter {
  let path: String

  /// Every file member of the archive, as Entries (paths are the in-archive entry names).
  func entries() throws -> [ComicBook.Entry] {
    var entries: [ComicBook.Entry] = []
    for entry in try readEntries() where entry.info.type == .regular {
      entries.append(ComicBook.Entry(path: entry.info.name))
    }
    return entries
  }

  /// Read `ComicInfo.xml` from the archive, if present.
  func info() throws -> ComicBook.Info? {
    guard let entry = try readEntries().first(where: { $0.info.name == "ComicInfo.xml" }),
      let data = entry.data, let xml = String(data: data, encoding: .utf8)
    else { return nil }
    return try ComicInfo.load(fromXML: xml)
  }

  /// Create a CBT from the source folder's files (filtered by `options.contents`).
  ///
  /// Returns the output path.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    let output = ComicBook.defaultOutputPath(forSource: path, newExtension: "cbt", to: options.to)
    guard !FileManager.default.fileExists(atPath: output) else {
      throw ComicBookError.destinationExists(output)
    }

    let sourceURL = URL(fileURLWithPath: path)
    let files = try ComicBook(path: path).files(type: options.contents)
    do {
      var entries: [TarEntry] = []
      for file in files {
        let data = try Data(contentsOf: sourceURL.appendingPathComponent(file.path))
        entries.append(TarEntry(info: TarEntryInfo(name: file.path, type: .regular), data: data))
      }
      try TarContainer.create(from: entries).write(to: URL(fileURLWithPath: output))
    } catch {
      throw ComicBookError.archiveError(error.localizedDescription)
    }

    if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
    return output
  }

  /// Extract the archive into a folder (default `<basename>.cb`).
  ///
  /// Returns the destination path.
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    let destination = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb", to: options.to)
    let destinationURL = URL(fileURLWithPath: destination)

    do {
      let entries = try readEntries()
      try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
      for entry in entries where entry.info.type == .regular {
        if options.imagesOnly && !ComicBook.isImageFile(entry.info.name) { continue }
        let fileURL = destinationURL.appendingPathComponent(entry.info.name)
        try FileManager.default.createDirectory(
          at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (entry.data ?? Data()).write(to: fileURL)
      }
    } catch let error as ComicBookError {
      throw error
    } catch {
      throw ComicBookError.extractionError(error.localizedDescription)
    }

    if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
    return destination
  }

  private func readEntries() throws -> [TarEntry] {
    do {
      return try TarContainer.open(container: try Data(contentsOf: URL(fileURLWithPath: path)))
    } catch {
      throw ComicBookError.extractionError("Could not read '\(path)': \(error.localizedDescription)")
    }
  }
}
