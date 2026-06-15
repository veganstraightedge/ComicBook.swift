//
// CBT.swift
// ComicBook
//

import Foundation

/// Adapter for CBT archives. TODO: implementation in progress.
struct CBT: ComicBookAdapter {
  let path: String
  init(path: String) { self.path = path }
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("CBT pages not yet ported") }
  func info() throws -> ComicBook.Info? { throw ComicBookError.notImplemented("CBT info not yet ported") }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notImplemented("CBT archive not yet ported")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("CBT extract not yet ported")
  }
}
