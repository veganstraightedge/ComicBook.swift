//
// PLzmaArchive.swift
// ComicBook
//

import ComicInfo
import Foundation
import PLzmaSDK

/// An archive in a format PLzmaSDK reads and writes, with the operations every adapter offers.
///
/// PLzmaSDK bundles the LZMA SDK, so nothing has to be installed on the system. The adapters for its
/// formats differ only in the file type and extension they pass here.
struct PLzmaArchive {
  let path: String
  /// The archive format, as PLzmaSDK names it.
  let fileType: FileType
  /// The comic file extension for this format, without a dot (`cb7`).
  let fileExtension: String

  /// Every file member of the archive, as Entries (paths are the in-archive entry names).
  func entries() throws -> [ComicBook.Entry] {
    let (decoder, count) = try openDecoder()
    var entries: [ComicBook.Entry] = []
    for index in 0..<count {
      let item = try decoder.item(at: index)
      guard !item.isDir else { continue }
      let itemPath = try item.path().description
      guard !ComicBook.isMacOSMetadata(itemPath) else { continue }
      entries.append(ComicBook.Entry(path: itemPath))
    }
    return entries
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

  /// Create the archive from the source folder's files (filtered by `options.contents`).
  ///
  /// Here `path` is the source folder. Returns the output path.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    let output = ComicBook.defaultOutputPath(forSource: path, newExtension: fileExtension, to: options.to)
    guard !FileManager.default.fileExists(atPath: output) else {
      throw ComicBookError.destinationExists(output)
    }

    let sourceURL = URL(fileURLWithPath: path)
    let files = try ComicBook(path: path).files(type: options.contents)
    do {
      // The method only applies to 7-Zip; PLzmaSDK ignores it for TAR, which is not compressed.
      let encoder = try Encoder(stream: try OutStream(path: try Path(output)), fileType: fileType, method: .LZMA2)
      for file in files {
        let fileURL = sourceURL.appendingPathComponent(file.path)
        try encoder.add(path: try Path(fileURL.path), mode: .default, archivePath: try Path(file.path))
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
      try removeUnwanted(in: destination, imagesOnly: options.imagesOnly)
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
      let decoder = try Decoder(stream: try InStream(path: try Path(path)), fileType: fileType)
      _ = try decoder.open()
      return (decoder, try decoder.count())
    } catch {
      throw ComicBookError.extractionError("Could not open '\(path)': \(error.localizedDescription)")
    }
  }

  /// Delete what should not have been extracted.
  ///
  /// That is macOS metadata always and, with `imagesOnly`, every file that is not an image. The
  /// whole archive is extracted in one go, so this tidies up afterwards.
  private func removeUnwanted(in directory: String, imagesOnly: Bool) throws {
    let fileManager = FileManager.default
    let directoryURL = URL(fileURLWithPath: directory)
    // Listed by path: listing by URL leaves out the `._` files this is here to remove.
    for relative in try fileManager.subpathsOfDirectory(atPath: directory) {
      let fileURL = directoryURL.appendingPathComponent(relative)
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else { continue }

      let isUnwantedFile = imagesOnly && !isDirectory.boolValue && !ComicBook.isImageFile(relative)
      if ComicBook.isMacOSMetadata(relative) || isUnwantedFile {
        try? fileManager.removeItem(at: fileURL)
      }
    }
  }
}
