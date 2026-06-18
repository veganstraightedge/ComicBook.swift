import Testing

@testable import ComicBook

struct EntryTests {
  @Test func testNameIsBasenameOfPath() {
    #expect(ComicBook.Entry(path: "subfolder/page1.jpg").name == "page1.jpg")
  }

  @Test func testIsImageTrueForImageExtensionsCaseInsensitive() {
    #expect(ComicBook.Entry(path: "page1.JPG").isImage)
    #expect(ComicBook.Entry(path: "a/b/cover.webp").isImage)
  }

  @Test func testIsImageFalseForNonImages() {
    #expect(!ComicBook.Entry(path: "ComicInfo.xml").isImage)
    #expect(!ComicBook.Entry(path: "notes.txt").isImage)
  }

  @Test func testIsInfoTrueForComicInfoAndMetronInfo() {
    #expect(ComicBook.Entry(path: "ComicInfo.xml").isInfo)
    #expect(ComicBook.Entry(path: "sub/MetronInfo.xml").isInfo)
  }

  @Test func testIsInfoFalseOtherwise() {
    #expect(!ComicBook.Entry(path: "page1.jpg").isInfo)
    #expect(!ComicBook.Entry(path: "notes.txt").isInfo)
  }
}
