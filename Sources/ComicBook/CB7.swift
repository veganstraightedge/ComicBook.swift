//
// CB7.swift
// ComicBook
//

import Foundation

/// Adapter for CB7 archives. TODO: implementation in progress.
struct CB7: ComicBookAdapter {
  let path: String
  init(path: String) { self.path = path }
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("CB7 pages not yet ported") }
  func info() throws -> ComicBook.Info? { throw ComicBookError.notImplemented("CB7 info not yet ported") }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notImplemented("CB7 archive not yet ported")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("CB7 extract not yet ported")
  }
}
