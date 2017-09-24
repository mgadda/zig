import Foundation

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

  enum CodingKeys : CodingKey {
    case permissions, objectId, objectType, name
  }

  init(permissions: Int, objectId: Data, objectType: String, name: String) {
    self.permissions = permissions
    self.objectId = objectId
    self.objectType = objectType
    self.name = name
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    permissions = try values.decode(Int.self, forKey: .permissions)
    objectId = try values.decode(String.self, forKey: .objectId).base16DecodedData()
    objectType = try values.decode(String.self, forKey: .objectType)
    name = try values.decode(String.self, forKey: .name)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(permissions, forKey: .permissions)
    try container.encode(objectId.base16EncodedString(), forKey: .objectId)
    try container.encode(objectType, forKey: .objectType)
    try container.encode(name, forKey: .name)
  }
}
