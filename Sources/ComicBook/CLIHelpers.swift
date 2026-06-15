//
// CLIHelpers.swift
// ComicBook
//

import Foundation

extension ComicBook {
  /// Optional directory containing signed `unar`/`lsar` binaries to use instead of the bundled copies.
  ///
  /// Set this from a sandboxed macOS app that embeds and code-signs its own `unar`/`lsar`, so the
  /// library runs them in place (the bundled copies are run from a writable cache, which the sandbox
  /// disallows). The CLI and non-sandboxed apps can leave this nil.
  nonisolated(unsafe) public static var rarToolsDirectory: String?
}

#if os(macOS)
  /// Shell-out helpers for RAR (CBR) via the bundled `lsar`/`unar` (The Unarchiver, MPL-licensed).
  enum CLIHelpers {
    /// Resolve an executable tool: the `rarToolsDirectory` override, else the bundled resource (copied to
    /// a cache and made executable), else `PATH`.
    static func toolURL(_ name: String) throws -> URL {
      if let directory = ComicBook.rarToolsDirectory {
        let url = URL(fileURLWithPath: directory).appendingPathComponent(name)
        if FileManager.default.isExecutableFile(atPath: url.path) { return url }
      }
      if let bundled = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Resources") {
        return try executableCopy(of: bundled, name: name)
      }
      if let onPath = which(name) { return URL(fileURLWithPath: onPath) }
      throw ComicBookError.dependencyMissing("'\(name)' was not found (bundled, overridden, or on PATH)")
    }

    /// `lsar <archive>` → entry names (dropping lsar's first header line), matching the Ruby gem.
    static func lsarList(_ archivePath: String) throws -> [String] {
      let result = try run(try toolURL("lsar"), [archivePath])
      guard result.status == 0 else { throw ComicBookError.extractionError("lsar failed: \(result.output)") }
      return result.output.split(separator: "\n", omittingEmptySubsequences: false)
        .dropFirst()
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    }

    /// `unar -o <destination> -f -D <archive>` (force overwrite, no enclosing dir).
    static func unarExtract(_ archivePath: String, to destination: String) throws {
      let result = try run(try toolURL("unar"), ["-o", destination, "-f", "-D", archivePath])
      guard result.status == 0 else { throw ComicBookError.extractionError("unar extraction failed: \(result.output)") }
    }

    // MARK: - Internals

    private static func executableCopy(of source: URL, name: String) throws -> URL {
      let fileManager = FileManager.default
      let cache = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ComicBook.swift", isDirectory: true)
      try fileManager.createDirectory(at: cache, withIntermediateDirectories: true)
      let destination = cache.appendingPathComponent(name)

      // Copy to a unique temp, make it executable, then atomically move into place. This tolerates
      // concurrent callers (the destination only appears once it is complete and executable).
      if !fileManager.isExecutableFile(atPath: destination.path) {
        let temporary = cache.appendingPathComponent("\(name).\(UUID().uuidString)")
        try fileManager.copyItem(at: source, to: temporary)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: temporary.path)
        do {
          try fileManager.moveItem(at: temporary, to: destination)
        } catch {
          try? fileManager.removeItem(at: temporary)
          if !fileManager.isExecutableFile(atPath: destination.path) { throw error }
        }
      }
      return destination
    }

    private static func which(_ name: String) -> String? {
      let result = try? run(URL(fileURLWithPath: "/usr/bin/which"), [name])
      guard let result, result.status == 0 else { return nil }
      let path = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
      return path.isEmpty ? nil : path
    }

    @discardableResult
    private static func run(_ toolURL: URL, _ arguments: [String]) throws -> (status: Int32, output: String) {
      let process = Process()
      process.executableURL = toolURL
      process.arguments = arguments
      let pipe = Pipe()
      process.standardOutput = pipe
      process.standardError = pipe
      try process.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
  }
#endif
