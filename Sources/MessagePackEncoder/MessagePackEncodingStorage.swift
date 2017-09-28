//
//  MessagePackEncodingStorage.swift
//  zigPackageDescription
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

internal struct MessagePackEncodingStorage {
  var containers: [MessagePackValue] = []
  init() {}
  var count: Int {
    return containers.count
  }

  mutating func pushKeyedContainer() -> MessagePackValue {
    let dictionary = MessagePackValue.map([MessagePackValue : MessagePackValue]())
    self.containers.append(dictionary)
    return dictionary
  }

  mutating func pushUnkeyedContainer() -> MessagePackValue {
    let array = MessagePackValue.array([MessagePackValue]())
    self.containers.append(array)
    return array
  }

  mutating func push(container: MessagePackValue) {
    self.containers.append(container)
  }

  mutating func popContainer() -> MessagePackValue {
    precondition(self.containers.count > 0, "Empty container stack.")
    return self.containers.popLast()!
  }
}
