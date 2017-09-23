//
//  ObjectLike.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

protocol ObjectLike : Codable {
  var type: String { get }
  var id: Data { get }
  func description(repository: Repository, verbose: Bool) -> String
}

extension ObjectLike {
  func hash(data: Data) -> Data {
    var digest = [UInt8](repeating: 0,  count: Int(CC_SHA1_DIGEST_LENGTH))
    let _ = data.withUnsafeBytes {
      CC_SHA1($0, CC_LONG(data.count), &digest)
    }
    return Data(bytes: digest)
  }
}

struct Author : Codable {
  let name: String
  let email: String
}

struct Commit : ObjectLike, Codable {

  let parentId: Data?
  let author: Author
  let createdAt: Date
  let treeId: Data
  let message: String

  init(parentId: Data?, author: Author, createdAt: Date, treeId: Data, message: String) {
    self.parentId = parentId
    self.author = author
    self.createdAt = createdAt
    self.treeId = treeId
    self.message = message
  }

  var type: String = "commit"
  var id: Data {
    var commitData = Data()
    commitData.append("commit".data(using: .utf8)!)
    parentId?.forEach { commitData.append($0) }
    commitData.append(author.name.data(using: .utf8)!)
    commitData.append(author.email.data(using: .utf8)!)
    var createdAtMut = Int(createdAt.timeIntervalSince1970)
    commitData.append(Data(bytes: &createdAtMut, count: MemoryLayout.size(ofValue: createdAtMut)))
    commitData.append(treeId)
    commitData.append(message.data(using: .utf8)!)

    return hash(data: commitData)
  }

  func description(repository: Repository, verbose: Bool = false) -> String {
    var out: String
    out = "commit: \(self.id.base16EncodedString())\n".withANSIColor(color: .yellow)
    if verbose {
      out += "Tree: \(treeId.base16EncodedString())"
      out += "\nParent: " + (parentId?.base16EncodedString() ?? "(no parent)") + "\n"
    }
    out += "Author: \(author.name) \(author.email)\n"
    out += "Date: " + createdAt.debugDescription + "\n\n"
    out += "  " + message + "\n"
    return out

  }
}

class Blob : ObjectLike, Codable {
  let content: Data

  var type: String = "blob"
  var id: Data {
    var blobData = Data()
    blobData.append("blob".data(using: .utf8)!)
    blobData.append(content);
    return hash(data: blobData)
  }

  init(content: Data) {
    self.content = content
  }

  func description(repository: Repository, verbose: Bool) -> String {
    if content.count > 0 {
      return String(data: content, encoding: .utf8)!
    } else {
      return "(empty)"
    }
  }
}

struct Tree : ObjectLike, Codable {
  let entries: [Entry]

  init(entries: [Entry]) {
    self.entries = entries
  }

  var type: String = "tree"
  var id: Data {
    var treeData = Data()
    treeData.append("tree".data(using: .utf8)!)

    entries.forEach { entry in
      treeData.append(contentsOf: entry.name.data(using: .utf8)!)
      treeData.append(entry.objectId)
      treeData.append(entry.objectType.data(using: .utf8)!)

      var perms = entry.permissions
      treeData.append(Data(bytes: &perms, count: MemoryLayout.size(ofValue: entry.permissions)))
    }
    return hash(data: treeData)
  }

  func description(repository: Repository, verbose: Bool) -> String {
    return entries.map { entry in
      return "\(entry.permissions)\t\(entry.objectType)\t\(entry.objectId.base16EncodedString())\t\(entry.name)\n"
      }.joined()
  }
}

struct Entry : Codable, Hashable {
  let permissions: Int
  let objectId: Data
  let objectType: String // TODO: make enum
  let name: String

  var hashValue: Int {
    return permissions.hashValue ^ objectId.hashValue ^ name.hashValue
  }

  static func ==(left: Entry, right: Entry) -> Bool {
    return left.permissions == right.permissions &&
      left.objectId == right.objectId &&
      left.name == right.name
  }
}

