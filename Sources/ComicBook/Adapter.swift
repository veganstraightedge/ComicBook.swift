//
// Adapter.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// The kind of comic book source, by file extension or folder convention.
  public enum ArchiveType: String, Equatable, Sendable {
    case cbz
    case cb7
    case cbt
    case cbr
    case cba
    case pdf
    /// An uncompressed comic: a folder whose name ends in `.cb`.
    case cb
    /// A plain folder (a source for archiving).
    case folder
  }

  /// Options controlling extraction.
  public struct ExtractOptions: Sendable {
    /// Explicit destination path (overrides the default `<basename>.cb`).
    public var to: String?
    /// Only extract image files, skipping everything else.
    public var imagesOnly: Bool
    /// Delete the source archive after a successful extraction.
    public var deleteOriginal: Bool
    /// Render DPI (PDF only; defaults to 300).
    public var dpi: Int?

    public init(to: String? = nil, imagesOnly: Bool = false, deleteOriginal: Bool = false, dpi: Int? = nil) {
      self.to = to
      self.imagesOnly = imagesOnly
      self.deleteOriginal = deleteOriginal
      self.dpi = dpi
    }
  }

  /// Options controlling archiving.
  public struct ArchiveOptions: Sendable {
    /// Explicit destination path (its extension selects the output format; defaults to `.cbz`).
    public var to: String?
    /// Delete the source after a successful archive.
    public var deleteOriginal: Bool

    public init(to: String? = nil, deleteOriginal: Bool = false) {
      self.to = to
      self.deleteOriginal = deleteOriginal
    }
  }
}

/// A per-format handler for a comic book source. Internal; one concrete type per `ArchiveType`.
protocol ComicBookAdapter {
  init(path: String)
  func pages() throws -> [ComicBook.Page]
  func info() throws -> ComicBook.Info?
  func archive(options: ComicBook.ArchiveOptions) throws -> String
  func extract(options: ComicBook.ExtractOptions) throws -> String
}
