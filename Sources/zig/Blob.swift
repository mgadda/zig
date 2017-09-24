//
//  Blob.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//

import Foundation

struct Blob : ObjectLike, Codable {
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

  enum CodingKeys : CodingKey {
    case content
  }
}
