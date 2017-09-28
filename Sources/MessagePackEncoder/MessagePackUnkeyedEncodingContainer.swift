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
  private var container: [MessagePackValue]
  private(set) public var codingPath: [CodingKey]

  public var count: Int {
    return self.container.count
  }

  internal init(referencing encoder: _MessagePackEncoder, codingPath: [CodingKey], wrapping container: MessagePackValue) {
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
    defer { encoder.codingPath.removeLast() }
    container.append(try encoder.box(value))
  }

  func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    codingPath.append(MessagePackKey(index: count))
    defer { self.codingPath.removeLast() }

    let messagePackMap: MessagePackValue = .map([MessagePackValue : MessagePackValue]())
    self.container.append(messagePackMap)

    let container = MessagePackKeyedEncodingContainer<NestedKey>(referencing: encoder, codingPath: codingPath, wrapping: messagePackMap)
    return KeyedEncodingContainer(container)
  }

  func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    codingPath.append(MessagePackKey(index: count))
    defer { codingPath.removeLast() }

    let messagePackArray: MessagePackValue = .array([MessagePackValue]())
    container.append(messagePackArray)
    return MessagePackUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: messagePackArray)
  }

  func superEncoder() -> Encoder {
    return MessagePackReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
  }
}
