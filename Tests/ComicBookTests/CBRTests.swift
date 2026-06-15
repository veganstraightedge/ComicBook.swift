import Foundation
import Testing

@testable import ComicBook

struct CBRTests {

  func fixture(_ name: String) throws -> String {
    let url = try #require(
      Bundle.module.url(forResource: name, withExtension: "cbr", subdirectory: "Fixtures/cbr"))
    return url.path
  }

  @Test func testCbrTypeAndPages() throws {
    let comic = try ComicBook.load(try fixture("simple"))
    #expect(comic.type == .cbr)
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png", "page3.gif"])
  }

  @Test func testCbrInfo() throws {
    let info = try ComicBook.load(try fixture("with_comicinfo")).info()
    #expect(info != nil)
    #expect(info?.title?.isEmpty == false)
  }

  @Test func testCbrInfoNilWhenAbsent() throws {
    #expect(try ComicBook.load(try fixture("simple")).info() == nil)
  }

  @Test func testCbrExtract() throws {
    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }
    _ = try ComicBook.load(try fixture("simple")).extract(options: ComicBook.ExtractOptions(to: destination))
    #expect(FileManager.default.fileExists(atPath: destination + "/page1.jpg"))
    #expect(FileManager.default.fileExists(atPath: destination + "/page3.gif"))
  }

  @Test func testCbrArchiveNotSupported() throws {
    #expect(throws: ComicBookError.self) {
      try ComicBook.load(try fixture("simple")).archive(options: ComicBook.ArchiveOptions())
    }
  }
}
