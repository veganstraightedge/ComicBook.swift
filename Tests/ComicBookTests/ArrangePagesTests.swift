import ComicInfo
import Foundation
import Testing

@testable import ComicBook

struct ArrangePagesTests {
  private let xml = """
    <?xml version="1.0"?>
    <ComicInfo>
      <Title>Saga</Title>
      <PageCount>3</PageCount>
      <Pages>
        <Page Image="0" Type="FrontCover" />
        <Page Image="1" Type="Story" Bookmark="Chapter 1" />
        <Page Image="2" Type="BackCover" />
      </Pages>
    </ComicInfo>
    """

  private func contents(_ folder: URL, _ relative: String) throws -> String {
    try String(contentsOf: folder.appendingPathComponent(relative), encoding: .utf8)
  }

  @Test func testReordersPagesByRenumberingThem() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.png": "second", "c.gif": "third"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["c.gif", "a.jpg", "b.png"])

    #expect(pages.map(\.path) == ["page_001.gif", "page_002.jpg", "page_003.png"])
    #expect(try contents(folder, "page_001.gif") == "third")
    #expect(try contents(folder, "page_002.jpg") == "first")
    #expect(try contents(folder, "page_003.png") == "second")
    #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("a.jpg").path))
  }

  @Test func testPagesLeftOutAreDeleted() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second", "c.jpg": "third"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["a.jpg", "c.jpg"])

    #expect(pages.map(\.path) == ["page_001.jpg", "page_002.jpg"])
    #expect(try contents(folder, "page_002.jpg") == "third")
    #expect(try ComicBook.load(folder.path).pages().count == 2)
  }

  @Test func testAbsolutePathsOutsideTheFolderAreAddedAsPages() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    let elsewhere = try makeFixtureDirectory(["new.png": "added"])
    defer {
      try? FileManager.default.removeItem(at: folder)
      try? FileManager.default.removeItem(at: elsewhere)
    }

    let added = elsewhere.appendingPathComponent("new.png").path
    let pages = try ComicBook.load(folder.path).arrangePages(["a.jpg", added, "b.jpg"])

    #expect(pages.map(\.path) == ["page_001.jpg", "page_002.png", "page_003.jpg"])
    #expect(try contents(folder, "page_002.png") == "added")
    // The outside file is copied, not moved.
    #expect(FileManager.default.fileExists(atPath: added))
  }

  @Test func testAbsolutePathsInsideTheFolderAreTheExistingPages() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages([
      folder.appendingPathComponent("b.jpg").path, folder.appendingPathComponent("a.jpg").path,
    ])

    #expect(pages.map(\.path) == ["page_001.jpg", "page_002.jpg"])
    #expect(try contents(folder, "page_001.jpg") == "second")
  }

  @Test func testPagesStayInTheSubfolderTheyWereIn() throws {
    let folder = try makeFixtureDirectory(["simple/page1.jpg": "first", "simple/page2.png": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["simple/page2.png", "simple/page1.jpg"])

    #expect(pages.map(\.path) == ["simple/page_001.png", "simple/page_002.jpg"])
    #expect(try contents(folder, "simple/page_001.png") == "second")
  }

  @Test func testPagesFromDifferentSubfoldersGoToTheirSharedParent() throws {
    let folder = try makeFixtureDirectory(["book/one/a.jpg": "first", "book/two/b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["book/two/b.jpg", "book/one/a.jpg"])

    #expect(pages.map(\.path) == ["book/page_001.jpg", "book/page_002.jpg"])
  }

  @Test func testOtherFilesAreLeftAlone() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second", "notes.txt": "n", "MetronInfo.xml": "m"])
    defer { try? FileManager.default.removeItem(at: folder) }

    try ComicBook.load(folder.path).arrangePages(["b.jpg"])

    #expect(try contents(folder, "notes.txt") == "n")
    #expect(try contents(folder, "MetronInfo.xml") == "m")
  }

  @Test func testNumbersArePaddedToAtLeastThreeDigits() throws {
    var files: [String: String] = [:]
    for number in 1...1000 { files["p\(String(format: "%04d", number)).jpg"] = "\(number)" }
    let folder = try makeFixtureDirectory(files)
    defer { try? FileManager.default.removeItem(at: folder) }

    let comic = try ComicBook.load(folder.path)
    let pages = try comic.arrangePages(try comic.pages().map(\.path))

    #expect(pages.first?.path == "page_0001.jpg")
    #expect(pages.last?.path == "page_1000.jpg")
    #expect(try contents(folder, "page_1000.jpg") == "1000")
  }

  @Test func testComicInfoPageEntriesFollowTheirPages() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second", "c.jpg": "third", "ComicInfo.xml": xml])
    let elsewhere = try makeFixtureDirectory(["new.jpg": "added"])
    defer {
      try? FileManager.default.removeItem(at: folder)
      try? FileManager.default.removeItem(at: elsewhere)
    }

    // Back cover first, the story page deleted, a new page added at the end.
    let comic = try ComicBook.load(folder.path)
    try comic.arrangePages(["c.jpg", "a.jpg", elsewhere.appendingPathComponent("new.jpg").path])

    let info = try #require(try comic.info())
    #expect(info.title == "Saga")
    #expect(info.pageCount == 3)
    #expect(info.pages.map(\.image) == [0, 1, 2])
    #expect(info.pages.map(\.type) == [.backCover, .frontCover, .story])
    #expect(info.pages.allSatisfy { $0.bookmark.isEmpty })
  }

  @Test func testFolderWithoutComicInfoGetsNone() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    try ComicBook.load(folder.path).arrangePages(["b.jpg", "a.jpg"])

    #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("ComicInfo.xml").path))
  }

  @Test func testWorksOnACbFolder() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"], suffix: ".cb")
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["b.jpg", "a.jpg"])
    #expect(pages.map(\.path) == ["page_001.jpg", "page_002.jpg"])
  }

  @Test func testMissingSourceThrowsAndChangesNothing() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    #expect(throws: ComicBookError.self) {
      try ComicBook.load(folder.path).arrangePages(["b.jpg", "nope.jpg"])
    }
    #expect(try ComicBook.load(folder.path).pages().map(\.path) == ["a.jpg", "b.jpg"])
  }

  @Test func testNonImageSourceThrows() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "notes.txt": "n"])
    defer { try? FileManager.default.removeItem(at: folder) }

    #expect(throws: ComicBookError.unsupportedFileType(".txt")) {
      try ComicBook.load(folder.path).arrangePages(["a.jpg", "notes.txt"])
    }
  }

  @Test func testArchivesCannotBeArranged() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first"])
    defer { try? FileManager.default.removeItem(at: folder) }
    let archive = try ComicBook.archive(folder.path, options: .init(to: tempPath(extension: "cbz")))
    defer { try? FileManager.default.removeItem(atPath: archive) }

    #expect(throws: ComicBookError.self) {
      try ComicBook.load(archive).arrangePages(["a.jpg"])
    }
  }
}
