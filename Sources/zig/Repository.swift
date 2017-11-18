//
//  Repository.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation
import MessagePackEncoder
import Compression

func findAscending(at url: URL, filename: String) -> [URL] {
  func _findAscending(url: URL, found: [URL]) -> [URL] {
    if url.path == "/" {
      return found
    } else {
      let urlWithFilename = url.appendingPathComponent(filename)
      if FileManager.default.fileExists(atPath: urlWithFilename.path) {
        return _findAscending(url: url.appendingPathComponent("..").standardized, found: found + [urlWithFilename])
      } else {
        return _findAscending(url: url.appendingPathComponent("..").standardized, found: found)
      }
    }
  }
  return _findAscending(url: url, found: [])
}

class Repository {
  let rootUrl: URL // working tree
  let HEADUrl: URL // .zig/HEAD
  let objectDir: URL // .zig/objects
  let refsUrl: URL // .zig/refs
  let branchHeadsUrl: URL // .zig/refs/heads
  let tagsUrl: URL // .zig/refs/tags
  let config: Config
  let gpg: Gpg

  private static let fileman = FileManager.default

  init?() {
    guard let url = Repository.findRepositoryRoot() else {
      print("Not a valid zig repository")
      return nil
    }

    rootUrl = url.standardizedFileURL
    let zigUrl = rootUrl.appendingPathComponent(".zig", isDirectory: true)

    HEADUrl = zigUrl.appendingPathComponent("HEAD", isDirectory: false)
    objectDir = zigUrl.appendingPathComponent("objects", isDirectory: true)
    refsUrl = zigUrl.appendingPathComponent("refs", isDirectory: true)
    branchHeadsUrl = refsUrl.appendingPathComponent("heads", isDirectory: true)
    tagsUrl = refsUrl.appendingPathComponent("tags", isDirectory: true)

    let repoConfigUrl = zigUrl.appendingPathComponent("config")

    guard Repository.fileman.fileExists(atPath: repoConfigUrl.path) else {
      print("Missing .zig/config")
      return nil
    }

    let configUrls: [URL] = ([repoConfigUrl] + Repository.findConfigs(at: rootUrl)).reversed()

    do {
      config = try Repository.loadMergedConfigs(at: configUrls)
    } catch {
      print(error)
      return nil
    }

    gpg = Gpg(homedir: config.gpg?.homedir?.standardized)
  }

  /// Find all configs from path up to root
  static func findConfigs(at url: URL) -> [URL] {
    return findAscending(at: url, filename: ".zigconfig")
  }

  /// Assumes paths represent json formated files. The files will be merged
  /// and then decoded into a Config.
  /// Currently requires jq 1.4 or higher to be in path
  static func loadMergedConfigs(at paths: [URL]) throws -> Config {
    // cat file1 file2 fileN | jq '.[0]*.[1]*.[N]' | self

    let cat = Process()
    cat.launchPath = "/usr/bin/env"
    cat.arguments = ["cat"] + paths.map { $0.path }

    let jq = Process()
    jq.launchPath = "/usr/bin/env"
    let mergeQuery: String = paths
      .enumerated()
      .map { (index, _) in ".[\(index)]" }
      .joined(separator: "*")

    jq.arguments = ["jq", "-c", "-e", "--slurp", mergeQuery]
    jq.environment = ProcessInfo.processInfo.environment

    let catToJq = Pipe()
    let jqToZig = Pipe()
    cat.standardOutput = catToJq
    jq.standardInput = catToJq
    jq.standardOutput = jqToZig

    cat.launch()
    jq.launch()
    jq.waitUntilExit()

    guard jq.terminationStatus == 0 else {
      throw ZigError.decodingError("Could not merge configs. Perhaps one of them contained invalid JSON.")
    }

    let mergedConfigData = jqToZig.fileHandleForReading.readDataToEndOfFile()

    let decoder = JSONDecoder()
    return try decoder.decode(Config.self, from: mergedConfigData)
  }

  var commits: CommitView {
    get {
      return CommitView(repository: self)
    }
  }

  var currentBranch: String? {
    switch identifyUnknown(getHEADContents()) {
    case let .branch(name)?:
      return name
    default:
      return nil
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

  var objectWriteCount = 0

  func writeObject(object: ObjectLike) {
    let (objIdPrefix, filename) = splitId(id: object.id)

    // TODO: this shouldn't happen with every attempt to write an object
    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)
    try! FileManager.default.createDirectory(
      atPath: prefixedObjDir.path,
      withIntermediateDirectories: true, attributes: nil
    )

    let fileURL = prefixedObjDir.appendingPathComponent(filename)

    guard !Repository.fileman.fileExists(atPath: fileURL.path) else { return }

//    let encoder = MessagePackEncoder()
//    let data: Data?
//    switch object {
//    case let blob as Blob:
//      data = try? encoder.encode(blob)
//      break
//    case let tree as Tree:
//      data = try? encoder.encode(tree)
//      break
//    case let commit as Commit:
//      data = try? encoder.encode(commit)
//      break
//    default:
//      data = nil
//      break
//    }

    let encoder = CMPEncoder(userContext: self)
    object.serialize(encoder: encoder)
    if let compressedData = encoder.buffer.compress() {
      objectWriteCount += 1
      Repository.fileman.createFile(atPath: fileURL.path, contents: compressedData, attributes: nil)
    } else {
      fatalError("BUG: Failed to write object due to encoding or compression issue")
    }
  }

  /// Load and uncompress raw object Data for object `id`
  func loadObjectData(id: Data) -> Data? {
    let (objIdPrefix, filename) = splitId(id: id)

    let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)

    let fileURL = prefixedObjDir.appendingPathComponent(filename)
    return (try? Data(contentsOf: fileURL))?.uncompress()
  }

  func readObject<T: Decodable & Serializable>(id: Data, type: T.Type) -> T? {
//    let decoder = MessagePackDecoder()
    return loadObjectData(id: id).flatMap {
//      try? decoder.decode(type, from: $0)
      let decoder = CMPDecoder(from: $0, userContext: self)
      return try? T(with: decoder)
    }
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

  func snapshot(message: String) -> ObjectLike {
    let topLevelTree = _snapshot(startingAt: rootUrl)

    let headContents = getHEADContents()
    let parentId: Data? = resolve(.head)?.commit?.base16DecodedData()

    let commit = Commit(
      parentId: parentId,
      author: config.author,
      createdAt: Date(),
      treeId: topLevelTree.id,
      message: message)

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

  /// Overwrite file with new content, create it if it doesn't already exist
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
    let urls = try! Repository.fileman.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants).map { $0.standardizedFileURL } // removes "private" from /tmp urls

    // return (url does not match zignore) and != rootUrl
    let zignoreUrl = dir.appendingPathComponent(".zignore")
    let ignoredPaths: [URL]
    if let ignoredGlobs = try? String(data: Data(contentsOf: zignoreUrl), encoding: .utf8)!.split(separator: "\n", omittingEmptySubsequences: true) {
      ignoredPaths = glob(patterns: ignoredGlobs.map { String($0) }, relativeTo: dir)
    } else {
      ignoredPaths = []
    }

    let zigUrl = rootUrl.appendingPathComponent(".zig", isDirectory: true)
    let validUrls = Set(urls).subtracting(Set(ignoredPaths).union([zigUrl]))

    let entries = validUrls.map { (url: URL) -> Entry in
      let attributes = try! FileManager.default.attributesOfItem(atPath: url.path)
      let perms = attributes[FileAttributeKey.posixPermissions] as? Int ?? 0 // TODO: pick sensible default

      let object: ObjectLike
      if url.hasDirectoryPath {

        // recurse to produce object (tree or blob)
        object = _snapshot(startingAt: url)
        writeObject(object: object)
        return Entry(permissions: perms, objectId: object.id, objectType: "tree", name: url.lastPathComponent)        

      } else {
        object = Blob(content: try! Data(contentsOf: url))
        writeObject(object: object)
        return Entry(permissions: perms, objectId: object.id, objectType: "blob", name: url.lastPathComponent)
      }
    }

    let topLevelTree = Tree(entries: entries)
    writeObject(object: topLevelTree)
    return topLevelTree
  }

  func checkout(ref: Reference) throws {
    // resolve ref into commit
    // read commit object
    // checkout top level tree contains recursively
    // don't delete things that haven't changed
    guard
      let commitRef = resolve(ref),
      let commitId = commitRef.commit else {
      print("Could not resolve to ref")
      return
    }

    guard let commit = readObject(id: commitId.base16DecodedData(), type: Commit.self) else {
      print("\(ref) is not a commit object")
      return
    }

    guard let newTree = readObject(id: commit.treeId, type: Tree.self) else {
      print("Zig database is probably corrupted because \(commit.treeId) does not exist")
      return
    }

    guard let currentHeadCommitId = resolve(.head)?.commit?.base16DecodedData() else {
      print("Zig HEAD contains invalid ref")
      return
    }

    guard let currentHeadCommit = readObject(id: currentHeadCommitId, type: Commit.self) else {
      print("Zig database is probably corrupted because \(currentHeadCommitId) does not exist")
      return
    }

    guard let currentTree = readObject(id: currentHeadCommit.treeId, type: Tree.self) else {
      print("Zig database is probably corrupted because \(commit.treeId) does not exist")
      return
    }

    // TODO: handle error. what's our failure strategy here? leave things in
    // broken state? restore to previous state?
    if newTree.id != currentTree.id {
      try _deleteTree(tree: currentTree, at: rootUrl)
      try _checkoutTree(tree: newTree, at: rootUrl)
    }

    // This is a bit ugly: run resolution just one step or two steps depending
    // on what we're attempting to check out.
    switch identifyUnknown(ref.fullyQualifiedName) {
    case let .branch(name)?: updateHEAD(branch: name)
    case .tag?: updateHEAD(commitId: commit.id)
    case .commit?: updateHEAD(commitId: commit.id)
    default:
      break // don't update HEAD
    }
  }

  private func _deleteTree(tree: Tree, at cwd: URL) throws {
    let blobEntries = tree.entries.filter { $0.objectType == "blob" }
    let subtreeEntries = tree.entries.filter { $0.objectType == "tree" }

    for blobEntry in blobEntries {
      let file = cwd.appendingPathComponent(blobEntry.name)
      try? Repository.fileman.removeItem(at: file)
    }

    for subtreeEntry in subtreeEntries {
      let newCwd = cwd.appendingPathComponent(subtreeEntry.name)
      guard let subtree = readObject(id: subtreeEntry.objectId, type: Tree.self) else {
        throw ZigError.genericError("Zig database is probably corrupted because tree \(subtreeEntry.objectId) does not exist")
      }
      try _deleteTree(tree: subtree, at: newCwd)
      let file = cwd.appendingPathComponent(subtreeEntry.name)
      try? Repository.fileman.removeItem(at: file)
    }
  }

  private func _checkoutTree(tree: Tree, at cwd: URL) throws {
    let blobEntries = tree.entries.filter { $0.objectType == "blob" }
    let subtreeEntries = tree.entries.filter { $0.objectType == "tree" }

    for blobEntry in blobEntries {
      let file = cwd.appendingPathComponent(blobEntry.name)
      guard let blob = readObject(id: blobEntry.objectId, type: Blob.self) else {
        throw ZigError.genericError("Could not find object with id \(blobEntry.objectId)")
      }
      Repository.fileman.createFile(atPath: file.path, contents: blob.content, attributes: [FileAttributeKey.posixPermissions : blobEntry.permissions])
    }

    for subtreeEntry in subtreeEntries {
      let newCwd = cwd.appendingPathComponent(subtreeEntry.name)
      guard let subtree = readObject(id: subtreeEntry.objectId, type: Tree.self) else {
        throw ZigError.genericError("Could not find object with id \(subtreeEntry.objectId)")
      }

      let subtreePath = cwd.appendingPathComponent(subtreeEntry.name)
      try Repository.fileman.createDirectory(at: subtreePath, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions : subtreeEntry.permissions])

      try _checkoutTree(tree: subtree, at: newCwd)

    }
  }
//
//  private func changeSet() -> (removed: Set<Entry>, added: Set<Entry>, changed: Set<Entry>) {
//    let tree: Tree
//    let tree2: Tree
//
//    let left = Set(tree.entries)
//    let right = Set(tree2.entries)
//
//  }

  func getHEADContents() -> String {
    let headContents = try! Data(contentsOf: HEADUrl)
    return String(data: headContents, encoding: .utf8)!
  }

  func resolveBranchOrTag(_ name: String, path: String) -> Reference? {
    let refURL = rootUrl
      .appendingPathComponent(".zig", isDirectory: true)
      .appendingPathComponent("refs", isDirectory: true)
      .appendingPathComponent(path, isDirectory: true)
      .appendingPathComponent(name)

    if let contents = try? String(contentsOfFile: refURL.path) {
      return Reference.commit(contents.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
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

    var refComponents = ref.split(
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
      return findFile(filename: tagOrBranchName, directory: branchHeadsUrl).map { p in
        Reference.branch(p.lastPathComponent)
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

  // Attempt to expand a partial id into a full id
  private func expandPartialId(_ id: String) -> String? {
    let (prefix, partialSuffix) = (String(id.prefix(2)), String(id.dropFirst(2)))
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
      return prefix + url.lastPathComponent
    }
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
      guard id.count >= 6 else {
        return nil
      }

      if id.count == 40 {
        return ref
      } else {
        return expandPartialId(id).map { .commit($0) }        
      }
    }
  }

  func resolve(ref: String) -> Reference? {
    return resolve(.unknown(ref))
  }

  // TODO: this entire method could be much more easily
  // implemented in bash (see scripts/zig-init)
  class func initRepo() -> Repository? {
    let cwdUrl = URL(fileURLWithPath: fileman.currentDirectoryPath)
    let zigDir = cwdUrl.appendingPathComponent(".zig")

    guard !fileman.fileExists(atPath: zigDir.path) else {
      print("Directory already contains a repository")
      return nil
    }

    try! fileman.createDirectory(at: zigDir, withIntermediateDirectories: false, attributes: nil)

    fileman.createFile(atPath: zigDir.appendingPathComponent("HEAD").path, contents: "refs/heads/master".data(using: .utf8), attributes: nil)

    let headsDir = zigDir.appendingPathComponent("refs").appendingPathComponent("heads")
    try! fileman.createDirectory(at: headsDir, withIntermediateDirectories: true, attributes: nil)

    fileman.createFile(
      atPath: headsDir.appendingPathComponent("master", isDirectory: false).path,
      contents: nil,
      attributes: nil
    )

    let tagsDir = zigDir.appendingPathComponent("refs").appendingPathComponent("tags")
    try! fileman.createDirectory(at: tagsDir, withIntermediateDirectories: true, attributes: nil)

    return Repository()
  }

  /// Create tag with name pointing to ref
  func createTag(_ name: String, ref: Reference?) {
    let tagURL = tagsUrl.appendingPathComponent(name)

    let tagRef = ref ?? resolve(.head)
    guard let commitId = tagRef?.resolve(repository: self)?.commit else {
      print("Could not resolve ref")
      return
    }
    trounce(tagURL, content: commitId.data(using: .utf8)!)
  }

  func createBranch(_ name: String, ref: Reference?) {
    let branchURL = branchHeadsUrl.appendingPathComponent(name)

    let branchRef = ref ?? resolve(.head)
    guard let commitId = branchRef?.resolve(repository: self)?.commit else {
      print("Could not resolve ref")
      return
    }
    trounce(branchURL, content: commitId.data(using: .utf8)!)
  }

//  func show(_ path: String, ref: Reference) {
////    let showUrl = rootUrl.appendingPathComponent(path)
//    guard let commitId = resolve(ref).commit else {
//      fatalError("Could not resolve ref")
//    }
//
//    let components = path.split(separator: "/")
//    guard let commit = readObject(id: commitId, type: Commit.self) else {
//      fatalError("Could not read object with id \(commitId)")
//    }
//
//    commit.treeId
//  }
}
