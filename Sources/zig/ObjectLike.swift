//
//  ObjectLike.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation
import CryptoSwift

protocol ObjectLike : NSCoding {
  var type: String { get }
  var id: Data { get }
  func description(repository: Repository, verbose: Bool) -> String
}

extension ObjectLike {
  func hash(data: Data) -> Data {
    return data.sha1()    
  }
}

struct Author {
  let name: String
  let email: String
}

class Commit : NSObject, ObjectLike {

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

  // NSCoding
  required init?(coder aDecoder: NSCoder) {
    self.parentId = aDecoder.decodeObject(forKey: "parentId") as? Data
    self.author = Author(
      name: aDecoder.decodeObject(forKey: "author.name") as! String,
      email: aDecoder.decodeObject(forKey: "author.email") as! String)
    self.createdAt = aDecoder.decodeObject(forKey: "createdAt") as! Date
    self.treeId = aDecoder.decodeObject(forKey: "treeId") as! Data
    self.message = aDecoder.decodeObject(forKey: "message") as! String
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode("commit", forKey: "type")
    parentId.map { aCoder.encode($0, forKey: "parentId") }
    aCoder.encode(author.name, forKey: "author.name")
    aCoder.encode(author.email, forKey: "author.email")
    aCoder.encode(createdAt, forKey: "createdAt")
    aCoder.encode(treeId, forKey: "treeId")
    aCoder.encode(message, forKey: "message")
  }
}

class Blob : NSObject, ObjectLike {
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

  // NSCoding
  required init?(coder aDecoder: NSCoder) {
    self.content = aDecoder.decodeObject(forKey: "content") as! Data
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode("blob", forKey: "type")
    aCoder.encode(content, forKey: "content")
  }
}

class Tree : NSObject, ObjectLike {
  let entries: [Entry]

  var type: String = "tree"
  var id: Data {
    var treeData = Data()
    treeData.append("tree".data(using: .utf8)!)

    entries.forEach { entry in
      treeData.append(contentsOf: entry.name.data(using: .utf8)!)
      treeData.append(entry.objectId)
      var perms = entry.permissions
      treeData.append(Data(bytes: &perms, count: MemoryLayout.size(ofValue: entry.permissions)))
    }
    return hash(data: treeData)
  }

  func description(repository: Repository, verbose: Bool) -> String {
    return entries.map { entry in
      return "\(entry.permissions)\t\(entry.object(repository: repository).type)\t\(entry.objectId.base16EncodedString())\t\(entry.name)\n"
      }.joined()
  }

  init(entries: [Entry]) {
    self.entries = entries
  }

  // NSCoding
  required init?(coder aDecoder: NSCoder) {
    self.entries = aDecoder.decodeObject(forKey: "entries") as! [Entry]
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode("tree", forKey: "type")
    aCoder.encode(entries, forKey: "entries")
  }

}

class Entry : NSObject, NSCoding {
  let permissions: Int
  var objectId: Data
  let name: String

  func object(repository: Repository) -> ObjectLike {
    return repository.readObject(id: self.objectId)!
  }

  init(permissions: Int, objectId: Data, name: String) {
    self.permissions = permissions
    self.objectId = objectId
    self.name = name
  }

  required init?(coder aDecoder: NSCoder) {
    self.permissions = aDecoder.decodeInteger(forKey: "permissions")
    guard let name = aDecoder.decodeObject(forKey: "name") as? String else { return nil }
    guard let id = aDecoder.decodeObject(forKey: "objectId") as? Data else { return nil }
    self.name = name
    self.objectId = id
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode(permissions, forKey: "permissions")
    aCoder.encode(name, forKey: "name")
    aCoder.encode(objectId, forKey: "objectId")
  }
}

