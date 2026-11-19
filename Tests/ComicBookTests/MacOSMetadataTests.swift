import Foundation
import Testing

@testable import ComicBook

/// The members macOS adds to archives it makes are not part of the comic.
struct MacOSMetadataTests {
  @Test func testRecognizesAppleDoubleMembersAndTheMacOSXFolder() {
    #expect(ComicBook.isMacOSMetadata("._page1.jpg"))
    #expect(ComicBook.isMacOSMetadata("sub/._page2.png"))
    #expect(ComicBook.isMacOSMetadata("._sub/page2.png"))
    #expect(ComicBook.isMacOSMetadata("__MACOSX/._page1.jpg"))
    #expect(ComicBook.isMacOSMetadata("__MACOSX/sub/page2.png"))
    #expect(ComicBook.isMacOSMetadata("comic/__MACOSX/page1.jpg"))
  }

  @Test func testLeavesOrdinaryFilesAlone() {
    #expect(!ComicBook.isMacOSMetadata("page1.jpg"))
    #expect(!ComicBook.isMacOSMetadata("sub/page2.png"))
    #expect(!ComicBook.isMacOSMetadata("ComicInfo.xml"))
    #expect(!ComicBook.isMacOSMetadata(".hidden.jpg"))
    #expect(!ComicBook.isMacOSMetadata("page._1.jpg"))
    #expect(!ComicBook.isMacOSMetadata("MACOSX/page1.jpg"))
    #expect(!ComicBook.isMacOSMetadata("my__MACOSX/page1.jpg"))
  }

  /// `ditto` is what Finder's Compress uses: extended attributes go in a `__MACOSX` folder.
  @Test func testCbzZippedTheFinderWayHasNoMacOSXPages() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "first", "sub/page2.png": "second"])
    defer { try? FileManager.default.removeItem(at: src) }
    try #require(try runTool("/usr/bin/xattr", ["-w", "com.example.note", "hello", src.path + "/page1.jpg"]) == 0)
    try #require(try runTool("/usr/bin/xattr", ["-w", "com.example.note", "hello", src.path + "/sub/page2.png"]) == 0)
    let cbz = tempPath(extension: "cbz")
    defer { try? FileManager.default.removeItem(atPath: cbz) }
    try #require(try runTool("/usr/bin/ditto", ["-c", "-k", "--sequesterRsrc", src.path, cbz]) == 0)
    // Make sure the archive really carries the folder, or the test proves nothing.
    try #require(try toolOutput("/usr/bin/unzip", ["-Z1", cbz]).contains("__MACOSX/"))

    let comic = try ComicBook.load(cbz)
    #expect(try comic.files().map(\.path) == ["page1.jpg", "sub/page2.png"])
    #expect(try comic.pages().map(\.path) == ["page1.jpg", "sub/page2.png"])

    let destination = tempPath(extension: "cb")
    defer { try? FileManager.default.removeItem(atPath: destination) }
    _ = try comic.extract(options: ComicBook.ExtractOptions(to: destination))
    #expect(!FileManager.default.fileExists(atPath: destination + "/__MACOSX"))
    #expect(FileManager.default.fileExists(atPath: destination + "/sub/page2.png"))
  }

  @Test func testFolderWithAMacOSXFolderHasNoPagesFromIt() throws {
    let src = try makeFixtureDirectory(["page1.jpg": "first", "__MACOSX/page1.jpg": "junk"])
    defer { try? FileManager.default.removeItem(at: src) }

    let comic = try ComicBook.load(src.path)
    #expect(try comic.pages().map(\.path) == ["page1.jpg"])

    let cbz = try comic.archive(options: ComicBook.ArchiveOptions(to: tempPath(extension: "cbz")))
    defer { try? FileManager.default.removeItem(atPath: cbz) }
    #expect(try CBZ(path: cbz).entries().map(\.path) == ["page1.jpg"])
  }
}
