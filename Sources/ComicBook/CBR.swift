//
// CBR.swift
// ComicBook
//

import Foundation

/// Adapter for CBR (RAR) archives. Read-only — RAR creation is proprietary. TODO: shell out to lsar/unar.
struct CBR: ComicBookAdapter {
  let path: String
  init(path: String) { self.path = path }
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("CBR pages not yet ported") }
  func info() throws -> ComicBook.Info? { throw ComicBookError.notImplemented("CBR info not yet ported") }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("CBR archiving not supported (RAR is proprietary)")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("CBR extract not yet ported")
  }
}
