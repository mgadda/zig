//
//  MessagePack.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//
// MessagePackEncoder uses the same design patterns and naming conventions as
// found Apple Swift's JSONEncoder.swift
// See: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/JSONEncoder.swift

import Foundation
import MessagePack

/// `MessagePackEncoder` facilitates the encoding of `Encodable` values into MessagePack format.
open class MessagePackEncoder {
  open var userInfo: [CodingUserInfoKey : Any] = [:]

  public init() {}

  open func encode<T : Encodable>(_ value: T) throws -> Data {
    let encoder = _MessagePackEncoder(userInfo: userInfo)
    guard let boxedValue = try encoder.box_(value) else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
    }
    return pack(MessagePackValue(boxedValue: boxedValue))
  }
}

internal class _MessagePackEncoder : Encoder {
  var codingPath: [CodingKey]

  var storage: MessagePackEncodingStorage
  let userInfo: [CodingUserInfoKey: Any]

  internal init(userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
    self.userInfo = userInfo
    self.storage = MessagePackEncodingStorage()
    self.codingPath = codingPath
  }

  internal var canEncodeNewValue: Bool {
    return self.storage.count == self.codingPath.count
  }

  func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
    // If an existing keyed container was already requested, return that one.
    let topContainer: MutableDictionaryReference<BoxedValue, BoxedValue>
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushKeyedContainer()
    } else {
      guard let container = self.storage.containers.last else {
        preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
      }

      guard case let .map(dictContainer) = container else {
        preconditionFailure("Previously encoded container at this path must be a BoxedValue.map")
      }

      topContainer = dictContainer
    }

    let container = MessagePackKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    return KeyedEncodingContainer(container)
  }

  func unkeyedContainer() -> UnkeyedEncodingContainer {
    // If an existing unkeyed container was already requested, return that one.
    let topContainer: MutableArrayReference<BoxedValue>
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushUnkeyedContainer()
    } else {
      guard let container = self.storage.containers.last else {
        preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
      }

      guard case let .array(arrayContainer) = container else {
        preconditionFailure("Previously encoded container at this path must be a BoxedValue.array")
      }

      topContainer = arrayContainer
    }

    return MessagePackUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
  }

  func singleValueContainer() -> SingleValueEncodingContainer {
    return self
  }
}

extension _MessagePackEncoder {
  /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
  internal func box(_ value: Bool)   -> BoxedValue { return BoxedValue.bool(value) }
  internal func box(_ value: Int)    -> BoxedValue { return BoxedValue.int(Int64(value)) }
  internal func box(_ value: Int8)   -> BoxedValue { return BoxedValue.int(Int64(value)) }
  internal func box(_ value: Int16)  -> BoxedValue { return BoxedValue.int(Int64(value)) }
  internal func box(_ value: Int32)  -> BoxedValue { return BoxedValue.int(Int64(value)) }
  internal func box(_ value: Int64)  -> BoxedValue { return BoxedValue.int(value) }
  internal func box(_ value: UInt)   -> BoxedValue { return BoxedValue.uint(UInt64(value)) }
  internal func box(_ value: UInt8)  -> BoxedValue { return BoxedValue.uint(UInt64(value)) }
  internal func box(_ value: UInt16) -> BoxedValue { return BoxedValue.uint(UInt64(value)) }
  internal func box(_ value: UInt32) -> BoxedValue { return BoxedValue.uint(UInt64(value)) }
  internal func box(_ value: UInt64) -> BoxedValue { return BoxedValue.uint(value) }
  internal func box(_ value: String) -> BoxedValue { return BoxedValue.string(value) }
  internal func box(_ value: Float)  -> BoxedValue { return BoxedValue.float(value) }
  internal func box(_ value: Double) -> BoxedValue { return BoxedValue.double(value) }
  internal func box(_ value: Data)   -> BoxedValue { return BoxedValue.binary(value) }
  internal func box(_ value: Date)   -> BoxedValue {
    return BoxedValue.double(value.timeIntervalSince1970)
  }

  internal func box<T : Encodable>(_ value: T) throws -> BoxedValue {
    return try self.box_(value) ?? BoxedValue.`nil`
  }

  fileprivate func box_<T : Encodable>(_ value: T) throws -> BoxedValue? {
    // The value should request a container from the _JSONEncoder.
    let depth = self.storage.count
    try value.encode(to: self)

    // The top container should be a new container.
    guard self.storage.count > depth else {
      return nil
    }

    return self.storage.popContainer()
  }
}


