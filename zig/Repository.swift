//
//  Repository.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

class Repository {
  let rootUrl: URL
  let objectDir: URL

  private static let fileman = FileManager.default

  var commits: CommitView {
    get {
      return CommitView(repository: self)
    }
  }

  init?() {
    if let url = Repository.getRepositoryRoot() {
      rootUrl = url
      objectDir = rootUrl.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)
    } else {
      print("Not a valid zig repository")
      return nil
    }
  }

  private class func getRepositoryRoot(startingAt cwd: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> URL? {
    if FileManager.default.fileExists(atPath: cwd.appendingPathComponent(".zig").path) {
      return cwd
    } else {
      if cwd.deletingLastPathComponent().path == "/" {
        return nil
      }
      return getRepositoryRoot(startingAt: cwd.deletingLastPathComponent())
    }
  }

  func getHeadId() -> Data? {
    let HEADUrl = rootUrl.appendingPathComponent(".zig").appendingPathComponent("HEAD")
    if let file = FileHandle(forUpdatingAtPath: HEADUrl.path) {
      return String(data: file.readDataToEndOfFile(), encoding: .utf8)?.base16DecodedData()
    }
    return nil
  }

//  func writeObject(treeish: Treeish) {
//    let (objIdPrefix, filename) = splitId(id: treeish.id)
//
//    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
//    try! FileManager.default.createDirectory(
//      atPath: prefixedObjDir.path,
//      withIntermediateDirectories: true, attributes: nil
//    )
//
//    let fileURL = prefixedObjDir.appendingPathComponent(filename)
//    NSKeyedArchiver.archiveRootObject(
//      Treeish.ForCoding(treeish: treeish),
//      toFile: fileURL.path
//    )
//  }

  func writeObject2(object: ObjectLike) {
    let (objIdPrefix, filename) = splitId(id: object.id)

    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
    try! FileManager.default.createDirectory(
      atPath: prefixedObjDir.path,
      withIntermediateDirectories: true, attributes: nil
    )

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    NSKeyedArchiver.archiveRootObject(object, toFile: fileURL.path)
  }

//  func readObject(id: Data) -> Treeish? {
//    let objectDir = rootUrl.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)
//
//    let (objIdPrefix, filename) = splitId(id: id)
//
//    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
//
//    let fileURL = prefixedObjDir.appendingPathComponent(filename)
//    let coding = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? Treeish.ForCoding
//    return coding.flatMap { $0.treeish }
//  }

  func readObject2(id: Data) -> ObjectLike? {
    let objectDir = rootUrl.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)

    let (objIdPrefix, filename) = splitId(id: id)

    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    return NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? ObjectLike
  }

  func hashFile(filename: String) -> ObjectLike {
    // TODO: check that file exists and return nil if not
    let path = URL(fileURLWithPath: Repository.fileman.currentDirectoryPath)
      .appendingPathComponent(filename)

    let object: ObjectLike
    if path.hasDirectoryPath {
      object = _snapshot(startingAt: path)
    } else {
      let content = try! Data(contentsOf: path)
      object = Blob(content: content)
      writeObject2(object: object)
    }
    return object
  }

  func snapshot() -> ObjectLike {
    let topLevelTree = _snapshot(startingAt: rootUrl)
    print("Snapshot message: ", terminator: "")
    let msg = readLine()!
    let commit = Commit(
      parentId: getHeadId(),
      author: Author(name: "Matt Gadda", email: "mgadda@gmail.com"),
      createdAt: Date(),
      treeId: topLevelTree.id,
      message: msg)

    writeObject2(object: commit)

    let HEADUrl = rootUrl.appendingPathComponent(".zig").appendingPathComponent("HEAD")
    if let file = FileHandle(forUpdatingAtPath: HEADUrl.path) {
      file.truncateFile(atOffset: 0)
      file.write(commit.id.base16EncodedString().data(using: .utf8)!)
      file.closeFile()
    } else {
      Repository.fileman.createFile(atPath: HEADUrl.path, contents: commit.id, attributes: nil)
    }
    return topLevelTree
  }

  private func _snapshot(startingAt dir: URL) -> ObjectLike {
    let urls = try! FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

    let entries = urls.map { (url: URL) -> Entry in
      let attributes = try! FileManager.default.attributesOfItem(atPath: url.path)
      let perms = attributes[FileAttributeKey.posixPermissions] as? Int ?? 0

      let object: ObjectLike
      if url.hasDirectoryPath {

        // recurse to produce treeish
        object = _snapshot(startingAt: url)
      } else {
        object = Blob(content: try! Data(contentsOf: url))
      }
      writeObject2(object: object)
      return Entry(permissions: perms, objectId: object.id, name: url.lastPathComponent)
    }

    let topLevelTree = Tree(entries: entries)
    writeObject2(object: topLevelTree)
    return topLevelTree
  }


  class func initRepo() -> Repository? {
    let cwdUrl = URL(fileURLWithPath: fileman.currentDirectoryPath)
    let zigDir = cwdUrl.appendingPathComponent(".zig")

    if fileman.fileExists(atPath: zigDir.path) {
      print("Directory already contains a repository")
      return nil
    } else {
      try! fileman.createDirectory(
        at: zigDir,
        withIntermediateDirectories: false,
        attributes: nil
      )
      fileman.createFile(atPath: zigDir.appendingPathComponent("HEAD").path, contents: Data(), attributes: nil)
    }
    return Repository()
  }
}
