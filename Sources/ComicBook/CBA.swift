//
// CBA.swift
// ComicBook
//

import Foundation

/// Adapter for CBA (ACE) archives. ACE is proprietary and obsolete; all operations are unimplemented,
/// matching the Ruby gem's stubs.
struct CBA: ComicBookAdapter {
  let path: String
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("CBA page listing not yet implemented") }
  func info() throws -> ComicBook.Info? { throw ComicBookError.notImplemented("CBA info not yet implemented") }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("CBA archiving not supported (ACE is proprietary)")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("CBA extraction not yet implemented")
  }
}
