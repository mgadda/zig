//
//  Tree.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//

import Foundation

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

  enum CodingKeys : CodingKey {
    case entries
  }
}

extension Tree : Serializable {
  func serialize(encoder: CMPEncoder) -> Data {
    encoder.write(entries)
    return encoder.buffer
  }

  static func deserialize(with decoder: CMPDecoder) -> Tree {
    return Tree(entries: decoder.read())
  }
}
