//
// ComicBook.swift
// ComicBook
//
// A Swift package for reading, extracting, archiving, and inspecting comic book archives
// (.cbz, .cbt, .cb7, .cbr, .cb folders, and PDF), with ComicInfo.xml metadata support.
//

import Foundation

/// Top-level namespace for working with comic book archives.
public enum ComicBook {

  // MARK: - Convenience entry points

  /// Load a comic book at the given path, detecting its type.
  public static func load(_ path: String) throws -> Comic {
    try Comic(path: path)
  }

  /// Archive the folder/`.cb` at `path`. The output format is taken from `options.to`'s extension
  /// (defaults to `.cbz`). Returns the output path.
  @discardableResult
  public static func archive(_ path: String, options: ArchiveOptions = ArchiveOptions()) throws -> String {
    try Comic(path: path).archive(options: options)
  }

  /// Extract the archive at `path` into a folder. Returns the destination path.
  @discardableResult
  public static func extract(_ path: String, options: ExtractOptions = ExtractOptions()) throws -> String {
    try Comic(path: path).extract(options: options)
  }

  // MARK: - Path helpers

  /// The default output path for an operation on `source`: `options.to` if set, otherwise the source's
  /// directory + basename (sans extension) + `.newExtension`.
  static func defaultOutputPath(forSource source: String, newExtension: String, to: String?) -> String {
    if let to { return to }
    let directory = (source as NSString).deletingLastPathComponent
    let base = ((source as NSString).lastPathComponent as NSString).deletingPathExtension
    return (directory as NSString).appendingPathComponent("\(base).\(newExtension)")
  }
}

extension ComicBook {
  /// A loaded comic book at a path, with a detected ``ArchiveType``.
  public struct Comic {
    /// The absolute, normalized path to the comic book.
    public let path: String

    /// The detected type of the comic book.
    public let type: ArchiveType

    /// Load and validate a comic book at `path`.
    public init(path: String) throws {
      let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
      let tildeExpanded = (trimmed as NSString).expandingTildeInPath
      let absolute = URL(fileURLWithPath: tildeExpanded).standardizedFileURL.path
      self.path = absolute
      self.type = try Comic.determineType(absolute)
    }

    /// List the image pages in this comic book (no extraction).
    public func pages() throws -> [Page] {
      if type == .folder { return try folderPages() }
      return try adapter().pages()
    }

    /// Read the `ComicInfo.xml` metadata, or nil if there is none.
    public func info() throws -> Info? {
      if type == .folder { return try CB(path: path).info() }
      return try adapter().info()
    }

    /// Extract this archive into a folder. Returns the destination path.
    @discardableResult
    public func extract(options: ExtractOptions = ExtractOptions()) throws -> String {
      switch type {
      case .folder: throw ComicBookError.notSupported("Cannot extract a folder")
      case .cb: throw ComicBookError.alreadyExtracted(path)
      default: return try adapter().extract(options: options)
      }
    }

    /// Archive this folder/`.cb` into an archive. Output format from `options.to`'s extension (default `.cbz`).
    @discardableResult
    public func archive(options: ArchiveOptions = ArchiveOptions()) throws -> String {
      guard type == .folder || type == .cb else {
        throw ComicBookError.notSupported("Cannot archive a \(type.rawValue) file")
      }

      let outputExtension =
        options.to.map { ($0 as NSString).pathExtension.lowercased() }.flatMap { $0.isEmpty ? nil : $0 } ?? "cbz"

      let archiver: ComicBookAdapter
      switch outputExtension {
      case "cb": archiver = CB(path: path)
      case "cb7": archiver = CB7(path: path)
      case "cbt": archiver = CBT(path: path)
      case "cbz": archiver = CBZ(path: path)
      case "cbr": throw ComicBookError.notSupported("Cannot archive to CBR format (RAR is proprietary)")
      case "cba": throw ComicBookError.notSupported("Cannot archive to CBA format (ACE is not supported)")
      default: throw ComicBookError.unsupportedFormat(".\(outputExtension)")
      }
      return try archiver.archive(options: options)
    }

    // MARK: - Internals

    private func adapter() -> ComicBookAdapter {
      switch type {
      case .cbz: return CBZ(path: path)
      case .cb7: return CB7(path: path)
      case .cbt: return CBT(path: path)
      case .cbr: return CBR(path: path)
      case .cba: return CBA(path: path)
      case .pdf: return PDF(path: path)
      case .cb, .folder: return CB(path: path)
      }
    }

    /// Recursively glob image files in a plain folder, sorted, as absolute-path pages.
    private func folderPages() throws -> [Page] {
      let fileManager = FileManager.default
      let baseURL = URL(fileURLWithPath: path)
      guard let enumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil) else {
        return []
      }

      var imagePaths: [String] = []
      for case let url as URL in enumerator where ComicBook.isImageFile(url.lastPathComponent) {
        imagePaths.append(url.path)
      }

      return imagePaths.sorted().map { Page(path: $0, name: ($0 as NSString).lastPathComponent) }
    }

    /// Detect the comic book type for a path that exists on disk.
    static func determineType(_ path: String) throws -> ArchiveType {
      let fileManager = FileManager.default
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
        throw ComicBookError.pathDoesNotExist(path)
      }

      if isDirectory.boolValue {
        return (path as NSString).pathExtension.lowercased() == "cb" ? .cb : .folder
      }

      switch (path as NSString).pathExtension.lowercased() {
      case "cbz": return .cbz
      case "cb7": return .cb7
      case "cbt": return .cbt
      case "cbr": return .cbr
      case "cba": return .cba
      case "pdf": return .pdf
      case let other: throw ComicBookError.unsupportedFileType(".\(other)")
      }
    }
  }
}
