//
// Entry.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// A single member of a comic book: an image, an info file (`ComicInfo.xml` / `MetronInfo.xml`),
  /// or anything else.
  ///
  /// `path` locates it within the comic — an entry name in an archive, a relative path in a folder —
  /// and `name` is its basename.
  public struct Entry: Equatable, Hashable, Codable, Sendable {
    /// The member's path (archive entry name, or folder-relative path).
    public let path: String

    /// The member's file basename.
    public let name: String

    /// Create an entry from its path; `name` is the basename of `path`.
    public init(path: String) {
      self.path = path
      self.name = (path as NSString).lastPathComponent
    }

    /// True if this entry is an image file.
    public var isImage: Bool { ComicBook.isImageFile(name) }

    /// True if this entry is a `ComicInfo.xml` / `MetronInfo.xml` sidecar.
    public var isInfo: Bool { ComicBook.isInfoFile(name) }
  }
}
