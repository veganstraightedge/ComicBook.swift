//
// CBZ.swift
// ComicBook
//

import ComicInfo
import Foundation
import ZIPFoundation

/// Adapter for CBZ (ZIP) archives, backed by ZIPFoundation.
struct CBZ: ComicBookAdapter {
  let path: String

  /// Image pages inside the archive, sorted by basename.
  func pages() throws -> [ComicBook.Page] {
    let archive = try openForReading()
    var pages: [ComicBook.Page] = []
    for entry in archive where entry.type == .file && ComicBook.isImageFile(entry.path) {
      pages.append(ComicBook.Page(path: entry.path, name: (entry.path as NSString).lastPathComponent))
    }
    return pages.sorted { $0.name < $1.name }
  }

  /// Read `ComicInfo.xml` from the archive, if present.
  func info() throws -> ComicBook.Info? {
    let archive = try openForReading()
    guard let entry = archive.first(where: { $0.path == "ComicInfo.xml" }) else { return nil }
    var data = Data()
    _ = try archive.extract(entry) { data.append($0) }
    guard let xml = String(data: data, encoding: .utf8) else { return nil }
    return try ComicInfo.load(fromXML: xml)
  }

  /// Create a CBZ from the source folder's image files (images only).
  ///
  /// Returns the output path.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    let output = ComicBook.defaultOutputPath(forSource: path, newExtension: "cbz", to: options.to)
    guard !FileManager.default.fileExists(atPath: output) else {
      throw ComicBookError.destinationExists(output)
    }

    do {
      let archive = try Archive(url: URL(fileURLWithPath: output), accessMode: .create)
      for image in ComicBook.imageFiles(in: URL(fileURLWithPath: path)) {
        try archive.addEntry(with: image.relativePath, fileURL: image.fileURL, compressionMethod: .deflate)
      }
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
      let archive = try openForReading()
      try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
      for entry in archive where entry.type == .file {
        if options.imagesOnly && !ComicBook.isImageFile(entry.path) { continue }
        let fileURL = destinationURL.appendingPathComponent(entry.path)
        try FileManager.default.createDirectory(
          at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: fileURL)
        _ = try archive.extract(entry, to: fileURL)
      }
    } catch let error as ComicBookError {
      throw error
    } catch {
      throw ComicBookError.extractionError(error.localizedDescription)
    }

    if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
    return destination
  }

  private func openForReading() throws -> Archive {
    do {
      return try Archive(url: URL(fileURLWithPath: path), accessMode: .read)
    } catch {
      throw ComicBookError.extractionError("Could not open '\(path)': \(error.localizedDescription)")
    }
  }
}
