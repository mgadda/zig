//
//  Blob.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//

import Foundation
import CMP

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

  // TODO: can this be removed?
  func serialize(file: inout FileHandle) {
    defer { file.closeFile() }

    withUnsafePointer(to: &file) { (filePtr) in
      var context = cmp_ctx_t()
      let rawFilePtr = UnsafeMutableRawPointer(mutating: filePtr)
      cmp_init(&context, rawFilePtr, cmpFileReader, cmpFileSkipper, cmpFileWriter)

      let _ = content.compress()!.withUnsafeBytes( { contentPtr in
        cmp_write_bin(&context, UnsafeRawPointer(contentPtr), UInt32(content.count))        
      })
    }

    file.closeFile()
  }

  enum CodingKeys : CodingKey {
    case content
  }
}

extension Blob : Serializable {
  func serialize(encoder: CMPEncoder) {
    encoder.write(content)    
  }
  
  init(with decoder: CMPDecoder) throws {
    content = decoder.read()
  }
}
