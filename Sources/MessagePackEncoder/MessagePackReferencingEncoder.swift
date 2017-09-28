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
    case array([MessagePackValue], Int)
    case dictionary([MessagePackValue : MessagePackValue], String)
  }

  let encoder: _MessagePackEncoder
  private let reference: Reference

  init(referencing encoder: _MessagePackEncoder, at index: Int, wrapping array: [MessagePackValue]) {
    self.encoder = encoder
    self.reference = .array(array, index)
    super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

    codingPath.append(MessagePackKey(index: index))
  }

  init(referencing encoder: _MessagePackEncoder, at key: CodingKey, wrapping dictionary: [MessagePackValue: MessagePackValue]) {
    self.encoder = encoder
    self.reference = .dictionary(dictionary, key.stringValue)
    super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

    self.codingPath.append(key)
  }

  // MARK: - Coding Path Operations

  internal override var canEncodeNewValue: Bool {
    // With a regular encoder, the storage and coding path grow together.
    // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
    // We have to take this into account.
    return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
  }

  // MARK: - Deinitialization

  // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
  deinit {
    let value: MessagePackValue
    switch self.storage.count {
    case 0: value = MessagePackValue.map([MessagePackValue : MessagePackValue]())
    case 1: value = self.storage.popContainer()
    default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
    }

    switch self.reference {
    case .array(var array, let index):
      array.insert(value, at: index)

    case .dictionary(var dictionary, let key):
      dictionary[MessagePackValue(key)] = value
    }
  }
}
