//
// PDF.swift
// ComicBook
//

import Foundation

#if canImport(CoreGraphics) && canImport(ImageIO)
  import CoreGraphics
  import ImageIO
  import UniformTypeIdentifiers
#endif

/// Adapter for PDF files: extract-only, rendering each page to a JPEG (`page_001.jpg`, 1-indexed).
/// PDFs never carry ComicInfo metadata, so `info` is always nil.
struct PDF: ComicBookAdapter {
  let path: String

  init(path: String) {
    self.path = path
  }

  /// PDFs never carry ComicInfo.xml.
  func info() throws -> ComicBook.Info? { nil }

  func archive(options: ComicBook.ArchiveOptions) throws -> String {
    throw ComicBookError.notSupported("PDF archiving not supported")
  }

  #if canImport(CoreGraphics) && canImport(ImageIO)
    /// Synthetic page list (`page_001.jpg` …) — one per PDF page, with no backing file until extracted.
    func pages() throws -> [ComicBook.Page] {
      guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL), document.numberOfPages > 0 else {
        return []
      }
      return (1...document.numberOfPages).map { pageNumber in
        let name = String(format: "page_%03d.jpg", pageNumber)
        return ComicBook.Page(path: name, name: name)
      }
    }

    /// Render each PDF page to a JPEG in the destination folder (default `<basename>.cb`).
    func extract(options: ComicBook.ExtractOptions) throws -> String {
      let destination = ComicBook.defaultOutputPath(forSource: path, newExtension: "cb", to: options.to)
      let destinationURL = URL(fileURLWithPath: destination)
      let dpi = CGFloat(options.dpi ?? 300)

      guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL) else {
        throw ComicBookError.extractionError("Could not open PDF '\(path)'")
      }

      do {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
      } catch {
        throw ComicBookError.extractionError(error.localizedDescription)
      }

      for pageNumber in 1...max(document.numberOfPages, 1) where pageNumber <= document.numberOfPages {
        guard let page = document.page(at: pageNumber) else { continue }
        let fileURL = destinationURL.appendingPathComponent(String(format: "page_%03d.jpg", pageNumber))
        try renderPage(page, to: fileURL, dpi: dpi)
      }

      if options.deleteOriginal { try? FileManager.default.removeItem(atPath: path) }
      return destination
    }

    private func renderPage(_ page: CGPDFPage, to fileURL: URL, dpi: CGFloat) throws {
      let mediaBox = page.getBoxRect(.mediaBox)
      let scale = dpi / 72.0
      let width = max(Int((mediaBox.width * scale).rounded()), 1)
      let height = max(Int((mediaBox.height * scale).rounded()), 1)

      guard
        let context = CGContext(
          data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
      else {
        throw ComicBookError.extractionError("Could not create a rendering context")
      }

      context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      context.scaleBy(x: scale, y: scale)
      context.translateBy(x: -mediaBox.origin.x, y: -mediaBox.origin.y)
      context.drawPDFPage(page)

      guard let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(
          fileURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
      else {
        throw ComicBookError.extractionError("Could not render page to '\(fileURL.lastPathComponent)'")
      }
      CGImageDestinationAddImage(destination, image, nil)
      guard CGImageDestinationFinalize(destination) else {
        throw ComicBookError.extractionError("Could not write '\(fileURL.lastPathComponent)'")
      }
    }
  #else
    func pages() throws -> [ComicBook.Page] {
      throw ComicBookError.notSupported("PDF rendering is not available on this platform")
    }
    func extract(options: ComicBook.ExtractOptions) throws -> String {
      throw ComicBookError.notSupported("PDF rendering is not available on this platform")
    }
  #endif
}
