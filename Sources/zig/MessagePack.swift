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

  fileprivate class _MessagePackEncoder : Encoder {
    var codingPath: [CodingKey]

    var storage: _MessagePackEncodingStorage
    let userInfo: [CodingUserInfoKey: Any]

    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
      self.userInfo = userInfo
      self.storage = _MessagePackEncodingStorage()
      self.codingPath = codingPath
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
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

  fileprivate struct _MessagePackEncodingStorage {
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
}

fileprivate class MessagePackKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
  typealias Key = K

  private let encoder: MessagePackEncoder._MessagePackEncoder
  private var container: [MessagePackValue : MessagePackValue]
  private(set) public var codingPath: [CodingKey]

  fileprivate init(referencing encoder: MessagePackEncoder._MessagePackEncoder, codingPath: [CodingKey], wrapping container: MessagePackValue) {
    self.encoder = encoder
    self.codingPath = codingPath
    switch container {
    case let .map(map):
      self.container = map
    default:
      preconditionFailure("MessagePackUnkeyedEncodingContainer wrapping container must be enum value of MessagePackValue.map")
    }
  }

  func encodeNil(forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = MessagePackValue() }
  func encode(_ value: Bool, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Int, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Int8, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Int16, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Int32, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Int64, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: UInt, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: UInt8, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: UInt16, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: UInt32, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: UInt64, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Float, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: Double, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }
  func encode(_ value: String, forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = encoder.box(value) }

  func encode<T>(_ value: T, forKey key: MessagePackKeyedEncodingContainer.Key) throws where T : Encodable {
    encoder.codingPath.append(key)
    defer { encoder.codingPath.removeLast() }
    self.container[.string(key.stringValue)] = try encoder.box(value)
  }

//  func encodeConditional<T>(_ object: T, forKey key: MessagePackKeyedEncodingContainer.Key) throws where T : AnyObject, T : Encodable {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Bool?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Int?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Int8?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Int16?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Int32?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Int64?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: UInt?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: UInt8?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: UInt16?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: UInt32?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: UInt64?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Float?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: Double?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent(_ value: String?, forKey key: MessagePackKeyedEncodingContainer.Key) throws {
//    <#code#>
//  }
//
//  func encodeIfPresent<T>(_ value: T?, forKey key: MessagePackKeyedEncodingContainer.Key) throws where T : Encodable {
//    <#code#>
//  }

  func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: MessagePackKeyedEncodingContainer.Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    let messagePackMap: MessagePackValue = .map([MessagePackValue : MessagePackValue]())
    self.container[.string(key.stringValue)] = messagePackMap

    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }

    let container = MessagePackKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: messagePackMap)
    return KeyedEncodingContainer(container)
  }

  func nestedUnkeyedContainer(forKey key: MessagePackKeyedEncodingContainer.Key) -> UnkeyedEncodingContainer {
    let messagePackArray: MessagePackValue = .array([MessagePackValue]())
    self.container[.string(key.stringValue)] = messagePackArray

    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }
    return MessagePackUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: messagePackArray)
  }

  func superEncoder() -> Encoder {
    <#code#>
  }

  func superEncoder(forKey key: MessagePackKeyedEncodingContainer.Key) -> Encoder {
    <#code#>
  }
}

fileprivate class MessagePackUnkeyedEncodingContainer : UnkeyedEncodingContainer {
  private let encoder: MessagePackEncoder._MessagePackEncoder

  /// A reference to the container we're writing to.
  private var container: [MessagePackValue]

  /// The path of coding keys taken to get to this point in encoding.
  private(set) public var codingPath: [CodingKey]

  /// The number of elements encoded into the container.
  public var count: Int {
    return self.container.count
  }

  fileprivate init(referencing encoder: MessagePackEncoder._MessagePackEncoder, codingPath: [CodingKey], wrapping container: MessagePackValue) {
    self.encoder = encoder
    self.codingPath = codingPath
    switch container {
    case let .array(array):
      self.container = array
    default:
      preconditionFailure("MessagePackUnkeyedEncodingContainer wrapping container must be enum value of MessagePackValue.array")
    }
  }

  func encodeNil() throws { container.append(MessagePackValue()) }
  func encode(_ value: Bool) throws { container.append(encoder.box(value)) }
  func encode(_ value: Int) throws { container.append(encoder.box(value)) }
  func encode(_ value: Int8) throws { container.append(encoder.box(value)) }
  func encode(_ value: Int16) throws { container.append(encoder.box(value)) }
  func encode(_ value: Int32) throws { container.append(encoder.box(value)) }
  func encode(_ value: Int64) throws { container.append(encoder.box(value)) }
  func encode(_ value: UInt) throws { container.append(encoder.box(value)) }
  func encode(_ value: UInt8) throws { container.append(encoder.box(value)) }
  func encode(_ value: UInt16) throws { container.append(encoder.box(value)) }
  func encode(_ value: UInt32) throws { container.append(encoder.box(value)) }
  func encode(_ value: UInt64) throws { container.append(encoder.box(value)) }
  func encode(_ value: Float) throws { container.append(encoder.box(value)) }
  func encode(_ value: Double) throws { container.append(encoder.box(value)) }
  func encode(_ value: String) throws { container.append(encoder.box(value)) }

  func encode<T>(_ value: T) throws where T : Encodable {
    encoder.codingPath.append(MessagePackKey(index: self.count))
    defer { self.encoder.codingPath.removeLast() }
    self.container.add(try encoder.box(value))
  }

  func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    <#code#>
  }

  func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    <#code#>
  }

  func superEncoder() -> Encoder {
    <#code#>
  }


}
extension MessagePackEncoder._MessagePackEncoder : SingleValueEncodingContainer {
  fileprivate func assertCanEncodeNewValue() {
    precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
  }

  public func encodeNil() throws {
    assertCanEncodeNewValue()
    self.storage.push(container: MessagePackValue())
  }

  func encode(_ value: Bool) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Float) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Double) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: String) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode<T>(_ value: T) throws where T : Encodable {
    assertCanEncodeNewValue()
    try self.storage.push(container: box(value))

  }
}

extension MessagePackEncoder._MessagePackEncoder {
  /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
  fileprivate func box(_ value: Bool)   -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Int)    -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Int8)   -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Int16)  -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Int32)  -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Int64)  -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: UInt)   -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: UInt8)  -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: UInt16) -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: UInt32) -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: UInt64) -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: String) -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Float)  -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Double) -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Data)   -> MessagePackValue { return MessagePackValue(value) }
  fileprivate func box(_ value: Date)   -> MessagePackValue { return MessagePackValue(value.timeIntervalSince1970) }

  fileprivate func box<T : Encodable>(_ value: T) throws -> MessagePackValue {
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

/*
class MessagePackDecoder : Decoder {
  var codingPath: [CodingKey]

  var userInfo: [CodingUserInfoKey : Any]

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
    <#code#>
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    <#code#>
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    <#code#>
  }


}
*/
