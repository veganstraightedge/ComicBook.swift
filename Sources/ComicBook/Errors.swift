//
// Errors.swift
// ComicBook
//

import Foundation

/// Errors that can occur while working with comic book archives.
public enum ComicBookError: Error, Equatable {
  /// The given path does not exist on disk.
  case pathDoesNotExist(String)

  /// The file's extension is not a recognized comic book type.
  case unsupportedFileType(String)

  /// The requested archive output format is not supported.
  case unsupportedFormat(String)

  /// The operation is not supported for this format (e.g. archiving a CBR or PDF).
  case notSupported(String)

  /// The format is recognized but not yet implemented in the Swift port (e.g. CBA/ACE).
  case notImplemented(String)

  /// Cannot extract something that is already extracted (a folder or `.cb`).
  case alreadyExtracted(String)

  /// The destination path already exists and would be overwritten.
  case destinationExists(String)

  /// A required external tool (e.g. `unar`, `lsar`, `7zz`) is missing.
  case dependencyMissing(String)

  /// An archive could not be created.
  case archiveError(String)

  /// An archive could not be extracted or read.
  case extractionError(String)
}

extension ComicBookError: LocalizedError {
  /// A human-readable description of the error.
  public var errorDescription: String? {
    switch self {
    case .pathDoesNotExist(let path): return "Path does not exist: '\(path)'"
    case .unsupportedFileType(let value): return "Unsupported file type: \(value)"
    case .unsupportedFormat(let value): return "Unsupported archive format: \(value)"
    case .notSupported(let message): return message
    case .notImplemented(let message): return message
    case .alreadyExtracted(let path): return "Cannot extract '\(path)': it is already extracted"
    case .destinationExists(let path): return "Destination already exists: '\(path)'"
    case .dependencyMissing(let message): return message
    case .archiveError(let message): return "Archive error: \(message)"
    case .extractionError(let message): return "Extraction error: \(message)"
    }
  }
}
