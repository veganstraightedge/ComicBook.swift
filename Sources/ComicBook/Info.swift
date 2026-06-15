//
// Info.swift
// ComicBook
//

import ComicInfo

extension ComicBook {
  /// Metadata parsed from a `ComicInfo.xml` inside an archive or folder.
  ///
  /// This is the `ComicInfo.Issue` type from the ComicInfo.swift package, mirroring the Ruby gem's
  /// `ComicBook::Info = ComicInfo::Issue`.
  public typealias Info = ComicInfo.Issue
}
