//
// ComicBook+ArrangePages.swift
// ComicBook
//

import ComicInfo
import Foundation

extension ComicBook {
  /// Make this folder's page images exactly `sources`, in that order.
  ///
  /// Use it to reorder, delete, and add pages of an extracted comic before archiving it again:
  /// ```swift
  /// let comic = try ComicBook.load("Issue1.cb")
  /// // Move the last of three pages to the front, drop the second, and add a new one.
  /// try comic.arrangePages(["page3.jpg", "page1.jpg", "/Users/me/Desktop/extra.png"])
  /// ```
  ///
  /// Each source is an image file: a path relative to the folder for a page already in it, or an
  /// absolute path for a file anywhere (it is copied in). Afterwards:
  ///
  /// - The pages are named `page_001`, `page_002`, … in the given order, keeping their extensions.
  /// - They are in the folder their pages were in before (the shared parent, if there were several).
  /// - Page images left out of `sources` are deleted. Files that are not images are left alone.
  /// - If the folder has a `ComicInfo.xml`, its `<Page>` entries and `PageCount` are updated to
  ///   follow the pages (see `ComicInfo.Issue.rearrangingPages`).
  ///
  /// Only a folder or `.cb` can be arranged; extract an archive first.
  ///
  /// - Parameter sources: The image files that should be the comic's pages, in page order.
  /// - Returns: The comic's pages afterwards.
  /// - Throws: `ComicBookError.notSupported` for an archive, `.pathDoesNotExist` for a missing
  ///   source, `.unsupportedFileType` for a source that is not an image. Nothing is changed then.
  @discardableResult
  public func arrangePages(_ sources: [String]) throws -> [Page] {
    guard type == .folder || type == .cb else {
      throw ComicBookError.notSupported("Cannot arrange the pages of a \(type.rawValue) file; extract it first")
    }

    let folderURL = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let previousPages = try pages().map(\.path)
    let resolved = try sources.map { try resolve($0, in: folderURL, previousPages: previousPages) }

    let staging = FileManager.default.temporaryDirectory
      .appendingPathComponent("ComicBook-arrange-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: staging) }

    do {
      let staged = try stage(resolved.map(\.url), in: staging)
      for previous in previousPages {
        try FileManager.default.removeItem(at: folderURL.appendingPathComponent(previous))
      }

      let pagesURL = folderURL.appendingPathComponent(Self.sharedDirectory(of: previousPages), isDirectory: true)
      try FileManager.default.createDirectory(at: pagesURL, withIntermediateDirectories: true)
      for file in staged {
        try FileManager.default.moveItem(at: file, to: pagesURL.appendingPathComponent(file.lastPathComponent))
      }
    } catch {
      throw ComicBookError.archiveError(error.localizedDescription)
    }

    try updateInfo(in: folderURL, order: resolved.map(\.previousIndex))
    return try pages()
  }

  /// Where a source is on disk, and which page it was before (nil for a file new to the comic).
  private func resolve(
    _ source: String, in folderURL: URL, previousPages: [String]
  ) throws -> (url: URL, previousIndex: Int?) {
    let url =
      source.hasPrefix("/")
      ? URL(fileURLWithPath: source).resolvingSymlinksInPath()
      : folderURL.appendingPathComponent(source)

    guard FileManager.default.fileExists(atPath: url.path) else {
      throw ComicBookError.pathDoesNotExist(url.path)
    }
    guard Self.isImageFile(url.lastPathComponent) else {
      throw ComicBookError.unsupportedFileType(".\(url.pathExtension)")
    }

    let folderPrefix = folderURL.path + "/"
    guard url.path.hasPrefix(folderPrefix) else { return (url, nil) }
    let relative = String(url.path.dropFirst(folderPrefix.count))
    return (url, previousPages.firstIndex(of: relative))
  }

  /// Copy the files into `staging` under their new page names, in order.
  private func stage(_ files: [URL], in staging: URL) throws -> [URL] {
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    let width = max(3, String(files.count).count)

    var staged: [URL] = []
    for (index, file) in files.enumerated() {
      let number = String(repeating: "0", count: width - String(index + 1).count) + String(index + 1)
      let destination = staging.appendingPathComponent("page_\(number).\(file.pathExtension)")
      try FileManager.default.copyItem(at: file, to: destination)
      staged.append(destination)
    }
    return staged
  }

  /// The deepest directory that contains every one of `paths`, relative like them (`""` for the top).
  static func sharedDirectory(of paths: [String]) -> String {
    let directories = paths.map { $0.split(separator: "/").dropLast().map(String.init) }
    guard var shared = directories.first else { return "" }

    for directory in directories.dropFirst() {
      var kept: [String] = []
      for (ours, theirs) in zip(shared, directory) {
        guard ours == theirs else { break }
        kept.append(ours)
      }
      shared = kept
    }
    return shared.joined(separator: "/")
  }

  /// Bring the folder's `ComicInfo.xml` (if any) in step with the rearranged pages.
  private func updateInfo(in folderURL: URL, order: [Int?]) throws {
    let infoURL = folderURL.appendingPathComponent("ComicInfo.xml")
    guard FileManager.default.fileExists(atPath: infoURL.path) else { return }

    let issue = try ComicInfo.load(from: infoURL)
    try issue.rearrangingPages(order).save(to: infoURL)
  }
}
