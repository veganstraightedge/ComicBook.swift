import Foundation
import Testing

@testable import ComicBook

struct ArchiveTypeTests {

  @Test func testEveryTypeIsListed() {
    #expect(Set(ComicBook.ArchiveType.allCases) == [.cb, .cb7, .cba, .cbr, .cbt, .cbz, .folder, .pdf])
  }

  @Test func testReadableTypesAreTheOnesThatCanBeOpened() {
    let readable = ComicBook.ArchiveType.allCases.filter(\.isReadable)
    #expect(Set(readable) == [.cb, .cb7, .cbr, .cbt, .cbz, .folder, .pdf])
    #expect(!ComicBook.ArchiveType.cba.isReadable)
  }

  @Test func testWritableTypesAreTheOnesArchiveCanProduce() {
    let writable = ComicBook.ArchiveType.allCases.filter(\.isWritable)
    #expect(Set(writable) == [.cb, .cb7, .cbt, .cbz])
  }

  @Test func testFileExtensions() {
    #expect(ComicBook.ArchiveType.cbz.fileExtension == "cbz")
    #expect(ComicBook.ArchiveType.cb.fileExtension == "cb")
    #expect(ComicBook.ArchiveType.pdf.fileExtension == "pdf")
    #expect(ComicBook.ArchiveType.folder.fileExtension == nil)
  }

  @Test func testTypeFromFileExtensionIsCaseInsensitive() {
    #expect(ComicBook.ArchiveType(fileExtension: "cbz") == .cbz)
    #expect(ComicBook.ArchiveType(fileExtension: "CBR") == .cbr)
    #expect(ComicBook.ArchiveType(fileExtension: ".pdf") == .pdf)
    #expect(ComicBook.ArchiveType(fileExtension: "zip") == nil)
    #expect(ComicBook.ArchiveType(fileExtension: "folder") == nil)
    #expect(ComicBook.ArchiveType(fileExtension: "") == nil)
  }

  @Test func testWritableTypesCanAllBeArchivedTo() throws {
    for type in ComicBook.ArchiveType.allCases where type.isWritable {
      let source = try makeFixtureDirectory(["page1.jpg": "a"])
      defer { try? FileManager.default.removeItem(at: source) }
      let fileExtension = try #require(type.fileExtension)
      let output = try ComicBook.archive(source.path, options: .init(to: tempPath(extension: fileExtension)))
      defer { try? FileManager.default.removeItem(atPath: output) }
      #expect(try ComicBook.load(output).type == type)
    }
  }

  @Test func testImageFileExtensionsAreListedWithoutDots() {
    #expect(ComicBook.imageFileExtensions == ["bmp", "gif", "jpeg", "jpg", "png", "webp"])
  }

  @Test func testIsImageFileIsCaseInsensitive() {
    #expect(ComicBook.isImageFile("page1.JPG"))
    #expect(ComicBook.isImageFile("folder/page2.webp"))
    #expect(!ComicBook.isImageFile("ComicInfo.xml"))
    #expect(!ComicBook.isImageFile("jpg"))
  }
}
