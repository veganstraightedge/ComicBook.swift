//
// ArchiveType+Signature.swift
// ComicBook
//

import Foundation

extension ComicBook.ArchiveType {
  /// How many leading bytes are enough to recognise any format (TAR's marker ends at byte 262).
  private static let signatureLength = 262

  /// The type of the file at `path`, told from the bytes it starts with.
  ///
  /// Comic files are often mislabelled (a RAR named `.cbz`), so what the file is matters more than
  /// what it is called. Nil when the file can't be read or starts like none of the formats; an old
  /// TAR with no `ustar` marker is one such file.
  static func detecting(contentsOfFileAt path: String) -> ComicBook.ArchiveType? {
    guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
    defer { try? handle.close() }
    guard let data = try? handle.read(upToCount: signatureLength) else { return nil }
    return matching(signature: [UInt8](data))
  }

  /// The type whose signature `bytes` (the start of a file) carries, or nil for none.
  static func matching(signature bytes: [UInt8]) -> ComicBook.ArchiveType? {
    func has(_ marker: [UInt8], at offset: Int = 0) -> Bool {
      bytes.count >= offset + marker.count && Array(bytes[offset..<offset + marker.count]) == marker
    }

    // ZIP: a local file header, or the end record of an empty archive.
    if has([0x50, 0x4B, 0x03, 0x04]) || has([0x50, 0x4B, 0x05, 0x06]) { return .cbz }
    // RAR, versions 4 and 5: "Rar!" 1A 07.
    if has([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07]) { return .cbr }
    // 7-Zip: "7z" BC AF 27 1C.
    if has([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) { return .cb7 }
    // PDF: "%PDF-".
    if has([0x25, 0x50, 0x44, 0x46, 0x2D]) { return .pdf }
    // ACE: "**ACE**" after a 7-byte header.
    if has([0x2A, 0x2A, 0x41, 0x43, 0x45, 0x2A, 0x2A], at: 7) { return .cba }
    // TAR: "ustar" in the first header block.
    if has([0x75, 0x73, 0x74, 0x61, 0x72], at: 257) { return .cbt }
    return nil
  }
}
