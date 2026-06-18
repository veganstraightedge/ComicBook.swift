//
// Page.swift
// ComicBook
//

extension ComicBook {
  /// A single page (image) inside a comic book archive or folder.
  ///
  /// `path` is the location of the page: an in-archive entry name for archives, or a source-relative
  /// path for `.cb`/folder sources. `name` is the basename.
  public struct Page: Equatable, Hashable, Codable, Sendable {
    /// The page's path (in-archive entry name, or source-relative path).
    public let path: String

    /// The page's file basename.
    public let name: String

    /// Create a page from its path and basename.
    public init(path: String, name: String) {
      self.path = path
      self.name = name
    }
  }
}
