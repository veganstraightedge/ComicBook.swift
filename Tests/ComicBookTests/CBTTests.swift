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

  /// AppleDouble members are not files or pages of the comic.
  ///
  /// macOS `tar` stores a file's extended attributes as a hidden `._name` member beside it.
  @Test func testMacOSTarAppleDoubleMembersAreNotPages() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "first", "sub/page2.png": "second"])
    defer { try? FileManager.default.removeItem(at: src) }
    // An extended attribute is what makes `tar` add the `._` member.
    try #require(try runTool("/usr/bin/xattr", ["-w", "com.example.note", "hello", src.path + "/page1.jpg"]) == 0)
    try #require(try runTool("/usr/bin/xattr", ["-w", "com.example.note", "hello", src.path + "/sub/page2.png"]) == 0)
    let cbt = tempPath(extension: "cbt")
    defer { try? FileManager.default.removeItem(atPath: cbt) }
    try #require(try runTool("/usr/bin/tar", ["-cf", cbt, "-C", src.path, "page1.jpg", "sub"]) == 0)

    let comic = try ComicBook.load(cbt)
    let entryNames = try CBT(path: cbt).entries().map(\.path).sorted()
    let pageNames = try comic.pages().map(\.path).sorted()
    #expect(entryNames == ["page1.jpg", "sub/page2.png"])
    #expect(pageNames == ["page1.jpg", "sub/page2.png"])

    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: destination))
    #expect(!FileManager.default.fileExists(atPath: destination + "/._page1.jpg"))
    #expect(!FileManager.default.fileExists(atPath: destination + "/sub/._page2.png"))
    #expect(FileManager.default.fileExists(atPath: destination + "/sub/page2.png"))
  }

  @Test func testSystemTarReadsTheCbtWeWrite() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "first", "sub/page2.png": "second", "ComicInfo.xml": "<ComicInfo/>"])
    defer { try? FileManager.default.removeItem(at: src) }
    let cbt = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: tempPath(extension: "cbt")))
    defer { try? FileManager.default.removeItem(atPath: cbt) }

    let listing = try toolOutput("/usr/bin/tar", ["-tf", cbt]).split(separator: "\n").map(String.init).sorted()
    #expect(listing == ["ComicInfo.xml", "page1.jpg", "sub/page2.png"])
    #expect(try toolOutput("/usr/bin/tar", ["-xOf", cbt, "sub/page2.png"]) == "second")
  }

  @Test func testLongAndUnicodePathsRoundTrip() throws {
    // Longer than the 100 characters a classic TAR header holds.
    let long = String(repeating: "deep-folder-name/", count: 9) + String(repeating: "p", count: 120) + ".jpg"
    let unicode = "ページ 01 – café.png"
    let src = try makeFixtureDirectory([long: "long", unicode: "unicode"])
    defer { try? FileManager.default.removeItem(at: src) }
    let cbt = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: tempPath(extension: "cbt")))
    defer { try? FileManager.default.removeItem(atPath: cbt) }

    let paths = try ComicBook.load(cbt).pages().map(\.path)
    #expect(paths.contains(long))
    #expect(paths.contains { $0.precomposedStringWithCanonicalMapping == unicode })
    #expect(try toolOutput("/usr/bin/tar", ["-tf", cbt]).contains(long))

    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }
    _ = try ComicBook.load(cbt).extract(options: ComicBook.ExtractOptions(to: destination))
    #expect(try String(contentsOfFile: destination + "/" + long, encoding: .utf8) == "long")
  }

  @Test func testLargeBinaryAndEmptyFilesRoundTrip() throws {
    let src = try makeFixtureDirectory(["empty.jpg": ""])
    defer { try? FileManager.default.removeItem(at: src) }
    var bytes = Data(count: 3_000_001)
    for index in bytes.indices { bytes[index] = UInt8(truncatingIfNeeded: index &* 31 &+ index >> 8) }
    try bytes.write(to: src.appendingPathComponent("big.png"))

    let cbt = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: tempPath(extension: "cbt")))
    defer { try? FileManager.default.removeItem(atPath: cbt) }
    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }
    _ = try ComicBook.load(cbt).extract(options: ComicBook.ExtractOptions(to: destination))

    #expect(try Data(contentsOf: URL(fileURLWithPath: destination + "/big.png")) == bytes)
    #expect(try Data(contentsOf: URL(fileURLWithPath: destination + "/empty.jpg")).isEmpty)
  }

  @Test func testImagesOnlyExtractionSkipsOtherFiles() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "a", "notes.txt": "n", "ComicInfo.xml": "<ComicInfo/>"])
    defer { try? FileManager.default.removeItem(at: src) }
    let cbt = try ComicBook.load(src.path).archive(options: ComicBook.ArchiveOptions(to: tempPath(extension: "cbt")))
    defer { try? FileManager.default.removeItem(atPath: cbt) }
    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }

    _ = try ComicBook.load(cbt).extract(options: ComicBook.ExtractOptions(to: destination, imagesOnly: true))
    #expect(try FileManager.default.contentsOfDirectory(atPath: destination) == ["page1.jpg"])
  }
}
