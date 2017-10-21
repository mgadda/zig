//
//  MessagePackEncodingStorage.swift
//  zigPackageDescription
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

internal struct MessagePackEncodingStorage {
  var containers: [BoxedValue] = []
  init() {}
  var count: Int {
    return containers.count
  }

  mutating func pushKeyedContainer() -> MutableDictionaryReference<BoxedValue, BoxedValue> {
    let dictRef = MutableDictionaryReference<BoxedValue, BoxedValue>()
    let boxedDictionary = BoxedValue.map(dictRef)
    self.containers.append(boxedDictionary)
    return dictRef
  }

  mutating func pushUnkeyedContainer() -> MutableArrayReference<BoxedValue> {
    let arrayRef = MutableArrayReference<BoxedValue>()
    let boxedArray = BoxedValue.array(arrayRef)
    self.containers.append(boxedArray)
    return arrayRef
  }

  mutating func push(container: BoxedValue) {
    self.containers.append(container)
  }

  mutating func popContainer() -> BoxedValue {
    precondition(self.containers.count > 0, "Empty container stack.")
    return self.containers.popLast()!
  }
}
