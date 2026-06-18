import Foundation
import Testing

@testable import ComicBook

struct CBZTests {

  @Test func testArchiveIncludesAllFilesByDefault() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>RT</Title></ComicInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "page2.png": "b", "ComicInfo.xml": xml, "notes.txt": "n"])
    defer { try? FileManager.default.removeItem(at: src) }

    let output = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: src.path + ".cbz"))
    defer { try? FileManager.default.removeItem(atPath: output) }

    // Default is .all: ComicInfo.xml and notes.txt are included alongside the images.
    let comic = try ComicBook.load(output)
    #expect(try comic.info()?.title == "RT")

    let extracted = src.path + "-out.cb"
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: extracted))
    defer { try? FileManager.default.removeItem(atPath: extracted) }
    #expect(FileManager.default.fileExists(atPath: extracted + "/notes.txt"))
    #expect(FileManager.default.fileExists(atPath: extracted + "/ComicInfo.xml"))
  }

  @Test func testArchiveImagesOnly() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>RT</Title></ComicInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "page2.png": "b", "ComicInfo.xml": xml, "notes.txt": "n"])
    defer { try? FileManager.default.removeItem(at: src) }

    let output = try ComicBook.load(src.path).archive(
      options: ComicBook.ArchiveOptions(to: src.path + ".cbz", contents: .imagesOnly))
    defer { try? FileManager.default.removeItem(atPath: output) }

    let comic = try ComicBook.load(output)
    #expect(try comic.pages().map(\.name) == ["page1.jpg", "page2.png"])
    #expect(try comic.info() == nil)
  }

  @Test func testArchiveImagesAndInfo() throws {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>RT</Title></ComicInfo>"
    let metron = "<?xml version=\"1.0\"?><MetronInfo><Number>1</Number></MetronInfo>"
    let src = try makeFixtureDirectory(["page1.jpg": "a", "ComicInfo.xml": xml, "MetronInfo.xml": metron, "notes.txt": "n"])
    defer { try? FileManager.default.removeItem(at: src) }

    let output = try ComicBook.load(src.path).archive(
      options: ComicBook.ArchiveOptions(to: src.path + ".cbz", contents: .imagesAndInfo))
    defer { try? FileManager.default.removeItem(atPath: output) }

    let comic = try ComicBook.load(output)
    #expect(try comic.info()?.title == "RT")

    let extracted = src.path + "-out.cb"
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: extracted))
    defer { try? FileManager.default.removeItem(atPath: extracted) }
    #expect(FileManager.default.fileExists(atPath: extracted + "/MetronInfo.xml"))
    #expect(!FileManager.default.fileExists(atPath: extracted + "/notes.txt"))
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
