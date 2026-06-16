//
// CB.swift
// ComicBook
//

import ComicInfo
import Foundation

/// Adapter for an uncompressed comic: a `.cb` folder (or a plain folder being archived).
struct CB: ComicBookAdapter {
  let path: String

  /// Image pages as folder-relative paths, sorted by path.
  func pages() throws -> [ComicBook.Page] {
    let fileManager = FileManager.default
    let baseURL = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let baseComponentCount = baseURL.pathComponents.count
    guard let enumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil) else {
      return []
    }

    var relativePaths: [String] = []
    for case let url as URL in enumerator where ComicBook.isImageFile(url.lastPathComponent) {
      let relativeComponents = url.resolvingSymlinksInPath().pathComponents.dropFirst(baseComponentCount)
      relativePaths.append(relativeComponents.joined(separator: "/"))
    }

    return relativePaths.sorted().map { ComicBook.Page(path: $0, name: ($0 as NSString).lastPathComponent) }
  }

  /// Read `ComicInfo.xml` from the folder, if present.
  func info() throws -> ComicBook.Info? {
    let xmlPath = (path as NSString).appendingPathComponent("ComicInfo.xml")
    guard FileManager.default.fileExists(atPath: xmlPath) else { return nil }
    return try ComicInfo.load(from: xmlPath)
  }

  /// Archive a folder into a `.cb` folder by moving it (uncompressed).
  ///
  /// Returns the destination.
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    let output = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb", to: options.to)
    guard !FileManager.default.fileExists(atPath: output) else {
      throw ComicBookError.destinationExists(output)
    }
    do {
      try FileManager.default.moveItem(atPath: path, toPath: output)
    } catch {
      throw ComicBookError.archiveError(error.localizedDescription)
    }
    return output
  }

  /// `.cb` folders are already extracted.
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.alreadyExtracted(path)
  }
}
