import Foundation
import Testing

@testable import ComicBook

struct ComicBookTests {

  // MARK: - Helpers

  /// Create a temp directory populated with the given relative-path → contents files.
  func makeTempDir(_ files: [String: String], suffix: String = "") throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + suffix)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (relative, contents) in files {
      let fileURL = dir.appendingPathComponent(relative)
      try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    return dir
  }

  // MARK: - Version & type detection

  @Test func testVersionIsPresent() throws {
    #expect(!ComicBook.Version.current.isEmpty)
  }

  @Test func testDetectsFolderType() throws {
    let dir = try makeTempDir(["page1.jpg": "x"])
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(try ComicBook.load(dir.path).type == .folder)
  }

  @Test func testDetectsCbFolderType() throws {
    let dir = try makeTempDir(["page1.jpg": "x"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(try ComicBook.load(dir.path).type == .cb)
  }

  @Test func testUnsupportedFileTypeThrows() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
    try "x".write(to: file, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: file) }
    #expect(throws: ComicBookError.self) { try ComicBook.load(file.path) }
  }

  @Test func testMissingPathThrows() throws {
    #expect(throws: ComicBookError.self) { try ComicBook.load("/nope/\(UUID().uuidString).cbz") }
  }

  // MARK: - Pages (folder and .cb both yield folder-relative paths)

  @Test func testFolderPagesAreSortedRelativeImagesOnly() throws {
    let dir = try makeTempDir(["page2.png": "x", "page1.jpg": "x", "readme.txt": "x", "sub/page3.gif": "x"])
    defer { try? FileManager.default.removeItem(at: dir) }
    let pages = try ComicBook.load(dir.path).pages()
    #expect(pages.map(\.name) == ["page1.jpg", "page2.png", "page3.gif"])
    #expect(pages.map(\.path) == ["page1.jpg", "page2.png", "sub/page3.gif"])
  }

  @Test func testCbPagesAreRelative() throws {
    let dir = try makeTempDir(["page1.jpg": "x", "sub/page2.png": "x"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: dir) }
    let pages = try ComicBook.load(dir.path).pages()
    #expect(pages.map(\.path).sorted() == ["page1.jpg", "sub/page2.png"])
  }

  // MARK: - Info

  @Test func testCbInfoReadsComicInfo() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>Test Comic</Title><Series>S</Series></ComicInfo>"
    let dir = try makeTempDir(["page1.jpg": "x", "ComicInfo.xml": xml], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(try ComicBook.load(dir.path).info()?.title == "Test Comic")
  }

  @Test func testInfoNilWhenNoComicInfo() throws {
    let dir = try makeTempDir(["page1.jpg": "x"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(try ComicBook.load(dir.path).info() == nil)
  }

  // MARK: - Archive / extract (folder ⇄ .cb)

  @Test func testArchiveFolderToCbMovesIt() throws {
    let dir = try makeTempDir(["page1.jpg": "x"])
    defer { try? FileManager.default.removeItem(at: dir) }
    let output = try ComicBook.load(dir.path).archive(options: ComicBook.ArchiveOptions(to: dir.path + ".cb"))
    defer { try? FileManager.default.removeItem(atPath: output) }
    #expect(output.hasSuffix(".cb"))
    #expect(FileManager.default.fileExists(atPath: output))
    #expect(!FileManager.default.fileExists(atPath: dir.path))
  }

  @Test func testExtractFolderThrows() throws {
    let dir = try makeTempDir(["page1.jpg": "x"])
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(throws: ComicBookError.self) { try ComicBook.load(dir.path).extract() }
  }

  @Test func testExtractCbThrowsAlreadyExtracted() throws {
    let dir = try makeTempDir(["page1.jpg": "x"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(throws: ComicBookError.self) { try ComicBook.load(dir.path).extract() }
  }
}
