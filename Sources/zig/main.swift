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

let realArgCount = CommandLine.argc - 1

if realArgCount < 1 {
  printHelp()
}

struct ObjectContainer : Encodable {
  let id: String
  let type: String
  let object: ObjectLike

  init(object: ObjectLike) {
    self.id = object.id.base16EncodedString()
    self.object = object
    switch object {
    case is Blob:
      type = "blob"
      break
    case is Tree:
      type = "tree"
      break
    case is Commit:
      type = "commit"
      break
    default:
      fatalError("Object type not supported for JSON encoding")
      break
    }
  }
  enum CodingKeys : CodingKey {
    case id, type, object
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(type, forKey: .type)
    switch object {
    case let blob as Blob:
      try container.encode(blob, forKey: .object)
      break
    case let tree as Tree:
      try container.encode(tree, forKey: .object)
      break
    case let commit as Commit:
      try container.encode(commit, forKey: .object)
      break
    default:
      fatalError("Object type not supported for JSON encoding")
      break
    }
  }
}

enum OutputFormat {
  case human(verbose: Bool)
  case json
}

switch (realArgCount, CommandLine.arguments[1], Array(CommandLine.arguments.dropFirst(2))) {
  case (1, "init", _):
    guard let _ = Repository.initRepo() else {
      exit(1)
    }
    break

  case let (2...3, "hash", args):
    guard let repo = Repository() else {
      exit(1)
    }

    var outputFormat: OutputFormat = .human(verbose: true)
    var filename: String
    if args.count >= 1 && args[0] == "--json" {
      outputFormat = .json
      filename = args[1]
    } else {
      filename = args[0]
    }

    let object = repo.hashFile(filename: filename)
    switch outputFormat {
    case let .human(verbose):
      print("id: ", object.id.base16EncodedString())
      print(object.description(repository: repo, verbose: verbose))
      break
    case .json:
      let objectForEncoding = ObjectContainer(object: object)
      print(String(data: try! JSONEncoder().encode(objectForEncoding), encoding: .utf8)!)

      break
    }

    break

  case let (2...3, "cat", args):
    guard let repo = Repository() else {
      exit(1)
    }

    var outputFormat: OutputFormat = .human(verbose: true)

    let id: String
    if args.count >= 1 && args[0] == "--json" {
      outputFormat = .json
      id = args[1]
    } else {
      id = args[0]
    }

    guard let ref = repo.resolve(.unknown(id)),
      case let .commit(objectId) = ref else {
      fatalError("Not a valid ref")
    }

    // This is kind gross: Attempt to read this object as
    // each of the known types until we get back .some(thing)
    if let blob = repo.readObject(id: objectId.base16DecodedData(), type: Blob.self) {

      switch outputFormat {
      case let .human(verbose):
        print(blob.description(repository: repo, verbose: verbose))
      case .json:
        let objectForEncoding = ObjectContainer(object: blob)
        print(String(data: try! JSONEncoder().encode(objectForEncoding), encoding: .utf8)!)
      }

    } else if let tree = repo.readObject(id: objectId.base16DecodedData(), type: Tree.self) {

      switch outputFormat {
      case let .human(verbose):
        print(tree.description(repository: repo, verbose: verbose))
      case .json:
        let objectForEncoding = ObjectContainer(object: tree)
        print(String(data: try! JSONEncoder().encode(objectForEncoding), encoding: .utf8)!)
      }

    } else if let commit = repo.readObject(id: objectId.base16DecodedData(), type: Commit.self) {

      switch outputFormat {
      case let .human(verbose):
        print(commit.description(repository: repo, verbose: verbose))
      case .json:
        let objectForEncoding = ObjectContainer(object: commit)
        print(String(data: try! JSONEncoder().encode(objectForEncoding), encoding: .utf8)!)
      }

    } else {
      print("Unknown object")
    }

  case (1, "snapshot", _):
    guard let repo = Repository() else {
      exit(1)
    }

    let _ = repo.snapshot()
    break

  case (1, "log", _):
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

  case let (2, "resolve", args):
    guard let repo = Repository() else {
      exit(1)
    }
    guard let resolved = repo.resolve(ref: args[0]) else {
      print("Could not resolve ref")
      exit(1)
    }

    print(resolved.description())

  break

  default:
    printHelp()
    break
}
