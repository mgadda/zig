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
    guard let _ = Repository.initRepo() else {
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

    if let blob = repo.readObject(id: id, type: Blob.self) {
      print(blob.description(repository: repo, verbose: true))
    } else if let tree = repo.readObject(id: id, type: Tree.self) {
      print(tree.description(repository: repo, verbose: true))
    } else if let commit = repo.readObject(id: id, type: Commit.self) {
      print(commit.description(repository: repo, verbose: true))
    } else {
      print("Unknown object")
    }    
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

  case (3, "resolve"):
    guard let repo = Repository() else {
      exit(1)
    }
    guard let resolved = repo.resolve(ref: CommandLine.arguments[2]) else {
      print("Could not resolve ref")
      exit(1)
    }

    print(resolved.description())

  break

  default:
    printHelp()
    break
}
