//
//  data.swift
//  zig
//
//  Created by Matt Gadda on 9/13/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

enum ZigError : Error {
  case DataError(String)
}

let ZigDir = "/tmp/zig"

indirect enum Treeish : Sequence {
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

  func debugDescription() -> String {
    switch self {
    case let .blob(content):
      if content.count > 0 {
        return String(data: content, encoding: .utf8)!
      } else {
        return "(empty)"
      }

    case let .tree(entries):
      return entries.map { entry in
        var mutableEntry = entry // TODO: this is gross
        return "\(entry.permissions)\t\(mutableEntry.treeish.type())\t\(entry.treeishId.base16EncodedString())\t\(entry.name)\n"
        }.joined()
      
    case let .commit(parentId, author, createdAt, treeId, message):
      var out: String
      out = "Commit: \(self.id.base16EncodedString())\n"
      out += "Tree: \(treeId.base16EncodedString())"
      out += "\nParent: " + (parentId?.base16EncodedString() ?? "(no parent)") + "\n"
      out += "\(author.name) \(author.email)\n"
      out += createdAt.debugDescription + "\n\n"
      out += message + "\n"
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

  func makeIterator() -> TreeishIterator {
    return TreeishIterator(self)
  }

  func writeObject() {
    zig.writeObject(treeish: self)
  }

  static func readObject(id: Data) -> Treeish? {
    return zig.readObject(id: id)
  }


  private func hash(data: Data) -> Data {
    var digest = [UInt8](repeating: 0,  count: Int(CC_SHA1_DIGEST_LENGTH))
    let _ = data.withUnsafeBytes {
      CC_SHA1($0, CC_LONG(data.count), &digest)
    }
    return Data(bytes: digest)
  }
}

struct TreeishIterator : IteratorProtocol {
  var treeish: Treeish?
  init(_ treeish: Treeish) {
    self.treeish = treeish
  }
  mutating func next() -> Treeish? {
    switch treeish {
    case .some(.commit(let maybeParentId, _, _, _, _)):
      return maybeParentId.flatMap { parentId in
        treeish = readObject(id: parentId)
        return treeish
      }
    default:
      return nil
    }
  }
}

struct Entry {
  let permissions: Int
  var treeishId: Data
  let name: String
  lazy var treeish: Treeish = {
    return readObject(id: self.treeishId)!
  }()

  init(permissions: Int, treeishId: Data, name: String) {
    self.permissions = permissions
    self.treeishId = treeishId
    self.name = name
  }
}

extension Entry {
  class ForCoding : NSObject, NSCoding {
    var entry: Entry?
    init(_ anEntry: Entry) {
      self.entry = anEntry
    }

    required init?(coder aDecoder: NSCoder) {      
      let perms = aDecoder.decodeInteger(forKey: "permissions")
      guard let name = aDecoder.decodeObject(forKey: "name") as? String else { return }
      guard let id = aDecoder.decodeObject(forKey: "treeishId") as? Data else { return }
      entry = Entry(permissions: perms, treeishId: id, name: name)
    }

    func encode(with aCoder: NSCoder) {
      entry.map {
        aCoder.encode($0.permissions, forKey: "permissions")
        aCoder.encode($0.name, forKey: "name")
        aCoder.encode($0.treeishId, forKey: "treeishId")
      }

    }

  }
}

struct Author {
  let name: String
  let email: String
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

extension Data {
  func base16EncodedString() -> String {
    return self.map { String(format: "%02hhx", $0) }.joined()
  }
}

extension String {
  func base16DecodedData() -> Data {
    var data = Data()
    let chs = Array(characters)
    let ints = stride(from: 0, to: chs.count, by: 2).map { idx in
      UInt8("\(chs[idx])\(chs[idx+1])", radix: 16)!
    }
    data.append(contentsOf: ints)
    return data
  }
}

func splitId(id: Data) -> (String, String) {
  return (
    Data(id.prefix(1)).base16EncodedString(),
    Data(id.dropFirst(1)).base16EncodedString()
  )
}

func getRepositoryRoot(startingAt cwd: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> URL? {


  if FileManager.default.fileExists(atPath: cwd.appendingPathComponent(".zig").path) {
    return cwd
  } else {
    if cwd.deletingLastPathComponent().path == "/" {
      return nil
    }
    return getRepositoryRoot(startingAt: cwd.deletingLastPathComponent())
  }
}

func writeObject(treeish: Treeish) {
  guard let rootDir = getRepositoryRoot() else { return }

  let objectDir = rootDir.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)

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
  guard let rootDir = getRepositoryRoot() else { return nil }

  let objectDir = rootDir.appendingPathComponent(".zig", isDirectory: true).appendingPathComponent("objects", isDirectory: true)

  let (objIdPrefix, filename) = splitId(id: id)

  let prefixedObjDir = objectDir.appendingPathComponent(objIdPrefix, isDirectory: true)

  let fileURL = prefixedObjDir.appendingPathComponent(filename)
  let coding = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? Treeish.ForCoding
  return coding.flatMap { $0.treeish }
}



