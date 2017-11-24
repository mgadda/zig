//
//  main.swift
//  zig
//
//  Created by Matt Gadda on 9/13/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation
import MessagePackEncoder

func printHelp() {
  print("zig: source control for the future")
  print("\nusage: zig init|snapshot")
  exit(1)
}

let fileman = FileManager.default

let realArgCount = CommandLine.argc - 2

if realArgCount < 0 {
  printHelp()
}

enum OutputFormat {
  case human(verbose: Bool)
  case json
}

switch (realArgCount, CommandLine.arguments[1], Array(CommandLine.arguments.dropFirst(2))) {
case (_, "writedummy", _):
  exit(1)
//  let blob = Blob(content: "Hello, world!\n".data(using: .utf8)!)
//
//  let url = URL(fileURLWithPath: "/tmp/\(blob.id.base16EncodedString())")
//  FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
//  var file = try! FileHandle(forWritingTo: url)
//  blob.serialize(file: &file)
//  exit(0)
  
//case (0, "init", _):
//  guard let _ = Repository.initRepo() else {
//    exit(1)
//  }

case let (1...2, "hash", args):
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

  case .json:
    let objectForEncoding = ObjectContainer(object: object)
    print(String(data: try! JSONEncoder().encode(objectForEncoding), encoding: .utf8)!)
  }

case let(1, "rawcat", args):
  guard let repo = Repository() else {
    exit(1)
  }
  guard let objectData = repo.loadObjectData(id: args[0].base16DecodedData()) else {
    fatalError("Coud not load object data for \(args[0])")
  }

  FileHandle.standardOutput.write(objectData)
//  print(objectData.base64EncodedString())

case let (2...3, "cat", args):
  guard let repo = Repository() else {
    exit(1)
  }

  var outputFormat: OutputFormat = .human(verbose: true)

  let id: String
  let type: String = args[0]

  if args.count >= 2 && args[1] == "--json" {
    outputFormat = .json
    id = args[2]
  } else {
    id = args[1]
  }

  guard let ref = repo.resolve(ref: id),
    case let .commit(objectId) = ref else {
    fatalError("Not a valid ref")
  }

  let encoder = JSONEncoder()

  // TODO: define date and data encoding strategies here

  // This is kind gross: Attempt to read this object as
  // each of the known types until we get back .some(thing)
  // TODO: fix this
  if type == "blob", let blob = repo.readObject(id: objectId.base16DecodedData(), type: Blob.self) {

    switch outputFormat {
    case let .human(verbose):
      print(blob.description(repository: repo, verbose: verbose))
    case .json:
      let objectForEncoding = ObjectContainer(object: blob)
      print(String(data: try! encoder.encode(objectForEncoding), encoding: .utf8)!)
    }

  } else if type == "tree", let tree = repo.readObject(id: objectId.base16DecodedData(), type: Tree.self) {

    switch outputFormat {
    case let .human(verbose):
      print(tree.description(repository: repo, verbose: verbose))
    case .json:
      let objectForEncoding = ObjectContainer(object: tree)
      print(String(data: try! encoder.encode(objectForEncoding), encoding: .utf8)!)
    }

  } else if type == "commit", let commit = repo.readObject(id: objectId.base16DecodedData(), type: Commit.self) {

    switch outputFormat {
    case let .human(verbose):
      print(commit.description(repository: repo, verbose: verbose))
    case .json:
      let objectForEncoding = ObjectContainer(object: commit)
      print(String(data: try! encoder.encode(objectForEncoding), encoding: .utf8)!)
    }

  } else {
    print("Unknown object")
  }

case let (1, "snapshot", args):
  guard let repo = Repository() else {
    exit(1)
  }

  let _ = repo.snapshot(message: args[0])
  print("Wrote \(repo.objectWriteCount) new object(s).")

case (0, "snapshot", _):
  guard let repo = Repository() else {
    exit(1)
  }

  // TODO: CTRL+C to bail out
  print("Snapshot message (press ENTER when finished): ", terminator: "")
  let message = readLine()!

  let _ = repo.snapshot(message: message)
  print("Wrote \(repo.objectWriteCount) new object(s).")

// TODO: allow ref arg
case (0, "log", _):
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

case let (1, "resolve", args):
  guard let repo = Repository() else {
    exit(1)
  }
  guard let resolved = repo.resolve(ref: args[0]) else {
    print("Could not resolve ref")
    exit(1)
  }

  print(resolved.description())

case let(1, "checkout", args):
  guard let repo = Repository() else {
    exit(1)
  }
  do {
    try repo.checkout(ref: .unknown(args[0]))
  } catch ZigError.genericError(let msg) {
    print(msg)
  }

case let(_, "tag", args):
  guard let repo = Repository() else {
    exit(1)
  }
  var tagArgs = args
  guard let name = tagArgs.first else {
    fatalError("Missing tag name as first argument")
  }
  tagArgs.removeFirst()

  repo.createTag(name, ref: tagArgs.first.map { .unknown($0) } )

case (0, "branch", _):
  guard let repo = Repository() else {
    exit(1)
  }
  let out: String = repo.currentBranch ?? "Not currently on a branch"
  print(out)

case let(_, "branch", args):
  guard let repo = Repository() else {
    exit(1)
  }

  var branchArgs = args
  guard let name = branchArgs.first else {
    fatalError("Missing branch name as first argument")
  }
  branchArgs.removeFirst()

  repo.createBranch(name, ref: branchArgs.first.map { .unknown($0) } )
case (_, "status", _):
  guard let repo = Repository() else {
    exit(1)
  }

  repo.status(ref: .head)

case let (_, cmdName, args):
  let scriptName = "zig-\(cmdName)"
  let which = Process()
  which.launchPath = "/usr/bin/env"
  which.arguments = ["which", scriptName]

  let pipe = Pipe()
  which.standardOutput = pipe
  which.launch()
  which.waitUntilExit()
  if which.terminationStatus == 0 {
    let path = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!.trimmingCharacters(in: CharacterSet.newlines)
    try Shell.replace(with: path, arguments: args)
  } else {
    printHelp()
  }
}
