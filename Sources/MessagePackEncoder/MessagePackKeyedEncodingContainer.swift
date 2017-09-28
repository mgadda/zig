//
//  MessagePackKeyedEncodingContainer.swift
//  zigPackageDescription
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

internal class MessagePackKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
  typealias Key = K

  private let encoder: _MessagePackEncoder
  private var container: [MessagePackValue : MessagePackValue]
  private(set) public var codingPath: [CodingKey]

  internal init(referencing encoder: _MessagePackEncoder, codingPath: [CodingKey], wrapping container: MessagePackValue) {
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

    let container = MessagePackKeyedEncodingContainer<NestedKey>(referencing: encoder, codingPath: codingPath, wrapping: messagePackMap)
    return KeyedEncodingContainer(container)
  }

  func nestedUnkeyedContainer(forKey key: MessagePackKeyedEncodingContainer.Key) -> UnkeyedEncodingContainer {
    let messagePackArray: MessagePackValue = .array([MessagePackValue]())
    self.container[.string(key.stringValue)] = messagePackArray

    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }
    return MessagePackUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: messagePackArray)
  }

  func superEncoder() -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: MessagePackKey.super, wrapping: self.container)
  }

  func superEncoder(forKey key: MessagePackKeyedEncodingContainer.Key) -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
  }
}
