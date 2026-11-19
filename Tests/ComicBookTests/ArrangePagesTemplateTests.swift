import ComicInfo
import Foundation
import Testing

@testable import ComicBook

struct ArrangePagesTemplateTests {
  private let xml = """
    <?xml version="1.0"?>
    <ComicInfo>
      <Series>Saga</Series>
      <Number>7</Number>
      <PageCount>2</PageCount>
    </ComicInfo>
    """

  @Test func testDefaultTemplateIsTheOneUsedWhenNoneIsGiven() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.png": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    #expect(ComicBook.defaultPageFilenameTemplate == "page_{page:3}")
    let pages = try ComicBook.load(folder.path).arrangePages(["b.png", "a.jpg"])
    #expect(pages.map(\.path) == ["page_001.png", "page_002.jpg"])
  }

  @Test func testPagesAreNamedFromTheTemplate() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.png": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["b.png", "a.jpg"], template: "scan-{page:4}")

    #expect(pages.map(\.path) == ["scan-0001.png", "scan-0002.jpg"])
    #expect(try String(contentsOf: folder.appendingPathComponent("scan-0001.png"), encoding: .utf8) == "second")
  }

  @Test func testTemplateCanUseTheComicsDetails() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second", "ComicInfo.xml": xml])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path)
      .arrangePages(["a.jpg", "b.jpg"], template: "{series}_{number:3}_{page:4}")

    #expect(pages.map(\.path) == ["Saga_007_0001.jpg", "Saga_007_0002.jpg"])
  }

  @Test func testDetailsAreLeftOutWhenThereIsNoComicInfo() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["a.jpg", "b.jpg"], template: "{series} {page:2}")

    #expect(pages.map(\.path) == ["01.jpg", "02.jpg"])
  }

  @Test func testTemplateWithoutAPageNumberStillKeepsPagesApart() throws {
    let folder = try makeFixtureDirectory(["a.jpg": "first", "b.jpg": "second"])
    defer { try? FileManager.default.removeItem(at: folder) }

    let pages = try ComicBook.load(folder.path).arrangePages(["b.jpg", "a.jpg"], template: "scan")

    #expect(pages.map(\.path) == ["scan_1.jpg", "scan_2.jpg"])
    #expect(try String(contentsOf: folder.appendingPathComponent("scan_1.jpg"), encoding: .utf8) == "second")
  }

  @Test func testNamesStayInPageOrderPastNinePages() throws {
    var files: [String: String] = [:]
    for number in 1...12 { files["p\(String(format: "%02d", number)).jpg"] = "\(number)" }
    let folder = try makeFixtureDirectory(files)
    defer { try? FileManager.default.removeItem(at: folder) }

    let comic = try ComicBook.load(folder.path)
    let pages = try comic.arrangePages(try comic.pages().map(\.path).reversed(), template: "p{page}")

    #expect(pages.first?.path == "p01.jpg")
    #expect(pages.last?.path == "p12.jpg")
    #expect(try String(contentsOf: folder.appendingPathComponent("p01.jpg"), encoding: .utf8) == "12")
  }
}
