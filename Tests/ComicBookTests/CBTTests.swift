import Foundation
import Testing

@testable import ComicBook

struct CBTTests {

  @Test func testCbtArchiveExtractRoundTrip() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "a", "sub/page2.png": "b", "ComicInfo.xml": "<ComicInfo/>"])
    defer { try? FileManager.default.removeItem(at: src) }

    let output = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: src.path + ".cbt"))
    defer { try? FileManager.default.removeItem(atPath: output) }

    let comic = try ComicBook.load(output)
    #expect(comic.type == .cbt)
    // Images only.
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png"])

    let destination = src.path + "-out.cb"
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: destination))
    defer { try? FileManager.default.removeItem(atPath: destination) }
    #expect(FileManager.default.fileExists(atPath: destination + "/page1.jpg"))
    #expect(FileManager.default.fileExists(atPath: destination + "/sub/page2.png"))
  }

  @Test func testCbtInfoFromRealArchive() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>Tarred</Title></ComicInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "ComicInfo.xml": xml])
    defer { try? FileManager.default.removeItem(at: src) }

    let cbtPath = tempPath(extension: "cbt")
    defer { try? FileManager.default.removeItem(atPath: cbtPath) }
    // Name entries explicitly so they have no "./" prefix.
    try #require(try runTool("/usr/bin/tar", ["-cf", cbtPath, "-C", src.path, "page1.jpg", "ComicInfo.xml"]) == 0)

    #expect(try ComicBook.load(cbtPath).info()?.title == "Tarred")
  }
}
