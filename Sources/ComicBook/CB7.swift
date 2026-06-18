//
// CB7.swift
// ComicBook
//

import ComicInfo
import Foundation
import PLzmaSDK

/// Adapter for CB7 (7-Zip) archives, backed by PLzmaSDK (bundled LZMA SDK — no system 7z needed).
struct CB7: ComicBookAdapter {
  let path: String

  /// Image pages inside the archive, sorted by basename.
  func pages() throws -> [ComicBook.Page] {
    let (decoder, count) = try openDecoder()
    var pages: [ComicBook.Page] = []
    for index in 0..<count {
      let item = try decoder.item(at: index)
      let name = try item.path().description
      guard !item.isDir, ComicBook.isImageFile(name) else { continue }
      pages.append(ComicBook.Page(path: name, name: (name as NSString).lastPathComponent))
    }
    return pages.sorted { $0.name < $1.name }
  }

  /// Read `ComicInfo.xml` from the archive, if present.
  func info() throws -> ComicBook.Info? {
    let (decoder, count) = try openDecoder()
    for index in 0..<count {
      let item = try decoder.item(at: index)
      guard try item.path().description == "ComicInfo.xml" else { continue }
      let memory = try OutStream()
      let map = try ItemOutStreamArray()
      try map.add(item: item, stream: memory)
      _ = try decoder.extract(itemsToStreams: map)
      guard let xml = String(data: try memory.copyContent(), encoding: .utf8) else { return nil }
      return try ComicInfo.load(fromXML: xml)
    }
    return nil
  }

  /// Create a CB7 from the source folder's image files (images only).
  ///
  /// Returns the output path.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    let output = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb7", to: options.to)
    guard !FileManager.default.fileExists(atPath: output) else {
      throw ComicBookError.destinationExists(output)
    }

    do {
      let encoder = try Encoder(stream: try OutStream(path: try Path(output)), fileType: .sevenZ, method: .LZMA2)
      for image in ComicBook.archiveFiles(in: URL(fileURLWithPath: path), contents: options.contents) {
        try encoder.add(path: try Path(image.fileURL.path), mode: .default, archivePath: try Path(image.relativePath))
      }
      _ = try encoder.open()
      _ = try encoder.compress()
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

    do {
      try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: destination), withIntermediateDirectories: true)
      let (decoder, _) = try openDecoder()
      _ = try decoder.extract(to: try Path(destination), itemsFullPath: true)
      if options.imagesOnly { try removeNonImages(in: destination) }
    } catch let error as ComicBookError {
      throw error
    } catch {
      throw ComicBookError.extractionError(error.localizedDescription)
    }

    if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
    return destination
  }

  // MARK: - Internals

  private func openDecoder() throws -> (decoder: Decoder, count: Size) {
    do {
      let decoder = try Decoder(stream: try InStream(path: try Path(path)), fileType: .sevenZ)
      _ = try decoder.open()
      return (decoder, try decoder.count())
    } catch {
      throw ComicBookError.extractionError("Could not open '\(path)': \(error.localizedDescription)")
    }
  }

  private func removeNonImages(in directory: String) throws {
    let fileManager = FileManager.default
    guard
      let enumerator = fileManager.enumerator(
        at: URL(fileURLWithPath: directory), includingPropertiesForKeys: [.isDirectoryKey])
    else { return }
    for case let fileURL as URL in enumerator {
      let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
      if !isDirectory && !ComicBook.isImageFile(fileURL.lastPathComponent) {
        try? fileManager.removeItem(at: fileURL)
      }
    }
  }
}
