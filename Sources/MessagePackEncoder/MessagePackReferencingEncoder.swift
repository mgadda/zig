//
//  MessagePackReferencingEncoder.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

internal class MessagePackReferencingEncoder : _MessagePackEncoder {
  private enum Reference {
    case array(MutableArrayReference<BoxedValue>, Int)
    case dictionary(MutableDictionaryReference<BoxedValue, BoxedValue>, String)
  }

  let encoder: _MessagePackEncoder
  private let reference: Reference

  init(referencing encoder: _MessagePackEncoder, at index: Int, wrapping array: MutableArrayReference<BoxedValue>) {
    self.encoder = encoder
    self.reference = .array(array, index)
    super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

    codingPath.append(MessagePackKey(index: index))
  }

  init(referencing encoder: _MessagePackEncoder, at key: CodingKey, wrapping dictionary: MutableDictionaryReference<BoxedValue, BoxedValue>) {
    self.encoder = encoder
    self.reference = .dictionary(dictionary, key.stringValue)
    super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

    self.codingPath.append(key)
  }

  internal override var canEncodeNewValue: Bool {
    return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
  }

  deinit {
    let value: BoxedValue
    switch self.storage.count {
    case 0: value = BoxedValue.map(MutableDictionaryReference<BoxedValue, BoxedValue>())
    case 1: value = self.storage.popContainer()
    default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
    }

    switch self.reference {
    case .array(let arrayRef, let index):
      arrayRef.insert(value, at: index)

    case .dictionary(let dictRef, let key):
      dictRef[BoxedValue.string(key)] = value
    }
  }
}
