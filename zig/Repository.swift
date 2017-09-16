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

  func writeObject(treeish: Treeish) {
    let (objIdPrefix, filename) = splitId(id: treeish.id)

    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
    try! FileManager.default.createDirectory(
      atPath: prefixedObjDir.path,
      withIntermediateDirectories: true, attributes: nil
    )

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    NSKeyedArchiver.archiveRootObject(
      Treeish.ForCoding(treeish: treeish),
      toFile: fileURL.path
    )
  }

  func readObject(id: Data) -> Treeish? {
    let objectDir = rootUrl.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)

    let (objIdPrefix, filename) = splitId(id: id)

    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    let coding = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? Treeish.ForCoding
    return coding.flatMap { $0.treeish }
  }

  func hashFile(filename: String) -> Treeish {
    // TODO: check that file exists and return nil if not
    let path = URL(fileURLWithPath: Repository.fileman.currentDirectoryPath)
      .appendingPathComponent(filename)

    let object: Treeish
    if path.hasDirectoryPath {
      object = _snapshot(startingAt: path)
    } else {
      let content = try! Data(contentsOf: path)
      object = Treeish.blob(content: content)
      writeObject(treeish: object)
    }
    return object
  }

  func snapshot() -> Treeish {
    let topLevelTree = _snapshot(startingAt: rootUrl)
    print("Snapshot message: ", terminator: "")
    let msg = readLine()!
    let commit = Treeish.commit(parentId: getHeadId(), author: Author(name: "Matt Gadda", email: "mgadda@gmail.com"), createdAt: Date(), treeId: topLevelTree.id, message: msg)
    writeObject(treeish: commit)


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

  private func _snapshot(startingAt dir: URL) -> Treeish {
    let urls = try! FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

    let entries = urls.map { (url: URL) -> Entry in
      let attributes = try! FileManager.default.attributesOfItem(atPath: url.path)
      let perms = attributes[FileAttributeKey.posixPermissions] as? Int ?? 0

      let treeish: Treeish
      if url.hasDirectoryPath {

        // recurse to produce treeish
        treeish = _snapshot(startingAt: url)
      } else {
        treeish = Treeish.blob(content: try! Data(contentsOf: url))
      }
      writeObject(treeish: treeish)
      return Entry(permissions: perms, treeishId: treeish.id, name: url.lastPathComponent)
    }

    let topLevelTree = Treeish.tree(entries: entries)
    writeObject(treeish: topLevelTree)
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
