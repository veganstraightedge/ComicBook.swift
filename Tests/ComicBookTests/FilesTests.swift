import Foundation
import Testing

@testable import ComicBook

struct FilesTests {
  /// A folder with an image, two info sidecars, and a stray text file.
  func withInfoFolder() throws -> URL {
    let xml = "<?xml version=\"1.0\"?><ComicInfo><Title>T</Title></ComicInfo>"
    return try makeFixtureDirectory([
      "page1.jpg": "a", "ComicInfo.xml": xml, "MetronInfo.xml": xml, "notes.txt": "n",
    ])
  }

  @Test func testAllReturnsEveryFileInPathOrder() throws {
    let dir = try withInfoFolder()
    defer { try? FileManager.default.removeItem(at: dir) }

    let names = try ComicBook(path: dir.path).files(type: .all).map(\.name)
    #expect(names == ["ComicInfo.xml", "MetronInfo.xml", "notes.txt", "page1.jpg"])
  }

  @Test func testImagesReturnsOnlyImages() throws {
    let dir = try withInfoFolder()
    defer { try? FileManager.default.removeItem(at: dir) }

    #expect(try ComicBook(path: dir.path).files(type: .images).map(\.name) == ["page1.jpg"])
  }

  @Test func testImagesAndInfoReturnsImagesPlusSidecars() throws {
    let dir = try withInfoFolder()
    defer { try? FileManager.default.removeItem(at: dir) }

    let names = try ComicBook(path: dir.path).files(type: .imagesAndInfo).map(\.name)
    #expect(names == ["ComicInfo.xml", "MetronInfo.xml", "page1.jpg"])
  }

  @Test func testDefaultsToAll() throws {
    let dir = try withInfoFolder()
    defer { try? FileManager.default.removeItem(at: dir) }

    let comic = try ComicBook(path: dir.path)
    #expect(try comic.files().map(\.name) == comic.files(type: .all).map(\.name))
  }

  @Test func testEntriesCarryFolderRelativePaths() throws {
    let dir = try makeFixtureDirectory(["page1.jpg": "a", "sub/nested.jpg": "b"])
    defer { try? FileManager.default.removeItem(at: dir) }

    let nested = try ComicBook(path: dir.path).files(type: .images).first { $0.name == "nested.jpg" }
    #expect(nested?.path == "sub/nested.jpg")
  }
}
