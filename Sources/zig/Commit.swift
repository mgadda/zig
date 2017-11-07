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
  let gpgKey: String?
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
//    encoder.write("commit")
    // TODO: support keyed containers so we don't have to encode empty field
    encoder.write(parentId ?? Data())
    encoder.write(author.name)
    encoder.write(author.email)
    encoder.write(author.gpgKey ?? "")
    encoder.write(Int(createdAt.timeIntervalSince1970))
    encoder.write(treeId)
    encoder.write(message)

    let commitDataUrl = URL(fileURLWithPath: "/tmp/commit.dat")
    try! encoder.buffer.write(to: commitDataUrl)

    let gpg = Process()
    gpg.launchPath = "/usr/bin/env"
    var arguments = ["gpg"]
    if let gpgKey = author.gpgKey {
      arguments += ["--default-key", gpgKey]
    }
    arguments += ["--output", "/tmp/commit.sig", "--detach-sign", "/tmp/commit"]
    gpg.launch()
    gpg.waitUntilExit()

    let signature = try! Data(contentsOf: URL(fileURLWithPath: "/tmp/commit.sig"))
    encoder.write(signature)

    try! FileManager.default.removeItem(at: commitDataUrl)
  }

  init(with decoder: CMPDecoder) throws {
    let signedCommitData: Data = decoder.read()

    let commitSigUrl = URL(fileURLWithPath: "/tmp/commit.sig")
    try! decoder.buffer.write(to: commitSigUrl)

    let gpg = Process()
    gpg.launchPath = "/usr/bin/env"
    gpg.arguments = ["gpg", "--verify", "/tmp/commit.sig"]


    let pipe = Pipe()
    gpg.standardOutput = pipe

    gpg.launch()
    gpg.waitUntilExit()

    let gpgData = pipe.fileHandleForReading.readDataToEndOfFile()

    try! FileManager.default.removeItem(at: commitSigUrl)

    let gpgDecoder = CMPDecoder(from: signedCommitData)

    let maybeParentId: Data = gpgDecoder.read()
    let createdAtInterval: Int = gpgDecoder.read()
    createdAt = Date(timeIntervalSince1970: TimeInterval(createdAtInterval))
    treeId = gpgDecoder.read()
    message = try gpgDecoder.read()

    if maybeParentId.count == 0 {
      parentId = nil
    } else {
      parentId = maybeParentId
    }
  }
}
