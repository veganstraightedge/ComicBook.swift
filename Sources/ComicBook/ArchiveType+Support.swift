//
// ArchiveType+Support.swift
// ComicBook
//

import Foundation

extension ComicBook.ArchiveType: CaseIterable {
  public static let allCases: [ComicBook.ArchiveType] = [.cb, .cb7, .cba, .cbr, .cbt, .cbz, .folder, .pdf]

  /// The type for a file extension such as `cbz` or `.CBR`, or nil if it is not a comic format.
  ///
  /// A plain folder has no extension, so this never returns `.folder`.
  public init?(fileExtension: String) {
    let bare = fileExtension.hasPrefix(".") ? String(fileExtension.dropFirst()) : fileExtension
    guard let type = ComicBook.ArchiveType(rawValue: bare.lowercased()), type != .folder else { return nil }
    self = type
  }

  /// The file extension for this type, without a dot, or nil for a plain folder.
  public var fileExtension: String? {
    self == .folder ? nil : rawValue
  }

  /// Whether a comic of this type can be opened: its pages listed, its metadata read.
  ///
  /// False only for `.cba`, which is recognised but not implemented.
  public var isReadable: Bool {
    self != .cba
  }

  /// Whether `archive` can produce this type.
  ///
  /// True for `.cbz`, `.cb7`, `.cbt` and `.cb`. RAR and ACE are proprietary, and PDF is only read.
  public var isWritable: Bool {
    switch self {
    case .cb, .cb7, .cbt, .cbz: true
    case .cba, .cbr, .folder, .pdf: false
    }
  }
}
