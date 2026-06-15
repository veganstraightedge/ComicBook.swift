import Testing

@testable import ComicBook

struct ComicBookTests {
  @Test func testVersionIsPresent() throws {
    #expect(!ComicBook.Version.current.isEmpty)
  }
}
