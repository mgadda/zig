//
//  main.swift
//  zig
//
//  Created by Matt Gadda on 9/13/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

// Test data
//let blob = Treeish.blob(content: "hello, world".data(using: .utf8)!)
//let tree: Treeish = .tree(entries: [
//  Entry(permissions: 0o777, treeishId: blob.id, name: "test")
//])
//let commit: Treeish = .commit(
//  author: Author(name: "Matt Gadda", email: "mgadda@gmail.com"),
//  createdAt: Date(),
//  treeId: tree.id,
//  message: "Initial commit"
//)

func printHelp() {
  print("zig: source control for the future")
  print("\nusage: zig init|hash [filename]")
  exit(1)
}

let fileman = FileManager.default

if CommandLine.argc < 2 {
  printHelp()
}

switch (CommandLine.argc, CommandLine.arguments[1]) {
  case (2, "init"):
    let zigDir = URL(fileURLWithPath: fileman.currentDirectoryPath)
      .appendingPathComponent(".zig")

    if fileman.fileExists(atPath: zigDir.path) {
      print("Directory already contains a repository")
      exit(1)
    } else {
      try! fileman.createDirectory(
        at: zigDir,
        withIntermediateDirectories: false,
        attributes: nil
      )
      fileman.createFile(atPath: zigDir.appendingPathComponent("HEAD").path, contents: Data(), attributes: nil)
    }
    break

  case (3, "hash"):
    guard let rootURL = getRepositoryRoot() else {
      print("Not a valid zig repository")
      exit(1)
    }

    let filename = CommandLine.arguments[2]
    let path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(filename);
    let object: Treeish
    if path.hasDirectoryPath {
      object = snapshotAll(startingAt: path)
    } else {
      let content = try! Data(contentsOf: path)
      object = Treeish.blob(content: content)
      object.writeObject()
    }
    print(object.debugDescription())
    break

  case (3, "cat"):
    guard let rootURL = getRepositoryRoot() else {
      print("Not a valid zig repository")
      exit(1)
    }

    let id = CommandLine.arguments[2].base16DecodedData()
    let desc = readObject(id: id).map { $0.debugDescription() } ?? "Unknown object"
    print(desc)

  case (2, "snapshot"):

    // find differences between top-level tree and working dir
    // create new tree as appropriate
    // create commit pointing to tree


    guard let rootURL = getRepositoryRoot() else {
      print("Not a valid zig repository")
      exit(1)
    }

    let topLevelTree = snapshotAll(startingAt: getRepositoryRoot()!)
    print("Snapshot message: ", terminator: "")
    let msg = readLine()!
    let commit = Treeish.commit(parentId: getHeadId(), author: Author(name: "Matt Gadda", email: "mgadda@gmail.com"), createdAt: Date(), treeId: topLevelTree.id, message: msg)
    commit.writeObject()


    let HEADURL = rootURL.appendingPathComponent(".zig").appendingPathComponent("HEAD")
    if let file = FileHandle(forUpdatingAtPath: HEADURL.path) {
      file.truncateFile(atOffset: 0)
      file.write(commit.id.base16EncodedString().data(using: .utf8)!)
      file.closeFile()
    } else {
      fileman.createFile(atPath: HEADURL.path, contents: commit.id, attributes: nil)
    }

    break

  case (2, "log"):
    guard let rootURL = getRepositoryRoot() else {
      print("Not a valid zig repository")
      exit(1)
    }

    if let headId = getHeadId() {
      if let head = readObject(id: headId) {
        print(head.debugDescription())
        for commit in head {
          print(commit.debugDescription())
        }
      }
    } else {
      print("No commits yet")
    }
    break

  default:
    printHelp()
    break
}
