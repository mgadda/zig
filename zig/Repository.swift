//
//  Repository.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

class Repository {
  let rootUrl: URL // working tree
  let HEADUrl: URL // .zig/HEAD
  let objectDir: URL // .zig/objects
  let refsUrl: URL // .zig/refs
  let branchHeadsUrl: URL // .zig/refs/heads
  let tagsUrl: URL // .zig/refs/tags

  private static let fileman = FileManager.default

  init?() {
    if let url = Repository.findRepositoryRoot() {
      rootUrl = url
      let zigUrl = rootUrl.appendingPathComponent(".zig", isDirectory: true)

      HEADUrl = zigUrl.appendingPathComponent("HEAD", isDirectory: false)
      objectDir = zigUrl.appendingPathComponent("objects", isDirectory: true)
      refsUrl = zigUrl.appendingPathComponent("refs", isDirectory: true)
      branchHeadsUrl = refsUrl.appendingPathComponent("heads", isDirectory: true)
      tagsUrl = refsUrl.appendingPathComponent("tags", isDirectory: true)

    } else {
      print("Not a valid zig repository")
      return nil
    }
  }

  var commits: CommitView {
    get {
      return CommitView(repository: self)
    }
  }

  private class func findRepositoryRoot(
    startingAt cwd: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  ) -> URL? {
    if FileManager.default.fileExists(atPath: cwd.appendingPathComponent(".zig").path) {
      return cwd
    } else {
      if cwd.deletingLastPathComponent().path == "/" {
        return nil
      }
      return findRepositoryRoot(startingAt: cwd.deletingLastPathComponent())
    }
  }

  func writeObject(object: ObjectLike) {
    let (objIdPrefix, filename) = splitId(id: object.id)

    // TODO: this shouldn't happen with every attempt to write an object
    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
    try! FileManager.default.createDirectory(
      atPath: prefixedObjDir.path,
      withIntermediateDirectories: true, attributes: nil
    )

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    NSKeyedArchiver.archiveRootObject(object, toFile: fileURL.path)
  }

  func readObject(id: Data) -> ObjectLike? {
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
      writeObject(object: object)
    }
    return object
  }

  func snapshot() -> ObjectLike {
    // TODO: CTRL+C to bail out
    print("Snapshot message: ", terminator: "")
    let msg = readLine()!

    let topLevelTree = _snapshot(startingAt: rootUrl)

    let headContents = getHEADContents()
    let parentId: Data? = resolve(.unknown(headContents)).flatMap {
      guard case let .commit(id) = $0 else {
        return nil
      }
      return id.base16DecodedData()
    }

    let commit = Commit(
      parentId: parentId,
      author: Author(name: "Matt Gadda", email: "mgadda@gmail.com"),
      createdAt: Date(),
      treeId: topLevelTree.id,
      message: msg)

    writeObject(object: commit)

    switch identifyUnknown(headContents) {
    case let .branch(name)?:
      // TODO: fix up this crazy data conversion!
      trounce(branchHeadsUrl.appendingPathComponent(name), content: commit.id.base16EncodedString().data(using: .utf8)!)
      break

    default:
      // head was garbage, empty, or a commit id
      updateHEAD(commitId: commit.id)

      break
    }
    return topLevelTree
  }

  /*
   if it's a branch, write "refs/heads/[branch]" into HEAD
   if it's a commit, write base 16 encoded string into HEAD
   if it's a tag, do same as commit
   */
  func updateHEAD(branch: String) {
    updateHEAD(content: "refs/heads/\(branch)".data(using: .utf8)!)
  }

  func updateHEAD(commitId: Data) {
    updateHEAD(content: commitId.base16EncodedString().data(using: .utf8)!)
  }

  private func updateHEAD(content: Data) {
    trounce(HEADUrl, content: content)
  }

  // Overwrite file with new content, create it if it doesn't already exist
  private func trounce(_ url: URL, content: Data) {
    if let file = FileHandle(forUpdatingAtPath: url.path) {
      file.truncateFile(atOffset: 0)
      file.write(content)
      file.closeFile()
    } else {
      Repository.fileman.createFile(atPath: url.path, contents: content, attributes: nil)
    }
  }

  private func _snapshot(startingAt dir: URL) -> ObjectLike {
    let urls = try! Repository.fileman.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

    let entries = urls.map { (url: URL) -> Entry in
      let attributes = try! FileManager.default.attributesOfItem(atPath: url.path)
      let perms = attributes[FileAttributeKey.posixPermissions] as? Int ?? 0

      let object: ObjectLike
      if url.hasDirectoryPath {

        // recurse to produce object
        object = _snapshot(startingAt: url)
      } else {
        object = Blob(content: try! Data(contentsOf: url))
      }
      writeObject(object: object)
      return Entry(permissions: perms, objectId: object.id, name: url.lastPathComponent)
    }

    let topLevelTree = Tree(entries: entries)
    writeObject(object: topLevelTree)
    return topLevelTree
  }

  func checkout(ref: Reference) {
    // resolve ref into commit
    // read commit object
    // checkout top level tree contains recursively
    // don't delete things that haven't changed
    guard case let .commit(commitId) = resolve(ref) else {
      print("This is not a commit")
      return
    }

    guard let commit as? Commit = readObject(id: commitId) else {
      print("This not a commit object")
      return
    }

    
  }

  func getHEADContents() -> String {
    let headContents = try! Data(contentsOf: HEADUrl)
    return String(data: headContents, encoding: .utf8)!
  }

  func resolveBranchOrTag(_ name: String, path: String) -> Reference? {
    let branchFileUrl = rootUrl
      .appendingPathComponent(".zig", isDirectory: true)
      .appendingPathComponent("refs", isDirectory: true)
      .appendingPathComponent(path, isDirectory: true)
      .appendingPathComponent(name)

    if let contents = try? String(contentsOfFile: branchFileUrl.path) {
      return Reference.commit(contents)
    }
    return nil
  }

  private func findFile(filename: String, directory: URL) -> URL? {
    guard let dirContents = try?  Repository.fileman.contentsOfDirectory(at: directory, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) else {
      return nil
    }
    return dirContents.filter { $0.lastPathComponent == filename }.first
  }

  private func parseSymbolicRef(ref: String) -> Reference? {
    guard !ref.isEmpty else {
      return nil
    }

    var refComponents = ref.characters.split(
      separator: "/",
      maxSplits: 2,
      omittingEmptySubsequences: true
    ).map(String.init)
    
    let tagOrBranchName = refComponents.popLast()!

    if refComponents.last == "heads" {
      return findFile(filename: tagOrBranchName, directory: branchHeadsUrl).map {
        Reference.branch($0.lastPathComponent)
      }
    } else if refComponents.last == "tags" {
      return findFile(filename: tagOrBranchName, directory: tagsUrl).map {
        Reference.tag($0.lastPathComponent)
      }
    } else {
      // search heads, then search tags for match
      return findFile(filename: tagOrBranchName, directory: branchHeadsUrl).map {
        Reference.branch($0.lastPathComponent)
        } ?? findFile(filename: tagOrBranchName, directory: tagsUrl).map {
          Reference.tag($0.lastPathComponent)
      }
    }
  }

  private func identifyUnknown(_ str: String) -> Reference? {
    if str == "HEAD" {
      return .head
    }
    if let _ = str.range(of: "^[a-fA-F0-9]{6,40}$", options: .regularExpression) {
      return .commit(str)
    }
    return parseSymbolicRef(ref: str)
  }
  // Attempt to resolve a String into something that
  // represents a commit object.
  // If full is false, resolve will stop only one step from the input.
  // A step may consist of converting:
  //  * "HEAD" into its contents.
  //  * A partial ref into a fully qualified one (master -> Reference)
  //  * A fully qualified ref into a commit id
  // If the resolution is ambiguous, multiple results may be returned
  //
  // Attempt to resolve committish into a real commit id
  // Here are things resolve can resolve:
  // commit ids, partial commit ids, symbolic refs, HEAD, branch names
  //
  // Examples:
  //
  // "0fd0bcfb44f83e7d5ac7a8922578276b9af48746" -> 0fd0bcfb44f83e7d5ac7a8922578276b9af48746
  // "0fd0bc" -> 0fd0bcfb44f83e7d5ac7a8922578276b9af48746
  // refs/heads/master -> commit id
  // heads/master -> commit id
  // @HEAD -> @refs/heads/master
  // @HEAD -> @refs/tag/v0.1.0
  //
  internal func resolve(_ ref: Reference) -> Reference? {
    switch ref {
    case let .unknown(str):
      return identifyUnknown(str).flatMap { resolve($0) }

    case .head:
      return resolve(.unknown(getHEADContents()))

    case let .branch(name):
      return resolveBranchOrTag(name, path: "heads").flatMap { resolve($0) }

    case let .tag(name):
      return resolveBranchOrTag(name, path: "tags").flatMap { resolve($0) }

    case let .commit(id):
      if id.characters.count == 40 {
        return ref
      } else {
        let (prefix, partialSuffix) = (String(id.characters.prefix(2)), String(id.characters.dropFirst(2)))
        let prefixedUrl = objectDir.appendingPathComponent(prefix, isDirectory: true)

        let objectUrls = try! Repository.fileman.contentsOfDirectory(
          at: prefixedUrl,
          includingPropertiesForKeys: [],
          options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

        let candidateUrls = objectUrls.filter { $0.lastPathComponent.hasPrefix(partialSuffix) }

        if candidateUrls.count > 1 {
          print("warning: ambiguous ref")
        }

        return candidateUrls.first.map { url in
          return .commit((prefix + url.lastPathComponent))
        }
      }

    }
  }

  func resolve(ref: String) -> Reference? {
    return resolve(.unknown(ref))
  }

  class func initRepo() -> Repository? {
    let cwdUrl = URL(fileURLWithPath: fileman.currentDirectoryPath)
    let zigDir = cwdUrl.appendingPathComponent(".zig")

    guard !fileman.fileExists(atPath: zigDir.path) else {
      print("Directory already contains a repository")
      return nil
    }

    try! fileman.createDirectory(at: zigDir, withIntermediateDirectories: false, attributes: nil)

    fileman.createFile(atPath: zigDir.appendingPathComponent("HEAD").path, contents: Data(), attributes: nil)

    let headsDir = zigDir.appendingPathComponent("refs").appendingPathComponent("heads")
    try! fileman.createDirectory(at: headsDir, withIntermediateDirectories: true, attributes: nil)

    let tagsDir = zigDir.appendingPathComponent("refs").appendingPathComponent("tags")
    try! fileman.createDirectory(at: tagsDir, withIntermediateDirectories: true, attributes: nil)

    return Repository()
  }
}

indirect enum Reference {
  case unknown(String)
  case head
  case branch(String)
  case tag(String)
  case commit(String)

  func description() -> String {
    switch self {
    case let .unknown(s):
      return "Could not resolve \(s)"
    case .head:
      return "HEAD"
    case let .branch(name):
      return "refs/heads/\(name)"
    case let .tag(name):
      return "refs/tags/\(name)"
    case let .commit(id):
      return id
    }
  }
}
