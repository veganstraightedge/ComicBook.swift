import Foundation
import Testing

@testable import ComicBook

struct CBZTests {

  @Test func testArchiveFolderToCbzIsImagesOnly() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>RT</Title></ComicInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "page2.png": "b", "ComicInfo.xml": xml, "notes.txt": "n"])
    defer { try? FileManager.default.removeItem(at: src) }

    let cbzPath = src.path + ".cbz"
    let output = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: cbzPath))
    defer { try? FileManager.default.removeItem(atPath: output) }

    #expect(output == cbzPath)
    let comic = try ComicBook.load(output)
    #expect(comic.type == .cbz)
    // Archiving is images-only: notes.txt and ComicInfo.xml are not included.
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png"])
    #expect(try comic.info() == nil)
  }

  @Test func testCbzExtractRestoresImages() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "a", "sub/page2.png": "b"])
    defer { try? FileManager.default.removeItem(at: src) }
    let output = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: src.path + ".cbz"))
    defer { try? FileManager.default.removeItem(atPath: output) }

    let destination = src.path + "-out.cb"
    _ = try ComicBook.load(output).extract(options: ComicBook.ExtractOptions(to: destination))
    defer { try? FileManager.default.removeItem(atPath: destination) }

    #expect(FileManager.default.fileExists(atPath: destination + "/page1.jpg"))
    #expect(FileManager.default.fileExists(atPath: destination + "/sub/page2.png"))
  }

  @Test func testCbzInfoAndPagesFromRealArchive() throws {
    // Our archiver is images-only, so build a CBZ that includes ComicInfo.xml using system `zip`.
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>Zipped</Title><Series>S</Series></ComicInfo>"
    let src = try makeFixtureDirectory(["page2.png": "b", "page1.jpg": "a", "ComicInfo.xml": xml])
    defer { try? FileManager.default.removeItem(at: src) }

    let cbzPath = tempPath(extension: "cbz")
    defer { try? FileManager.default.removeItem(atPath: cbzPath) }
    try #require(try runTool("/usr/bin/zip", ["-rq", cbzPath, "."], cwd: src) == 0)

    let comic = try ComicBook.load(cbzPath)
    #expect(try comic.info()?.title == "Zipped")
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png"])
  }
}
