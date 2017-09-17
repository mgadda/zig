//
//  data.swift
//  zig
//
//  Created by Matt Gadda on 9/13/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

/*
 
indirect enum Treeish {
  case blob(content: Data)
  case tree(entries: Array<Entry>)
  case commit(parentId: Data?, author: Author, createdAt: Date, treeId: Data, message: String)

  var id: Data {
    switch self {
    case .blob(let content):
      var blobData = Data()
      blobData.append("blob".data(using: .utf8)!)
      blobData.append(content);
      return hash(data: blobData)

    case .tree(let entries):

      var treeData = Data()
      treeData.append("tree".data(using: .utf8)!)

      entries.forEach { entry in
        treeData.append(contentsOf: entry.name.data(using: .utf8)!)
        treeData.append(entry.treeishId)
        var perms = entry.permissions
        treeData.append(Data(bytes: &perms, count: MemoryLayout.size(ofValue: entry.permissions)))
      }
      return hash(data: treeData)

    case let .commit(parentId, author, createdAt, treeId, message):

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
  }

  func description(repository: Repository, verbose: Bool = false) -> String {
    switch self {
    case let .blob(content):
      if content.count > 0 {
        return String(data: content, encoding: .utf8)!
      } else {
        return "(empty)"
      }

    case let .tree(entries):
      return entries.map { entry in
        return "\(entry.permissions)\t\(entry.treeish(repository: repository).type())\t\(entry.treeishId.base16EncodedString())\t\(entry.name)\n"
        }.joined()
      
    case let .commit(parentId, author, createdAt, treeId, message):
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

  func type() -> String {
    switch self {
    case .blob: return "blob"
    case .tree: return "tree"
    case .commit: return "commit"
    }
  }

  func writeObject(repository: Repository) {
    repository.writeObject(treeish: self)
  }

  static func readObject(id: Data, repository: Repository) -> Treeish? {
    return repository.readObject(id: id)
  }


  private func hash(data: Data) -> Data {
    var digest = [UInt8](repeating: 0,  count: Int(CC_SHA1_DIGEST_LENGTH))
    let _ = data.withUnsafeBytes {
      CC_SHA1($0, CC_LONG(data.count), &digest)
    }
    return Data(bytes: digest)
  }
}

extension Treeish {
  class ForCoding : NSObject, NSCoding {
    var treeish: Treeish?
    init(treeish: Treeish) {
      self.treeish = treeish
    }

    required init?(coder aDecoder: NSCoder) {
      switch aDecoder.decodeObject(forKey: "type") as? String {
      case .some("blob"):
        let content = aDecoder.decodeObject(forKey: "content") as! Data
        treeish = Treeish.blob(content: content)
        break
      case .some("commit"):
        let parentId = aDecoder.decodeObject(forKey: "parentId") as? Data 
        let name = aDecoder.decodeObject(forKey: "author.name") as! String
        let email = aDecoder.decodeObject(forKey: "author.email") as! String
        let createdAt = aDecoder.decodeObject(forKey: "createdAt") as! Date
        let treeId = aDecoder.decodeObject(forKey: "treeId") as! Data
        let message = aDecoder.decodeObject(forKey: "message") as! String
        treeish = Treeish.commit(parentId: parentId, author: Author(name: name, email: email), createdAt: createdAt, treeId: treeId, message: message)
        break
      case .some("tree"):
        let entriesForCoding = aDecoder.decodeObject(forKey: "entries") as! [Entry.ForCoding]
        treeish = Treeish.tree(entries: entriesForCoding.map { $0.entry! })
        break
      default:
        break
      }
    }

    func encode(with aCoder: NSCoder) {
      treeish.map {
        switch $0 {
        case let .blob(content):
          aCoder.encode("blob", forKey: "type")
          aCoder.encode(content, forKey: "content")
          break
        case let .commit(maybeParentId, author, createdAt, treeId, message):
          aCoder.encode("commit", forKey: "type")
          if let parentId = maybeParentId {
            aCoder.encode(parentId, forKey: "parentId")
          }
          aCoder.encode(author.name, forKey: "author.name")
          aCoder.encode(author.email, forKey: "author.email")
          aCoder.encode(createdAt, forKey: "createdAt")
          aCoder.encode(treeId, forKey: "treeId")
          aCoder.encode(message, forKey: "message")
          break
        case let .tree(entries):
          aCoder.encode("tree", forKey: "type")
          aCoder.encode(entries.map { Entry.ForCoding($0) }, forKey: "entries")
        }
      }
    }
  }
}

*/

