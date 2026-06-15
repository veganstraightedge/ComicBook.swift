import CoreGraphics
import Foundation
import Testing

@testable import ComicBook

struct PDFTests {

  /// Generate a simple multi-page PDF and return its path.
  func makePDF(pageCount: Int) throws -> String {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
    var mediaBox = CGRect(x: 0, y: 0, width: 200, height: 300)
    guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
      throw ComicBookError.archiveError("Could not create a PDF context")
    }
    for _ in 0..<pageCount {
      context.beginPDFPage(nil)
      context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
      context.fill(CGRect(x: 20, y: 20, width: 100, height: 120))
      context.endPDFPage()
    }
    context.closePDF()
    return url.path
  }

  @Test func testPdfPagesAndExtract() throws {
    let pdfPath = try makePDF(pageCount: 2)
    defer { try? FileManager.default.removeItem(atPath: pdfPath) }

    let comic = try ComicBook.load(pdfPath)
    #expect(comic.type == .pdf)
    #expect(try comic.pages().map(\.name) == ["page_001.jpg", "page_002.jpg"])
    #expect(try comic.info() == nil)

    let destination = pdfPath + "-out.cb"
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: destination, dpi: 72))
    defer { try? FileManager.default.removeItem(atPath: destination) }
    #expect(FileManager.default.fileExists(atPath: destination + "/page_001.jpg"))
    #expect(FileManager.default.fileExists(atPath: destination + "/page_002.jpg"))
  }

  @Test func testPdfArchiveNotSupported() throws {
    let pdfPath = try makePDF(pageCount: 1)
    defer { try? FileManager.default.removeItem(atPath: pdfPath) }
    #expect(throws: ComicBookError.self) {
      try ComicBook.load(pdfPath).archive(options: ComicBook.ArchiveOptions())
    }
  }
}
