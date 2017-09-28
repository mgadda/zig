//
//  MessagePack.swift
//  zig
//
//  Created by Matt Gadda on 9/23/17.
//

import Foundation
import MessagePack


/// `MessagePackEncoder` facilitates the encoding of `Encodable` values into MessagePack format.
open class MessagePackEncoder {

  /// Contextual user-provided information for use during encoding.
  open var userInfo: [CodingUserInfoKey : Any] = [:]

  // MARK: - Constructing a MessagePack Encoder

  public init() {}

  // MARK: - Encoding Values

  /// Encodes the given top-level value and returns its MessagePack representation.
  ///
  /// - parameter value: The value to encode.
  /// - returns: A new `Data` value containing the encoded MessagePack data.
  /// - throws: An error if any value throws an error during encoding.
  open func encode<T : Encodable>(_ value: T) throws -> Data {
    let encoder = _MessagePackEncoder(userInfo: userInfo)
    guard let mpValue = try encoder.box_(value) else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
    }
    return pack(mpValue)
  }
}

internal class _MessagePackEncoder : Encoder {
  var codingPath: [CodingKey]

  var storage: MessagePackEncodingStorage
  let userInfo: [CodingUserInfoKey: Any]

  // MARK: - Initialization
  /// Initializes `self` with the given top-level encoder options.
  internal init(userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
    self.userInfo = userInfo
    self.storage = MessagePackEncodingStorage()
    self.codingPath = codingPath
  }

  /// Returns whether a new element can be encoded at this coding path.
  ///
  /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
  internal var canEncodeNewValue: Bool {
    return self.storage.count == self.codingPath.count
  }

  func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
    // If an existing keyed container was already requested, return that one.
    let topContainer: MessagePackValue
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushKeyedContainer()
    } else {
      guard let container = self.storage.containers.last else {
        preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
      }

      topContainer = container
    }

    let container = MessagePackKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    return KeyedEncodingContainer(container)
  }

  func unkeyedContainer() -> UnkeyedEncodingContainer {
    // If an existing unkeyed container was already requested, return that one.
    let topContainer: MessagePackValue
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushUnkeyedContainer()
    } else {
      guard let container = self.storage.containers.last else {
        preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
      }

      topContainer = container
    }

    return MessagePackUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
  }

  func singleValueContainer() -> SingleValueEncodingContainer {
    return self
  }
}

extension _MessagePackEncoder {
  /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
  internal func box(_ value: Bool)   -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Int)    -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Int8)   -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Int16)  -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Int32)  -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Int64)  -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: UInt)   -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: UInt8)  -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: UInt16) -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: UInt32) -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: UInt64) -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: String) -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Float)  -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Double) -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Data)   -> MessagePackValue { return MessagePackValue(value) }
  internal func box(_ value: Date)   -> MessagePackValue {
    return MessagePackValue(value.timeIntervalSince1970)
  }

  internal func box<T : Encodable>(_ value: T) throws -> MessagePackValue {
    return try self.box_(value) ?? MessagePackValue()
  }

  fileprivate func box_<T : Encodable>(_ value: T) throws -> MessagePackValue? {
//    if T.self == Date.self || T.self == NSDate.self {
//      // Respect Date encoding strategy
//      return try self.box((value as! Date))
//    } else if T.self == Data.self || T.self == NSData.self {
//      // Respect Data encoding strategy
//      return try self.box((value as! Data))
//    } else if T.self == URL.self || T.self == NSURL.self {
//      // Encode URLs as single strings.
//      return self.box((value as! URL).absoluteString)
//    } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
//      // JSONSerialization can natively handle NSDecimalNumber.
//      return (value as! NSDecimalNumber)
//    }

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

