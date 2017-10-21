//
//  MessagePackKeyedDecodingContainer.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 10/1/17.
//

import Foundation
import MessagePack

internal class MessagePackKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
  typealias Key = K

  private let decoder: _MessagePackDecoder

  var codingPath: [CodingKey]
  var allKeys: [K] {
    return self.container.keys.flatMap { (boxedKey: MessagePackValue) -> Key? in
      guard case let .string(key) = boxedKey else {
        return nil
      }
      return Key(stringValue: key)
    }
  }
  let container: [MessagePackValue : MessagePackValue]

  internal init(decoder: _MessagePackDecoder, container: [MessagePackValue : MessagePackValue]) {
    self.decoder = decoder
    self.container = container
    self.codingPath = decoder.codingPath
  }

  func contains(_ key: K) -> Bool {
    return self.container[.string(key.stringValue)] != nil
  }

  private func extractValue(forKey key: K) throws -> MessagePackValue {
    guard let value = self.container[.string(key.stringValue)] else {
      throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key does not exist"))
    }
    return value
  }

  func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let boxedValue = try extractValue(forKey: key)

    guard let dictionaryValue = boxedValue.dictionaryValue else {
      throw DecodingError.typeMismatch([MessagePackValue : MessagePackValue].self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected MessagePackValue.map enum value"))
    }
    let innerContainer = MessagePackKeyedDecodingContainer<NestedKey>(decoder: self.decoder, container: dictionaryValue)
    return KeyedDecodingContainer(innerContainer)
  }

  func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let boxedValue = try extractValue(forKey: key)

    guard let arrayValue = boxedValue.arrayValue else {
      throw DecodingError.typeMismatch([MessagePackValue].self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected MessagePackValue.array enum value"))
    }

    return MessagePackUnkeyedDecodingContainer(decoder: self.decoder, container: arrayValue)
  }

  func _superDecoder(forKey key: CodingKey) throws -> Decoder {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let value = self.container[MessagePackValue(key.stringValue)] ?? MessagePackValue.nil
    return _MessagePackDecoder(referencing: value, at: self.decoder.codingPath)
  }

  func superDecoder(forKey key: K) throws -> Decoder {
    return try _superDecoder(forKey: key)
  }

  func superDecoder() throws -> Decoder {
    return try _superDecoder(forKey: MessagePackKey.super)
  }

  
  /// Decode non-standard types (i.e. your own types)
  func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
    let boxedValue = try extractValue(forKey: key)

    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try self.decoder.unbox(boxedValue, as: type) else {
      throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
    }
    return value
  }

  func decodeNil(forKey key: K) throws -> Bool {
    return try extractValue(forKey: key).isNil
  }

  func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: Int.Type, forKey key: K) throws -> Int {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
    return try Int16(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
    return try Int32(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
    return try UInt(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
    return try UInt8(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
    return try UInt16(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
    return try UInt32(self.decoder.unbox(extractValue(forKey: key), as: type))
  }

  func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: Float.Type, forKey key: K) throws -> Float {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: Double.Type, forKey key: K) throws -> Double {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }

  func decode(_ type: String.Type, forKey key: K) throws -> String {
    return try self.decoder.unbox(extractValue(forKey: key), as: type)
  }
}
