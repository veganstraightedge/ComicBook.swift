//
// PDF.swift
// ComicBook
//

import Foundation

/// Adapter for PDF files: extract-only, rendering pages to images. PDFs never carry ComicInfo metadata.
/// TODO: implement extraction with PDFKit + ImageIO.
struct PDF: ComicBookAdapter {
  let path: String
  init(path: String) { self.path = path }
  func pages() throws -> [ComicBook.Page] { throw ComicBookError.notImplemented("PDF pages not yet ported") }
  /// PDFs never carry ComicInfo.xml.
  func info() throws -> ComicBook.Info? { nil }
  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("PDF archiving not supported")
  }
  func extract(options: ComicBook.ExtractOptions) throws -> String {
    throw ComicBookError.notImplemented("PDF extract not yet ported")
  }
}
