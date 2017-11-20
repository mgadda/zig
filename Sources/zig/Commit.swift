//
//  Commit.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//

import Foundation
import CMP

struct Author : Codable {
  let name: String
  let email: String
}

extension Author : Serializable {
  func serialize(encoder: CMPEncoder) {
    let container = encoder.keyedContainer()
    container.write(key: "name", value: name)
    container.write(key: "email", value: email)
    encoder.write(container)
  }
  init(with decoder: CMPDecoder) throws {
    let container = try decoder.read([
      "name": String.self,
      "email": String.self
    ])
    name = container["name"]! as! String
    email = container["email"]! as! String
  }
}

struct Commit : ObjectLike {

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
    out += "Author: \(author.name) <\(author.email)>\n"
    out += "Date: " + createdAt.debugDescription + "\n\n"
    out += "  " + message + "\n"
    return out

  }
}

extension Commit : Codable {
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    parentId = try values.decodeIfPresent(Data.self, forKey: .parentId)
    author = try values.decode(Author.self, forKey: .author)
    createdAt = try values.decode(Date.self, forKey: .createdAt)
    treeId = try values.decode(Data.self, forKey: .treeId)
    message = try values.decode(String.self, forKey: .message)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(parentId, forKey: .parentId)
    try container.encode(author, forKey: .author)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(treeId, forKey: .treeId)
    try container.encode(message, forKey: .message)
  }


  enum CodingKeys : CodingKey {
    case parentId, author, createdAt, treeId, message
  }
}


extension Commit : Serializable {
  func serialize(encoder: CMPEncoder) {
    let repo = (encoder.userContext as? Repository)
    let container = encoder.keyedContainer()

    if parentId != nil {
      container.write(key: "parentId", value: parentId!)
    }

    container.write(key: "author", value: author)
    container.write(key: "createdAt", value: createdAt.timeIntervalSince1970)
    container.write(key: "treeId", value: treeId)
    container.write(key: "message", value: message)

    if case let .some(.some(signature)) = try? repo?.gpg.sign(data: self.id, keyName: repo?.config.gpg?.key) {
      container.write(key: "signature", value: signature)
    }

    encoder.write(container)
  }

  init(with decoder: CMPDecoder) throws {
    let container = try decoder.read([
      "parentId": Data.self,
      "author": Author.self,
      "createdAt": TimeInterval.self,
      "treeId": Data.self,
      "message": String.self,
      "signature": Data.self
    ])

    parentId = container["parentId"] as? Data
    author = container["author"] as! Author
    createdAt = Date(timeIntervalSince1970: container["createdAt"] as! TimeInterval)
    treeId = container["treeId"] as! Data
    message = container["message"] as! String

    if let repo = decoder.userContext as? Repository,
       let signature = container["signature"] as? Data {

      if !(try repo.gpg.verify(data: id, signature: signature)) {
        throw ZigError.decodingError("WARNING: Object with id \(id) may have been tampered with")
      }
    }
  }
}
