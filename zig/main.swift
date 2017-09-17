//
//  main.swift
//  zig
//
//  Created by Matt Gadda on 9/13/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

func printHelp() {
  print("zig: source control for the future")
  print("\nusage: zig init|snapshot")
  exit(1)
}

let fileman = FileManager.default

if CommandLine.argc < 2 {
  printHelp()
}

switch (CommandLine.argc, CommandLine.arguments[1]) {
  case (2, "init"):
    guard let repo = Repository.initRepo() else {
      exit(1)
    }
    break

  case (3, "hash"):
    guard let repo = Repository() else {
      exit(1)
    }

    let filename = CommandLine.arguments[2]
    let object = repo.hashFile(filename: filename)
    print(object.description(repository: repo, verbose: true))
    break

  case (3, "cat"):
    guard let repo = Repository() else {
      exit(1)
    }

    let id = CommandLine.arguments[2].base16DecodedData()
    let desc = repo.readObject2(id: id).map { $0.description(repository: repo, verbose: true) } ?? "Unknown object"
    print(desc)

  case (2, "snapshot"):
    guard let repo = Repository() else {
      exit(1)
    }

    let _ = repo.snapshot()
    break

  case (2, "log"):
    guard let repo = Repository() else {
      exit(1)
    }

    let pipe = Pipe()
    let less = Process()
    less.launchPath = "/usr/bin/env"
    less.arguments = ["less", "-R", "-X"]
    less.standardInput = pipe

    for commit in repo.commits {
      pipe.fileHandleForWriting.write(commit.description(repository: repo).data(using: .utf8)!)
    }

    less.launch()
    pipe.fileHandleForWriting.closeFile()

  break

  default:
    printHelp()
    break
}
