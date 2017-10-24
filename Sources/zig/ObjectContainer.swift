//
//  ObjectContainer.swift
//  zig
//
//  Created by Matt Gadda on 10/23/17.
//

struct ObjectContainer : Encodable {
  let id: String
  let type: String
  let object: ObjectLike

  init(object: ObjectLike) {
    self.id = object.id.base16EncodedString()
    self.object = object
    switch object {
    case is Blob:
      type = "blob"
      break
    case is Tree:
      type = "tree"
      break
    case is Commit:
      type = "commit"
      break
    default:
      fatalError("Object type not supported for JSON encoding")
      break
    }
  }
  enum CodingKeys : CodingKey {
    case id, type, object
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(type, forKey: .type)

    switch object {
    case let blob as Blob:
      try container.encode(blob, forKey: .object)

    case let tree as Tree:
      try container.encode(tree, forKey: .object)

    case let commit as Commit:
      try container.encode(commit, forKey: .object)

    default:
      fatalError("Object type not supported for JSON encoding")
    }
  }
}
