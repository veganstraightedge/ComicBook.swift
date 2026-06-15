//
// main.swift
// ComicBookCLI
//

import ArgumentParser
import ComicBook
import ComicInfo
import Foundation

// MARK: - Root

struct Comicbook: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "comicbook",
    abstract: "Read, extract, archive, and inspect comic book archives.",
    discussion: """
      Supported formats: .cbz, .cbt, .cb7, .cbr (read-only), .cb folders, and PDF (extract-only).

      EXAMPLES:
        comicbook extract Comic.cbz
        comicbook extract Comic.pdf --dpi 150
        comicbook archive ./pages --to Comic.cbz
        comicbook info Comic.cbz
        comicbook info Comic.cbz --format json
        comicbook pages Comic.cbz
      """,
    version: ComicBook.Version.current,
    subcommands: [Extract.self, Archive.self, Info.self, Pages.self, Version.self]
  )
}

// MARK: - extract

struct Extract: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Extract an archive into a folder.")

  @Argument(help: "The archive (or PDF) to extract.")
  var input: String

  @Option(name: .long, help: "Destination folder (defaults to <name>.cb).")
  var to: String?

  @Option(name: .long, help: "Render DPI for PDFs (default 300).")
  var dpi: Int?

  @Flag(name: .customLong("images-only"), help: "Extract only image files.")
  var imagesOnly = false

  @Flag(name: .customLong("delete-original"), help: "Delete the source after a successful extraction.")
  var deleteOriginal = false

  func run() throws {
    let options = ComicBook.ExtractOptions(
      to: to, imagesOnly: imagesOnly, deleteOriginal: deleteOriginal, dpi: dpi)
    let destination = try ComicBook.extract(input, options: options)
    print("Extracted \(input) to \(destination)")
  }
}

// MARK: - archive

struct Archive: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Archive a folder into a comic book archive.")

  @Argument(help: "The folder of images to archive.")
  var input: String

  @Option(name: .long, help: "Output archive path; its extension selects the format (default .cbz).")
  var to: String?

  @Flag(name: .customLong("delete-original"), help: "Delete the source folder after a successful archive.")
  var deleteOriginal = false

  func run() throws {
    let options = ComicBook.ArchiveOptions(to: to, deleteOriginal: deleteOriginal)
    let output = try ComicBook.archive(input, options: options)
    print("Archived \(input) to \(output)")
  }
}

// MARK: - info

enum InfoFormat: String, CaseIterable, ExpressibleByArgument {
  case verbose
  case terse
  case json
  case yaml
}

struct Info: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Display ComicInfo.xml metadata from an archive.")

  @Argument(help: "The archive or folder to read.")
  var input: String

  @Option(name: .long, help: "Output format: verbose, terse, json, or yaml.")
  var format: InfoFormat = .verbose

  @Option(name: .long, help: "Comma-separated field names to include (verbose/terse).")
  var only: String?

  @Option(name: .long, help: "Comma-separated field names to exclude (verbose/terse).")
  var except: String?

  func run() throws {
    guard let info = try ComicBook.load(input).info() else {
      throw ComicBookError.notSupported("No ComicInfo.xml found in \(input)")
    }

    switch format {
    case .json: print(try info.toJSONString())
    case .yaml: print(try info.toYAMLString())
    case .verbose, .terse: print(try renderFields(info))
    }
  }

  private func renderFields(_ info: ComicBook.Info) throws -> String {
    var fields = try infoFieldPairs(info)
    if let only {
      let keep = Set(commaList(only))
      fields = fields.filter { keep.contains($0.key) }
    }
    if let except {
      let drop = Set(commaList(except))
      fields = fields.filter { !drop.contains($0.key) }
    }

    if format == .terse {
      return fields.map { "\($0.key)=\($0.value)" }.joined(separator: " | ")
    }
    let width = fields.map(\.key.count).max() ?? 0
    return fields.map { "\($0.key.padding(toLength: width, withPad: " ", startingAt: 0))  \($0.value)" }
      .joined(separator: "\n")
  }
}

// MARK: - pages

struct Pages: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "List the image pages in an archive or folder.")

  @Argument(help: "The archive or folder to list.")
  var input: String

  func run() throws {
    for page in try ComicBook.load(input).pages() {
      print(page.path)
    }
  }
}

// MARK: - version

struct Version: ParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Show version information.")

  func run() {
    print("comicbook \(ComicBook.Version.current)")
    print("ComicBook.swift Package")
  }
}

// MARK: - Helpers

private func commaList(_ value: String) -> [String] {
  value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
}

/// Flatten a ComicInfo issue to sorted `(key, value)` string pairs for terse/verbose display
/// (the `pages` array is omitted).
private func infoFieldPairs(_ info: ComicBook.Info) throws -> [(key: String, value: String)] {
  let data = try info.toJSONData()
  guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
  return dictionary.keys.sorted().compactMap { key in
    guard key != "pages" else { return nil }
    return (key, displayValue(dictionary[key]))
  }
}

private func displayValue(_ value: Any?) -> String {
  switch value {
  case let string as String: return string
  case let number as NSNumber: return number.stringValue
  case let array as [Any]: return array.map { displayValue($0) }.joined(separator: ", ")
  case .some(let other): return "\(other)"
  case .none: return ""
  }
}

Comicbook.main()
