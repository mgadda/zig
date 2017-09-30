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

/*
internal struct MessagePackEncodingStorage {
  var containers: [BoxedValue] = []
  init() {}
  var count: Int {
    return containers.count
  }

  mutating func pushKeyedContainer() -> BoxedValue {
    let dictionary = BoxedValue.map(MutableDictionaryReference<BoxedValue, BoxedValue>())
    self.containers.append(dictionary)
    return dictionary
  }

  mutating func pushUnkeyedContainer() -> BoxedValue {
    let array = BoxedValue.array(MutableArrayReference<BoxedValue>())
    self.containers.append(array)
    return array
  }

  mutating func push(container: BoxedValue) {
    self.containers.append(container)
  }

  mutating func popContainer() -> BoxedValue {
    precondition(self.containers.count > 0, "Empty container stack.")
    return self.containers.popLast()!
  }
}
*/
