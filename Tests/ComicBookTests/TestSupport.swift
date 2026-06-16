import Foundation

/// Create a temp directory populated with the given relative-path → contents files.
func makeFixtureDirectory(_ files: [String: String], suffix: String = "") throws -> URL {
  let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + suffix)
  try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  for (relative, contents) in files {
    let fileURL = dir.appendingPathComponent(relative)
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)
  }
  return dir
}

/// A throwaway temp path (not created) with the given extension, for archive outputs.
func tempPath(extension ext: String) -> String {
  FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)").path
}

/// Run a command-line tool (used to build zip/tar fixtures in tests).
///
/// Returns its exit status.
@discardableResult
func runTool(_ launchPath: String, _ arguments: [String], cwd: URL? = nil) throws -> Int32 {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: launchPath)
  process.arguments = arguments
  if let cwd { process.currentDirectoryURL = cwd }
  process.standardOutput = FileHandle.nullDevice
  process.standardError = FileHandle.nullDevice
  try process.run()
  process.waitUntilExit()
  return process.terminationStatus
}
