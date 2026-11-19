import Foundation
import Testing

@testable import ComicBook

/// A comic's type comes from what the file is, not what it is named: mislabelled archives are
/// common (a RAR named `.cbz`).
struct ContentDetectionTests {
  private let pageNames = ["page1.jpg", "page2.png"]

  /// A copy of the file at `path` under a new extension, in the temp directory.
  private func copy(of path: String, namedWithExtension ext: String) throws -> String {
    let renamed = tempPath(extension: ext)
    try FileManager.default.copyItem(atPath: path, toPath: renamed)
    return renamed
  }

  /// A real archive of two pages in the format of `ext`, saved under the extension `misnamedAs`.
  private func archive(as ext: String, misnamedAs wrong: String) throws -> String {
    let source = try makeFixtureDirectory(["page1.jpg": "first", "page2.png": "second"])
    defer { try? FileManager.default.removeItem(at: source) }
    let real = try ComicBook.archive(source.path, options: .init(to: tempPath(extension: ext)))
    defer { try? FileManager.default.removeItem(atPath: real) }
    return try copy(of: real, namedWithExtension: wrong)
  }

  @Test func testRarNamedCbzIsReadAsCbr() throws {
    let fixture = try #require(
      Bundle.module.url(forResource: "simple", withExtension: "cbr", subdirectory: "Fixtures/cbr"))
    let misnamed = try copy(of: fixture.path, namedWithExtension: "cbz")
    defer { try? FileManager.default.removeItem(atPath: misnamed) }

    let comic = try ComicBook.load(misnamed)
    #expect(comic.type == .cbr)
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png", "page3.gif"])
  }

  @Test func testZipNamedCbrIsReadAsCbz() throws {
    let misnamed = try archive(as: "cbz", misnamedAs: "cbr")
    defer { try? FileManager.default.removeItem(atPath: misnamed) }

    let comic = try ComicBook.load(misnamed)
    #expect(comic.type == .cbz)
    #expect(try comic.pages().map(\.name) == pageNames)
  }

  @Test func testSevenZipNamedCbzIsReadAsCb7() throws {
    let misnamed = try archive(as: "cb7", misnamedAs: "cbz")
    defer { try? FileManager.default.removeItem(atPath: misnamed) }

    let comic = try ComicBook.load(misnamed)
    #expect(comic.type == .cb7)
    #expect(try comic.pages().map(\.name) == pageNames)
  }

  @Test func testTarNamedCbzIsReadAsCbt() throws {
    let misnamed = try archive(as: "cbt", misnamedAs: "cbz")
    defer { try? FileManager.default.removeItem(atPath: misnamed) }

    let comic = try ComicBook.load(misnamed)
    #expect(comic.type == .cbt)
    #expect(try comic.pages().map(\.name) == pageNames)
  }

  @Test func testPdfNamedCbzIsReadAsPdf() throws {
    let misnamed = tempPath(extension: "cbz")
    try Data("%PDF-1.7\n".utf8).write(to: URL(fileURLWithPath: misnamed))
    defer { try? FileManager.default.removeItem(atPath: misnamed) }

    #expect(try ComicBook.load(misnamed).type == .pdf)
  }

  @Test func testCorrectlyNamedArchivesKeepTheirType() throws {
    for ext in ["cbz", "cb7", "cbt"] {
      let named = try archive(as: ext, misnamedAs: ext)
      defer { try? FileManager.default.removeItem(atPath: named) }
      #expect(try ComicBook.load(named).type.rawValue == ext)
    }
  }

  @Test func testUnrecognisedContentsFallBackToTheExtension() throws {
    for contents in ["", "x", "not an archive at all, just some text that is long enough"] {
      let file = tempPath(extension: "cbz")
      try Data(contents.utf8).write(to: URL(fileURLWithPath: file))
      defer { try? FileManager.default.removeItem(atPath: file) }
      #expect(try ComicBook.load(file).type == .cbz)
    }
  }

  @Test func testAnArchiveWithoutAComicExtensionIsStillUnsupported() throws {
    let zip = try archive(as: "cbz", misnamedAs: "zip")
    defer { try? FileManager.default.removeItem(atPath: zip) }

    #expect(throws: ComicBookError.unsupportedFileType(".zip")) { try ComicBook.load(zip) }
  }

  @Test func testAFolderIsNeverReadForASignature() throws {
    let folder = try makeFixtureDirectory(["page1.jpg": "first"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: folder) }

    #expect(try ComicBook.load(folder.path).type == .cb)
  }
}
