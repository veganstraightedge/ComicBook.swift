//
// main.swift
// ComicBookCLI
//

import ArgumentParser
import ComicBook
import Foundation

struct Comicbook: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "comicbook",
    abstract: "Read, extract, archive, and inspect comic book archives.",
    version: ComicBook.Version.current
  )
}

Comicbook.main()
