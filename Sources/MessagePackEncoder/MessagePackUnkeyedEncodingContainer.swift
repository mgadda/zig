//
//  MessagePackUnkeyedEncodingContainer.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

internal class MessagePackUnkeyedEncodingContainer : UnkeyedEncodingContainer {
  private let encoder: _MessagePackEncoder
  private var container: MutableArrayReference<BoxedValue> = []
  private(set) public var codingPath: [CodingKey]

  public var count: Int {
    return self.container.count
  }

  internal init(referencing encoder: _MessagePackEncoder, codingPath: [CodingKey], wrapping container: MutableArrayReference<BoxedValue>) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }

  func encodeNil() throws { container.append(BoxedValue.`nil`) }
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
    defer { encoder.codingPath.removeLast() }
    container.append(try encoder.box(value))
  }

  func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    codingPath.append(MessagePackKey(index: count))
    defer { self.codingPath.removeLast() }

    let dictRef = MutableDictionaryReference<BoxedValue, BoxedValue>()
    let boxedDict: BoxedValue = .map(dictRef)
    self.container.append(boxedDict)

    let container = MessagePackKeyedEncodingContainer<NestedKey>(referencing: encoder, codingPath: codingPath, wrapping: dictRef)
    return KeyedEncodingContainer(container)
  }

  func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    codingPath.append(MessagePackKey(index: count))
    defer { codingPath.removeLast() }

    let arrayRef = MutableArrayReference<BoxedValue>()
    let boxedArray: BoxedValue = .array(arrayRef)
    container.append(boxedArray)
    return MessagePackUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: arrayRef)
  }

  func superEncoder() -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
  }
}
