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
  private var container: MutableDictionaryReference<BoxedValue, BoxedValue> = [:]
  private(set) public var codingPath: [CodingKey]

  internal init(referencing encoder: _MessagePackEncoder, codingPath: [CodingKey], wrapping container: MutableDictionaryReference<BoxedValue, BoxedValue>) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }

  func encodeNil(forKey key: MessagePackKeyedEncodingContainer.Key) throws { container[.string(key.stringValue)] = BoxedValue.`nil` }
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
    let dictRef = MutableDictionaryReference<BoxedValue, BoxedValue>()
    let boxedDict: BoxedValue = .map(dictRef)
    self.container[.string(key.stringValue)] = boxedDict

    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }

    let container = MessagePackKeyedEncodingContainer<NestedKey>(referencing: encoder, codingPath: codingPath, wrapping: dictRef)
    return KeyedEncodingContainer(container)
  }

  func nestedUnkeyedContainer(forKey key: MessagePackKeyedEncodingContainer.Key) -> UnkeyedEncodingContainer {
    let arrayRef = MutableArrayReference<BoxedValue>()
    let boxedArray: BoxedValue = .array(arrayRef)
    self.container[.string(key.stringValue)] = boxedArray

    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }
    return MessagePackUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: arrayRef)
  }

  func superEncoder() -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: MessagePackKey.super, wrapping: self.container)
  }

  func superEncoder(forKey key: MessagePackKeyedEncodingContainer.Key) -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
  }
}
