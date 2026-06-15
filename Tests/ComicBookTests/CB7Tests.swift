import Foundation
import Testing

@testable import ComicBook

struct CB7Tests {

  @Test func testCb7ArchiveExtractRoundTrip() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "a", "sub/page2.png": "b", "ComicInfo.xml": "<ComicInfo/>"])
    defer { try? FileManager.default.removeItem(at: src) }

    let output = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: src.path + ".cb7"))
    defer { try? FileManager.default.removeItem(atPath: output) }

    let comic = try ComicBook.load(output)
    #expect(comic.type == .cb7)
    // Images only.
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png"])

    let destination = src.path + "-out.cb"
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: destination))
    defer { try? FileManager.default.removeItem(atPath: destination) }
    #expect(FileManager.default.fileExists(atPath: destination + "/page1.jpg"))
    #expect(FileManager.default.fileExists(atPath: destination + "/sub/page2.png"))
  }

  @Test func testCb7InfoFromRealArchive() throws {
    // Build a CB7 containing ComicInfo.xml with the 7zz tool, if available (our archiver is images-only).
    let sevenZip = "/opt/homebrew/bin/7zz"
    guard FileManager.default.fileExists(atPath: sevenZip) else { return }

    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>Sevened</Title></ComicInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "ComicInfo.xml": xml])
    defer { try? FileManager.default.removeItem(at: src) }

    let cb7Path = tempPath(extension: "cb7")
    defer { try? FileManager.default.removeItem(atPath: cb7Path) }
    try #require(try runTool(sevenZip, ["a", "-bso0", "-bsp0", cb7Path, "page1.jpg", "ComicInfo.xml"], cwd: src) == 0)

    #expect(try ComicBook.load(cb7Path).info()?.title == "Sevened")
  }
}
