//
//  ObjectId.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

extension Data {
  func base16EncodedString() -> String {
    return self.map { String(format: "%02hhx", $0) }.joined()
  }
}

extension String {
  func base16DecodedData() -> Data {
    var data = Data()
    let chs = Array(self)
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


struct ObjectId {
  let data: Data
  var hex: String {
    get {
      return data.map { String(format: "%02hhx", $0) }.joined()
    }
  }

  static func fromHexString(str: String) -> ObjectId? {
    var newData = Data()
    let chs = Array(str)
    let ints = stride(from: 0, to: chs.count, by: 2).map { idx in
      UInt8("\(chs[idx])\(chs[idx+1])", radix: 16)
    }

    guard ints.filter({ $0 == nil }).count == 0 else {
      return nil
    }

    newData.append(contentsOf: ints.map { $0! })
    return ObjectId(data: newData)
  }

  func description() -> String {
    return hex
  }
}
