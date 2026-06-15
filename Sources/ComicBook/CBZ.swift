//
// CBZ.swift
// ComicBook
//

import Foundation

/// Adapter for CBZ archives. TODO: implementation in progress.
struct CBZ: ComicBookAdapter {
  let path: String
  init(path: String) { self.path = path }
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("CBZ pages not yet ported") }
  func info() throws -> ComicBook.Info? { throw ComicBookError.notImplemented("CBZ info not yet ported") }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notImplemented("CBZ archive not yet ported")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("CBZ extract not yet ported")
  }
}
